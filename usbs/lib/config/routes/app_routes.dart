import 'package:flutter/material.dart';
import 'route_names.dart';

// Auth
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/guest_entry_screen.dart';

// Client
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

// Admin
import '../../features/admin/screens/admin_dashboard.dart';
import '../../features/admin/screens/superadmin_dashboard.dart';

// Services
import '../../features/legal/screens/legal_info_screen.dart';
import '../../features/medical/screens/medical_info_screen.dart';
import '../../features/education/screens/education_info_screen.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    RouteNames.splash: (_) => const SplashScreen(),
    RouteNames.login: (_) => const LoginScreen(),
    RouteNames.guest: (_) => const GuestEntryScreen(),

    RouteNames.home: (_) => const HomeScreen(),

    RouteNames.adminDashboard: (_) => const AdminDashboard(),
    RouteNames.superAdminDashboard: (_) => const SuperAdminDashboard(),

    RouteNames.legalInfo: (_) => const LegalInfoScreen(),
    RouteNames.medicalInfo: (_) => const MedicalInfoScreen(),
    RouteNames.educationInfo: (_) => const EducationInfoScreen(),

    RouteNames.profile: (_) => const ProfileScreen(),
  };
}
