import 'package:flutter/material.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/auth_service.dart';

import '../../config/routes/route_names.dart';

class LogoutConfirmDialog {
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(AppI18n.tx(context, 'Logout')),
        content: Text(AppI18n.tx(context, 'Are you sure you want to logout?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppI18n.tx(context, 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await AuthService().logout();

              if (!context.mounted) return;

              Navigator.pop(context);

              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.login,
                (route) => false,
              );
            },
            child: Text(AppI18n.tx(context, 'Logout')),
          ),
        ],
      ),
    );
  }
}
