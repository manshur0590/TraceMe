import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'sign_in.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool isLoading = false;

  // 🔥 SIGN UP FUNCTION WITH SUPABASE
  void signUpUser() async {
    // 🔒 Basic validation
    if (nameController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1️⃣ Create Account (Auth SignUp)
      final user = await _authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        // 2️⃣ Insert user profile data into Supabase Table `users`
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'mobile': mobileController.text.trim(),
          'address': "",
          'imageUrl': "",
          'role': "user",
          'createdAt': DateTime.now().toIso8601String(),
        });

        // 3️⃣ Navigate to Login
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup failed! Try again.")),
        );
      }
    } catch (e) {
      // 🛑 Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/bg.jpg", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),

          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Create Your TraceMe Account",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),

                        _frostedTextField(
                          controller: nameController,
                          hint: "Full Name",
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 15),

                        _frostedTextField(
                          controller: mobileController,
                          hint: "Mobile Number",
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 15),

                        _frostedTextField(
                          controller: emailController,
                          hint: "Email",
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),

                        _frostedTextField(
                          controller: passwordController,
                          hint: "Password",
                          icon: Icons.lock,
                          obscureText: true,
                        ),

                        const SizedBox(height: 25),

                        ElevatedButton(
                          onPressed: isLoading ? null : signUpUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 80,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 15),

                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignInScreen()),
                            );
                          },
                          child: const Text(
                            "Already have an account? Sign In",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
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

  // ✨ Frosted Text Field Widget
  Widget _frostedTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        floatingLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
