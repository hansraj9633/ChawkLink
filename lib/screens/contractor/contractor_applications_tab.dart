import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contractor_theme.dart';
import 'job_applications_screen.dart';

class ContractorApplicationsTab extends StatefulWidget {
  const ContractorApplicationsTab({super.key});

  @override
  State<ContractorApplicationsTab> createState() =>
      _ContractorApplicationsTabState();
}

class _ContractorApplicationsTabState extends State<ContractorApplicationsTab> {
  int _selectedView = 0;
  String _jobStatusFilter = 'open';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    return Scaffold(
      backgroundColor: contractorBackground,
      appBar: AppBar(
        title: Text(
          _selectedView == 0 ? 'Applications' : 'My Workers',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: contractorDarkGreen,
          ),
        ),
        backgroundColor: contractorBackground,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                children: [
                  _viewButton(
                    label: 'Applications',
                    icon: Icons.assignment_outlined,
                    selected: _selectedView == 0,
                    onTap: () => setState(() => _selectedView = 0),
                  ),
                  _viewButton(
                    label: 'My Workers',
                    icon: Icons.groups_outlined,
                    selected: _selectedView == 1,
                    onTap: () => setState(() => _selectedView = 1),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedView == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: Row(
                  children: [
                    _jobFilterButton(
                      label: 'Job Open',
                      icon: Icons.check_circle_outline,
                      value: 'open',
                    ),
                    _jobFilterButton(
                      label: 'Job Closed',
                      icon: Icons.lock_outline,
                      value: 'closed',
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _selectedView == 0
                ? _buildJobs(user.uid)
                : _buildMyWorkers(user.uid),
          ),
        ],
      ),
    );
  }

  Widget _viewButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? contractorDarkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
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

  Widget _jobFilterButton({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final selected = _jobStatusFilter == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => setState(() => _jobStatusFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDDF1E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: contractorDarkGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: contractorDarkGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobs(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('contractorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, jobsSnapshot) {
        if (jobsSnapshot.hasError) {
          return _emptyState(
            Icons.error_outline,
            'Unable to load your jobs',
            'Check your internet connection and Firestore rules.',
          );
        }

        if (jobsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allJobs = jobsSnapshot.data?.docs ?? [];

        if (allJobs.isEmpty) {
          return _emptyState(
            Icons.work_outline,
            'No jobs posted yet',
            'Post a job first. Applications for your jobs will appear here.',
          );
        }

        final jobs = allJobs.where((job) {
          final status = (job.data()['status'] ?? 'open').toString();
          return status == _jobStatusFilter;
        }).toList();

        if (jobs.isEmpty) {
          return _emptyState(
            _jobStatusFilter == 'open'
                ? Icons.work_outline
                : Icons.lock_outline,
            _jobStatusFilter == 'open' ? 'No open jobs' : 'No closed jobs',
            _jobStatusFilter == 'open'
                ? 'Your open jobs will appear here.'
                : 'Your closed jobs will appear here.',
          );
        }

        jobs.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          final aDate = aTime is Timestamp ? aTime.toDate() : DateTime(2000);
          final bDate = bTime is Timestamp ? bTime.toDate() : DateTime(2000);

          return bDate.compareTo(aDate);
        });

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('applications')
              .where('contractorId', isEqualTo: uid)
              .snapshots(),
          builder: (context, applicationsSnapshot) {
            if (applicationsSnapshot.hasError) {
              return _emptyState(
                Icons.error_outline,
                'Unable to load applications',
                'Please check your Firestore rules and connection.',
              );
            }

            if (applicationsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final applications = applicationsSnapshot.data?.docs ?? [];

            final Map<String, Map<String, int>> counts = {};

            for (final application in applications) {
              final data = application.data();
              final jobId = data['jobId']?.toString();

              if (jobId == null || jobId.isEmpty) continue;

              final status = (data['status'] ?? 'pending').toString();

              counts.putIfAbsent(
                jobId,
                () => {'pending': 0, 'accepted': 0, 'rejected': 0},
              );

              if (counts[jobId]!.containsKey(status)) {
                counts[jobId]![status] = counts[jobId]![status]! + 1;
              }
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = jobs[index];
                final data = job.data();
                final jobCounts =
                    counts[job.id] ??
                    {'pending': 0, 'accepted': 0, 'rejected': 0};

                final wage = data['wageAmount'];
                final status = (data['status'] ?? 'open').toString();

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobApplicantsScreen(
                            jobId: job.id,
                            jobTitle:
                                data['title']?.toString() ?? 'Untitled job',
                            location:
                                data['location']?.toString() ??
                                'Location not specified',
                            wage: wage is num ? wage : null,
                            wageType: data['wageType']?.toString() ?? 'Daily',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE7ECE8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDF1E5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.work_outline_rounded,
                                  color: contractorGreen,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title']?.toString() ??
                                          'Untitled job',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: contractorDarkGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      data['location']?.toString() ??
                                          'Location not specified',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
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
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _countChip(
                                'Pending',
                                jobCounts['pending']!,
                                Colors.orange.shade800,
                              ),
                              const SizedBox(width: 6),
                              _countChip(
                                'Accepted',
                                jobCounts['accepted']!,
                                contractorGreen,
                              ),
                              const SizedBox(width: 6),
                              _countChip(
                                'Rejected',
                                jobCounts['rejected']!,
                                Colors.red.shade700,
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              Icon(
                                status == 'open'
                                    ? Icons.check_circle_outline
                                    : Icons.lock_outline,
                                size: 16,
                                color: status == 'open'
                                    ? contractorGreen
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                status == 'open' ? 'Job open' : 'Job closed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: status == 'open'
                                      ? contractorGreen
                                      : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),

                              Builder(
                                builder: (context) {
                                  final createdAt = data['createdAt'];
                                  String postedDate = 'Date unavailable';
                                  String postedTime = '';

                                  if (createdAt is Timestamp) {
                                    final date = createdAt.toDate();
                                    final hour = date.hour % 12 == 0
                                        ? 12
                                        : date.hour % 12;
                                    final minute = date.minute
                                        .toString()
                                        .padLeft(2, '0');
                                    final period = date.hour >= 12
                                        ? 'PM'
                                        : 'AM';

                                    postedDate =
                                        '${date.day.toString().padLeft(2, '0')}/'
                                        '${date.month.toString().padLeft(2, '0')}/'
                                        '${date.year}';

                                    postedTime = '$hour:$minute $period';
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 13,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            postedDate,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (postedTime.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 13,
                                              color: Colors.black54,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              postedTime,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '$count $label',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildMyWorkers(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('contractorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            Icons.error_outline,
            'Unable to load workers',
            'Please check your connection and Firestore rules.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final accepted = docs.where((doc) {
          final data = doc.data();
          return data['status'] == 'accepted' &&
              (data['applicantId']?.toString().isNotEmpty ?? false);
        }).toList();

        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        grouped = {};

        for (final doc in accepted) {
          final applicantId = doc.data()['applicantId'].toString();
          grouped.putIfAbsent(applicantId, () => []).add(doc);
        }

        if (grouped.isEmpty) {
          return _emptyState(
            Icons.groups_outlined,
            'No workers yet',
            'Workers whose applications you accept will appear here.',
          );
        }

        final workerIds = grouped.keys.toList();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: workerIds.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final workerId = workerIds[index];
            final workerJobs = grouped[workerId]!;

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(workerId)
                  .get(),
              builder: (context, workerSnapshot) {
                final worker = workerSnapshot.data?.data() ?? {};
                final name =
                    worker['name']?.toString().trim().isNotEmpty == true
                    ? worker['name'].toString()
                    : 'Worker';

                final phone =
                    worker['phone']?.toString().trim().isNotEmpty == true
                    ? worker['phone'].toString().trim()
                    : worker['phoneNumber']?.toString().trim() ?? '';

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
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFDDF1E5),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'W',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: contractorDarkGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
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
                                Text(
                                  phone.isEmpty ? 'Phone not available' : phone,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Accepted for ${workerJobs.length} job(s)',
                                  style: const TextStyle(
                                    color: contractorGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (phone.isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                try {
                                  await launchUrl(
                                    Uri(scheme: 'tel', path: phone),
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to open the phone app.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.call_rounded,
                                color: contractorGreen,
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 25),
                      ...workerJobs.map((application) {
                        final data = application.data();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.work_outline,
                                size: 18,
                                color: contractorGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['jobTitle']?.toString() ??
                                      'Untitled job',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: contractorGreen),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: contractorDarkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
