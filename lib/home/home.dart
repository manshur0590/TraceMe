import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/sign_in.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> registeredPeople = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRegisteredPeople();
  }

  Future<void> fetchRegisteredPeople() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.from('missing_persons').select();
      setState(() {
        registeredPeople = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching registered people: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Top fixed section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Welcome Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Welcome TraceMe",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "10K Happy Family reunite",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Auto-scrolling Horizontal Cards
                const AutoScrollFamilyCarousel(),

                const SizedBox(height: 20),

                const Text(
                  "Recent Reported Missing Persons",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Only this section scrollable
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: registeredPeople.length,
              itemBuilder: (context, index) {
                final person = registeredPeople[index];
                return Card(
                  color: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        person['img_url'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                        const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    title: Text(
                      person["name"] ?? "Unknown",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Age: ${person["age"] ?? "N/A"} | Location: ${person["last_seen_location"] ?? "N/A"}\nNotes: ${person["notes"] ?? "-"}",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
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

// Horizontal Card with frosted white bottom for info
class FamilyReuniteCard extends StatelessWidget {
  final String name;
  final String address;
  final String imagePath;
  final double rating;
  final String description;

  const FamilyReuniteCard({
    super.key,
    required this.name,
    required this.address,
    required this.imagePath,
    required this.rating,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // White frosted info box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  address,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Auto-scrolling Carousel Widget
class AutoScrollFamilyCarousel extends StatefulWidget {
  const AutoScrollFamilyCarousel({super.key});

  @override
  State<AutoScrollFamilyCarousel> createState() =>
      _AutoScrollFamilyCarouselState();
}

class _AutoScrollFamilyCarouselState extends State<AutoScrollFamilyCarousel> {
  final ScrollController _scrollController = ScrollController();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double current = _scrollController.offset;
        double next = current + 220 + 12; // card width + spacing

        if (next >= maxScroll) {
          next = 0; // loop back to start
        }

        _scrollController.animateTo(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        children: const [
          SizedBox(width: 4),
          FamilyReuniteCard(
            name: "Arjun Patel",
            address: "Ahmedabad, Gujarat",
            rating: 4.9,
            description: "Reunited successfully",
            imagePath: "assets/images/f1.jpeg",
          ),
          SizedBox(width: 12),
          FamilyReuniteCard(
            name: "Sara Khan",
            address: "Mumbai, Maharashtra",
            rating: 4.8,
            description: "Family found with help of TraceMe.",
            imagePath: "assets/images/f2.jpeg",
          ),
          SizedBox(width: 12),
          FamilyReuniteCard(
            name: "Manshur Ali",
            address: "Delhi, India",
            rating: 4.7,
            description: "Happy reunion in city center.",
            imagePath: "assets/images/f3.jpeg",
          ),
          SizedBox(width: 12),
          FamilyReuniteCard(
            name: "Arman Ali",
            address: "Rajkot, India",
            rating: 4.7,
            description: "Found after 1 week of search.",
            imagePath: "assets/images/f4.jpeg",
          ),
          SizedBox(width: 12),
          FamilyReuniteCard(
            name: "Md Sadab",
            address: "Gopalgaanj, India",
            rating: 4.7,
            description: "Family safely reunited.",
            imagePath: "assets/images/f5.jpeg",
          ),
          SizedBox(width: 4),
        ],
      ),
    );
  }
}
