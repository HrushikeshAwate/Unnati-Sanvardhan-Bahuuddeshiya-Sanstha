import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EducationQueryDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot queryDoc;

  const EducationQueryDetailScreen({
    super.key,
    required this.queryDoc,
  });

  @override
  Widget build(BuildContext context) {
    final data = queryDoc.data() as Map<String, dynamic>;

    final String topic = data['topic'] ?? 'General';
    final String queryText = data['queryText'] ?? '';
    final String studentClass = data['studentClass'] ?? 'Not specified';
    final String userName = data['userName'] ?? 'Anonymous';
    final String status = data['status'] ?? 'open';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Query Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _infoTile('Student Name', userName),
            _infoTile('Class / Course', studentClass),
            _infoTile('Topic', topic),
            _infoTile('Status', status),

            const SizedBox(height: 16),

            const Text(
              'Query',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                queryText,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
