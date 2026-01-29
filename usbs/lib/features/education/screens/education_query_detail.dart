import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EducationQueryDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot queryDoc;

  const EducationQueryDetailScreen({
    super.key,
    required this.queryDoc,
  });

  @override
  State<EducationQueryDetailScreen> createState() =>
      _EducationQueryDetailScreenState();
}

class _EducationQueryDetailScreenState
    extends State<EducationQueryDetailScreen> {
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
      appBar: AppBar(title: const Text('Education Query Details')),
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
            return const Center(child: Text('Query not found'));
          }

          final status = data['status'] ?? 'open';
          final bool canReply = status == 'replied';

          return Column(
            children: [
              /// 🔹 QUERY DETAILS
              Expanded(
                flex: 2,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _infoTile(
                        'Student Name', data['userName'] ?? 'Anonymous'),
                    _infoTile(
                        'Topic', data['topic'] ?? '-'),
                    _infoTile(
                        'Class', data['studentClass'] ?? '-'),
                    _infoTile('Status', status),

                    const SizedBox(height: 12),

                    const Text(
                      'Query',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(data['description'] ?? ''),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      'Conversation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              /// 🔹 CHAT (ORDERED)
              Expanded(
                flex: 3,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('queries')
                      .doc(queryId)
                      .collection('messages')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, msgSnapshot) {
                    if (!msgSnapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final messages = msgSnapshot.data!.docs
                        .where(
                            (d) => d.data()['createdAt'] != null)
                        .toList();

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Waiting for admin reply...'),
                      );
                    }

                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index].data();
                        final role = msg['senderRole'] ?? 'system';

                        Alignment alignment;
                        Color color;

                        if (role == 'admin') {
                          alignment = Alignment.centerLeft;
                          color = Colors.grey.shade300;
                        } else if (role == 'client') {
                          alignment = Alignment.centerRight;
                          color = Colors.blue.shade100;
                        } else {
                          alignment = Alignment.center;
                          color = Colors.grey.shade400;
                        }

                        return Align(
                          alignment: alignment,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            padding: const EdgeInsets.all(10),
                            constraints:
                                const BoxConstraints(maxWidth: 300),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              msg['message'] ?? '',
                              textAlign: role == 'system'
                                  ? TextAlign.center
                                  : TextAlign.left,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              /// 🔹 REPLY BOX
              _replyBox(queryId, canReply),
            ],
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
      child: Column(
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.attach_file),
            label: const Text('Upload Document'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document upload coming soon'),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: replyController,
                  enabled: canReply,
                  decoration: InputDecoration(
                    hintText: canReply
                        ? 'Write a reply...'
                        : 'Waiting for admin reply',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: canReply
                    ? () async {
                        final text =
                            replyController.text.trim();
                        if (text.isEmpty) return;

                        await FirebaseFirestore.instance
                            .collection('queries')
                            .doc(queryId)
                            .collection('messages')
                            .add({
                          'senderRole': 'client',
                          'message': text,
                          'createdAt':
                              FieldValue.serverTimestamp(),
                        });

                        replyController.clear();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
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
