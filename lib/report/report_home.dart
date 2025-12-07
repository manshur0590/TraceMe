import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportMissingScreen extends StatefulWidget {
  const ReportMissingScreen({super.key});

  @override
  State<ReportMissingScreen> createState() => _ReportMissingScreenState();
}

class _ReportMissingScreenState extends State<ReportMissingScreen> {
  File? selectedImage;
  bool isUploading = false;
  String? uploadedImageUrl;

  final picker = ImagePicker();

  // 🔑 Cloudinary Keys
  final String cloudName = "dkm2h9psc";
  final String uploadPreset = "TraceMe";

  // 🔑 Face Recognition API
  final String faceSearchApi = "https://YOUR_BACKEND_URL/search-face"; // Replace with your FastAPI URL

  // ✏️ Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController clothingController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController locationDescriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // 📌 Pick Image
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  // ☁️ Upload To Cloudinary
  Future<void> uploadToCloudinary() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      final request = http.MultipartRequest("POST", Uri.parse(url))
        ..fields["upload_preset"] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", selectedImage!.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      setState(() => uploadedImageUrl = jsonData["secure_url"]);

      // 🔍 Call face search API
      final matchResult = await searchFace(selectedImage!);

      if (matchResult != null) {
        // Pre-fill Name field if match found
        nameController.text = matchResult['name'] ?? "";

        // Show match info in a dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Match Found!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Name: ${matchResult['name']}"),
                Text("Distance: ${matchResult['distance']}"),
                if (matchResult['photo_url'] != null)
                  Image.network(matchResult['photo_url']),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

      // 💾 Save Report To Supabase
      await saveReportToSupabase();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  // 🔍 Call FastAPI Face Recognition
  Future<Map<String, dynamic>?> searchFace(File image) async {
    try {
      var request = http.MultipartRequest("POST", Uri.parse(faceSearchApi));
      request.files.add(await http.MultipartFile.fromPath("file", image.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final jsonRes = jsonDecode(resStr);

        if (jsonRes.containsKey("message") && jsonRes["message"] == "No match found") {
          return null;
        }
        return jsonRes;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error calling face recognition API")),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Face recognition error: $e")),
      );
      return null;
    }
  }

  // 💾 Save Report To Supabase
  Future<void> saveReportToSupabase() async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('missing_persons').insert({
        'img_url': uploadedImageUrl,
        'name': nameController.text.isEmpty ? null : nameController.text,
        'age': ageController.text.isNotEmpty
            ? int.tryParse(ageController.text)
            : null,
        'clothing_color': clothingController.text,
        'last_seen_location': locationController.text,
        'location_description': locationDescriptionController.text,
        'notes':
        notesController.text.isNotEmpty ? notesController.text : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report saved successfully!")),
      );

      // Clear all after submit
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Report Missing Person"),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌄 Background Image
          Image.asset(
            "assets/images/bg_index.jpg",
            fit: BoxFit.cover,
          ),

          // ❄️ Frosted Glass Container
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white30, width: 1.4),
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),

                          /// 🖼️ Image Picker
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

                          // 🌐 Input Fields
                          buildGlassInput(nameController, "Full Name (optional)"),
                          const SizedBox(height: 12),
                          buildGlassInput(ageController, "Estimated Age",
                              type: TextInputType.number),
                          const SizedBox(height: 12),
                          buildGlassInput(clothingController, "Clothing Color"),
                          const SizedBox(height: 12),
                          buildGlassInput(locationController, "Last Seen Location",
                              hint: "City / Street / Area"),
                          const SizedBox(height: 12),
                          buildGlassInput(locationDescriptionController,
                              "Describe the Location",
                              hint:
                              "Near temple, behind school, beside market...",
                              maxLines: 3),
                          const SizedBox(height: 12),
                          buildGlassInput(notesController, "Additional Notes (optional)",
                              maxLines: 3),

                          const SizedBox(height: 20),

                          /// ☁️ Upload Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: isUploading ? null : uploadToCloudinary,
                              child: isUploading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Upload & Submit Report"),
                            ),
                          ),

                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 Reusable Frosted Text Fields
  Widget buildGlassInput(
      TextEditingController controller, String label,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white60),
        ),
      ),
    );
  }
}
