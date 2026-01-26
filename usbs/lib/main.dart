import 'package:flutter/material.dart';
import 'bootstrap/firebase_init.dart';
import 'bootstrap/dependency_injection.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseInit.init();
  await DependencyInjection.init();

  runApp(const App());
}
