import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contractor_theme.dart';

class JobApplicantsScreen extends StatefulWidget {
  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.location,
    this.wage,
    required this.wageType,
    this.postedAt,
    required this.requiredWorkers,
  });

  final String jobId;
  final String jobTitle;
  final String location;
  final num? wage;
  final String wageType;
  final DateTime? postedAt;
  final int requiredWorkers;

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
                : status == 'rejected'
                ? 'Application rejected.'
                : 'Application moved to pending.',
          ),
          backgroundColor: status == 'accepted'
              ? contractorGreen
              : status == 'rejected'
              ? Colors.red.shade700
              : Colors.orange.shade800,
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
      if (mounted) {
        setState(() => _updating.remove(applicationId));
      }
    }
  }

  Future<void> _callWorker(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the phone app.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app.')),
      );
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
          _buildJobHeader(user.uid),
          Expanded(child: _buildApplicants(user.uid)),
        ],
      ),
    );
  }

  Widget _buildJobHeader(String uid) {
    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
              const SizedBox(width: 12),
              if (widget.postedAt != null) _buildPostedDate(widget.postedAt!),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('contractorId', isEqualTo: uid)
                .where('jobId', isEqualTo: widget.jobId)
                .snapshots(),
            builder: (context, snapshot) {
              final applications = snapshot.data?.docs ?? [];

              final accepted = applications
                  .where((doc) => doc.data()['status'] == 'accepted')
                  .length;

              final required = widget.requiredWorkers;

              final progress = required > 0
                  ? (accepted / required).clamp(0.0, 1.0).toDouble()
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Hiring progress',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: contractorDarkGreen,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        required > 0
                            ? '$accepted/$required workers'
                            : '$accepted accepted',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE7ECE8),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      contractorGreen,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Posted on',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 3),
        Text(
          '$day/$month/${date.year}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$hour:$minute $period',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildApplicants(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('contractorId', isEqualTo: uid)
          .where('jobId', isEqualTo: widget.jobId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load applicants. '
                'Check your Firestore rules or connection.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

        return Column(
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
                  ? _buildEmptyApplicants()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildApplicantCard(filtered[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyApplicants() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 54, color: contractorGreen),
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
            const Text(
              'Applicants for this job will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final applicantId = data['applicantId']?.toString() ?? '';
    final status = (data['status'] ?? 'pending').toString();
    final wage = data['wageAmount'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDDF1E5),
                child: Icon(Icons.person_outline, color: contractorGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: applicantId.isEmpty
                    ? const Text(
                        'Worker details unavailable',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: contractorDarkGreen,
                        ),
                      )
                    : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(applicantId)
                            .get(),
                        builder: (context, workerSnapshot) {
                          final worker = workerSnapshot.data?.data() ?? {};

                          final name = _readValue(worker['name'], 'Worker');
                          final phone = _readValue(worker['phone'], '');
                          final email = _readValue(worker['email'], '');
                          final workArea = _readValue(
                            worker['preferredWorkArea'],
                            '',
                          );
                          final skills = _readValue(worker['skills'], '');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: contractorDarkGreen,
                                ),
                              ),
                              const SizedBox(height: 7),
                              _infoLine(
                                Icons.phone_outlined,
                                phone.isEmpty
                                    ? 'Phone: Not available'
                                    : 'Phone: $phone',
                              ),
                              if (phone.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => _callWorker(phone),
                                  icon: const Icon(Icons.call, size: 16),
                                  label: const Text('Call worker'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: contractorGreen,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              _infoLine(
                                Icons.email_outlined,
                                email.isEmpty
                                    ? 'Email: Not available'
                                    : 'Email: $email',
                              ),
                              _infoLine(
                                Icons.location_on_outlined,
                                workArea.isEmpty
                                    ? 'Preferred area: Not added'
                                    : 'Preferred area: $workArea',
                              ),
                              _infoLine(
                                Icons.construction_outlined,
                                skills.isEmpty
                                    ? 'Skills: Not added'
                                    : 'Skills: $skills',
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Application status: ${_capitalize(status)}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          _infoLine(
            Icons.access_time,
            'Applied: ${_formatAppliedAt(data['appliedAt'])}',
          ),
          if (wage is num) ...[
            const SizedBox(height: 10),
            Text(
              'Wage: ₹${wage.round()} / '
              '${data['wageType'] ?? widget.wageType}',
              style: const TextStyle(
                color: contractorGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (status == 'pending' ||
              status == 'accepted' ||
              status == 'rejected') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (status == 'pending' || status == 'accepted')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _updating.contains(doc.id)
                          ? null
                          : () => _updateStatus(doc.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),

                if (status == 'pending') const SizedBox(width: 10),

                if (status == 'pending' || status == 'rejected')
                  Expanded(
                    child: FilledButton(
                      onPressed: _updating.contains(doc.id)
                          ? null
                          : () => _updateStatus(doc.id, 'accepted'),
                      style: FilledButton.styleFrom(
                        backgroundColor: contractorGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: _updating.contains(doc.id)
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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
  }

  String _readValue(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAppliedAt(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return 'Time not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/${date.year} at '
        '$hour:$minute $period';
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
