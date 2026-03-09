import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/routes/route_names.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/config/theme/app_text_styles.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/auth_service.dart';
import 'package:usbs/core/services/firestore_service.dart';
import 'package:usbs/core/utils/query_status_utils.dart';

class SuperadminDashboard extends StatefulWidget {
  const SuperadminDashboard({super.key});

  @override
  State<SuperadminDashboard> createState() => _SuperadminDashboardState();
}

class _SuperadminDashboardState extends State<SuperadminDashboard> {
  final _limitCtrl = TextEditingController();

  String _expertiseLabel(Map<String, dynamic> data) {
    final raw = data['expertises'];
    if (raw is List) {
      final values = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      if (values.isNotEmpty) return values.join(', ');
    }
    final legacy = (data['expertise'] ?? '').toString().trim();
    if (legacy.isNotEmpty) return legacy;
    return (data['email'] ?? '-').toString();
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  String t(String key) => AppI18n.tr(context, key);

  Future<void> _updateLimit() async {
    final value = int.tryParse(_limitCtrl.text.trim());
    if (value == null || value <= 0) return;
    await FirestoreService().updateQueryLimit(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${t('query_limit')} ${t('update').toLowerCase()}d')),
    );
  }

  Future<void> _showOwnershipTransferSheet() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppI18n.tx(context, 'Transfer Superadmin Ownership'),
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 8),
                Text(
                  AppI18n.tx(
                    context,
                    'Select an admin to make the new superadmin.',
                  ),
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 380,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'admin')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final admins = snapshot.data?.docs ?? [];
                      if (admins.isEmpty) {
                        return Center(
                          child: Text(
                            AppI18n.tx(
                              context,
                              'No admins found. Create admin first.',
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: admins.length,
                        itemBuilder: (context, index) {
                          final adminDoc = admins[index];
                          final data = adminDoc.data();
                          final label = (data['name'] ??
                                  data['email'] ??
                                  'Admin')
                              .toString();
                          final subtitle = _expertiseLabel(data);

                          return Card(
                            child: ListTile(
                              title: Text(label),
                              subtitle: Text(subtitle),
                              trailing: ElevatedButton(
                                onPressed: adminDoc.id == currentUid
                                    ? null
                                    : () async {
                                        try {
                                          await FirestoreService()
                                              .transferSuperadminOwnership(
                                                newSuperadminId: adminDoc.id,
                                              );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                SnackBar(
                                                  content: Text(e.toString()),
                                                ),
                                              );
                                          return;
                                        }

                                        if (!context.mounted) return;
                                        Navigator.pop(sheetContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppI18n.tx(
                                                context,
                                                'Ownership transferred successfully.',
                                              ),
                                            ),
                                          ),
                                        );
                                        await AuthService().logout();
                                        if (!context.mounted) return;
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          RouteNames.login,
                                          (route) => false,
                                        );
                                      },
                                child: Text(AppI18n.tx(context, 'Transfer')),
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(body: Center(child: Text(AppI18n.tx(context, 'Please login'))));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (roleSnap.data?.data()?['role'] != 'superadmin') {
          return Scaffold(
            appBar: AppBar(title: Text(t('superadmin_title'))),
            body: Center(child: Text(AppI18n.tx(context, 'Access denied'))),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(t('superadmin_title')),
            actions: const [LanguageMenuButton()],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.pageGradient(context),
            ),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('system')
                  .doc('config')
                  .snapshots(),
              builder: (context, configSnap) {
                final limit =
                    (configSnap.data?.data()?['queryLimit'] as num?)?.toInt() ??
                    1000;
                if (_limitCtrl.text.isEmpty) {
                  _limitCtrl.text = limit.toString();
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('queries')
                      .snapshots(),
                  builder: (context, querySnap) {
                    if (querySnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (querySnap.hasError) {
                      return Center(
                        child: Text(
                          '${AppI18n.tx(context, 'Unable to load dashboard.')}\n${querySnap.error}',
                        ),
                      );
                    }

                    final queries = querySnap.data?.docs ?? [];
                    final total = queries.length;
                    final unanswered = queries.where((q) {
                      return normalizeQueryStatus(q.data()['status']?.toString()) ==
                          'unanswered';
                    }).length;
                    final inProgress = queries.where((q) {
                      return normalizeQueryStatus(q.data()['status']?.toString()) ==
                          'in_progress';
                    }).length;
                    final answered = queries.where((q) {
                      return normalizeQueryStatus(q.data()['status']?.toString()) ==
                          'answered';
                    }).length;

                    final usage = limit == 0
                        ? 0.0
                        : (total / limit).clamp(0.0, 1.0).toDouble();

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          AppI18n.tx(context, 'Operations Overview'),
                          style: AppTextStyles.title.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 560;
                                final tiles = [
                                  _compactMetricTile(
                                    label: t('unanswered'),
                                    value: unanswered.toString(),
                                    icon: Icons.mark_email_unread_outlined,
                                    accent: AppColors.statusUnanswered,
                                  ),
                                  _compactMetricTile(
                                    label: t('in_progress'),
                                    value: inProgress.toString(),
                                    icon: Icons.pending_actions_outlined,
                                    accent: AppColors.statusInProgress,
                                  ),
                                  _compactMetricTile(
                                    label: t('answered'),
                                    value: answered.toString(),
                                    icon: Icons.check_circle_outline,
                                    accent: AppColors.statusAnswered,
                                  ),
                                ];

                                if (compact) {
                                  return Column(
                                    children: [
                                      tiles[0],
                                      const SizedBox(height: 8),
                                      tiles[1],
                                      const SizedBox(height: 8),
                                      tiles[2],
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: tiles[0]),
                                    const SizedBox(width: 8),
                                    Expanded(child: tiles[1]),
                                    const SizedBox(width: 8),
                                    Expanded(child: tiles[2]),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppI18n.tx(context, 'Query Capacity'),
                                  style: AppTextStyles.title,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${t('total')}: $total / $limit',
                                  style: AppTextStyles.body,
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    minHeight: 9,
                                    value: usage,
                                    backgroundColor: AppColors.border,
                                    color: usage > 0.85
                                        ? Colors.red
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _limitCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: t('query_limit'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: _updateLimit,
                                      child: Text(t('update')),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                _actionTile(
                                  icon: Icons.list_alt,
                                  title: t('track_all_queries'),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.adminQueries,
                                  ),
                                ),
                                _actionTile(
                                  icon: Icons.assignment_ind,
                                  title: t('assign_queries'),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.assignQueries,
                                  ),
                                ),
                                _actionTile(
                                  icon: Icons.manage_accounts,
                                  title: t('manage_users_roles'),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.manageAdmins,
                                  ),
                                ),
                                _actionTile(
                                  icon: Icons.bar_chart_rounded,
                                  title: AppI18n.tx(context, 'Admin Performance'),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.adminPerformance,
                                  ),
                                ),
                                _actionTile(
                                  icon: Icons.swap_horiz_rounded,
                                  title: AppI18n.tx(
                                    context,
                                    'Transfer Superadmin Ownership',
                                  ),
                                  onTap: _showOwnershipTransferSheet,
                                ),
                              ],
                            ),
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

  Widget _compactMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    final dark = AppColors.isDark(context);
    final bg = dark
        ? accent.withValues(alpha: 0.16)
        : accent.withValues(alpha: 0.1);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}
