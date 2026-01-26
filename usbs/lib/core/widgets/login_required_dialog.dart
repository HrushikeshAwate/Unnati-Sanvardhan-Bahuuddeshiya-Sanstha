import 'package:flutter/material.dart';
import '../../config/routes/route_names.dart';

class LoginRequiredDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'Please log in to access this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, RouteNames.login);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
