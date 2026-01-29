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

  Future<String?> fetchMyRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['role'];
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
    await _createQuery(
      category: 'legal',
      description: queryText,
      systemMessage: 'Legal query created. Awaiting admin response.',
      userName: userName,
      extraData: {
        'caseType': caseType,
        'location': location,
      },
    );
  }

  Future<void> submitMedicalQuery({
    required String description,
    required String urgency,
    String? patientName,
    String? age,
  }) async {
    await _createQuery(
      category: 'medical',
      description: description,
      systemMessage: 'Medical query created. Awaiting admin response.',
      userName: patientName,
      extraData: {
        'urgency': urgency,
        'age': age,
      },
    );
  }

  Future<void> submitEducationQuery({
    required String topic,
    required String description,
    String? studentName,
    String? studentClass,
  }) async {
    await _createQuery(
      category: 'education',
      description: description,
      systemMessage: 'Education query created. Awaiting admin response.',
      userName: studentName,
      extraData: {
        'topic': topic,
        'studentClass': studentClass,
      },
    );
  }

  Future<void> _createQuery({
  required String category,
  required String description,
  required String systemMessage,
  required Map<String, dynamic> extraData,
  String? userName,
}) async {
  final user = _auth.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  final queryRef = _db.collection('queries').doc();

  /// 🔹 MAIN QUERY DOCUMENT
  await queryRef.set({
    'id': queryRef.id,
    'userId': user.uid,
    'userName': userName ?? user.displayName ?? 'Anonymous',
    'category': category,
    'description': description,

    /// 🔐 QUERY STATE
    'status': 'open', // open | replied | closed

    /// 🔐 ASSIGNMENT (VERY IMPORTANT)
    /// Must EXIST and be NULL for "Unassigned Queries" to work
    'assignedAdminId': null,
    'assignedAdminName': null,
    'assignedAt': null,

    /// 🔢 MESSAGE COUNTER (FOR ORDERING)
    'lastMessageSeq': 0,

    /// EXTRA CATEGORY-SPECIFIC DATA
    ...extraData,

    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// 🔹 SYSTEM MESSAGE (CREATES messages SUBCOLLECTION)
  await queryRef.collection('messages').add({
    'senderRole': 'system', // system | admin | client
    'message': systemMessage,

    /// 🔢 FIRST MESSAGE SEQUENCE
    'sequence': 0,

    /// 🔗 PLACEHOLDER FOR FUTURE FILES
    'attachments': [],

    'createdAt': FieldValue.serverTimestamp(),
  });
}

  /* =====================================================
   * FETCH QUERIES
   * ===================================================== */

  /// Client: own queries
  Stream<QuerySnapshot<Map<String, dynamic>>> fetchMyQueries() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _db
        .collection('queries')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Admin: only assigned queries
  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAssignedQueries() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _db
        .collection('queries')
        .where('assignedAdminId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Superadmin: all queries
  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAllQueries() {
    return _db
        .collection('queries')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /* =====================================================
   * ASSIGN QUERY (SUPERADMIN ONLY)
   * ===================================================== */

  Future<void> assignQuery({
    required String queryId,
    required String adminId,
    required String adminName,
  }) async {
    await _db.collection('queries').doc(queryId).update({
      'assignedAdminId': adminId,
      'assignedAdminName': adminName,
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /* =====================================================
   * FETCH ADMINS (SUPERADMIN)
   * ===================================================== */

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAdmins() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .orderBy('name')
        .snapshots();
  }

  /* =====================================================
   * CHAT / REPLIES
   * ===================================================== */

  /// Admin reply
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

    await queryRef.update({
      'status': 'replied',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Client reply (only after admin)
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

    await queryRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /* =====================================================
   * CHAT STREAM (ORDERED)
   * ===================================================== */

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchMessages(String queryId) {
    return _db
        .collection('queries')
        .doc(queryId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
