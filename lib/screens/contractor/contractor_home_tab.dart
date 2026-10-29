import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'contractor_theme.dart';
import 'post_job_screen.dart';

class ContractorHomeTab extends StatelessWidget {
  const ContractorHomeTab({super.key, required this.onOpenJobs});
  final VoidCallback onOpenJobs;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please sign in again.'));
    final jobsStream = FirebaseFirestore.instance
        .collection('jobs')
        .where('contractorId', isEqualTo: user.uid)
        .snapshots();
    final applicationsStream = FirebaseFirestore.instance
        .collection('applications')
        .where('contractorId', isEqualTo: user.uid)
        .snapshots();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF1E5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.engineering_rounded,
                color: contractorGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Majdoor Setu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: contractorDarkGreen,
                    ),
                  ),
                  Text(
                    'Contractor workspace',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {
            final name = snapshot.data?.data()?['name']?.toString().trim();
            final greeting = (name == null || name.isEmpty)
                ? 'Welcome back!'
                : 'Namaste, $name 👋';
            return Text(
              greeting,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: contractorDarkGreen,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage your jobs and find the right workers.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PostJobScreen())),
            style: FilledButton.styleFrom(
              backgroundColor: contractorGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Post a Job',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 22),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: jobsStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final openCount = docs
                .where((d) => (d.data()['status'] ?? '').toString() == 'open')
                .length;
            return Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total jobs',
                    value: snapshot.hasError ? '—' : '${docs.length}',
                    icon: Icons.work_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Open jobs',
                    value: snapshot.hasError ? '—' : '$openCount',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: applicationsStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final pending = docs
                .where(
                  (d) =>
                      (d.data()['status'] ?? 'pending').toString() == 'pending',
                )
                .length;
            return _SummaryCard(
              title: 'Applications received',
              value: snapshot.hasError ? '—' : '${docs.length}',
              subtitle: '$pending pending review',
              icon: Icons.groups_2_outlined,
              wide: true,
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recently posted jobs',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: contractorDarkGreen,
                ),
              ),
            ),
            TextButton(onPressed: onOpenJobs, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 6),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: jobsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Unable to load jobs. Check your connection and Firestore rules.',
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = [...?snapshot.data?.docs];
            docs.sort((a, b) {
              final at = a.data()['createdAt'];
              final bt = b.data()['createdAt'];
              if (at is Timestamp && bt is Timestamp) return bt.compareTo(at);
              return 0;
            });
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.post_add_rounded,
                      size: 38,
                      color: contractorGreen,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No jobs posted yet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create your first job to start receiving applications.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: docs.take(3).map((doc) {
                final data = doc.data();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE7ECE8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF1E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: contractorGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title']?.toString() ?? 'Untitled job',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: contractorDarkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['location']?.toString() ??
                                  'Location not specified',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        (data['status'] ?? 'open').toString(),
                        style: TextStyle(
                          color: (data['status'] ?? 'open') == 'open'
                              ? contractorGreen
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.wide = false,
  });
  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final bool wide;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7ECE8)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: contractorGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: contractorDarkGreen,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
