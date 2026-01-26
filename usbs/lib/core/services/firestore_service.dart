import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /* =====================================================
   * USERS
   * ===================================================== */

  /// Sync user on login (email / google)
  Future<void> syncUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'role': 'client', // default role
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  /// Create guest user (anonymous login)
  Future<void> createGuestUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': null,
        'name': 'Guest',
        'role': 'guest',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Fetch role for routing & permissions
  Future<String> fetchUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('User document missing');
    }

    return doc.data()!['role'] as String;
  }

  /* =====================================================
   * QUERIES (COMMON COLLECTION)
   * ===================================================== */

  /// Submit LEGAL query (client only)
  Future<void> submitLegalQuery({
    required String caseType,
    required String queryText,
    required String location,
    String? userName,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final docRef = _db.collection('queries').doc();

    await docRef.set({
      'id': docRef.id,

      // ownership
      'userId': user.uid,
      'userName': userName ?? user.displayName ?? 'Anonymous',

      // query info
      'category': 'legal',
      'caseType': caseType,
      'location': location,
      'description': queryText,

      // status
      'status': 'open', // open | replied | closed
      // timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitMedicalQuery({
    required String description,
    required String urgency,
    String? patientName,
    String? age,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final docRef = _db.collection('queries').doc();

    await docRef.set({
      'id': docRef.id,

      // ownership
      'userId': user.uid,
      'userName': patientName ?? user.displayName ?? 'Anonymous',

      // query info
      'category': 'medical',
      'urgency': urgency,
      'age': age,
      'description': description,

      // status
      'status': 'open',

      // timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitEducationQuery({
  required String topic,
  required String description,
  String? studentName,
  String? studentClass,
}) async {
  final user = _auth.currentUser;

  if (user == null) {
    throw Exception('User not logged in');
  }

  final docRef = _db.collection('queries').doc();

  await docRef.set({
    'id': docRef.id,

    // ownership
    'userId': user.uid,
    'userName': studentName ?? user.displayName ?? 'Anonymous',

    // query info
    'category': 'education',
    'topic': topic,
    'studentClass': studentClass,
    'description': description,

    // status
    'status': 'open',

    // timestamps
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}


  /* =====================================================
   * FETCH QUERIES
   * ===================================================== */

  /// Client: fetch only their queries
  Stream<QuerySnapshot<Map<String, dynamic>>> fetchMyQueries() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return _db
        .collection('queries')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Admin / Superadmin: fetch all queries
  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAllQueries() {
    return _db
        .collection('queries')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /* =====================================================
   * ADMIN ACTIONS
   * ===================================================== */

  /// Admin reply to query
  Future<void> replyToQuery({
    required String queryId,
    required String replyText,
  }) async {
    await _db.collection('queries').doc(queryId).update({
      'adminReply': replyText,
      'status': 'replied',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
