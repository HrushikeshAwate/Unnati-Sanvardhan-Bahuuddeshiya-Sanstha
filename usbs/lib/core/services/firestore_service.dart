import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Resolve user & create document on first login
  Future<AppUser> resolveUser(User firebaseUser) async {
    final ref = _db.collection('users').doc(firebaseUser.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'email': firebaseUser.email,
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final data = (await ref.get()).data()!;
    return AppUser(
      uid: firebaseUser.uid,
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.client,
      ),
    );
  }

  /// Create query
  Future<void> createQuery({
    required String type,
    required String category,
    required String description,
    required String userId,
  }) {
    return _db.collection('queries').add({
      'type': type,
      'category': category,
      'description': description,
      'createdBy': userId,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
