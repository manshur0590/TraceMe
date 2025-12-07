import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadService {
  static final _client = Supabase.instance.client;

  static Future<String?> uploadProfileImage(String uid, File file) async {
    try {
      final fileName = "$uid.jpg";

      // Upload file to Supabase Storage
      await _client.storage.from('profile_pics').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // Return public image URL
      return _client.storage.from('profile_pics').getPublicUrl(fileName);
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}
