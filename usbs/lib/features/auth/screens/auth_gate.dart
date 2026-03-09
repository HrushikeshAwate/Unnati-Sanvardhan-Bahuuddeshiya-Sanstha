import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/core/services/firestore_service.dart';
import 'package:usbs/features/auth/screens/login_screen.dart';
import 'package:usbs/features/home/screens/home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void> _ensureUserDoc(User user) async {
    final service = FirestoreService();
    if (user.isAnonymous) {
      await service.createGuestUser(user);
      return;
    }
    await service.syncUser(user);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<void>(
          future: _ensureUserDoc(user),
          builder: (context, ensureSnap) {
            if (ensureSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, roleSnap) {
                if (roleSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (roleSnap.hasError) {
                  final error = roleSnap.error;
                  if (error is FirebaseException &&
                      error.code == 'permission-denied') {
                    return const HomeScreen();
                  }
                }

                final role =
                    roleSnap.data?.data()?['role']?.toString() ?? 'client';

                if (role == 'superadmin') return const HomeScreen();
                if (role == 'admin') return const HomeScreen();
                return const HomeScreen();
              },
            );
          },
        );
      },
    );
  }
}
