import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:usbs/core/services/firestore_service.dart';

class AssignQueriesScreen extends StatelessWidget {
  const AssignQueriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Queries')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('queries')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, querySnap) {
          if (querySnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!querySnap.hasData || querySnap.data!.docs.isEmpty) {
            return const Center(child: Text('No queries found'));
          }

          final queries = querySnap.data!.docs;

          return ListView.builder(
            itemCount: queries.length,
            itemBuilder: (context, index) {
              final queryDoc = queries[index];
              final query = queryDoc.data();

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// QUERY INFO
                      Text(
                        query['description'] ?? 'No description',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Category: ${query['category']}'),
                      Text(
                        'Assigned: ${query['assignedAdminName'] ?? 'Unassigned'}',
                        style: TextStyle(
                          color: query['assignedAdminId'] == null
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ADMIN DROPDOWN
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: service.fetchAdmins(),
                        builder: (context, adminSnap) {
                          if (!adminSnap.hasData ||
                              adminSnap.data!.docs.isEmpty) {
                            return const Text(
                              'No admins available',
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          final admins = adminSnap.data!.docs;

                          return DropdownButtonFormField<String>(
                            value: admins.any(
                                    (a) => a.id == query['assignedAdminId'])
                                ? query['assignedAdminId']
                                : null,
                            hint: const Text('Assign admin'),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: admins.map((adminDoc) {
                              final admin = adminDoc.data();

                              final adminName =
                                  admin['name'] ??
                                  admin['email'] ??
                                  'Admin';

                              return DropdownMenuItem(
                                value: adminDoc.id,
                                child: Text(adminName),
                              );
                            }).toList(),
                            onChanged: (adminId) async {
                              if (adminId == null) return;

                              final adminDoc = admins.firstWhere(
                                (a) => a.id == adminId,
                              );
                              final admin = adminDoc.data();

                              await service.assignQuery(
                                queryId: queryDoc.id,
                                adminId: adminDoc.id,
                                adminName:
                                    admin['name'] ??
                                    admin['email'] ??
                                    'Admin',
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Query assigned successfully'),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
