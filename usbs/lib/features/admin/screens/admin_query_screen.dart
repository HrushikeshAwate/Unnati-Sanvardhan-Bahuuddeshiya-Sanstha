import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/routes/route_names.dart';

class AdminQueriesScreen extends StatefulWidget {
  const AdminQueriesScreen({super.key});

  @override
  State<AdminQueriesScreen> createState() => _AdminQueriesScreenState();
}

class _AdminQueriesScreenState extends State<AdminQueriesScreen> {
  String _searchText = '';
  String? _role;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _finishLoading();
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _role = doc.data()?['role'];
        _loadingRole = false;
      });
    } catch (_) {
      _finishLoading();
    }
  }

  void _finishLoading() {
    if (!mounted) return;
    setState(() {
      _role = null;
      _loadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isAdmin = _role == 'admin';
    final bool isSuperAdmin = _role == 'superadmin';

    /// 🔐 ROLE-BASED QUERY
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('queries');

    if (isAdmin) {
      query = query.where(
        'assignedAdminId',
        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
      );
    }

    // IMPORTANT: order for stable UI
    query = query.orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSuperAdmin ? 'All Queries' : 'Assigned Queries',
        ),
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: isSuperAdmin
                    ? 'Search by client or admin name'
                    : 'Search by client name',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
            ),
          ),

          /// 📄 QUERY LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading queries',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No queries found'),
                  );
                }

                List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                    snapshot.data!.docs;

                /// 🔍 CLIENT-SIDE SEARCH (SAFE)
                if (_searchText.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data();

                    final clientName =
                        (data['userName'] ?? '')
                            .toString()
                            .toLowerCase();

                    final adminName =
                        (data['assignedAdminName'] ?? '')
                            .toString()
                            .toLowerCase();

                    return isSuperAdmin
                        ? clientName.contains(_searchText) ||
                            adminName.contains(_searchText)
                        : clientName.contains(_searchText);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No matching queries'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(
                          data['description'] ?? 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['category']} • ${data['status']}',
                            ),
                            if (isSuperAdmin &&
                                data['assignedAdminName'] !=
                                    null)
                              Text(
                                'Assigned to: ${data['assignedAdminName']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing:
                            const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteNames.answerQuery,
                            arguments: doc,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
