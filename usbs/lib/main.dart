import 'package:flutter/material.dart';
import 'bootstrap/firebase_init.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInit.init();
  runApp(const App());
}



// stream: FirebaseFirestore.instance
//             .collection('queries')
//             .where('category', isEqualTo: 'legal')
//             .where('userId', isEqualTo: user.uid)
//             .snapshots(),