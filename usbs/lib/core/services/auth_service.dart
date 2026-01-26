import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  Future<void> initSession() async {
    await _auth.setPersistence(Persistence.LOCAL);
  }

  /// EMAIL LOGIN
  Future<UserCredential> loginWithEmail(
      String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestoreService.syncUser(cred.user!);
    return cred;
  }

  /// GOOGLE LOGIN
  Future<UserCredential> loginWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
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
    final cred = await _auth.signInAnonymously();
    await _firestoreService.createGuestUser(cred.user!);
    return cred;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
