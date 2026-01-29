import 'package:flutter/material.dart';
import 'bootstrap/firebase_init.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInit.init();
  runApp(const App());
}

