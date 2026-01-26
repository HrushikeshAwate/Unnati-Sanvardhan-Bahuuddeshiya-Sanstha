import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:usbs/core/widgets/logout_confirn_dialog.dart';

import '../../../config/routes/route_names.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// 🔹 Local asset images
  final List<String> _images = const [
    'assets/images/banner_1.jpeg',
    'assets/images/banner_2.jpeg',
    'assets/images/banner_3.jpeg',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload images to avoid grey flash
    for (final img in _images) {
      precacheImage(AssetImage(img), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          /// 🔥 Full height carousel
          CarouselSlider.builder(
            itemCount: _images.length,
            options: CarouselOptions(
              height: height,
              viewportFraction: 1,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 1200),
              autoPlayCurve: Curves.easeInOutCubic,
              enableInfiniteScroll: true,
              onPageChanged: (index, _) {
                setState(() => _currentIndex = index);
              },
            ),
            itemBuilder: (context, index, _) {
              return SizedBox(
                width: double.infinity,
                child: Image.asset(_images[index], fit: BoxFit.cover),
              );
            },
          ),

          /// 🌑 Dark overlay
          Container(height: height, color: Colors.black.withOpacity(0.45)),

          /// 🧭 Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  const Text(
                    'NGO Support Services',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Legal • Medical • Education\nSupporting communities with care',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),

                  const SizedBox(height: 40),

                  _actionButton(
                    context,
                    title: 'Legal Services',
                    route: RouteNames.legalInfo,
                  ),
                  _actionButton(
                    context,
                    title: 'Medical Services',
                    route: RouteNames.medicalInfo,
                  ),
                  _actionButton(
                    context,
                    title: 'Education Services',
                    route: RouteNames.educationInfo,
                  ),
                  _actionButton(
                    context,
                    title: 'Photo Gallery',
                    route: RouteNames.photoGallery,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          /// ⚪ Indicators
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _images.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentIndex == entry.key ? 14 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentIndex == entry.key
                        ? Colors.white
                        : Colors.white54,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Translucent AppBar with logo + profile + logout
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.25),
      elevation: 0,
      centerTitle: false,

      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Image.asset('assets/logo.png', height: 34),
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            Navigator.pushNamed(context, RouteNames.profile);
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            LogoutConfirmDialog.show(context);
          },
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  /// 🔹 Reusable action button
  Widget _actionButton(
    BuildContext context, {
    required String title,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => Navigator.pushNamed(context, route),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
