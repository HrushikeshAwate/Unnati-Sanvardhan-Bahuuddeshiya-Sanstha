import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LegalQueryDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot queryDoc;

  const LegalQueryDetailScreen({super.key, required this.queryDoc});

  @override
  State<LegalQueryDetailScreen> createState() =>
      _LegalQueryDetailScreenState();
}

class _LegalQueryDetailScreenState extends State<LegalQueryDetailScreen> {
  final TextEditingController replyController = TextEditingController();

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queryId = widget.queryDoc.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Legal Query Details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('queries')
            .doc(queryId)
            .snapshots(),
        builder: (context, querySnap) {
          if (!querySnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = querySnap.data!.data();
          if (data == null) {
            return const Center(child: Text('Query not found'));
          }

          final status = data['status'] ?? 'open';
          final canReply = status == 'replied';

          return Column(
            children: [
              _queryHeader(data, status),
              _chatSection(queryId),
              _replyBox(queryId, canReply),
            ],
          );
        },
      ),
    );
  }

  Widget _queryHeader(Map<String, dynamic> data, String status) {
    return Expanded(
      flex: 2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _info('Name', data['userName'] ?? 'Anonymous'),
          _info('Location', data['location'] ?? '-'),
          _info('Case Type', data['caseType'] ?? '-'),
          _info('Status', status),
          const SizedBox(height: 10),
          const Text('Legal Issue',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(data['description'] ?? ''),
          ),
          const Divider(height: 30),
          const Text('Conversation',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _chatSection(String queryId) {
    return Expanded(
      flex: 3,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('queries')
            .doc(queryId)
            .collection('messages')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snap.data!.docs
              .where((d) => d.data()['createdAt'] != null)
              .toList();

          if (messages.isEmpty) {
            return const Center(
                child: Text('Waiting for admin reply...'));
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final msg = messages[i].data();
              final role = msg['senderRole'];

              Alignment align;
              Color color;

              if (role == 'admin') {
                align = Alignment.centerLeft;
                color = Colors.grey.shade300;
              } else if (role == 'client') {
                align = Alignment.centerRight;
                color = Colors.blue.shade100;
              } else {
                align = Alignment.center;
                color = Colors.grey.shade400;
              }

              return Align(
                alignment: align,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(msg['message'] ?? '',
                      textAlign:
                          role == 'system' ? TextAlign.center : TextAlign.left),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _replyBox(String queryId, bool canReply) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: replyController,
              enabled: canReply,
              decoration: InputDecoration(
                hintText:
                    canReply ? 'Write a reply…' : 'Waiting for admin reply',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: canReply
                ? () async {
                    final text = replyController.text.trim();
                    if (text.isEmpty) return;

                    await FirebaseFirestore.instance
                        .collection('queries')
                        .doc(queryId)
                        .collection('messages')
                        .add({
                      'senderRole': 'client',
                      'message': text,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    replyController.clear();
                  }
                : null,
          )
        ],
      ),
    );
  }

  Widget _info(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
                width: 120,
                child:
                    Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
