// import 'package:flutter/material.dart';
// import '../../../core/services/auth_service.dart';
// import '../../../bootstrap/role_router.dart';

// class GuestEntryScreen extends StatefulWidget {
//   const GuestEntryScreen({super.key});

//   @override
//   State<GuestEntryScreen> createState() => _GuestEntryScreenState();
// }

// class _GuestEntryScreenState extends State<GuestEntryScreen> {
//   bool _loading = false;

//   Future<void> _continueAsGuest() async {
//     setState(() => _loading = true);

//     try {
//       await AuthService().signInAsGuest();

//       if (!mounted) return;

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => const RoleRouter()),
//         (_) => false,
//       );
//     } catch (e) {
//       setState(() => _loading = false);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Guest login failed')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Continue as Guest')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: _loading ? null : _continueAsGuest,
//           child: _loading
//               ? const CircularProgressIndicator()
//               : const Text('Continue as Guest'),
//         ),
//       ),
//     );
//   }
// }
