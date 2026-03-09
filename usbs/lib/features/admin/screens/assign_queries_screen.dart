import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/firestore_service.dart';
import 'package:usbs/core/utils/date_utils.dart';

class AssignQueriesScreen extends StatelessWidget {
  const AssignQueriesScreen({super.key});

  String _canonicalCategory(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'education':
      case 'educational':
      case 'eduaction':
        return 'education';
      case 'medical':
      case 'medic':
        return 'medical';
      case 'legal':
      case 'law':
        return 'legal';
      default:
        return normalized;
    }
  }

  List<String> _adminExpertises(Map<String, dynamic> data) {
    final raw = data['expertises'];
    if (raw is List) {
      final values = raw
          .map((e) => _canonicalCategory(e.toString()))
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      if (values.isNotEmpty) return values;
    }

    final legacy = (data['expertise'] ?? '').toString().trim();
    if (legacy.isEmpty) return const [];
    return [_canonicalCategory(legacy)];
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
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
        title: Text(t('Assign Queries')),
        actions: [
          const LanguageMenuButton(),
          TextButton.icon(
            onPressed: () async {
              await service.autoAssignUnassignedQueries();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('Auto-assigned unassigned queries'))),
              );
            },
            icon: const Icon(Icons.auto_fix_high, color: Colors.white, size: 18),
            label: Text(
              t('Auto-Assign'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.pageGradient(context),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('queries')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, querySnap) {
            if (querySnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!querySnap.hasData || querySnap.data!.docs.isEmpty) {
              return Center(child: Text(t('No unassigned queries')));
            }

            final queries = querySnap.data!.docs.where((doc) {
              final data = doc.data();
              final assignedAdminId = data['assignedAdminId'];
              final needsManual = data['needsManualAssignment'] == true;
              return assignedAdminId == null || needsManual;
            }).toList();

            if (queries.isEmpty) {
              return Center(child: Text(t('No unassigned queries')));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: queries.length,
              itemBuilder: (context, index) {
                final queryDoc = queries[index];
                final query = queryDoc.data();
                final category = (query['category'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t((query['description'] ?? t('No description')).toString()),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${t('Category')}: ${t(category)}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          Text(
                            '${t('Submitted At')}: ${formatSubmittedAt(query)}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          Text(
                            '${t('Answered At')}: ${formatAnsweredAt(query)}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: service.fetchAdmins(category: category),
                            builder: (context, adminSnap) {
                              if (!adminSnap.hasData ||
                                  adminSnap.data!.docs.isEmpty) {
                                return Text(
                                  t('No eligible admin in this category'),
                                  style: const TextStyle(color: Colors.red),
                                );
                              }

                              final admins = adminSnap.data!.docs.where((adminDoc) {
                                final admin = adminDoc.data();
                                final isActive = admin['isActive'] != false;
                                final expertises = _adminExpertises(admin);
                                return isActive &&
                                    expertises.contains(_canonicalCategory(category));
                              }).toList();

                              if (admins.isEmpty) {
                                return Text(
                                  t('No eligible admin in this category'),
                                  style: const TextStyle(color: Colors.red),
                                );
                              }
                              return DropdownButtonFormField<String>(
                                initialValue: null,
                                hint: Text(t('Assign admin')),
                                decoration: const InputDecoration(),
                                items: admins.map((adminDoc) {
                                  final admin = adminDoc.data();
                                  final adminName =
                                      (admin['name'] ?? admin['email'] ?? 'Admin')
                                          .toString();
                                  return DropdownMenuItem(
                                    value: adminDoc.id,
                                    child: Text(adminName),
                                  );
                                }).toList(),
                                onChanged: (adminId) async {
                                  if (adminId == null) return;
                                  final adminDoc = admins.firstWhere(
                                    (a) => a.id == adminId,
                                  );
                                  final admin = adminDoc.data();
                                  await service.assignQuery(
                                    queryId: queryDoc.id,
                                    adminId: adminDoc.id,
                                    adminName:
                                        (admin['name'] ?? admin['email'] ?? 'Admin')
                                            .toString(),
                                  );

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(t('Query assigned successfully')),
                                    ),
                                  );
                                },
                              );
                            },
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
    );
  }
}
