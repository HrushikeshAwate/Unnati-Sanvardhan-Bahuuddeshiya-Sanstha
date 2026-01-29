import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /* =====================================================
   * USERS
   * ===================================================== */

  Future<void> syncUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'role': 'client',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

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

  Future<String> fetchUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User document missing');
    }
    return doc.data()!['role'] as String;
  }

  /* =====================================================
   * QUERY CREATION (SYSTEM MESSAGE)
   * ===================================================== */

  Future<void> submitLegalQuery({
    required String caseType,
    required String queryText,
    required String location,
    String? userName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final queryRef = _db.collection('queries').doc();

    await queryRef.set({
      'id': queryRef.id,
      'userId': user.uid,
      'userName': userName ?? user.displayName ?? 'Anonymous',
      'category': 'legal',
      'caseType': caseType,
      'location': location,
      'description': queryText,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // System message (creates messages collection)
    await queryRef.collection('messages').add({
      'senderRole': 'system',
      'message': 'Legal query created. Awaiting admin response.',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitMedicalQuery({
    required String description,
    required String urgency,
    String? patientName,
    String? age,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final queryRef = _db.collection('queries').doc();

    await queryRef.set({
      'id': queryRef.id,
      'userId': user.uid,
      'userName': patientName ?? user.displayName ?? 'Anonymous',
      'category': 'medical',
      'urgency': urgency,
      'age': age,
      'description': description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await queryRef.collection('messages').add({
      'senderRole': 'system',
      'message': 'Medical query created. Awaiting admin response.',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitEducationQuery({
    required String topic,
    required String description,
    String? studentName,
    String? studentClass,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final queryRef = _db.collection('queries').doc();

    await queryRef.set({
      'id': queryRef.id,
      'userId': user.uid,
      'userName': studentName ?? user.displayName ?? 'Anonymous',
      'category': 'education',
      'topic': topic,
      'studentClass': studentClass,
      'description': description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await queryRef.collection('messages').add({
      'senderRole': 'system',
      'message': 'Education query created. Awaiting admin response.',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* =====================================================
   * FETCH QUERIES
   * ===================================================== */

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchMyQueries() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _db
        .collection('queries')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAllQueries() {
    return _db.collection('queries').snapshots();
  }

  /* =====================================================
   * CHAT / REPLIES (STRICT FLOW)
   * ===================================================== */

  /// ADMIN REPLY (FIRST + CONTINUED)
  Future<void> sendAdminReply({
    required String queryId,
    required String message,
  }) async {
    final queryRef = _db.collection('queries').doc(queryId);

    await queryRef.collection('messages').add({
      'senderRole': 'admin',
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Admin reply unlocks client chat
    await queryRef.update({
      'status': 'replied',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// CLIENT REPLY (ONLY AFTER ADMIN)
  Future<void> sendClientReply({
    required String queryId,
    required String message,
  }) async {
    final queryRef = _db.collection('queries').doc(queryId);

    await queryRef.collection('messages').add({
      'senderRole': 'client',
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Status remains replied
    await queryRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
