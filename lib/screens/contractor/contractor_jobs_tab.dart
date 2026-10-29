import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'contractor_theme.dart';
import 'post_job_screen.dart';

class ContractorJobsTab extends StatefulWidget {
  const ContractorJobsTab({super.key});

  @override
  State<ContractorJobsTab> createState() => _ContractorJobsTabState();
}

class _ContractorJobsTabState extends State<ContractorJobsTab> {
  String selectedFilter = 'open';
  final Set<String> _closingExpiredJobs = <String>{};

  bool _isExpired(Map<String, dynamic> data) {
    final value = data['applicationDeadline'];
    if (value is! Timestamp) return false;
    return !DateTime.now().isBefore(value.toDate());
  }

  Future<void> _closeExpiredJob(String jobId, Map<String, dynamic> data) async {
    if (_closingExpiredJobs.contains(jobId)) return;
    _closingExpiredJobs.add(jobId);
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'closeReason': 'visibility_period_ended',
      });
    } on FirebaseException {
      // Keep the job visible as expired in this UI; the write can retry when
      // the jobs stream rebuilds. Server-side scheduling is recommended too.
    } finally {
      _closingExpiredJobs.remove(jobId);
    }
  }

  Future<void> _changeStatus(
    BuildContext context,
    String jobId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': status,
        if (status == 'closed') 'closedAt': FieldValue.serverTimestamp(),
        if (status == 'closed') 'closeReason': 'manually_closed',
        if (status == 'open') 'closedAt': FieldValue.delete(),
        if (status == 'open') 'closeReason': FieldValue.delete(),
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

  void _editJob(BuildContext context, String jobId, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostJobScreen(jobId: jobId, initialData: data),
      ),
    );
  }

  void _postJob(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PostJobScreen()));
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
            onPressed: () => _postJob(context),
            icon: const Icon(Icons.add_rounded, color: contractorGreen),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please sign in again.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7ECE8)),
                    ),
                    child: Row(
                      children: [
                        _buildFilterButton(label: 'Open Jobs', value: 'open'),
                        _buildFilterButton(
                          label: 'Closed Jobs',
                          value: 'closed',
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                              'Unable to load jobs. Check your Firestore '
                              'rules and connection.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allDocs = snapshot.data?.docs ?? [];

                      // Expired visibility windows are treated as closed and
                      // persisted to Firestore while this screen is active.
                      for (final doc in allDocs) {
                        final data = doc.data();
                        final status = (data['status'] ?? 'open').toString();
                        if (status == 'open' && _isExpired(data)) {
                          _closeExpiredJob(doc.id, data);
                        }
                      }

                      final docs = allDocs.where((doc) {
                        final data = doc.data();
                        final status = (data['status'] ?? 'open').toString();
                        final effectiveStatus =
                            status == 'open' && _isExpired(data)
                            ? 'closed'
                            : status;
                        return effectiveStatus == selectedFilter;
                      }).toList();

                      docs.sort((a, b) {
                        final aTime = a.data()['createdAt'];
                        final bTime = b.data()['createdAt'];

                        final aDate = aTime is Timestamp
                            ? aTime.toDate()
                            : DateTime(2000);
                        final bDate = bTime is Timestamp
                            ? bTime.toDate()
                            : DateTime(2000);

                        return bDate.compareTo(aDate);
                      });

                      if (docs.isEmpty) {
                        final isOpen = selectedFilter == 'open';

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOpen
                                      ? Icons.work_outline_rounded
                                      : Icons.inventory_2_outlined,
                                  size: 56,
                                  color: contractorGreen,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isOpen ? 'No open jobs' : 'No closed jobs',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isOpen
                                      ? 'Post a job to start receiving '
                                            'applications.'
                                      : 'Jobs you close will appear here.',
                                  textAlign: TextAlign.center,
                                ),
                                if (isOpen) ...[
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => _postJob(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Post a Job'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final title =
                              data['title']?.toString() ?? 'Untitled job';
                          final storedStatus = (data['status'] ?? 'open')
                              .toString();
                          final status =
                              storedStatus == 'open' && _isExpired(data)
                              ? 'closed'
                              : storedStatus;
                          final isOpen = status == 'open';
                          final wage = data['wageAmount'];

                          final wageText = wage is num
                              ? '₹${wage.round()} / '
                                    '${data['wageType'] ?? 'Daily'}'
                              : 'Wage not specified';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE7ECE8),
                              ),
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
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: contractorDarkGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOpen
                                            ? const Color(0xFFDDF1E5)
                                            : const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isOpen ? 'open' : 'closed',
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
                                const SizedBox(height: 12),
                                Text(
                                  '${data['category'] ?? 'General work'}'
                                  ' • '
                                  '${data['location'] ?? 'Location not specified'}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  wageText,
                                  style: const TextStyle(
                                    color: contractorGreen,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _editJob(context, doc.id, data),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
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
                                      label: Text(
                                        isOpen ? 'Close job' : 'Reopen job',
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
                ),
              ],
            ),
    );
  }

  Widget _buildFilterButton({required String label, required String value}) {
    final selected = selectedFilter == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => setState(() => selectedFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? contractorDarkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value == 'open'
                    ? Icons.check_circle_outline
                    : Icons.lock_outline,
                size: 17,
                color: selected ? Colors.white : contractorDarkGreen,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : contractorDarkGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
