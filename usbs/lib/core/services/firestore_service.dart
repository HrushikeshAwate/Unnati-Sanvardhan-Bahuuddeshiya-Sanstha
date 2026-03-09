import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  static const int _defaultQueryLimit = 1000;

  String _canonicalCategory(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'education':
      case 'educational':
      case 'eduaction':
        return 'education';
      case 'medical':
      case 'medic':
        return 'medical';
      case 'legal':
      case 'law':
        return 'legal';
      default:
        return normalized;
    }
  }

  List<String> _normalizeExpertises(Iterable<dynamic> values) {
    final out = <String>{};
    for (final value in values) {
      final normalized = _canonicalCategory(value.toString());
      if (normalized.isEmpty) continue;
      out.add(normalized);
    }
    return out.toList()..sort();
  }

  List<String> _extractExpertises(Map<String, dynamic> data) {
    final rawList = data['expertises'];
    if (rawList is List) {
      final normalized = _normalizeExpertises(rawList);
      if (normalized.isNotEmpty) return normalized;
    }

    final legacy = (data['expertise'] ?? '').toString().trim();
    if (legacy.isEmpty) return const [];
    return _normalizeExpertises([legacy]);
  }

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
        'expertise': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.update({
      'email': user.email,
      'name': user.displayName,
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createGuestUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': null,
        'name': 'Guest User',
        'role': 'client',
        'isDummyAccess': true,
        'isActive': true,
        'expertise': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.set({
      'name': 'Guest User',
      'role': 'client',
      'isDummyAccess': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> fetchMyRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['role'] as String?;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchMe() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _db.collection('users').doc(user.uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMe() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _db.collection('users').doc(user.uid).snapshots();
  }

  Future<void> updateMyProfile({
    required String name,
    String? email,
    String? alternateEmail,
    String? city,
    String? state,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'alternateEmail': alternateEmail,
      'city': city,
      'state': state,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> submitLegalQuery({
    required String caseType,
    required String queryText,
    required String location,
    String? userName,
  }) async {
    await _createQuery(
      category: 'legal',
      description: queryText,
      userName: userName,
      extraData: {'caseType': caseType, 'location': location},
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
      userName: patientName,
      extraData: {'urgency': urgency, 'age': age},
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
      userName: studentName,
      extraData: {'topic': topic, 'studentClass': studentClass},
    );
  }

  Future<void> _createQuery({
    required String category,
    required String description,
    required Map<String, dynamic> extraData,
    String? userName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    if (user.isAnonymous) {
      throw Exception('Guest users cannot submit queries. Please login with Google.');
    }

    final queryRef = _db.collection('queries').doc();

    final limit = await getQueryLimit();
    final total = await getTotalQueryCount();
    if (total >= limit) {
      throw Exception(
        'Query limit reached ($limit). Please contact superadmin.',
      );
    }

    final assignment = await _pickAdminForCategory(category);

    await queryRef.set({
      'id': queryRef.id,
      'userId': user.uid,
      'userName': userName ?? user.displayName ?? 'Anonymous',
      'category': category,
      'description': description,
      'status': 'unanswered',
      'submittedAt': FieldValue.serverTimestamp(),
      'assignedAdminId': assignment?['id'],
      'assignedAdminName': assignment?['name'],
      'assignedAt': assignment == null ? null : FieldValue.serverTimestamp(),
      'needsManualAssignment': assignment == null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...extraData,
    });

    await _safeRun(() async {
      await _db.collection('system').doc('queryCounter').set({
        'total': FieldValue.increment(1),
      }, SetOptions(merge: true));
    });
    await _safeRun(() async {
      await _db.collection('system').doc('config').set({
        'queryLimit': limit,
      }, SetOptions(merge: true));
    });

    await _safeRun(_notifySuperAdminsForLimit);
  }

  Future<void> _safeRun(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      rethrow;
    }
  }

  Future<Map<String, String>?> _pickAdminForCategory(String category) async {
    try {
      final adminsSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      final normalizedCategory = _canonicalCategory(category);
      final eligibleAdmins = adminsSnap.docs.where((adminDoc) {
        final data = adminDoc.data();
        final isActive = data['isActive'] != false;
        final expertises = _extractExpertises(data);
        return isActive && expertises.contains(normalizedCategory);
      }).toList();

      if (eligibleAdmins.isEmpty) return null;

      String? selectedId;
      String selectedName = 'Admin';
      int minLoad = 1 << 30;

      for (final adminDoc in eligibleAdmins) {
        final loadSnap = await _db
            .collection('queries')
            .where('assignedAdminId', isEqualTo: adminDoc.id)
            .where('status', whereIn: ['unanswered', 'in_progress'])
            .count()
            .get();
        final load = loadSnap.count ?? 0;

        if (load < minLoad) {
          minLoad = load;
          selectedId = adminDoc.id;
          final data = adminDoc.data();
          selectedName = (data['name'] ?? data['email'] ?? 'Admin').toString();
        }
      }

      if (selectedId == null) return null;
      return {'id': selectedId, 'name': selectedName};
    } on FirebaseException {
      // If client-side role-based read rules block admin lookup, still allow
      // query submission and leave it for manual assignment.
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchMyQueries({
    String? category,
  }) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    var query = _db.collection('queries').where('userId', isEqualTo: user.uid);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('updatedAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAssignedQueries() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('queries')
        .where('assignedAdminId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAllQueries() {
    return _db
        .collection('queries')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchQueriesForAdminView() {
    return _db
        .collection('queries')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<void> assignQuery({
    required String queryId,
    required String adminId,
    required String adminName,
  }) async {
    await _db.collection('queries').doc(queryId).update({
      'assignedAdminId': adminId,
      'assignedAdminName': adminName,
      'assignedAt': FieldValue.serverTimestamp(),
      'needsManualAssignment': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

  }

  Future<void> autoAssignUnassignedQueries() async {
    final unassigned = await _db
        .collection('queries')
        .where('assignedAdminId', isNull: true)
        .limit(200)
        .get();

    for (final doc in unassigned.docs) {
      final data = doc.data();
      final category = (data['category'] ?? '').toString();
      final assignment = await _pickAdminForCategory(category);
      if (assignment == null) continue;

      await assignQuery(
        queryId: doc.id,
        adminId: assignment['id']!,
        adminName: assignment['name']!,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAdmins({String? category}) {
    return _db.collection('users').where('role', isEqualTo: 'admin').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchAllUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendAdminReply({
    required String queryId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final queryRef = _db.collection('queries').doc(queryId);
    final querySnap = await queryRef.get();
    final queryData = querySnap.data();
    if (queryData == null) throw Exception('Query not found');

    final assignedAdminId = queryData['assignedAdminId'] as String?;
    final role = await fetchMyRole();
    final isSuperadmin = role == 'superadmin';
    if (!isSuperadmin && assignedAdminId != user.uid) {
      throw Exception('Only assigned admin can answer this query.');
    }

    await queryRef.collection('messages').add({
      'senderRole': 'admin',
      'senderId': user.uid,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await queryRef.update({
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });

  }

  Future<void> sendClientReply({
    required String queryId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final queryRef = _db.collection('queries').doc(queryId);
    final querySnap = await queryRef.get();
    final queryData = querySnap.data();
    if (queryData == null) throw Exception('Query not found');

    await queryRef.collection('messages').add({
      'senderRole': 'client',
      'senderId': user.uid,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await queryRef.update({
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });

  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchMessages(String queryId) {
    return _db
        .collection('queries')
        .doc(queryId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> updateQueryStatus({
    required String queryId,
    required String status,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'answered') {
      payload['answeredAt'] = FieldValue.serverTimestamp();
    }

    await _db.collection('queries').doc(queryId).update(payload);
  }

  Future<void> markQuerySatisfied({required String queryId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final queryRef = _db.collection('queries').doc(queryId);
    final querySnap = await queryRef.get();
    final data = querySnap.data();
    if (data == null) throw Exception('Query not found');

    final role = await fetchMyRole();
    final isOwner = data['userId'] == user.uid;
    final isSuperadmin = role == 'superadmin';
    if (!isOwner && !isSuperadmin) {
      throw Exception('Only query owner can mark it satisfied.');
    }

    await queryRef.update({
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
      'resolvedByClient': true,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

  }

  Future<void> escalateQueryToSuperadmin({
    required String queryId,
    String? reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final role = await fetchMyRole();
    if (role != 'admin' && role != 'superadmin') {
      throw Exception('Only admin can escalate query to superadmin.');
    }

    final queryRef = _db.collection('queries').doc(queryId);
    await queryRef.update({
      'escalatedToSuperadmin': true,
      'escalatedBy': user.uid,
      'escalationReason': reason,
      'escalatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

  }

  Future<void> closeEscalatedQueryBySuperadmin({
    required String queryId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final role = await fetchMyRole();
    if (role != 'superadmin') {
      throw Exception('Only superadmin can close escalated queries.');
    }

    final queryRef = _db.collection('queries').doc(queryId);
    final querySnap = await queryRef.get();
    final data = querySnap.data();
    if (data == null) throw Exception('Query not found');
    if (data['escalatedToSuperadmin'] != true) {
      throw Exception('This query is not escalated.');
    }

    await queryRef.update({
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
      'resolvedBySuperadmin': true,
      'resolvedByClient': false,
      'resolvedAt': FieldValue.serverTimestamp(),
      'escalatedResolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuery(String queryId) async {
    final role = await fetchMyRole();
    if (role != 'superadmin') {
      throw Exception('Only superadmin can delete queries.');
    }

    final queryRef = _db.collection('queries').doc(queryId);
    final querySnap = await queryRef.get();
    if (!querySnap.exists) return;

    try {
      final messages = await queryRef.collection('messages').get();
      final batch = _db.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(queryRef);
      batch.set(_db.collection('system').doc('queryCounter'), {
        'total': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;

      // Fallback for environments where nested message deletion is blocked.
      await _db.runTransaction((tx) async {
        tx.delete(queryRef);
        tx.set(_db.collection('system').doc('queryCounter'), {
          'total': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      });
    }
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
    String? expertise,
    List<String>? expertises,
  }) async {
    final myRole = await fetchMyRole();
    if (myRole != 'superadmin') {
      throw Exception('Only superadmin can update user role.');
    }

    if (role == 'superadmin') {
      throw Exception('Superadmin role cannot be assigned from app.');
    }

    final target = await _db.collection('users').doc(userId).get();
    final currentRole = target.data()?['role']?.toString();
    if (currentRole == 'superadmin') {
      throw Exception('Superadmin role cannot be changed from app.');
    }

    final normalizedExpertises = _normalizeExpertises([
      ...?expertises,
      if (expertise != null) expertise,
    ]);

    await _db.collection('users').doc(userId).update({
      'role': role,
      'expertises': role == 'admin' ? normalizedExpertises : null,
      'expertise': role == 'admin' && normalizedExpertises.isNotEmpty
          ? normalizedExpertises.first
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> transferSuperadminOwnership({
    required String newSuperadminId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');
    if (newSuperadminId == currentUser.uid) {
      throw Exception('You are already the superadmin.');
    }

    final myRole = await fetchMyRole();
    if (myRole != 'superadmin') {
      throw Exception('Only superadmin can transfer ownership.');
    }

    final currentRef = _db.collection('users').doc(currentUser.uid);
    final targetRef = _db.collection('users').doc(newSuperadminId);

    await _db.runTransaction((tx) async {
      final currentSnap = await tx.get(currentRef);
      final targetSnap = await tx.get(targetRef);

      if (!currentSnap.exists) {
        throw Exception('Current user not found.');
      }
      if (!targetSnap.exists) {
        throw Exception('Selected user not found.');
      }
      if ((currentSnap.data()?['role'] as String?) != 'superadmin') {
        throw Exception('Only superadmin can transfer ownership.');
      }

      final targetRole = (targetSnap.data()?['role'] as String?) ?? 'client';
      if (targetRole == 'superadmin') {
        throw Exception('Selected user is already superadmin.');
      }

      final currentExpertises = _extractExpertises(
        currentSnap.data() ?? const <String, dynamic>{},
      );

      tx.update(targetRef, {
        'role': 'superadmin',
        'expertises': null,
        'expertise': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(currentRef, {
        'role': 'admin',
        'expertises': currentExpertises.isEmpty ? ['legal'] : currentExpertises,
        'expertise': currentExpertises.isEmpty ? 'legal' : currentExpertises.first,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<DeleteUserResult> deleteUser(String userId) async {
    final myRole = await fetchMyRole();
    if (myRole != 'superadmin') {
      throw Exception('Only superadmin can delete users.');
    }

    final target = await _db.collection('users').doc(userId).get();
    final currentRole = target.data()?['role']?.toString();
    if (currentRole == 'superadmin') {
      throw Exception('Superadmin account cannot be deleted from app.');
    }

    final authStatus = await _deleteAuthUser(userId);
    if (authStatus == 'function_missing') {
      throw Exception(
        'Cannot delete Firebase Auth user because deleteUserAuthAccount function is not deployed.',
      );
    }

    final userRef = _db.collection('users').doc(userId);
    final userQueries = await _db
        .collection('queries')
        .where('userId', isEqualTo: userId)
        .get();
    final assignedQueries = await _db
        .collection('queries')
        .where('assignedAdminId', isEqualTo: userId)
        .get();

    for (final q in userQueries.docs) {
      await deleteQuery(q.id);
    }

    final batch = _db.batch();
    for (final q in assignedQueries.docs) {
      batch.update(q.reference, {
        'assignedAdminId': null,
        'assignedAdminName': null,
        'needsManualAssignment': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.delete(userRef);
    await batch.commit();
    return DeleteUserResult(authStatus: authStatus);
  }

  Future<String> _deleteAuthUser(String userId) async {
    try {
      final callable = _functions.httpsCallable('deleteUserAuthAccount');
      final response = await callable.call(<String, dynamic>{'uid': userId});
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final authDeleted = data['authDeleted'];
        if (authDeleted == true) return 'deleted';
        if (authDeleted == false) return 'not_found';
      }
      return 'deleted';
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'unimplemented') {
        // Continue with Firestore cleanup even when auth function is unavailable.
        return 'function_missing';
      }
      throw Exception(e.message ?? 'Failed to delete user auth account.');
    }
  }

  Future<Map<String, int>> fetchStatusCounts() async {
    final unanswered = await _db
        .collection('queries')
        .where('status', isEqualTo: 'unanswered')
        .count()
        .get();
    final inProgress = await _db
        .collection('queries')
        .where('status', isEqualTo: 'in_progress')
        .count()
        .get();
    final answered = await _db
        .collection('queries')
        .where('status', isEqualTo: 'answered')
        .count()
        .get();

    return {
      'unanswered': unanswered.count ?? 0,
      'in_progress': inProgress.count ?? 0,
      'answered': answered.count ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> fetchAdminPerformance() async {
    final admins = await _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    final List<Map<String, dynamic>> out = [];

    for (final admin in admins.docs) {
      final unanswered = await _db
          .collection('queries')
          .where('assignedAdminId', isEqualTo: admin.id)
          .where('status', isEqualTo: 'unanswered')
          .count()
          .get();
      final inProgress = await _db
          .collection('queries')
          .where('assignedAdminId', isEqualTo: admin.id)
          .where('status', isEqualTo: 'in_progress')
          .count()
          .get();
      final answered = await _db
          .collection('queries')
          .where('assignedAdminId', isEqualTo: admin.id)
          .where('status', isEqualTo: 'answered')
          .count()
          .get();

      out.add({
        'id': admin.id,
        'name': admin.data()['name'] ?? admin.data()['email'] ?? 'Admin',
        'expertises': _extractExpertises(admin.data()),
        'expertise': _extractExpertises(admin.data()).join(', '),
        'unanswered': unanswered.count ?? 0,
        'in_progress': inProgress.count ?? 0,
        'answered': answered.count ?? 0,
      });
    }

    return out;
  }

  Future<int> getQueryLimit() async {
    try {
      final snap = await _db.collection('system').doc('config').get();
      return (snap.data()?['queryLimit'] as num?)?.toInt() ??
          _defaultQueryLimit;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return _defaultQueryLimit;
      rethrow;
    }
  }

  Future<void> updateQueryLimit(int limit) async {
    await _db.collection('system').doc('config').set({
      'queryLimit': limit,
    }, SetOptions(merge: true));
  }

  Future<int> getTotalQueryCount() async {
    try {
      final snap = await _db.collection('system').doc('queryCounter').get();
      return (snap.data()?['total'] as num?)?.toInt() ?? 0;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return 0;
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchMyNotifications() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchMyUnreadNotifications() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
  }

  Future<void> _notifyUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> metadata,
  }) async {
    await _db.collection('users').doc(userId).collection('notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'metadata': metadata,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _notifySuperAdminsForLimit() async {
    final total = await getTotalQueryCount();
    final limit = await getQueryLimit();
    if (total < limit) return;

    final superAdmins = await _db
        .collection('users')
        .where('role', isEqualTo: 'superadmin')
        .get();
    for (final admin in superAdmins.docs) {
      await _notifyUser(
        userId: admin.id,
        title: 'Query limit reached',
        body: 'Total queries reached $total / $limit',
        type: 'limit_reached',
        metadata: {'total': total, 'limit': limit},
      );
    }
  }
}

class DeleteUserResult {
  const DeleteUserResult({
    required this.authStatus,
  });

  final String authStatus;
}
