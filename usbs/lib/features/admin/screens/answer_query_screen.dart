import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerQueryScreen extends StatefulWidget {
  const AnswerQueryScreen({super.key});

  @override
  State<AnswerQueryScreen> createState() => _AnswerQueryScreenState();
}

class _AnswerQueryScreenState extends State<AnswerQueryScreen> {
  final TextEditingController replyController = TextEditingController();

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! QueryDocumentSnapshot) {
      return const Scaffold(
        body: Center(child: Text('Invalid query data')),
      );
    }

    final QueryDocumentSnapshot queryDoc = args;
    final String queryId = queryDoc.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Answer Query')),
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

          return Column(
            children: [
              /// 🔹 QUERY DETAILS (LIVE)
              Expanded(
                flex: 2,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _infoTile('Name', data['userName'] ?? 'Anonymous'),
                    _infoTile('Category', data['category'] ?? '-'),
                    _infoTile('Status', data['status'] ?? 'open'),

                    const SizedBox(height: 12),

                    const Text(
                      'Query Description',
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

              /// 🔹 CHAT (ORDERED + BUBBLES)
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
                        child: Text('No messages yet'),
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
                          alignment = Alignment.centerRight;
                          color = Colors.blue.shade100;
                        } else if (role == 'client') {
                          alignment = Alignment.centerLeft;
                          color = Colors.grey.shade300;
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

              /// 🔹 ADMIN REPLY BAR
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Upload Document'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Document upload coming soon'),
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
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Write admin reply...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            final text =
                                replyController.text.trim();
                            if (text.isEmpty) return;

                            await FirebaseFirestore.instance
                                .collection('queries')
                                .doc(queryId)
                                .collection('messages')
                                .add({
                              'senderRole': 'admin',
                              'message': text,
                              'createdAt':
                                  FieldValue.serverTimestamp(),
                            });

                            await FirebaseFirestore.instance
                                .collection('queries')
                                .doc(queryId)
                                .update({
                              'status': 'replied',
                              'updatedAt':
                                  FieldValue.serverTimestamp(),
                            });

                            replyController.clear();
                          },
                        ),
                      ],
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
