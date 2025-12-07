import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;

  // Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  String? imagePath; // Local file path
  String? onlineImageUrl; // To load saved image

  @override
  void initState() {
    super.initState();
    fetchUserProfile(); // Load saved data
  }

  Future<void> fetchUserProfile() async {
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .maybeSingle();

    if (response != null) {
      nameController.text = response['name'] ?? "";
      phoneController.text = response['phone'] ?? "";
      addressController.text = response['address'] ?? "";
      onlineImageUrl = response['image_url'];
      setState(() {});
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => imagePath = picked.path);
    }
  }

  Future<String?> uploadImageToSupabase() async {
    if (imagePath == null) return onlineImageUrl;

    try {
      final file = File(imagePath!);
      final fileName = "${user!.id}.jpg";

      // Upload to Supabase Storage
      await supabase.storage.from('profile_pics').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get image URL
      final publicUrl = supabase.storage
          .from('profile_pics')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  Future<void> saveProfile() async {
    final imageUrl = await uploadImageToSupabase();

    await supabase.from('profiles').upsert({
      'id': user!.id,
      'email': user!.email,
      'name': nameController.text,
      'phone': phoneController.text,
      'address': addressController.text,
      'image_url': imageUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Details saved successfully")),
    );

    fetchUserProfile(); // Reload saved data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/bg_index.jpg", fit: BoxFit.cover),
          frostedGlassLayout(),
        ],
      ),
    );
  }

  Widget frostedGlassLayout() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white30, width: 1.5),
            ),
            child: profileContent(),
          ),
        ),
      ),
    );
  }

  Widget profileContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Circle
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white24,
                backgroundImage: imagePath != null
                    ? FileImage(File(imagePath!))
                    : (onlineImageUrl != null
                    ? NetworkImage(onlineImageUrl!)
                    : null) as ImageProvider?,
                child: (imagePath == null && onlineImageUrl == null)
                    ? const Icon(Icons.person, color: Colors.white, size: 80)
                    : null,
              ),
            ),

            const SizedBox(height: 25),

            // Email
            Text(
              user?.email ?? "No Email",
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            buildTextField("Full Name", nameController),
            buildTextField("Phone Number", phoneController,
                keyboard: TextInputType.phone),
            buildTextField("Address", addressController, maxLines: 2),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: saveProfile,
              child: const Text("Save Details",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () async {
                await supabase.auth.signOut();
                Navigator.pop(context);
              },
              child: const Text("Sign Out", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.white24),
          ),
        ),
      ),
    );
  }
}
