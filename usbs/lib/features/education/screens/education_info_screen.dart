import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:usbs/features/education/screens/my_educational_queries.dart';

import 'education_query_form.dart';

class EducationInfoScreen extends StatelessWidget {
  const EducationInfoScreen({super.key});

  void _openMyQueries(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to view your education queries'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyEducationQueriesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Support'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'My Education Queries',
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () => _openMyQueries(context),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Education Guidance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'We help with education-related guidance such as admissions, '
              'scholarships, career advice, and academic planning.',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),

            const Text(
              'You can ask about:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),
            const Text('• Scholarships and financial aid'),
            const Text('• School / college admissions'),
            const Text('• Career guidance'),
            const Text('• Academic support'),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: Advice provided is for guidance only and does not guarantee '
                'admissions or financial assistance.',
                style: TextStyle(fontSize: 13),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EducationQueryForm(),
                    ),
                  );
                },
                child: const Text(
                  'Submit Education Query',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
