import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/widgets/translated_text.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  static const String _defaultOrgName =
      'Unnati Sanvardhan Bahuuddeshiya Sanstha';
  bool _isSuperadmin = false;

  final _orgNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _registrationActCtrl = TextEditingController();
  final _registrationNumberCtrl = TextEditingController();
  final _registrationOfficeCtrl = TextEditingController();
  final _registrationDateCtrl = TextEditingController();
  final _visionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _locationCtrl.dispose();
    _aboutCtrl.dispose();
    _registrationActCtrl.dispose();
    _registrationNumberCtrl.dispose();
    _registrationOfficeCtrl.dispose();
    _registrationDateCtrl.dispose();
    _visionCtrl.dispose();
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
    setState(() {
      _isSuperadmin = doc.data()?['role'] == 'superadmin';
    });
  }

  Future<void> _showEditDialog(Map<String, dynamic> data) async {
    _orgNameCtrl.text = (data['orgName'] ?? _defaultOrgName).toString();
    _locationCtrl.text =
        (data['location'] ?? 'War Taluka, District Dhule, Maharashtra')
            .toString();
    _aboutCtrl.text = (data['about'] ??
            'Unnati Sanvardhan Bahuuddeshiya Sanstha is a registered Public Trust '
                'working towards social welfare and community development. '
                'The organization aims to support individuals and communities through '
                'initiatives in legal awareness, medical assistance, education, and '
                'other social support services.')
        .toString();
    _registrationActCtrl.text =
        (data['registrationAct'] ?? 'Mumbai Public Trust Act, 1950').toString();
    _registrationNumberCtrl.text =
        (data['registrationNumber'] ?? 'F-0015533 (DHL)').toString();
    _registrationOfficeCtrl.text =
        (data['registrationOffice'] ??
                'Public Trust Registration Office, Dhule')
            .toString();
    _registrationDateCtrl.text =
        (data['registrationDate'] ?? '21 November 2024').toString();
    _visionCtrl.text = (data['vision'] ??
            'To build a supportive and inclusive society by providing access to '
                'essential services, promoting awareness, and empowering communities '
                'to lead dignified and secure lives.')
        .toString();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit About Section'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_orgNameCtrl, 'Organization Name'),
              _field(_locationCtrl, 'Location'),
              _field(_aboutCtrl, 'About', minLines: 4, maxLines: 8),
              _field(_registrationActCtrl, 'Registration Act'),
              _field(_registrationNumberCtrl, 'Registration Number'),
              _field(_registrationOfficeCtrl, 'Registration Office'),
              _field(_registrationDateCtrl, 'Date of Registration'),
              _field(_visionCtrl, 'Vision', minLines: 3, maxLines: 6),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('system').doc('about').set({
                'orgName': _orgNameCtrl.text.trim(),
                'location': _locationCtrl.text.trim(),
                'about': _aboutCtrl.text.trim(),
                'registrationAct': _registrationActCtrl.text.trim(),
                'registrationNumber': _registrationNumberCtrl.text.trim(),
                'registrationOffice': _registrationOfficeCtrl.text.trim(),
                'registrationDate': _registrationDateCtrl.text.trim(),
                'vision': _visionCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
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
        title: Text(t('About Us')),
        centerTitle: true,
        actions: [
          if (_isSuperadmin)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('system')
                  .doc('about')
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? <String, dynamic>{};
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
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
            .doc('about')
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};

          final orgName = (data['orgName'] ?? _defaultOrgName).toString();
          final location =
              (data['location'] ?? 'War Taluka, District Dhule, Maharashtra')
                  .toString();
          final about = (data['about'] ??
                  'Unnati Sanvardhan Bahuuddeshiya Sanstha is a registered Public Trust '
                      'working towards social welfare and community development. '
                      'The organization aims to support individuals and communities through '
                      'initiatives in legal awareness, medical assistance, education, and '
                      'other social support services.')
              .toString();
          final registrationAct =
              (data['registrationAct'] ?? 'Mumbai Public Trust Act, 1950')
                  .toString();
          final registrationNumber =
              (data['registrationNumber'] ?? 'F-0015533 (DHL)').toString();
          final registrationOffice =
              (data['registrationOffice'] ??
                      'Public Trust Registration Office, Dhule')
                  .toString();
          final registrationDate =
              (data['registrationDate'] ?? '21 November 2024').toString();
          final vision = (data['vision'] ??
                  'To build a supportive and inclusive society by providing access to '
                      'essential services, promoting awareness, and empowering communities '
                      'to lead dignified and secure lives.')
              .toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orgName.trim().toLowerCase() == _defaultOrgName.toLowerCase()
                      ? AppI18n.tr(context, 'ngo_name')
                      : AppI18n.tx(context, orgName),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TranslatedText(
                  location,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),
                TranslatedText(
                  'About the Organization',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TranslatedText(
                  about,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 24),
                TranslatedText(
                  'Registration Details',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _infoTile(
                  title: t('Registration Act'),
                  value: registrationAct,
                ),
                _infoTile(
                  title: t('Registration Number'),
                  value: registrationNumber,
                ),
                _infoTile(
                  title: t('Registration Office'),
                  value: registrationOffice,
                ),
                _infoTile(
                  title: t('Date of Registration'),
                  value: registrationDate,
                ),
                const SizedBox(height: 24),
                TranslatedText(
                  'Our Vision',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TranslatedText(
                  vision,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            title,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 4),
          TranslatedText(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
