import 'package:flutter/material.dart';
import '../screens/sign_in.dart';   // 👈 make sure this path is correct

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 🚪 Logout (Only Navigation, No Firebase)
  void logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔐 Logout Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => logout(context),
                  tooltip: "Logout",
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              "Welcome to Missing People Finder",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Your safety companion. Search, report, and help identify missing individuals.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 30),

            const HomeCard(
              title: "Search Missing People",
              icon: Icons.search,
            ),

            const SizedBox(height: 15),

            const HomeCard(
              title: "Report a Missing Person",
              icon: Icons.report,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const HomeCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
