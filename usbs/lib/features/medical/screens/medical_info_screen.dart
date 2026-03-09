import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/core/localization/app_language.dart';

import 'medical_query_form.dart';

class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  bool _isSuperadmin = false;

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _bulletsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _submitCtrl = TextEditingController();

  static const String _docId = 'medical';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _bulletsCtrl.dispose();
    _noteCtrl.dispose();
    _submitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!mounted) return;
    setState(() => _isSuperadmin = doc.data()?['role'] == 'superadmin');
  }

  Future<void> _showEditDialog(Map<String, dynamic> data) async {
    _titleCtrl.text = (data['title'] ?? 'Medical Assistance').toString();
    _descriptionCtrl.text = (data['description'] ??
            'We provide guidance related to medical concerns, treatment options, '
                'health schemes, and referrals. You can submit your query for support.')
        .toString();
    _noteCtrl.text = (data['note'] ??
            'Note: This service does not replace professional medical consultation. '
                'For emergencies, please contact local emergency services.')
        .toString();
    _submitCtrl.text = (data['submitText'] ?? 'Submit Medical Query').toString();

    final rawBullets = (data['bullets'] as List<dynamic>? ?? <dynamic>[
      'General health concerns',
      'Treatment guidance',
      'Government health schemes',
      'Hospital or referral advice',
    ]).map((e) => e.toString()).toList();
    _bulletsCtrl.text = rawBullets.join('\n');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppI18n.tx(context, 'Edit Medical Support')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_titleCtrl, 'Heading'),
              _field(_descriptionCtrl, 'Description', minLines: 3, maxLines: 8),
              _field(_bulletsCtrl, 'Bullet points (one per line)',
                  minLines: 4, maxLines: 10),
              _field(_noteCtrl, 'Note', minLines: 3, maxLines: 8),
              _field(_submitCtrl, 'Submit button text'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppI18n.tx(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final bullets = _bulletsCtrl.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              try {
                await FirebaseFirestore.instance
                    .collection('system')
                    .doc('supportScreens')
                    .collection('pages')
                    .doc(_docId)
                    .set({
                      'title': _titleCtrl.text.trim(),
                      'description': _descriptionCtrl.text.trim(),
                      'bullets': bullets,
                      'note': _noteCtrl.text.trim(),
                      'submitText': _submitCtrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } on FirebaseException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${AppI18n.tx(context, 'Save failed')}: ${e.message ?? e.code}')),
                );
              }
            },
            child: Text(AppI18n.tx(context, 'Save')),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
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
        title: Text(t('Medical Support')),
        elevation: 0,
        actions: [
          if (_isSuperadmin)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('system')
                  .doc('supportScreens')
                  .collection('pages')
                  .doc(_docId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? <String, dynamic>{};
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppI18n.tx(context, 'Edit'),
                  onPressed: () => _showEditDialog(data),
                );
              },
            ),
          const LanguageMenuButton(),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('system')
            .doc('supportScreens')
            .collection('pages')
            .doc(_docId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final title = (data['title'] ?? 'Medical Assistance').toString();
          final description = (data['description'] ??
                  'We provide guidance related to medical concerns, treatment options, '
                      'health schemes, and referrals. You can submit your query for support.')
              .toString();
          final note = (data['note'] ??
                  'Note: This service does not replace professional medical consultation. '
                      'For emergencies, please contact local emergency services.')
              .toString();
          final submitText =
              (data['submitText'] ?? 'Submit Medical Query').toString();
          final bullets = (data['bullets'] as List<dynamic>? ?? <dynamic>[
            'General health concerns',
            'Treatment guidance',
            'Government health schemes',
            'Hospital or referral advice',
          ]).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(title),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t(description),
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 20),
                Text(
                  t('You can ask about:'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...bullets.map((b) => Text(t('• $b'))),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t(note),
                    style: const TextStyle(fontSize: 13),
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
                        MaterialPageRoute(builder: (_) => const MedicalQueryForm()),
                      );
                    },
                    child: Text(
                      t(submitText),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
