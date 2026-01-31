import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/core/services/firestore_service.dart';

class EducationQueryForm extends StatefulWidget {
  const EducationQueryForm({super.key});

  @override
  State<EducationQueryForm> createState() => _EducationQueryFormState();
}

class _EducationQueryFormState extends State<EducationQueryForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentClassController = TextEditingController();
  final _queryController = TextEditingController();

  String _topic = 'General Guidance';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _studentClassController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;

    /// 🔒 Block guest users
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to submit an education query'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await FirestoreService().submitEducationQuery(
        topic: _topic,
        description: _queryController.text.trim(),
        studentName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        studentClass: _studentClassController.text.trim().isEmpty
            ? null
            : _studentClassController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Education query submitted successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Education Support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Student Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _studentClassController,
                decoration: const InputDecoration(
                  labelText: 'Current Class / Course',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _topic,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'General Guidance',
                    child: Text('General Guidance'),
                  ),
                  DropdownMenuItem(
                    value: 'Scholarships',
                    child: Text('Scholarships'),
                  ),
                  DropdownMenuItem(
                    value: 'Admissions',
                    child: Text('Admissions'),
                  ),
                  DropdownMenuItem(
                    value: 'Career Advice',
                    child: Text('Career Advice'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _topic = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _queryController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Describe your education query',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                      : const Text('Submit Education Query'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
