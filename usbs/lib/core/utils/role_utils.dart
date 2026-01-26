import 'package:firebase_auth/firebase_auth.dart';

class RoleUtils {
  static bool isGuest() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }
}
