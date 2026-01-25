import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class AuthController {
  final AuthService _auth;
  final FirestoreService _firestore;

  AuthController(this._auth, this._firestore);

  Stream<AppUser> userStream() async* {
    await for (final User? user in _auth.authStateChanges()) {
      if (user == null) {
        yield const AppUser(uid: 'unauth', role: UserRole.guest);
      } else {
        yield await _firestore.resolveUser(user);
      }
    }
  }
}
