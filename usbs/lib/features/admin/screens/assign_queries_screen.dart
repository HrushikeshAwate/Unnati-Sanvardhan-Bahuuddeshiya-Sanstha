import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignQueriesScreen extends StatefulWidget {
  const AssignQueriesScreen({super.key});

  @override
  State<AssignQueriesScreen> createState() => _AssignQueriesScreenState();
}

class _AssignQueriesScreenState extends State<AssignQueriesScreen> {
  String? _selectedAdminId;
  String? _selectedAdminName;

  /// 🔐 HARD BLOCK (UI LEVEL)
  Future<bool> _isSuperAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['role'] == 'superadmin';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isSuperAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == false) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Access Denied',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Assign Queries')),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('queries')
                .where('assignedAdminId', isNull: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No unassigned queries 🎉',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final queries = snapshot.data!.docs;

              return ListView.builder(
                itemCount: queries.length,
                itemBuilder: (context, index) {
                  final doc = queries[index];
                  final data = doc.data();

                  return Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['description'] ??
                                'No description',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Category: ${data['category']}',
                          ),

                          Text(
                            'Client: ${data['userName'] ?? 'Anonymous'}',
                          ),

                          const Divider(height: 24),

                          /// 👤 ADMIN DROPDOWN
                          StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('role',
                                    isEqualTo: 'admin')
                                .snapshots(),
                            builder: (context, adminSnap) {
                              if (!adminSnap.hasData) {
                                return const Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              }

                              final admins =
                                  adminSnap.data!.docs;

                              return DropdownButtonFormField<
                                  String>(
                                value: _selectedAdminId,
                                hint: const Text(
                                    'Select Admin'),
                                items: admins.map((admin) {
                                  return DropdownMenuItem<
                                      String>(
                                    value: admin.id,
                                    child: Text(
                                      admin
                                              .data()['name'] ??
                                          admin
                                              .data()['email'] ??
                                          'Admin',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  final admin = admins.firstWhere(
                                      (a) => a.id == value);

                                  setState(() {
                                    _selectedAdminId =
                                        admin.id;
                                    _selectedAdminName =
                                        admin.data()['name'] ??
                                            admin
                                                .data()['email'];
                                  });
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label:
                                  const Text('Assign'),
                              onPressed:
                                  _selectedAdminId == null
                                      ? null
                                      : () async {
                                          await FirebaseFirestore
                                              .instance
                                              .collection(
                                                  'queries')
                                              .doc(doc.id)
                                              .update({
                                            'assignedAdminId':
                                                _selectedAdminId,
                                            'assignedAdminName':
                                                _selectedAdminName,
                                            'assignedAt':
                                                FieldValue
                                                    .serverTimestamp(),
                                            'updatedAt':
                                                FieldValue
                                                    .serverTimestamp(),
                                          });

                                          setState(() {
                                            _selectedAdminId =
                                                null;
                                            _selectedAdminName =
                                                null;
                                          });

                                          ScaffoldMessenger.of(
                                                  context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Query assigned successfully'),
                                            ),
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
            },
          ),
        );
      },
    );
  }
}
