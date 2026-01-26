import '../../../bootstrap/dependency_injection.dart';

class AuthController {
  static Future<void> loginWithEmail(
      String email, String password) async {
    await DependencyInjection.authService
        .loginWithEmail(email, password);
  }

  static Future<void> loginWithGoogle() async {
    await DependencyInjection.authService.loginWithGoogle();
  }

  static Future<void> loginAsGuest() async {
    await DependencyInjection.authService.loginAsGuest();
  }

  static Future<void> logout() async {
    await DependencyInjection.authService.logout();
  }
}
