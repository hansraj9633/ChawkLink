import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_theme.dart';

class WorkerMyJobsTab extends StatelessWidget {
  const WorkerMyJobsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: workerBackground,
      appBar: AppBar(
        title: const Text(
          'My Jobs',
          style: TextStyle(fontWeight: FontWeight.bold, color: workerDarkGreen),
        ),
        backgroundColor: workerBackground,
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text('Please sign in to view your applications.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('applicantId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Unable to load applications. Check your Firestore rules and connection.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final applications = snapshot.data?.docs ?? [];
                if (applications.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline_rounded,
                            size: 56,
                            color: workerGreen,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No applications yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: workerDarkGreen,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Apply for a job and it will appear here.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final application = applications[index].data();
                    final status =
                        application['status']?.toString() ?? 'pending';
                    final statusColor = status == 'accepted'
                        ? Colors.green
                        : status == 'rejected'
                        ? Colors.red
                        : Colors.orange;
                    final wage = application['wageAmount'];
                    final wageText = wage is num ? '₹${wage.round()}' : '';

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              application['jobTitle']?.toString() ??
                                  'Untitled job',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: workerDarkGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              application['location']?.toString() ??
                                  'Location not specified',
                            ),
                            if (wageText.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '$wageText / ${application['wageType'] ?? 'Daily'}',
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Status: '),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() +
                                        status.substring(1),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
