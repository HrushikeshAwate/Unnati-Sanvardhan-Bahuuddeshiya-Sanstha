import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../config/routes/route_names.dart';
import '../../auth/controllers/auth_controller.dart';

class SplashScreen extends StatelessWidget {
  final AuthController authController;

  const SplashScreen({
    super.key,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser>(
      stream: authController.userStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data!;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user.uid == 'unauth') {
            Navigator.pushReplacementNamed(
                context, Routes.authLanding);
            return;
          }

          switch (user.role) {
            case UserRole.superadmin:
              Navigator.pushReplacementNamed(
                  context, Routes.superadminDashboard);
              break;
            case UserRole.admin:
              Navigator.pushReplacementNamed(
                  context, Routes.adminDashboard);
              break;
            case UserRole.client:
              Navigator.pushReplacementNamed(
                  context, Routes.clientHome);
              break;
            case UserRole.guest:
              Navigator.pushReplacementNamed(
                  context, Routes.guest);
              break;
          }
        });

        return const SizedBox.shrink();
      },
    );
  }
}
