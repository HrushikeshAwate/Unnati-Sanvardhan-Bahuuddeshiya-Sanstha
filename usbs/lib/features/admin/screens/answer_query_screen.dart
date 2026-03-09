import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/firestore_service.dart';
import 'package:usbs/core/utils/date_utils.dart';
import 'package:usbs/core/utils/query_status_utils.dart';
import 'package:usbs/core/widgets/status_chip.dart';

class AnswerQueryScreen extends StatefulWidget {
  const AnswerQueryScreen({super.key});

  @override
  State<AnswerQueryScreen> createState() => _AnswerQueryScreenState();
}

class _AnswerQueryScreenState extends State<AnswerQueryScreen> {
  final TextEditingController replyController = TextEditingController();
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted) return;
    setState(() {
      _role = userDoc.data()?['role']?.toString();
    });
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = (String s) => AppI18n.tx(context, s);
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! QueryDocumentSnapshot) {
      return Scaffold(body: Center(child: Text(t('Invalid query data'))));
    }

    final QueryDocumentSnapshot queryDoc = args;
    final String queryId = queryDoc.id;
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
        title: Text(t('Query Chat')),
        actions: const [LanguageMenuButton()],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('queries')
            .doc(queryId)
            .snapshots(),
        builder: (context, querySnapshot) {
          if (!querySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = querySnapshot.data!.data();
          if (data == null) {
            return Center(child: Text(t('Query not found')));
          }

          final assignedAdminId = data['assignedAdminId']?.toString();
          final canReply = _role == 'superadmin' || assignedAdminId == myUid;
          final normalizedStatus = normalizeQueryStatus(data['status']?.toString());
          final escalated = data['escalatedToSuperadmin'] == true;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.support_agent_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  t('Query Description'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                StatusChip(status: normalizedStatus),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _infoTile(
                              t('Client'),
                              (data['userName'] ?? 'Anonymous').toString(),
                            ),
                            _infoTile(t('Category'), (data['category'] ?? '-').toString()),
                            _infoTile(
                              t('Assigned To'),
                              (data['assignedAdminName'] ?? 'Unassigned').toString(),
                            ),
                            if (_role == 'superadmin')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showReassignDialog(
                                      queryId: queryId,
                                      currentAssignedAdminId: assignedAdminId,
                                      t: t,
                                    ),
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                    label: Text(t('Assign admin')),
                                  ),
                                ),
                              ),
                            _infoTile(t('Submitted At'), formatSubmittedAt(data)),
                            _infoTile(t('Answered At'), formatAnsweredAt(data)),
                            if (escalated)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.isDark(context)
                                        ? AppColors.accent.withValues(alpha: 0.22)
                                        : AppColors.softAmber,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.isDark(context)
                                          ? AppColors.accent.withValues(alpha: 0.7)
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
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.elevatedSurface(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                t((data['description'] ?? '').toString()),
                              ),
                            ),
                            if (_role == 'admin' && canReply)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: OutlinedButton.icon(
                                  onPressed: () => _showEscalateDialog(queryId, t),
                                  icon: const Icon(Icons.report_problem_outlined),
                                  label: Text(t('Escalate to Superadmin')),
                                ),
                              ),
                            if (_role == 'superadmin' &&
                                escalated &&
                                normalizedStatus != 'answered')
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await FirestoreService()
                                          .closeEscalatedQueryBySuperadmin(
                                            queryId: queryId,
                                          );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            t(
                                              'Escalated query marked as satisfied',
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: Text(t('Mark as Satisfied')),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t('Conversation'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _chatSection(queryId, t),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface(context),
                  border: const Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.elevatedSurface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: replyController,
                          enabled: canReply,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: canReply
                                ? t('Reply...')
                                : t('Only assigned admin can reply'),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: canReply ? AppColors.primary : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: !canReply
                            ? null
                            : () async {
                                final text = replyController.text.trim();
                                if (text.isEmpty) return;
                                try {
                                  await FirestoreService().sendAdminReply(
                                    queryId: queryId,
                                    message: text,
                                  );
                                  replyController.clear();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              },
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chatSection(String queryId, String Function(String) t) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().fetchMessages(queryId),
      builder: (context, msgSnapshot) {
        if (!msgSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final messages = msgSnapshot.data!.docs
            .where(
              (d) =>
                  d.data()['createdAt'] != null &&
                  (d.data()['senderRole']?.toString() ?? '') != 'system',
            )
            .toList();
        if (messages.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(t('No messages yet')),
            ),
          );
        }

        return Column(
          children: messages.map((doc) {
            final msg = doc.data();
            final role = (msg['senderRole'] ?? 'system').toString();
            final isAdmin = role == 'admin';
            final isClient = role == 'client';
            final bubbleColor = isAdmin
                ? const Color(0xFFE3EEF9)
                : isClient
                ? AppColors.elevatedSurface(context)
                : AppColors.softAmber;
            final textColor = isAdmin || role == 'system'
                ? const Color(0xFF102133)
                : Theme.of(context).colorScheme.onSurface;

            return Align(
              alignment: isAdmin
                  ? Alignment.centerRight
                  : isClient
                  ? Alignment.centerLeft
                  : Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isAdmin ? 14 : 4),
                    bottomRight: Radius.circular(isAdmin ? 4 : 14),
                  ),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  t((msg['message'] ?? '').toString()),
                  style: TextStyle(color: textColor),
                  textAlign: role == 'system' ? TextAlign.center : TextAlign.left,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showEscalateDialog(
    String queryId,
    String Function(String) t,
  ) async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('Escalate to Superadmin')),
        content: TextField(
          controller: reasonController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: t('Escalation reason (optional)'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService().escalateQueryToSuperadmin(
                queryId: queryId,
                reason: reasonController.text.trim(),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('Escalated to superadmin'))),
              );
            },
            child: Text(t('Escalate')),
          ),
        ],
      ),
    );
    reasonController.dispose();
  }

  Future<void> _showReassignDialog({
    required String queryId,
    required String? currentAssignedAdminId,
    required String Function(String) t,
  }) async {
    String? selectedAdminId = currentAssignedAdminId;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            final admins = docs.where((doc) => doc.data()['isActive'] != false).toList();

            return AlertDialog(
              title: Text(t('Assign admin')),
              content: StatefulBuilder(
                builder: (context, setLocalState) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 70,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (admins.isEmpty) {
                    return Text(t('No admin available'));
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: selectedAdminId != null &&
                            admins.any((a) => a.id == selectedAdminId)
                        ? selectedAdminId
                        : null,
                    hint: Text(t('Assign admin')),
                    items: admins.map((doc) {
                      final data = doc.data();
                      final name =
                          (data['name'] ?? data['email'] ?? 'Admin').toString();
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setLocalState(() => selectedAdminId = value);
                    },
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('Cancel')),
                ),
                ElevatedButton(
                  onPressed: admins.isEmpty || selectedAdminId == null
                      ? null
                      : () async {
                          final selectedDoc = admins.firstWhere(
                            (a) => a.id == selectedAdminId,
                          );
                          final selectedData = selectedDoc.data();
                          final adminName = (selectedData['name'] ??
                                  selectedData['email'] ??
                                  'Admin')
                              .toString();

                          await FirestoreService().assignQuery(
                            queryId: queryId,
                            adminId: selectedDoc.id,
                            adminName: adminName,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t('Query assigned successfully'))),
                          );
                        },
                  child: Text(t('update')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
