import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:usbs/features/legal/screens/my_legal_queries.dart';
import 'legal_query_form.dart';

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key});

  void _openMyQueries(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to view your legal queries'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyLegalQueriesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Support'),
        elevation: 0,

        /// 🔹 APP BAR ACTION
        actions: [
          IconButton(
            tooltip: 'My Legal Queries',
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
              'Legal Assistance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'If you need guidance related to legal matters, documentation, '
              'government schemes, or general legal rights, you can submit '
              'your query here for assistance.',
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
            const Text('• Legal rights and procedures'),
            const Text('• Government legal aid schemes'),
            const Text('• Documentation and affidavits'),
            const Text('• Family, property, or workplace issues'),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: This platform does not provide court representation or '
                'emergency legal services. Responses are for guidance purposes only.',
                style: TextStyle(fontSize: 13),
              ),
            ),

            const Spacer(),

            /// ➕ SUBMIT QUERY
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalQueryForm(),
                    ),
                  );
                },
                child: const Text(
                  'Submit Legal Query',
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
