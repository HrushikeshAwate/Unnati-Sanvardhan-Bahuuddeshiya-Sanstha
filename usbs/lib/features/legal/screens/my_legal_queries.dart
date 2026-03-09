import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/utils/date_utils.dart';
import 'package:usbs/core/widgets/status_chip.dart';
import 'package:usbs/features/legal/screens/legal_query_detail.dart';

class MyLegalQueriesScreen extends StatelessWidget {
  const MyLegalQueriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final t = (String s) => AppI18n.tx(context, s);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B4A45), Color(0xFF0D5F58)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  ),
          ),
        ),
        title: Text(t('My Legal Queries')),
        actions: const [LanguageMenuButton()],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('queries')
            .where('category', isEqualTo: 'legal')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(t('No legal queries submitted yet')));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  isThreeLine: true,
                  title: Text(t((data['caseType'] ?? 'General').toString())),
                  subtitle: Text(
                    '${t((data['description'] ?? '').toString())}\n'
                    '${t('Assigned')}: ${(data['assignedAdminName'] ?? t('Unassigned')).toString()}\n'
                    '${t('Submitted At')}: ${formatSubmittedAt(data)}\n'
                    '${t('Answered At')}: ${formatAnsweredAt(data)}',
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: StatusChip(
                    status: (data['status'] ?? 'unanswered').toString(),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LegalQueryDetailScreen(queryDoc: docs[index]),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
