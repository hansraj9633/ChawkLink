import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_theme.dart';

class WorkerMyJobsTab extends StatefulWidget {
  const WorkerMyJobsTab({super.key});

  @override
  State<WorkerMyJobsTab> createState() => _WorkerMyJobsTabState();
}

class _WorkerMyJobsTabState extends State<WorkerMyJobsTab> {
  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Pending',
    'Accepted',
    'Declined',
  ];

  bool _matchesFilter(Map<String, dynamic> application) {
    final status = (application['status'] ?? 'pending')
        .toString()
        .trim()
        .toLowerCase();

    switch (_selectedFilter) {
      case 'Pending':
        return status == 'pending';
      case 'Accepted':
        return status == 'accepted';
      case 'Declined':
        return status == 'declined' || status == 'rejected';
      case 'All':
      default:
        return true;
    }
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFDDF1E5),
              side: BorderSide(
                color: selected ? workerGreen : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                color: selected ? workerDarkGreen : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
                        'Unable to load applications. '
                        'Check your Firestore rules and connection.',
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

                final filteredApplications = applications
                    .where((doc) => _matchesFilter(doc.data()))
                    .toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: _buildStatusFilters(),
                    ),
                    Expanded(
                      child: filteredApplications.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.filter_list_off_rounded,
                                      size: 48,
                                      color: workerGreen,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No ${_selectedFilter.toLowerCase()} applications',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: workerDarkGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredApplications.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final application = filteredApplications[index]
                                    .data();

                                final status =
                                    (application['status'] ?? 'pending')
                                        .toString();

                                final statusColor = status == 'accepted'
                                    ? Colors.green
                                    : status == 'rejected'
                                    ? Colors.red
                                    : Colors.orange;

                                final wage = application['wageAmount'];
                                final wageText = wage is num
                                    ? '₹${wage.round()}'
                                    : '';

                                final history = application['statusHistory'];

                                final historyItems = history is List
                                    ? history
                                          .whereType<Map>()
                                          .map(
                                            (item) =>
                                                Map<String, dynamic>.from(item),
                                          )
                                          .toList()
                                    : <Map<String, dynamic>>[];

                                // Show newest status changes first.
                                historyItems.sort((a, b) {
                                  final dateA = _readDate(a['changedAt']);
                                  final dateB = _readDate(b['changedAt']);

                                  if (dateA == null && dateB == null) return 0;
                                  if (dateA == null) return 1;
                                  if (dateB == null) return -1;

                                  return dateB.compareTo(dateA);
                                });

                                return Card(
                                  color: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        _infoRow(
                                          Icons.location_on_outlined,
                                          application['location']?.toString() ??
                                              'Location not specified',
                                        ),
                                        if (wageText.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          _infoRow(
                                            Icons.currency_rupee,
                                            '$wageText / '
                                            '${application['wageType'] ?? 'Daily'}',
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Text('Current status: '),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _capitalize(status),
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _infoRow(
                                          Icons.access_time,
                                          'Applied: ${_formatDate(application['appliedAt'])}',
                                        ),
                                        const SizedBox(height: 8),
                                        const Divider(),
                                        ExpansionTile(
                                          tilePadding: EdgeInsets.zero,
                                          childrenPadding:
                                              const EdgeInsets.only(bottom: 8),
                                          leading: const Icon(
                                            Icons.history,
                                            color: workerGreen,
                                          ),
                                          title: const Text(
                                            'Status History',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: workerDarkGreen,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${historyItems.length} status change'
                                            '${historyItems.length == 1 ? '' : 's'}',
                                          ),
                                          children: [
                                            if (historyItems.isEmpty)
                                              const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: Text(
                                                  'No status change history recorded yet.',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              )
                                            else
                                              ...historyItems.map((item) {
                                                final eventStatus =
                                                    (item['status'] ??
                                                            'unknown')
                                                        .toString();

                                                final eventColor =
                                                    eventStatus == 'accepted'
                                                    ? Colors.green
                                                    : eventStatus == 'rejected'
                                                    ? Colors.red
                                                    : Colors.orange;

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Icon(
                                                        eventStatus ==
                                                                'accepted'
                                                            ? Icons.check_circle
                                                            : eventStatus ==
                                                                  'rejected'
                                                            ? Icons.cancel
                                                            : Icons
                                                                  .pending_actions,
                                                        color: eventColor,
                                                        size: 21,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Status: '
                                                              '${_capitalize(eventStatus)}',
                                                              style: TextStyle(
                                                                color:
                                                                    eventColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              _formatDate(
                                                                item['changedAt'],
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .black54,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  static Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: Colors.black54),
        const SizedBox(width: 7),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _formatDate(dynamic value) {
    final date = _readDate(value);
    if (date == null) return 'Time not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/${date.year} at $hour:$minute $period';
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
