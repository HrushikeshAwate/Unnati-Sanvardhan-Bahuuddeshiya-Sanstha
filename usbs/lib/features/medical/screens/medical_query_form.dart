import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/config/theme/app_text_styles.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/firestore_service.dart';

class MedicalQueryForm extends StatefulWidget {
  const MedicalQueryForm({super.key});

  @override
  State<MedicalQueryForm> createState() => _MedicalQueryFormState();
}

class _MedicalQueryFormState extends State<MedicalQueryForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _queryController = TextEditingController();

  String _urgency = 'Normal';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    final t = (String s) => AppI18n.tx(context, s);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Please login to submit a medical query'))),
      );
      return;
    }

    if (user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Guest users cannot submit queries. Please login with Google.'),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await FirestoreService().submitMedicalQuery(
        description: _queryController.text.trim(),
        urgency: _urgency,
        patientName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        age: _ageController.text.trim().isEmpty
            ? null
            : _ageController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Medical query submitted successfully'))),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t('Submission failed')}: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
        title: Text(t('Medical Assistance')),
        actions: const [LanguageMenuButton()],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.pageGradient(context),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.isDark(context)
                              ? const Color(0xFF2A3A4E)
                              : AppColors.softTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_hospital_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t('Patient Information'),
                          style: AppTextStyles.title,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: t('Patient Name (optional)'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t('Age (optional)'),
                          prefixIcon: const Icon(Icons.cake_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _urgency,
                        decoration: InputDecoration(
                          labelText: t('Urgency Level'),
                          prefixIcon: const Icon(Icons.priority_high_outlined),
                        ),
                        items: [
                          DropdownMenuItem(value: 'Low', child: Text(t('Low'))),
                          DropdownMenuItem(
                            value: 'Normal',
                            child: Text(t('Normal')),
                          ),
                          DropdownMenuItem(value: 'High', child: Text(t('High'))),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _urgency = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _queryController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: t('Describe the medical concern'),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? t('Required') : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: const Icon(Icons.send_outlined),
                  label: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(t('Submit Medical Query')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
