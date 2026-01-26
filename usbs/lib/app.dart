import 'package:flutter/material.dart';

// ✅ THIS import is REQUIRED
import 'config/routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // start app from login
      initialRoute: '/login',

      // use centralized routes
      routes: AppRoutes.routes,
    );
  }
}
