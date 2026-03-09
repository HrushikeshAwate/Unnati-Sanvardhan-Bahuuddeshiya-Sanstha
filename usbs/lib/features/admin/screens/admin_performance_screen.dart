import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/config/theme/app_text_styles.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/utils/query_status_utils.dart';

class AdminPerformanceScreen extends StatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  State<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends State<AdminPerformanceScreen> {
  String _searchText = '';
  String _expertiseFilter = 'all';

  List<String> _readExpertises(Map<String, dynamic> data) {
    final raw = data['expertises'];
    if (raw is List) {
      final values = raw
          .map((e) => e.toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      if (values.isNotEmpty) return values;
    }

    final legacy = (data['expertise'] ?? '').toString().trim().toLowerCase();
    if (legacy.isEmpty) return const [];
    return [legacy];
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, meSnap) {
        if (meSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final isSuperadmin = meSnap.data?.data()?['role'] == 'superadmin';
        if (!isSuperadmin) {
          return Scaffold(
            appBar: AppBar(title: Text(AppI18n.tx(context, 'Admin Performance'))),
            body: Center(child: Text(AppI18n.tx(context, 'Access denied'))),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(AppI18n.tx(context, 'Admin Performance'))),
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.pageGradient(context)),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('queries').snapshots(),
              builder: (context, querySnap) {
                if (querySnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (querySnap.hasError) {
                  return Center(
                    child: Text(
                      '${AppI18n.tx(context, 'Unable to load dashboard.')}\n${querySnap.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final queries = querySnap.data?.docs ?? [];
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'admin')
                      .snapshots(),
                  builder: (context, adminSnap) {
                    if (adminSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (adminSnap.hasError) {
                      return Center(
                        child: Text(
                          '${AppI18n.tx(context, 'Failed to load admins')}\n${adminSnap.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final allAdmins = adminSnap.data?.docs ?? [];
                    if (allAdmins.isEmpty) {
                      return Center(
                        child: Text(AppI18n.tx(context, 'No admin data')),
                      );
                    }

                    final expertiseValues = <String>{
                      'all',
                      ...allAdmins.expand((a) {
                        final values = _readExpertises(a.data());
                        return values.isEmpty ? ['-'] : values;
                      }),
                    }.toList()
                      ..sort();
                    if (expertiseValues.contains('all')) {
                      expertiseValues.remove('all');
                      expertiseValues.insert(0, 'all');
                    }

                    var admins = allAdmins;
                    if (_expertiseFilter != 'all') {
                      admins = admins.where((admin) {
                        final values = _readExpertises(admin.data());
                        if (values.isEmpty) return _expertiseFilter == '-';
                        return values.contains(_expertiseFilter);
                      }).toList();
                    }
                    if (_searchText.isNotEmpty) {
                      admins = admins.where((admin) {
                        final data = admin.data();
                        final name =
                            (data['name'] ?? '').toString().toLowerCase();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        final exp = _readExpertises(data).join(', ');
                        return name.contains(_searchText) ||
                            email.contains(_searchText) ||
                            exp.contains(_searchText);
                      }).toList();
                    }

                    if (admins.isEmpty) {
                      return Column(
                        children: [
                          _filters(expertiseValues),
                          Expanded(
                            child: Center(
                              child: Text(AppI18n.tx(context, 'No admin data')),
                            ),
                          ),
                        ],
                      );
                    }

                    final cards = admins.map((admin) {
                      final adminData = admin.data();
                      final adminQueries = queries
                          .where((q) => q.data()['assignedAdminId'] == admin.id)
                          .toList();

                      final answered = adminQueries.where((q) {
                        return normalizeQueryStatus(
                              q.data()['status']?.toString(),
                            ) ==
                            'answered';
                      }).length;
                      final inProgress = adminQueries.where((q) {
                        return normalizeQueryStatus(
                              q.data()['status']?.toString(),
                            ) ==
                            'in_progress';
                      }).length;
                      final unanswered = adminQueries.where((q) {
                        return normalizeQueryStatus(
                              q.data()['status']?.toString(),
                            ) ==
                            'unanswered';
                      }).length;

                      return _performanceTile(
                        context: context,
                        name:
                            (adminData['name'] ?? adminData['email'] ?? 'Admin')
                                .toString(),
                        expertise: _readExpertises(adminData).isEmpty
                            ? '-'
                            : _readExpertises(adminData).join(', '),
                        answered: answered,
                        inProgress: inProgress,
                        unanswered: unanswered,
                      );
                    }).toList();

                    cards.sort((a, b) => (b.total).compareTo(a.total));

                    return Column(
                      children: [
                        _filters(expertiseValues),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            children: cards.map((e) => e.widget).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _filters(List<String> expertiseValues) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: AppI18n.tx(context, 'Search by admin name/email'),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) =>
                    setState(() => _searchText = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _expertiseFilter,
                decoration: InputDecoration(
                  labelText: AppI18n.tx(context, 'Filter by expertise'),
                ),
                items: expertiseValues
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e == 'all'
                              ? AppI18n.tx(context, 'All')
                              : e,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _expertiseFilter = value ?? 'all'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TileData _performanceTile({
    required BuildContext context,
    required String name,
    required String expertise,
    required int answered,
    required int inProgress,
    required int unanswered,
  }) {
    final total = answered + inProgress + unanswered;
    final widget = Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expertise,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip(
                    context: context,
                    label: AppI18n.tx(context, 'Answered'),
                    value: answered,
                    color: AppColors.statusAnswered,
                  ),
                  _statChip(
                    context: context,
                    label: AppI18n.tx(context, 'In Progress'),
                    value: inProgress,
                    color: AppColors.statusInProgress,
                  ),
                  _statChip(
                    context: context,
                    label: AppI18n.tx(context, 'Unanswered'),
                    value: unanswered,
                    color: AppColors.statusUnanswered,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${AppI18n.tx(context, 'Total')}: $total',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ),
    );

    return _TileData(total: total, widget: widget);
  }

  Widget _statChip({
    required BuildContext context,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TileData {
  const _TileData({required this.total, required this.widget});

  final int total;
  final Widget widget;
}
