import 'package:flutter/material.dart';
import 'package:usbs/features/auth/controllers/auth_controller.dart';
import '../../auth/screens/login_screen.dart';
import 'manage_admins_screen.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  void _logout(BuildContext context) async {
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
        title: const Text('Superadmin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// QUERY MANAGEMENT
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text('Manage Client Queries'),
              onTap: () {
                // Navigate to query list
              },
            ),

            const Divider(),

            /// ADMIN MANAGEMENT
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Manage Admin Users'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageAdminsScreen(),
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
