import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';

class DependencyInjection {
  static late AuthService authService;
  static late FirestoreService firestoreService;

  static Future<void> init() async {
    authService = AuthService();
    firestoreService = FirestoreService();
  }
}
