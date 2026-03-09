import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/firestore_service.dart';
import 'package:usbs/core/utils/date_utils.dart';
import 'package:usbs/core/utils/query_status_utils.dart';
import 'package:usbs/core/widgets/status_chip.dart';

class MedicalQueryDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot queryDoc;

  const MedicalQueryDetailScreen({super.key, required this.queryDoc});

  @override
  State<MedicalQueryDetailScreen> createState() =>
      _MedicalQueryDetailScreenState();
}

class _MedicalQueryDetailScreenState extends State<MedicalQueryDetailScreen> {
  final TextEditingController replyController = TextEditingController();
  String? _role;
  String t(String s) => AppI18n.tx(context, s);

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
    final queryId = widget.queryDoc.id;

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
        title: Text(t('Medical Query Details')),
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

          final status = normalizeQueryStatus(data['status']?.toString());

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
                                const Icon(Icons.local_hospital_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  t('Patient Information'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                StatusChip(status: status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _info(
                              t('Patient Name'),
                              (data['userName'] ?? 'Anonymous').toString(),
                            ),
                            _info(t('Age'), (data['age'] ?? '-').toString()),
                            _info(t('Urgency'), (data['urgency'] ?? '-').toString()),
                            _info(
                              t('Assigned To'),
                              (data['assignedAdminName'] ?? t('Unassigned'))
                                  .toString(),
                            ),
                            _info(t('Submitted At'), formatSubmittedAt(data)),
                            _info(t('Answered At'), formatAnsweredAt(data)),
                            if (_role == 'superadmin')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showReassignDialog(
                                      queryId: queryId,
                                      currentAssignedAdminId: data['assignedAdminId']
                                          ?.toString(),
                                    ),
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                    label: Text(t('Assign admin')),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              t('Medical Concern'),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
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
                    _chatSection(queryId),
                  ],
                ),
              ),
              _replyBox(queryId, status),
            ],
          );
        },
      ),
    );
  }

  Widget _chatSection(String queryId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('queries')
          .doc(queryId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots(),
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
            final isClient = role == 'client';
            final isAdmin = role == 'admin';
            final bubbleColor = isAdmin
                ? AppColors.elevatedSurface(context)
                : isClient
                ? const Color(0xFFE3EEF9)
                : AppColors.softAmber;
            final textColor = isClient || role == 'system'
                ? const Color(0xFF102133)
                : Theme.of(context).colorScheme.onSurface;
            return Align(
              alignment: isAdmin
                  ? Alignment.centerLeft
                  : isClient
                  ? Alignment.centerRight
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
                    bottomLeft: Radius.circular(isClient ? 14 : 4),
                    bottomRight: Radius.circular(isClient ? 4 : 14),
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

  Widget _replyBox(String queryId, String status) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface(context),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          if (status != 'answered')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await FirestoreService().markQuerySatisfied(queryId: queryId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('Marked as satisfied'))),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(t('Mark as Satisfied')),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(t('Upload Document')),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('Document upload coming soon'))),
                );
              },
            ),
          ),
          Row(
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
                    decoration: InputDecoration(
                      hintText: t('Write a reply...'),
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final text = replyController.text.trim();
                    if (text.isEmpty) return;

                    await FirestoreService().sendClientReply(
                      queryId: queryId,
                      message: text,
                    );

                    replyController.clear();
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
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
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

  Future<void> _showReassignDialog({
    required String queryId,
    required String? currentAssignedAdminId,
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
                            SnackBar(
                              content: Text(t('Query assigned successfully')),
                            ),
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
}
