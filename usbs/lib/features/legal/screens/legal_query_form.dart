import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';

class LegalQueryForm extends StatefulWidget {
  const LegalQueryForm({super.key});

  @override
  State<LegalQueryForm> createState() => _LegalQueryFormState();
}

class _LegalQueryFormState extends State<LegalQueryForm> {
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);

    await FirestoreService().submitQuery(
      category: 'legal',
      description: _controller.text,
      userId: FirebaseAuth.instance.currentUser!.uid,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal Query')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe your legal issue',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}
