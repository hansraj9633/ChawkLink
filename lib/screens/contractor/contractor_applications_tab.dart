import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'contractor_theme.dart';

class ContractorApplicationsTab extends StatelessWidget {
  const ContractorApplicationsTab({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    String applicationId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({'status': status});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Application accepted.'
                  : 'Application rejected.',
            ),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not update application: ${e.message ?? e.code}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: contractorBackground,
      appBar: AppBar(
        title: const Text(
          'Applications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: contractorDarkGreen,
          ),
        ),
        backgroundColor: contractorBackground,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please sign in again.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('contractorId', isEqualTo: user.uid)
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
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 56,
                            color: contractorGreen,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No applications yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Applications for your jobs will appear here.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final status = (data['status'] ?? 'pending').toString();
                    final pending = status == 'pending';
                    final wage = data['wageAmount'];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7ECE8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['jobTitle']?.toString() ?? 'Untitled job',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: contractorDarkGreen,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            data['location']?.toString() ??
                                'Location not specified',
                          ),
                          if (wage is num) ...[
                            const SizedBox(height: 5),
                            Text(
                              '₹${wage.round()} / ${data['wageType'] ?? 'Daily'}',
                              style: const TextStyle(
                                color: contractorGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Status: '),
                              Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == 'accepted'
                                      ? contractorGreen
                                      : status == 'rejected'
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          if (pending) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateStatus(
                                      context,
                                      doc.id,
                                      'rejected',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _updateStatus(
                                      context,
                                      doc.id,
                                      'accepted',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: contractorGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
