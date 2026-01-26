import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'config/routes/route_names.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ❌ REMOVED home:
      // home: const SplashScreen(),

      // ✅ USE initialRoute instead
      initialRoute: RouteNames.splash,
      routes: AppRoutes.routes,
    );
  }
}
