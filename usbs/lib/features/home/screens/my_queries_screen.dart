import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/config/theme/app_text_styles.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/utils/date_utils.dart';
import 'package:usbs/core/utils/query_status_utils.dart';
import 'package:usbs/core/widgets/status_chip.dart';
import 'package:usbs/features/education/screens/education_query_detail.dart';
import 'package:usbs/features/legal/screens/legal_query_detail.dart';
import 'package:usbs/features/medical/screens/medical_query_detail.dart';

class MyQueriesScreen extends StatefulWidget {
  const MyQueriesScreen({super.key});

  @override
  State<MyQueriesScreen> createState() => _MyQueriesScreenState();
}

class _MyQueriesScreenState extends State<MyQueriesScreen> {
  String _queryCategory = 'all';
  String _queryStatus = 'all';

  String t(String key) => AppI18n.tr(context, key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
        title: Text(t('my_queries')),
        actions: const [LanguageMenuButton()],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.pageGradient(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: user == null || user.isAnonymous
                  ? Center(
                      child: Text(
                        t('please_login_queries'),
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _queryCategory,
                                decoration: InputDecoration(labelText: t('category')),
                                items: [
                                  DropdownMenuItem(value: 'all', child: Text(t('all'))),
                                  DropdownMenuItem(
                                    value: 'legal',
                                    child: Text(t('legal')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medical',
                                    child: Text(t('medical')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'education',
                                    child: Text(t('education')),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _queryCategory = value ?? 'all');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _queryStatus,
                                decoration: InputDecoration(labelText: t('status')),
                                items: [
                                  DropdownMenuItem(value: 'all', child: Text(t('all'))),
                                  DropdownMenuItem(
                                    value: 'answered',
                                    child: Text(t('answered')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'unanswered',
                                    child: Text(t('unanswered')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'in_progress',
                                    child: Text(t('in_progress')),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _queryStatus = value ?? 'all');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('queries')
                                .where('userId', isEqualTo: user.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    t('no_queries'),
                                    style: AppTextStyles.caption,
                                  ),
                                );
                              }

                              var docs = snapshot.data!.docs.toList();
                              docs.sort((a, b) {
                                final at = a.data()['updatedAt'];
                                final bt = b.data()['updatedAt'];
                                final aMs =
                                    at is Timestamp ? at.millisecondsSinceEpoch : 0;
                                final bMs =
                                    bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
                                return bMs.compareTo(aMs);
                              });

                              if (_queryCategory != 'all') {
                                docs = docs
                                    .where(
                                      (d) =>
                                          d.data()['category']?.toString() ==
                                          _queryCategory,
                                    )
                                    .toList();
                              }

                              if (_queryStatus != 'all') {
                                docs = docs.where((d) {
                                  final normalized = normalizeQueryStatus(
                                    d.data()['status']?.toString(),
                                  );
                                  return normalized == _queryStatus;
                                }).toList();
                              }

                              if (docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    t('no_queries'),
                                    style: AppTextStyles.caption,
                                  ),
                                );
                              }

                              return ListView(
                                children: docs.map((doc) {
                                  final data = doc.data();
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: AppColors.elevatedSurface(context),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: ListTile(
                                      isThreeLine: true,
                                      leading: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.softTeal,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.question_answer_outlined,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      title: Text(
                                        t(
                                          (data['description'] ??
                                                  t('no_description'))
                                              .toString(),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${t((data['category'] ?? '').toString())} • ${t('Assigned')}: ${(data['assignedAdminName'] ?? t('Unassigned')).toString()}\n'
                                        '${t('Submitted At')}: ${formatSubmittedAt(data)}\n'
                                        '${t('Answered At')}: ${formatAnsweredAt(data)}',
                                      ),
                                      trailing: StatusChip(
                                        status:
                                            (data['status'] ?? 'unanswered').toString(),
                                      ),
                                      onTap: () => _openQueryDetail(doc),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _openQueryDetail(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final category = doc.data()['category']?.toString();
    if (category == 'legal') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LegalQueryDetailScreen(queryDoc: doc)),
      );
      return;
    }
    if (category == 'medical') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MedicalQueryDetailScreen(queryDoc: doc)),
      );
      return;
    }
    if (category == 'education') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EducationQueryDetailScreen(queryDoc: doc),
        ),
      );
    }
  }
}
