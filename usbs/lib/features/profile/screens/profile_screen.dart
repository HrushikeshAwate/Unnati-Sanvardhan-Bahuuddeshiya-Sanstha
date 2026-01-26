import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final formatter = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? const Icon(Icons.person, size: 64)
                  : null,
            ),

            const SizedBox(height: 20),

            Text(
              user.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              user.email ?? 'Guest User',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            _tile('Account Type', user.isAnonymous ? 'Guest' : 'Registered'),
            _tile('Login Method', _provider(user)),
            _tile('Email Verified', user.emailVerified ? 'Yes' : 'No'),
            _tile(
              'Created On',
              formatter.format(user.metadata.creationTime!),
            ),
            _tile(
              'Last Login',
              formatter.format(user.metadata.lastSignInTime!),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // ✅ NOTHING ELSE
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Divider(),
        ],
      ),
    );
  }

  String _provider(User user) {
    if (user.isAnonymous) return 'Guest';
    for (final p in user.providerData) {
      if (p.providerId == 'google.com') return 'Google';
      if (p.providerId == 'password') return 'Email & Password';
    }
    return 'Unknown';
  }
}
