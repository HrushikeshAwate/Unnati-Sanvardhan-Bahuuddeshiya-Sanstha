import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MedicalQueryDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot queryDoc;

  const MedicalQueryDetailScreen({
    super.key,
    required this.queryDoc,
  });

  @override
  Widget build(BuildContext context) {
    final data = queryDoc.data() as Map<String, dynamic>;

    final String patientName = data['patientName'] ?? 'Anonymous';
    final String age = data['age']?.toString() ?? 'Not specified';
    final String urgency = data['urgency'] ?? 'Normal';
    final String queryText = data['queryText'] ?? '';
    final String status = data['status'] ?? 'open';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Query Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _infoTile('Patient Name', patientName),
            _infoTile('Age', age),
            _infoTile('Urgency', urgency),
            _infoTile('Status', status),

            const SizedBox(height: 16),

            const Text(
              'Medical Concern',
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
