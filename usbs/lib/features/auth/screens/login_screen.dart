import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../home/screens/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              Image.asset(
                'assets/logo.png',
                height: 80,
              ),

              const SizedBox(height: 40),

              /// 🔐 LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().loginWithGoogle();
                    _goToHome(context);
                  },
                  child: const Text('Login with Google'),
                ),
              ),

              const SizedBox(height: 16),

              /// 👤 CONTINUE AS GUEST
              TextButton(
                onPressed: () {
                  // ❗ NO AUTH, NO FIREBASE
                  _goToHome(context);
                },
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
