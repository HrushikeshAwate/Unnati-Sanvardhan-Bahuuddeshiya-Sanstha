import 'package:flutter/material.dart';

class NotAuthorizedScreen extends StatelessWidget {
  const NotAuthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: const Center(
        child: Text(
          'You are not authorized to access this page.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
