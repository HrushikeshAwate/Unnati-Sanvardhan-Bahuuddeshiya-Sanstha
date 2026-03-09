import 'package:flutter/material.dart';
import 'package:usbs/core/localization/app_language.dart';

class PhotoGalleryScreen extends StatelessWidget {
  const PhotoGalleryScreen({super.key});

  final List<String> images = const [
    // 'assets/gallery/img1.jpg',
    // 'assets/gallery/img2.jpg',
    // 'assets/gallery/img3.jpg',
    // 'assets/gallery/img4.jpg',
    // 'assets/gallery/img5.jpg',
    // 'assets/gallery/img6.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final t = (String s) => AppI18n.tx(context, s);
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B4A45), Color(0xFF0D5F58)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  ),
          ),
        ),
        title: Text(t('Photo Gallery')),
        actions: const [LanguageMenuButton()],
      ),
      body: images.isEmpty
          ? Center(child: Text(t('No photos available yet')))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(images[index], fit: BoxFit.cover),
                  );
                },
              ),
            ),
    );
  }
}
