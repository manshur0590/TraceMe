import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _auth = Supabase.instance.client;

  /// 📌 Get Current User
  User? getCurrentUser() => _auth.auth.currentUser;

  /// 🔐 SIGN UP USER (Supabase)
  Future<User?> signUp(String email, String password) async {
    try {
      final response = await _auth.auth.signUp(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      print("SignUp Error: $e");
      return null;
    }
  }

  /// 🔑 SIGN IN USER (Supabase)
  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _auth.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      print("SignIn Error: $e");
      return null;
    }
  }

  /// 🚪 SIGN OUT USER
  Future<void> signOut() async {
    try {
      await _auth.auth.signOut();
    } catch (e) {
      print("SignOut Error: $e");
    }
  }
}
