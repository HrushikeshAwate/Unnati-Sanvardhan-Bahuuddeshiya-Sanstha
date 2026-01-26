import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> fetchUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists || !doc.data()!.containsKey('role')) {
      throw Exception('User role not found');
    }

    return doc['role'] as String;
  }
}
