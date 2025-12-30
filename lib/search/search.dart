import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // Required for FaceNet processing
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _missingPeople = [];
  List<Map<String, dynamic>> _filteredPeople = [];

  Interpreter? _interpreter;
  String? _searchImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModel();
    fetchMissingPeople();
  }

  // Load the FaceNet Model from assets
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('models/facenet.tflite');
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  // Initial fetch: Displays all registered data
  Future<void> fetchMissingPeople() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('missing_persons').select();
      setState(() {
        _missingPeople = List<Map<String, dynamic>>.from(response);
        _filteredPeople = _missingPeople;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Text search logic
  void _filterSearchResults(String query) {
    setState(() {
      _filteredPeople = _missingPeople.where((p) {
        final name = (p["name"] ?? "Unknown").toLowerCase();
        final location = (p["last_seen_location"] ?? "").toLowerCase();
        final notes = (p["notes"] ?? "").toLowerCase();
        return name.contains(query.toLowerCase()) ||
            location.contains(query.toLowerCase()) ||
            notes.contains(query.toLowerCase());
      }).toList();
    });
  }

  // FaceNet Image Processing
  Future<List<double>> _extractEmbedding(String path) async {
    final imageBytes = File(path).readAsBytesSync();
    final decoded = img.decodeImage(imageBytes)!;
    final resized = img.copyResize(decoded, width: 160, height: 160);

    var input = List.generate(1, (_) =>
        List.generate(160, (_) =>
            List.generate(160, (_) => List.filled(3, 0.0))));

    for (int y = 0; y < 160; y++) {
      for (int x = 0; x < 160; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    var output = List.filled(1 * 128, 0.0).reshape([1, 128]);
    _interpreter?.run(input, output);

    return List<double>.from(output[0]);
  }

  // Face search using Supabase RPC
  Future<void> _searchByFace() async {
    if (_searchImagePath == null) return;
    setState(() => _isLoading = true);

    try {
      final embedding = await _extractEmbedding(_searchImagePath!);

      final List<dynamic> response = await supabase.rpc(
        'match_missing_person',
        params: {
          'query_embedding': embedding,
          'threshold': 0.5,
        },
      );

      setState(() {
        _filteredPeople = List<Map<String, dynamic>>.from(response);
      });

      if (_filteredPeople.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No face match found in database")),
        );
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFaceImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _searchImagePath = picked.path);
      await _searchByFace();
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  "Report Missing Person",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ✅ Face Search Section FIRST
            Column(
              children: [
                const Text(
                  "Find Your Missing Family & Friend",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickFaceImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                    _searchImagePath != null ? FileImage(File(_searchImagePath!)) : null,
                    child: _searchImagePath == null
                        ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Text Search Field BELOW Face Search
            TextField(
              controller: _searchController,
              onChanged: _filterSearchResults,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by name, location, or clue",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Results List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _filteredPeople.isEmpty
                  ? const Center(
                  child: Text("No records found", style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                itemCount: _filteredPeople.length,
                itemBuilder: (context, index) {
                  final person = _filteredPeople[index];
                  return Card(
                    color: Colors.white.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          person['img_url'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                          const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                      title: Text(
                        person["name"] ?? "Unknown",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Age: ${person["age"] ?? "N/A"} | Location: ${person["last_seen_location"] ?? "N/A"}\nNotes: ${person["notes"] ?? "-"}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
