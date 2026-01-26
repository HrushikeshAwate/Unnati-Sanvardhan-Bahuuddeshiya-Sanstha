import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import '../../legal/screens/legal_info_screen.dart';
import '../../medical/screens/medical_info_screen.dart';
import '../../education/screens/education_info_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<bool> _isGuest() async {
    final user = FirebaseAuth.instance.currentUser!;
    final role = await FirestoreService().fetchUserRole(user.uid);
    return role == 'guest';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isGuest(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bool isGuest = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('NGO Services'),
            actions: [
              if (!isGuest)
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGuest)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'You are browsing as a guest. Login is required to submit queries or upload documents.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),

                const Text(
                  'Available Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                /// LEGAL
                _ServiceCard(
                  icon: Icons.gavel,
                  title: 'Legal Assistance',
                  description:
                      'Family, civil, criminal, and legal guidance.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalInfoScreen(),
                      ),
                    );
                  },
                ),

                /// MEDICAL
                _ServiceCard(
                  icon: Icons.medical_services,
                  title: 'Medical Support',
                  description:
                      'Health guidance, consultation, and support.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicalInfoScreen(),
                      ),
                    );
                  },
                ),

                /// EDUCATION
                _ServiceCard(
                  icon: Icons.school,
                  title: 'Education Support',
                  description:
                      'Academic help, scholarships, and counseling.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EducationInfoScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🔒 UI COMPONENT ONLY – SECURITY IS BACKEND ENFORCED
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
