import 'package:firebase_auth/firebase_auth.dart';

class AuthUtils {
  static bool isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  static bool isGuest() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.isAnonymous;
  }
}
