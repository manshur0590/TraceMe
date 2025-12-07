import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _missingPeople = [
    {"name": "Unknown Male", "age": "35", "location": "Hyderabad", "status": "Unidentified"},
    {"name": "Unidentified Female", "age": "25", "location": "Chennai", "status": "Found unconscious"},
    {"name": "Child - No name", "age": "6", "location": "Bangalore", "status": "Found at railway station"},
    {"name": "Unknown Elder", "age": "70", "location": "Mumbai", "status": "Found wandering"},
  ];

  List<Map<String, String>> _filteredPeople = [];

  // Face search variables
  String? _searchImagePath;
  String? _faceSearchResult;

  @override
  void initState() {
    super.initState();
    _filteredPeople = _missingPeople;
  }

  void _filterSearchResults(String query) {
    setState(() {
      _filteredPeople = _missingPeople
          .where((person) =>
      person["name"]!.toLowerCase().contains(query.toLowerCase()) ||
          person["location"]!.toLowerCase().contains(query.toLowerCase()) ||
          person["status"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _pickFaceImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _searchImagePath = picked.path;
        _faceSearchResult = null; // Reset previous result
      });
    }
  }

  Future<void> _searchByFace() async {
    if (_searchImagePath == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://your-backend.com/search-face'), // Replace with your API
    );
    request.files.add(await http.MultipartFile.fromPath('file', _searchImagePath!));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final data = jsonDecode(respStr);

    setState(() {
      if (data['distance'] != null && data['distance'] < 0.8) {
        _faceSearchResult = "Match Found: ${data['name']}";
      } else {
        _faceSearchResult = "No match found";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text(
            "Search Missing People",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Text search field
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

          // Face search section
          Column(
            children: [
              const Text(
                "Or search by face",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickFaceImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white24,
                  backgroundImage: _searchImagePath != null
                      ? FileImage(File(_searchImagePath!))
                      : null,
                  child: _searchImagePath == null
                      ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _searchByFace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Search", style: TextStyle(color: Colors.white)),
              ),
              if (_faceSearchResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _faceSearchResult!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Filtered list
          Expanded(
            child: _filteredPeople.isEmpty
                ? const Center(
              child: Text(
                "No matching records found.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: _filteredPeople.length,
              itemBuilder: (context, index) {
                final person = _filteredPeople[index];
                return Card(
                  color: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: Text(
                      person["name"]!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Age: ${person["age"]} | Location: ${person["location"]}\nStatus: ${person["status"]}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
