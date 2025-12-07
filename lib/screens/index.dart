import 'dart:ui';
import 'package:flutter/material.dart';
import '../search/search.dart';
import '../report/report_home.dart';
import 'user_profile.dart';
import 'sign_in.dart';
import '../home/home.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const SearchScreen(),
    const ReportMissingScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg_index.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // Active Screen Content
          Positioned.fill(
            child: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),

      // Frosted Glass Bottom Navigation Bar
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              border: Border.all(
                color: Colors.white30,
                width: 1,
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: "Search",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.report),
                  label: "Report",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
