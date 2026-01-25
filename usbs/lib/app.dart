import 'package:flutter/material.dart';
import 'config/routes/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'features/auth/controllers/auth_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController(
      AuthService(),
      FirestoreService(),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: buildAppRoutes(authController),
    );
  }
}
