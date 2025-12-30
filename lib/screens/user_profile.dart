import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  String? imagePath;
  String? onlineImageUrl;
  String userName = "";

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    if (user == null) return;

    final response = await supabase
        .from('user_profiles')
        .select()
        .eq('id', user!.id)
        .maybeSingle();

    if (response != null) {
      nameController.text = response['name'] ?? "";
      phoneController.text = response['phone'] ?? "";
      addressController.text = response['address'] ?? "";
      onlineImageUrl = response['image_url'];
      userName = response['name'] ?? "User";
      setState(() {});
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => imagePath = picked.path);
  }

  Future<String?> uploadImageToSupabase() async {
    if (imagePath == null) return onlineImageUrl;

    final file = File(imagePath!);
    final fileName = "${user!.id}.jpg";

    await supabase.storage.from('profile_pics').upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return supabase.storage.from('profile_pics').getPublicUrl(fileName);
  }

  Future<void> saveProfile() async {
    final imageUrl = await uploadImageToSupabase();

    await supabase.from('user_profiles').upsert({
      'id': user!.id,
      'name': nameController.text,
      'phone': phoneController.text,
      'address': addressController.text,
      'image_url': imageUrl,
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Details saved successfully")));

    fetchUserProfile();
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
      padding: const EdgeInsets.all(12),
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

            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white24,
                backgroundImage: imagePath != null
                    ? FileImage(File(imagePath!))
                    : (onlineImageUrl != null
                    ? NetworkImage(onlineImageUrl!)
                    : null),
                child: (imagePath == null && onlineImageUrl == null)
                    ? const Icon(Icons.person, color: Colors.white, size: 80)
                    : null,
              ),
            ),

            const SizedBox(height: 25),

            Text(
              "Hey, $userName 👋",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600),
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
              child:
              const Text("Sign Out", style: TextStyle(color: Colors.white70)),
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
