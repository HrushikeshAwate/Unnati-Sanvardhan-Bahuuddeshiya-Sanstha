// scaffold file
import 'package:flutter/material.dart';
import '../../home/screens/home_screen.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

class GuestEntryScreen extends StatelessWidget {
  const GuestEntryScreen({super.key});

  void _exitGuest(BuildContext context) async {
    await AuthController.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Access'),
        actions: [
          TextButton(
            onPressed: () => _exitGuest(context),
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Welcome Guest',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can explore our services, but login is required to submit queries.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            /// SERVICES VIEW ONLY
            ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Legal Services'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Medical Services'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Education Services'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
