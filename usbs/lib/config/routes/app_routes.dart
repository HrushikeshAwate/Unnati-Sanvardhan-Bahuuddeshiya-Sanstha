import 'package:flutter/material.dart';
import 'package:usbs/features/legal/screens/my_legal_queries.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/medical/screens/medical_info_screen.dart';
import '../../features/legal/screens/legal_info_screen.dart';
import '../../features/education/screens/education_info_screen.dart';
import '../../features/gallery/screens/photo_gallery_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    // AUTH
    RouteNames.login: (_) => const LoginScreen(),

    // HOME
    RouteNames.home: (_) => const HomeScreen(),

    // SERVICES
    RouteNames.medicalInfo: (_) => const MedicalInfoScreen(),
    RouteNames.legalInfo: (_) => const LegalInfoScreen(),
    RouteNames.educationInfo: (_) => const EducationInfoScreen(),

    // QUERIES
    RouteNames.myLegalQueries: (_) => const MyLegalQueriesScreen(),

    // OTHER
    RouteNames.photoGallery: (_) => const PhotoGalleryScreen(),
    RouteNames.profile: (_) => const ProfileScreen(),
  };
}
