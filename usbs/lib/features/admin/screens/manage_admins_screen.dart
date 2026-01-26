import 'package:flutter/material.dart';

class ManageAdminsScreen extends StatelessWidget {
  const ManageAdminsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Admins')),
      body: const Center(
        child: Text('Only Superadmin can access this'),
      ),
    );
  }
}
