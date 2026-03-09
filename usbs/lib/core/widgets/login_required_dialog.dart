import 'package:flutter/material.dart';
import 'package:usbs/core/localization/app_language.dart';
import '../../config/routes/route_names.dart';

class LoginRequiredDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppI18n.tx(context, 'Login Required')),
        content: Text(
          AppI18n.tx(context, 'Please log in to access this feature.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppI18n.tx(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, RouteNames.login);
            },
            child: Text(AppI18n.tx(context, 'Login')),
          ),
        ],
      ),
    );
  }
}
