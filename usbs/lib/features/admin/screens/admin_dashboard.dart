// import 'package:flutter/material.dart';
// import 'package:usbs/features/auth/controllers/auth_controller.dart';
// import '../../auth/screens/login_screen.dart';

// class AdminDashboard extends StatelessWidget {
//   const AdminDashboard({super.key});

//   void _logout(BuildContext context) async {
//     await AuthController.logout();
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (_) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () => _logout(context),
//           )
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Client Queries',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),

//             /// Placeholder – you’ll connect Firestore query list here
//             Expanded(
//               child: ListView.builder(
//                 itemCount: 0,
//                 itemBuilder: (_, __) {
//                   return const ListTile(
//                     title: Text('Query Title'),
//                     subtitle: Text('Query status'),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
