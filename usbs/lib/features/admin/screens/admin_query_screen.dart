import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/routes/route_names.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/firestore_service.dart';
import 'package:usbs/core/utils/date_utils.dart';
import 'package:usbs/core/utils/query_status_utils.dart';
import 'package:usbs/core/widgets/status_chip.dart';

class AdminQueriesScreen extends StatefulWidget {
  const AdminQueriesScreen({super.key});

  @override
  State<AdminQueriesScreen> createState() => _AdminQueriesScreenState();
}

class _AdminQueriesScreenState extends State<AdminQueriesScreen> {
  String _keywordSearch = '';
  String? _selectedAdminId;
  String? _selectedAdminLabel;
  String _categoryFilter = 'all';
  String _statusFilter = 'all';
  String? _role;
  bool _loadingRole = true;

  Future<bool> _confirmDelete(String Function(String) t) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('Delete')),
        content: Text(
          AppI18n.tx(
            context,
            'Delete this query permanently from app and Firebase?',
          ),
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

  Future<void> _pickAdminFromList() async {
    final selected = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        String search = '';
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppI18n.tx(context, 'Select Admin'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: AppI18n.tx(context, 'Search admin'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => setSheetState(
                        () => search = value.trim().toLowerCase(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 420,
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'admin')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final admins = (snapshot.data?.docs ?? []).where((doc) {
                            if (search.isEmpty) return true;
                            final data = doc.data();
                            final name =
                                (data['name'] ?? '').toString().toLowerCase();
                            final email =
                                (data['email'] ?? '').toString().toLowerCase();
                            return name.contains(search) || email.contains(search);
                          }).toList()
                            ..sort((a, b) {
                              final aData = a.data();
                              final bData = b.data();
                              final aName = (aData['name'] ?? aData['email'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final bName = (bData['name'] ?? bData['email'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return aName.compareTo(bName);
                            });

                          return ListView(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.clear_all_outlined),
                                title: Text(AppI18n.tx(context, 'All admins')),
                                onTap: () => Navigator.pop(
                                  sheetContext,
                                  <String, String>{},
                                ),
                              ),
                              ...admins.map((doc) {
                                final data = doc.data();
                                final label = (data['name'] ??
                                        data['email'] ??
                                        'Admin')
                                    .toString();
                                final subtitle = (data['email'] ?? '-').toString();
                                return ListTile(
                                  leading: const Icon(Icons.person_outline),
                                  title: Text(label),
                                  subtitle: Text(subtitle),
                                  onTap: () => Navigator.pop(
                                    sheetContext,
                                    <String, String>{
                                      'id': doc.id,
                                      'label': label,
                                    },
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;
    if (!mounted) return;
    setState(() {
      _selectedAdminId = selected['id'];
      _selectedAdminLabel = selected['label'];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRole();
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
      _role = doc.data()?['role']?.toString();
      _loadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = (String s) => AppI18n.tx(context, s);
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSuperadmin = _role == 'superadmin';
    final isAdmin = _role == 'admin';
    if (!isAdmin && !isSuperadmin) {
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
          title: Text(t('All Queries')),
          actions: const [LanguageMenuButton()],
        ),
        body: Center(child: Text(t('Access denied'))),
      );
    }

    final myUid = FirebaseAuth.instance.currentUser?.uid;

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
        title: Text(t('All Queries')),
        actions: [
          const LanguageMenuButton(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.pageGradient(context),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: isSuperadmin
                              ? 'Search by keyword (name, description, category)'
                              : 'Search your assigned queries by any keyword',
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            setState(
                              () => _keywordSearch = value.trim().toLowerCase(),
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (isSuperadmin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _pickAdminFromList,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: t('Select admin'),
                                    suffixIcon: _selectedAdminLabel == null
                                        ? const Icon(Icons.arrow_drop_down)
                                        : IconButton(
                                            tooltip: t('Clear'),
                                            icon: const Icon(Icons.clear),
                                            onPressed: () => setState(() {
                                              _selectedAdminId = null;
                                              _selectedAdminLabel = null;
                                            }),
                                          ),
                                  ),
                                  child: Text(
                                    _selectedAdminLabel ?? t('All admins'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _categoryFilter,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: t('Filter by category'),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text(t('All')),
                                  ),
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
                                onChanged: (value) => setState(
                                  () => _categoryFilter = value ?? 'all',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _statusFilter,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: t('Sort/Filter by status'),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text(t('All')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'answered',
                                    child: Text(t('Answered')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'unanswered',
                                    child: Text(t('Unanswered')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'in_progress',
                                    child: Text(t('In Progress')),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _statusFilter = value ?? 'all',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: t('Sort/Filter by status'),
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text(t('All'))),
                            DropdownMenuItem(
                              value: 'answered',
                              child: Text(t('Answered')),
                            ),
                            DropdownMenuItem(
                              value: 'unanswered',
                              child: Text(t('Unanswered')),
                            ),
                            DropdownMenuItem(
                              value: 'in_progress',
                              child: Text(t('In Progress')),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _statusFilter = value ?? 'all'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: isSuperadmin
                    ? FirestoreService().fetchQueriesForAdminView()
                    : FirestoreService().fetchAssignedQueries(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load queries: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text(t('No queries found')));
                  }

                  final allDocs = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aTs = a.data()['updatedAt'];
                      final bTs = b.data()['updatedAt'];
                      final aMs = aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
                      final bMs = bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
                      return bMs.compareTo(aMs);
                    });
                  final total = allDocs.length;
                  final answered = allDocs.where((d) {
                    return normalizeQueryStatus(d.data()['status']?.toString()) ==
                        'answered';
                  }).length;
                  final inProgress = allDocs.where((d) {
                    return normalizeQueryStatus(d.data()['status']?.toString()) ==
                        'in_progress';
                  }).length;
                  final unanswered = allDocs.where((d) {
                    return normalizeQueryStatus(d.data()['status']?.toString()) ==
                        'unanswered';
                  }).length;

                  var docs = allDocs;
                  if (isSuperadmin) {
                    docs.sort((a, b) {
                      final aEsc = a.data()['escalatedToSuperadmin'] == true ? 1 : 0;
                      final bEsc = b.data()['escalatedToSuperadmin'] == true ? 1 : 0;
                      return bEsc.compareTo(aEsc);
                    });
                  }
                  if (_categoryFilter != 'all') {
                    docs = docs.where((d) {
                      final category = (d.data()['category'] ?? '')
                          .toString()
                          .toLowerCase();
                      return category == _categoryFilter;
                    }).toList();
                  }
                  if (_statusFilter != 'all') {
                    docs = docs.where((d) {
                      final normalized = normalizeQueryStatus(
                        d.data()['status']?.toString(),
                      );
                      return normalized == _statusFilter;
                    }).toList();
                  }
                  if (_selectedAdminId != null) {
                    docs = docs.where((d) {
                      final adminId =
                          (d.data()['assignedAdminId'] ?? '').toString();
                      return adminId == _selectedAdminId;
                    }).toList();
                  }
                  if (_keywordSearch.isNotEmpty) {
                    docs = docs.where((d) {
                      final data = d.data();
                      final client = (data['userName'] ?? '')
                          .toString()
                          .toLowerCase();
                      final admin =
                          (data['assignedAdminName'] ?? '')
                              .toString()
                              .toLowerCase();
                      final description =
                          (data['description'] ?? '').toString().toLowerCase();
                      final category =
                          (data['category'] ?? '').toString().toLowerCase();
                      return client.contains(_keywordSearch) ||
                          admin.contains(_keywordSearch) ||
                          description.contains(_keywordSearch) ||
                          category.contains(_keywordSearch);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(child: Text(t('No matching queries')));
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      if (!isSuperadmin) ...[
                        _statsCard(
                          t: t,
                          total: total,
                          answered: answered,
                          inProgress: inProgress,
                          unanswered: unanswered,
                        ),
                        const SizedBox(height: 10),
                      ],
                      ...docs.map((doc) {
                        final data = doc.data();
                        final assignedId = data['assignedAdminId']?.toString();
                        final canAnswer = isSuperadmin || assignedId == myUid;
                        final escalated = data['escalatedToSuperadmin'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.answerQuery,
                                  arguments: doc,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t((data['description'] ?? '').toString()),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        StatusChip(
                                          status: (data['status'] ?? 'unanswered')
                                              .toString(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${t('Category')}: ${t((data['category'] ?? '').toString())}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${t('Assigned')}: ${data['assignedAdminName'] ?? t('Unassigned')}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${t('Submitted At')}: ${formatSubmittedAt(data)}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${t('Answered At')}: ${formatAnsweredAt(data)}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (isSuperadmin && escalated)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.isDark(context)
                                                ? AppColors.accent.withValues(
                                                    alpha: 0.22,
                                                  )
                                                : AppColors.softAmber,
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(
                                              color: AppColors.isDark(context)
                                                  ? AppColors.accent.withValues(
                                                      alpha: 0.7,
                                                    )
                                                  : AppColors.accent,
                                            ),
                                          ),
                                          child: Text(
                                            t('Escalated to Superadmin'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: AppColors.isDark(context)
                                                  ? Colors.white
                                                  : const Color(0xFF6A3C00),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!canAnswer)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          t('View only (not assigned)'),
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isSuperadmin)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              final confirmed = await _confirmDelete(
                                                t,
                                              );
                                              if (!confirmed) return;

                                              try {
                                                await FirestoreService().deleteQuery(
                                                  doc.id,
                                                );
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          e.toString(),
                                                        ),
                                                      ),
                                                    );
                                                return;
                                              }

                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(t('Query deleted')),
                                                ),
                                              );
                                            },
                                          ),
                                        Icon(
                                          canAnswer
                                              ? Icons.chat_bubble_outline
                                              : Icons.lock_outline,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsCard({
    required String Function(String) t,
    required int total,
    required int answered,
    required int inProgress,
    required int unanswered,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Query Status Overview',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(170, 170),
                      painter: _StatusRingPainter(
                        answered: answered,
                        inProgress: inProgress,
                        unanswered: unanswered,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _legendDot(
                  color: AppColors.statusAnswered,
                  label: '${t('answered')}: $answered',
                ),
                _legendDot(
                  color: AppColors.statusInProgress,
                  label: '${t('in_progress')}: $inProgress',
                ),
                _legendDot(
                  color: AppColors.statusUnanswered,
                  label: '${t('unanswered')}: $unanswered',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _StatusRingPainter extends CustomPainter {
  _StatusRingPainter({
    required this.answered,
    required this.inProgress,
    required this.unanswered,
  });

  final int answered;
  final int inProgress;
  final int unanswered;

  @override
  void paint(Canvas canvas, Size size) {
    final total = answered + inProgress + unanswered;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - 8,
    );

    final basePaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, basePaint);

    if (total <= 0) return;

    const gap = 0.04;
    var start = -math.pi / 2;
    final segments = <(int, Color)>[
      (answered, AppColors.statusAnswered),
      (inProgress, AppColors.statusInProgress),
      (unanswered, AppColors.statusUnanswered),
    ];

    for (final segment in segments) {
      final value = segment.$1;
      final color = segment.$2;
      if (value <= 0) continue;
      final sweep = (value / total) * (2 * math.pi);
      final adjustedSweep = (sweep - gap).clamp(0.0, 2 * math.pi);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, adjustedSweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusRingPainter oldDelegate) {
    return answered != oldDelegate.answered ||
        inProgress != oldDelegate.inProgress ||
        unanswered != oldDelegate.unanswered;
  }
}
