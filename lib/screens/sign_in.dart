import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sign_up.dart';
import 'index.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> signInUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const IndexPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login failed. Check your credentials."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/bg.jpg",
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 80, color: Colors.white),
                          const SizedBox(height: 15),
                          const Text(
                            "Welcome Back 👋",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                    blurRadius: 6,
                                    color: Colors.black54,
                                    offset: Offset(0, 2))
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: const TextStyle(color: Colors.white),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Colors.white),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: const TextStyle(color: Colors.white),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.white),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: signInUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.white.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                side: const BorderSide(
                                    color: Colors.white70, width: 1.2),
                              ),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen()),
                              );
                            },
                            child: const Text(
                              "Don't have an account? Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                      blurRadius: 6,
                                      color: Colors.black54,
                                      offset: Offset(0, 2))
                                ],
                              ),
                            ),
                          ),
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
}
