import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:usbs/core/widgets/logout_confirn_dialog.dart';

import '../../../config/routes/route_names.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<String> _images = const [
    'assets/images/banner_1.jpeg',
    'assets/images/banner_2.jpeg',
    'assets/images/banner_3.jpeg',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final img in _images) {
      precacheImage(AssetImage(img), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: _buildDrawer(context),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          CarouselSlider.builder(
            itemCount: _images.length,
            options: CarouselOptions(
              height: height,
              viewportFraction: 1,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration:
                  const Duration(milliseconds: 1200),
              autoPlayCurve: Curves.easeInOutCubic,
              onPageChanged: (index, _) {
                setState(() => _currentIndex = index);
              },
            ),
            itemBuilder: (context, index, _) {
              return Image.asset(
                _images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),

          Container(height: height, color: Colors.black.withOpacity(0.45)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  const Text(
                    'Unnati Sanvardhan Bahuuddeshiya Sanstha',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Legal • Medical • Education\nSupporting communities with care',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
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
                    title: 'Answer Queries',
                    route: RouteNames.adminQueries,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

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

  /// 🔹 AppBar
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.6),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Image.asset(
            'assets/logo.png',
            height: 28,
            width: 28,
            fit: BoxFit.contain,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        'USBS',
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Colors.white),
      ),
      centerTitle: true,
      actions: [
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

  /// 🔹 Drawer (SUPERADMIN OPTION FIXED)
  Drawer _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                height: 60,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, RouteNames.profile);
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, RouteNames.about);
            },
          ),

          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Photo Gallery'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, RouteNames.photoGallery);
            },
          ),

          /// 🔐 SUPERADMIN ONLY: ASSIGN QUERIES
          if (user != null)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final role = snapshot.data!.data()?['role'];

                if (role == 'superadmin') {
                  return ListTile(
                    leading: const Icon(Icons.assignment_ind),
                    title: const Text('Assign Queries'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        RouteNames.assignQueries,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
