import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Added
import 'package:image/image.dart' as img; // Added

class ReportMissingScreen extends StatefulWidget {
  const ReportMissingScreen({super.key});

  @override
  State<ReportMissingScreen> createState() => _ReportMissingScreenState();
}

class _ReportMissingScreenState extends State<ReportMissingScreen> {
  File? selectedImage;
  bool isUploading = false;
  String? uploadedImageUrl;
  Interpreter? _interpreter; // Added for TFLite

  final picker = ImagePicker();

  // 🔑 Cloudinary Keys
  final String cloudName = "dkm2h9psc";
  final String uploadPreset = "TraceMe";

  // ✏️ Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController clothingController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController locationDescriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
    } catch (e) {
      debugPrint("Failed to load model: $e");
    }
  }

  Future<List<double>> _extractEmbedding(File imageFile) async {
    final imageBytes = imageFile.readAsBytesSync();
    final decoded = img.decodeImage(imageBytes)!;
    final resized = img.copyResize(decoded, width: 160, height: 160);

    var input = List.generate(1, (_) => List.generate(160, (_) => List.generate(160, (_) => List.filled(3, 0.0))));

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

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> uploadToCloudinary() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final embedding = await _extractEmbedding(selectedImage!);

      final List<dynamic> matches = await Supabase.instance.client.rpc(
          'match_missing_person',
          params: {'query_embedding': embedding, 'threshold': 0.4}
      );

      if (matches.isNotEmpty) {
        final match = matches[0];
        nameController.text = match['name'] ?? "";

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Possible Match Found!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Name: ${match['name'] ?? 'Unknown'}"),
                if (match['img_url'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.network(match['img_url'], height: 150),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      }

      final url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";
      final request = http.MultipartRequest("POST", Uri.parse(url))
        ..fields["upload_preset"] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", selectedImage!.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      uploadedImageUrl = jsonData["secure_url"];

      await saveReportToSupabase(embedding);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Process failed: $e")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> saveReportToSupabase(List<double> embedding) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('missing_persons').insert({
        'img_url': uploadedImageUrl,
        'name': nameController.text.isEmpty ? null : nameController.text,
        'age': ageController.text.isNotEmpty ? int.tryParse(ageController.text) : null,
        'clothing_color': clothingController.text,
        'last_seen_location': locationController.text,
        'location_description': locationDescriptionController.text,
        'notes': notesController.text.isNotEmpty ? notesController.text : null,
        'face_embedding': embedding,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report saved successfully!")),
      );

      setState(() {
        selectedImage = null;
        uploadedImageUrl = null;
      });

      nameController.clear();
      ageController.clear();
      clothingController.clear();
      locationController.clear();
      locationDescriptionController.clear();
      notesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error saving report: $e")),
      );
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // title: const Text("Report Missing Person"),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/bg_index.jpg", fit: BoxFit.cover),

          // ✅ Fixed Welcome Header at top
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
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
          ),

          // Scrollable Form below header
          Padding(
            padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white60),
                        color: Colors.white.withOpacity(0.12),
                        image: selectedImage != null
                            ? DecorationImage(
                          image: FileImage(selectedImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: selectedImage == null
                          ? const Center(
                        child: Text(
                          "📸 Tap to select picture",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  buildGlassInput(nameController, "Full Name (optional)"),
                  const SizedBox(height: 12),
                  buildGlassInput(ageController, "Estimated Age", type: TextInputType.number),
                  const SizedBox(height: 12),
                  buildGlassInput(clothingController, "Clothing Color"),
                  const SizedBox(height: 12),
                  buildGlassInput(locationController, "Last Seen Location", hint: "City / Street / Area"),
                  const SizedBox(height: 12),
                  buildGlassInput(locationDescriptionController, "Describe the Location", hint: "Near temple, behind school, beside market...", maxLines: 3),
                  const SizedBox(height: 12),
                  buildGlassInput(notesController, "Additional Notes (optional)", maxLines: 3),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: isUploading ? null : uploadToCloudinary,
                      child: isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Report"),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGlassInput(TextEditingController controller, String label,
      {String? hint, TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white70)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white60)),
      ),
    );
  }
}
