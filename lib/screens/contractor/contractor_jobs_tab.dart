import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'contractor_theme.dart';
import 'post_job_screen.dart';

class ContractorJobsTab extends StatelessWidget {
  const ContractorJobsTab({super.key});

  Future<void> _changeStatus(
    BuildContext context,
    String jobId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': status,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'open' ? 'Job reopened.' : 'Job closed.'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update job: ${e.message ?? e.code}')),
      );
    }
  }

  Future<void> _deleteJob(
    BuildContext context,
    String jobId,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text(
          'Delete "$title"? This removes the job listing. Existing application records will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job deleted.')));
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete job: ${e.message ?? e.code}')),
      );
    }
  }

  void _editJob(BuildContext context, String jobId, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostJobScreen(jobId: jobId, initialData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: contractorBackground,
      appBar: AppBar(
        title: const Text(
          'Post Jobs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: contractorDarkGreen,
          ),
        ),
        backgroundColor: contractorBackground,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Post a job',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PostJobScreen()),
            ),
            icon: const Icon(Icons.add_rounded, color: contractorGreen),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please sign in again.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('contractorId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Unable to load jobs. Check your Firestore rules and connection.',
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.work_outline,
                            size: 56,
                            color: contractorGreen,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No jobs posted yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Post your first job to start receiving applications.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PostJobScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Post a Job'),
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
                    final title = data['title']?.toString() ?? 'Untitled job';
                    final status = (data['status'] ?? 'open').toString();
                    final isOpen = status == 'open';
                    final wage = data['wageAmount'];
                    final wageText = wage is num
                        ? '₹${wage.round()} / ${data['wageType'] ?? 'Daily'}'
                        : 'Wage not specified';

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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: contractorDarkGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? const Color(0xFFDDF1E5)
                                      : const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: isOpen
                                        ? contractorGreen
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data['category'] ?? 'General work'} • ${data['location'] ?? 'Location not specified'}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            wageText,
                            style: const TextStyle(
                              color: contractorGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _editJob(context, doc.id, data),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _changeStatus(
                                  context,
                                  doc.id,
                                  isOpen ? 'closed' : 'open',
                                ),
                                icon: Icon(
                                  isOpen
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                  size: 18,
                                ),
                                label: Text(isOpen ? 'Close job' : 'Reopen'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _deleteJob(context, doc.id, title),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
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
