import 'package:flutter/material.dart';
import 'legal_query_form.dart';

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal Services')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'We provide free legal assistance for family, civil and criminal matters.',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              child: const Text('Submit Legal Query'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalQueryForm(),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
