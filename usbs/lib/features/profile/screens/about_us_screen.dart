import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// NGO NAME
            const Text(
              'Unnati Sanvardhan Bahuuddeshiya Sanstha',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'War Taluka, District Dhule, Maharashtra',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            /// ABOUT
            const Text(
              'About the Organization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Unnati Sanvardhan Bahuuddeshiya Sanstha is a registered Public Trust '
              'working towards social welfare and community development. '
              'The organization aims to support individuals and communities through '
              'initiatives in legal awareness, medical assistance, education, and '
              'other social support services.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),

            const SizedBox(height: 24),

            /// REGISTRATION DETAILS
            const Text(
              'Registration Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            _infoTile(
              title: 'Registration Act',
              value: 'Mumbai Public Trust Act, 1950',
            ),
            _infoTile(
              title: 'Registration Number',
              value: 'F-0015533 (DHL)',
            ),
            _infoTile(
              title: 'Registration Office',
              value: 'Public Trust Registration Office, Dhule',
            ),
            _infoTile(
              title: 'Date of Registration',
              value: '21 November 2024',
            ),

            const SizedBox(height: 24),

            /// VISION
            const Text(
              'Our Vision',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'To build a supportive and inclusive society by providing access to '
              'essential services, promoting awareness, and empowering communities '
              'to lead dignified and secure lives.',
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  /// REUSABLE INFO TILE
  Widget _infoTile({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
