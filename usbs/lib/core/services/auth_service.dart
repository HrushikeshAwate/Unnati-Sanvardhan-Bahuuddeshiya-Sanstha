import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  Future<void> initSession() async {
    if (kIsWeb) {
      await _auth.setPersistence(Persistence.LOCAL);
    }
  }

  /// EMAIL LOGIN
  Future<UserCredential> loginWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestoreService.syncUser(cred.user!);
    return cred;
  }

  /// GOOGLE LOGIN
  Future<UserCredential> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final result = await _auth.signInWithCredential(credential);
    await _firestoreService.syncUser(result.user!);

    return result;
  }

  /// GUEST LOGIN
  Future<UserCredential> loginAsGuest() async {
    try {
      final app = Firebase.app();
      debugPrint(
        '[GuestLogin] Firebase app="${app.name}", projectId="${app.options.projectId}"',
      );
      final cred = await _auth.signInAnonymously();
      debugPrint('[GuestLogin] Anonymous sign-in success uid=${cred.user?.uid}');
      await _firestoreService.createGuestUser(cred.user!);
      return cred;
    } on FirebaseAuthException catch (e) {
      final app = Firebase.app();
      debugPrint(
        '[GuestLogin] FAILED projectId="${app.options.projectId}" code="${e.code}" message="${e.message}"',
      );
      if (e.code == 'admin-restricted-operation' ||
          e.code == 'operation-not-allowed') {
        throw Exception(
          'Guest access is disabled in Firebase project "${app.options.projectId}". '
          'Enable Anonymous sign-in in Firebase Console > Authentication > Sign-in method.',
        );
      }
      throw Exception(e.message ?? 'Guest login failed.');
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateMyPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await user.updatePassword(newPassword);
  }
}
