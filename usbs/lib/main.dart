import 'package:flutter/material.dart';
import 'bootstrap/firebase_init.dart';
import 'bootstrap/dependency_injection.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024;
  await FirebaseInit.init();
  await DependencyInjection.init();
  await DependencyInjection.authService.initSession();
  runApp(const App());
}
