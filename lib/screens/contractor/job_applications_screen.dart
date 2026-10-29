import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'contractor_theme.dart';

class JobApplicantsScreen extends StatefulWidget {
  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.location,
    this.wage,
    required this.wageType,
  });

  final String jobId;
  final String jobTitle;
  final String location;
  final num? wage;
  final String wageType;

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  String _statusFilter = 'pending';
  final Set<String> _updating = {};

  Future<void> _updateStatus(String applicationId, String status) async {
    if (_updating.contains(applicationId)) return;

    setState(() => _updating.add(applicationId));

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({'status': status});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Application accepted.'
                : 'Application rejected.',
          ),
          backgroundColor: status == 'accepted'
              ? contractorGreen
              : Colors.red.shade700,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update application: ${e.message ?? e.code}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _updating.remove(applicationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    return Scaffold(
      backgroundColor: contractorBackground,
      appBar: AppBar(
        title: const Text(
          'Job Applicants',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: contractorDarkGreen,
          ),
        ),
        backgroundColor: contractorBackground,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.jobTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: contractorDarkGreen,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.location,
                  style: const TextStyle(color: Colors.black54),
                ),
                if (widget.wage != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '₹${widget.wage!.round()} / ${widget.wageType}',
                    style: const TextStyle(
                      color: contractorGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('contractorId', isEqualTo: user.uid)
                .where('jobId', isEqualTo: widget.jobId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Unable to load applicants. Check your Firestore rules or connection.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              final pendingCount = docs
                  .where((doc) => doc.data()['status'] == 'pending')
                  .length;
              final acceptedCount = docs
                  .where((doc) => doc.data()['status'] == 'accepted')
                  .length;
              final rejectedCount = docs
                  .where((doc) => doc.data()['status'] == 'rejected')
                  .length;

              final filtered = docs.where((doc) {
                return (doc.data()['status'] ?? 'pending') == _statusFilter;
              }).toList();

              return Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _statusTab('Pending', pendingCount, 'pending'),
                          _statusTab('Accepted', acceptedCount, 'accepted'),
                          _statusTab('Rejected', rejectedCount, 'rejected'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 54,
                                      color: contractorGreen,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No $_statusFilter applications',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: contractorDarkGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Applicants for this job will appear here.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final doc = filtered[index];
                                final data = doc.data();
                                final applicantId =
                                    data['applicantId']?.toString() ?? '';
                                final status = (data['status'] ?? 'pending')
                                    .toString();
                                final wage = data['wageAmount'];

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border.all(
                                      color: const Color(0xFFE7ECE8),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            backgroundColor: Color(0xFFDDF1E5),
                                            child: Icon(
                                              Icons.person_outline,
                                              color: contractorGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FutureBuilder<
                                                  DocumentSnapshot<
                                                    Map<String, dynamic>
                                                  >
                                                >(
                                                  future: applicantId.isEmpty
                                                      ? null
                                                      : FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(applicantId)
                                                            .get(),
                                                  builder: (context, worker) {
                                                    final workerData =
                                                        worker.data?.data() ??
                                                        {};
                                                    final name =
                                                        workerData['name']
                                                                ?.toString()
                                                                .trim()
                                                                .isNotEmpty ==
                                                            true
                                                        ? workerData['name']
                                                              .toString()
                                                        : 'Worker';
                                                    return Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color:
                                                            contractorDarkGreen,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Application status: ${status[0].toUpperCase()}${status.substring(1)}',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (wage is num) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          'Wage: ₹${wage.round()} / ${data['wageType'] ?? widget.wageType}',
                                          style: const TextStyle(
                                            color: contractorGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if (status == 'pending') ...[
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed:
                                                    _updating.contains(doc.id)
                                                    ? null
                                                    : () => _updateStatus(
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
                                                onPressed:
                                                    _updating.contains(doc.id)
                                                    ? null
                                                    : () => _updateStatus(
                                                        doc.id,
                                                        'accepted',
                                                      ),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      contractorGreen,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child:
                                                    _updating.contains(doc.id)
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : const Text('Accept'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statusTab(String label, int count, String value) {
    final selected = _statusFilter == value;
    final color = value == 'accepted'
        ? contractorGreen
        : value == 'rejected'
        ? Colors.red.shade700
        : Colors.orange.shade800;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () => setState(() => _statusFilter = value),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected ? color : const Color(0xFFE7ECE8),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
