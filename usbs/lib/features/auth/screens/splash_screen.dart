import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../bootstrap/role_router.dart';
import '../../../core/services/firestore_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<String>(
      future: FirestoreService().fetchUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const LoginScreen();
        }

        return RoleRouter.resolve(snapshot.data!);
      },
    );
  }
}
