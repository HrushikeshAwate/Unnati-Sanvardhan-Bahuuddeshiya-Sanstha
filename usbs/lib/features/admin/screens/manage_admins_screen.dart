import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/firestore_service.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  String _searchText = '';

  static const roles = ['client', 'admin'];
  static const expertise = ['education', 'legal', 'medical'];

  List<String> _readExpertises(Map<String, dynamic> data) {
    final raw = data['expertises'];
    if (raw is List) {
      final values = raw
          .map((e) => e.toString().trim().toLowerCase())
          .where((e) => expertise.contains(e))
          .toSet()
          .toList()
        ..sort();
      if (values.isNotEmpty) return values;
    }

    final legacy = (data['expertise'] ?? '').toString().trim().toLowerCase();
    if (expertise.contains(legacy)) return [legacy];
    return const [];
  }

  Future<bool> _confirmDelete({
    required String userLabel,
    required String Function(String) t,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('Delete user')),
        content: Text(
          'Delete $userLabel permanently from Firebase Auth and Firestore?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('Delete')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final t = (String s) => AppI18n.tx(context, s);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(body: Center(child: Text(t('Please login'))));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, meSnap) {
        if (meSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (meSnap.data?.data()?['role'] != 'superadmin') {
          return Scaffold(
            appBar: AppBar(title: Text(t('Manage Users'))),
            body: Center(child: Text(t('Access denied'))),
          );
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
        title: Text(t('Manage Users')),
        actions: const [LanguageMenuButton()],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.pageGradient(context),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: t('Search by name or email'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.fetchAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text(t('No users found')));
                  }

                  var docs = snapshot.data!.docs;
                  if (_searchText.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data();
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return name.contains(_searchText) ||
                          email.contains(_searchText);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(child: Text(t('No users found')));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final role = (data['role'] ?? 'client').toString();
                      final isSuperadminUser = role == 'superadmin';
                      final currentExpertises = _readExpertises(data);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data['name'] ?? data['email'] ?? 'Unknown').toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (data['email'] ?? '-').toString(),
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: isSuperadminUser
                                          ? InputDecorator(
                                              decoration: InputDecoration(
                                                labelText: t('Role'),
                                              ),
                                              child: const Text('superadmin'),
                                            )
                                          : DropdownButtonFormField<String>(
                                              initialValue: roles.contains(role)
                                                  ? role
                                                  : 'client',
                                              decoration: InputDecoration(
                                                labelText: t('Role'),
                                              ),
                                              items: roles
                                                  .map(
                                                    (r) => DropdownMenuItem(
                                                      value: r,
                                                      child: Text(r),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (value) async {
                                                if (value == null) return;
                                                final nextExpertises = value == 'admin'
                                                    ? (currentExpertises.isEmpty
                                                          ? <String>['legal']
                                                          : currentExpertises)
                                                    : <String>[];
                                                await service.updateUserRole(
                                                  userId: doc.id,
                                                  role: value,
                                                  expertises: nextExpertises,
                                                );
                                              },
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (role == 'admin')
                                      Expanded(
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: t('Expertise'),
                                          ),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: expertise.map((e) {
                                              final selected = currentExpertises.contains(e);
                                              return FilterChip(
                                                label: Text(e),
                                                selected: selected,
                                                onSelected: (isSelected) async {
                                                  final updated = currentExpertises.toList();
                                                  if (isSelected) {
                                                    if (!updated.contains(e)) updated.add(e);
                                                  } else {
                                                    updated.remove(e);
                                                  }
                                                  updated.sort();
                                                  if (updated.isEmpty) return;
                                                  await service.updateUserRole(
                                                    userId: doc.id,
                                                    role: 'admin',
                                                    expertises: updated,
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: isSuperadminUser
                                        ? null
                                        : () async {
                                            final userLabel =
                                                (data['name'] ??
                                                        data['email'] ??
                                                        doc.id)
                                                    .toString();
                                            final confirmed =
                                                await _confirmDelete(
                                                  userLabel: userLabel,
                                                  t: t,
                                                );
                                            if (!confirmed) return;

                                            try {
                                              final result = await service.deleteUser(
                                                doc.id,
                                              );
                                              final authMessage = switch (
                                                result.authStatus
                                              ) {
                                                'deleted' =>
                                                  ' Auth account deleted.',
                                                'not_found' =>
                                                  ' Auth account was already missing.',
                                                'function_missing' =>
                                                  ' App data deleted. Auth delete function not deployed.',
                                                _ => '',
                                              };
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${t('User deleted')}$authMessage',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(e.toString())),
                                              );
                                              return;
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    label: Text(
                                      t('Delete user'),
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
