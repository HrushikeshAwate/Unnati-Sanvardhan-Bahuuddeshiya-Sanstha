import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _alternateEmailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  String _role = 'client';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _alternateEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    final doc = await FirestoreService().fetchMe();
    final data = doc.data() ?? {};
    _nameCtrl.text = (data['name'] ?? user?.displayName ?? '').toString();
    _emailCtrl.text = (data['email'] ?? user?.email ?? '').toString();
    _alternateEmailCtrl.text = (data['alternateEmail'] ?? '').toString();
    _phoneCtrl.text = (data['phone'] ?? user?.phoneNumber ?? '').toString();
    _cityCtrl.text = (data['city'] ?? '').toString();
    _stateCtrl.text = (data['state'] ?? '').toString();
    _role = (data['role'] ?? 'client').toString();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await FirestoreService().updateMyProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      alternateEmail: _alternateEmailCtrl.text.trim().isEmpty
          ? null
          : _alternateEmailCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppI18n.tx(context, 'Profile updated'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = (String s) => AppI18n.tx(context, s);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        title: Text(t('My Profile')),
        centerTitle: true,
        actions: const [LanguageMenuButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _field(t('Full Name'), _nameCtrl),
            _field('${t('Email')} (optional)', _emailCtrl),
            _field('Alternate Email (optional)', _alternateEmailCtrl),
            _field(t('Phone Number'), _phoneCtrl),
            _readOnlyField(t('Role'), _role),
            _field(t('City'), _cityCtrl),
            _field(t('State'), _stateCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (!isEditing) {
                    setState(() => isEditing = true);
                    return;
                  }
                  _save();
                },
                child: Text(isEditing ? t('Save Profile') : t('Edit Profile')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool editable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 6),
          isEditing && editable
              ? TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.text.isEmpty
                        ? AppI18n.tx(context, 'Not provided')
                        : controller.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
