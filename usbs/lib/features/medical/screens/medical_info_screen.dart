import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'medical_query_form.dart';
import 'my_medical_queries.dart';

class MedicalInfoScreen extends StatelessWidget {
  const MedicalInfoScreen({super.key});

  void _openMyQueries(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to view your medical queries'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyMedicalQueriesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Support'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'My Medical Queries',
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
              'Medical Assistance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'We provide guidance related to medical concerns, treatment options, '
              'health schemes, and referrals. You can submit your query for support.',
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
            const Text('• General health concerns'),
            const Text('• Treatment guidance'),
            const Text('• Government health schemes'),
            const Text('• Hospital or referral advice'),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: This service does not replace professional medical consultation. '
                'For emergencies, please contact local emergency services.',
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
                      builder: (_) => const MedicalQueryForm(),
                    ),
                  );
                },
                child: const Text(
                  'Submit Medical Query',
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
