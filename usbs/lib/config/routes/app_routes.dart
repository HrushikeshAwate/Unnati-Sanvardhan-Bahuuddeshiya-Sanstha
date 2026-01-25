import 'package:flutter/material.dart';
import '../../features/common/screens/splash_screen.dart';
import '../../features/auth/screens/auth_landing_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import 'route_names.dart';

Map<String, WidgetBuilder> buildAppRoutes(
  AuthController authController,
) {
  return {
    Routes.splash: (_) =>
        SplashScreen(authController: authController),

    Routes.authLanding: (_) => const AuthLandingScreen(),
    Routes.login: (_) => const LoginScreen(),

    Routes.guest: (_) => const Scaffold(
          body: Center(child: Text('Guest Home')),
        ),

    Routes.clientHome: (_) => const Scaffold(
          body: Center(child: Text('Client Home')),
        ),

    Routes.adminDashboard: (_) => const Scaffold(
          body: Center(child: Text('Admin Dashboard')),
        ),

    Routes.superadminDashboard: (_) => const Scaffold(
          body: Center(child: Text('Superadmin Dashboard')),
        ),
  };
}
