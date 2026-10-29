import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'worker_theme.dart';
import 'dart:async';

class FindWorkTab extends StatefulWidget {
  const FindWorkTab({super.key});

  @override
  State<FindWorkTab> createState() => _FindWorkTabState();
}

class _FindWorkTabState extends State<FindWorkTab> {
  Timer? _visibilityRefreshTimer;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _applicationsStream;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _jobsStream;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    _applicationsStream = FirebaseFirestore.instance
        .collection('applications')
        .where('applicantId', isEqualTo: uid)
        .snapshots();

    _jobsStream = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'open')
        .snapshots();

    _visibilityRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _visibilityRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _locationFilter = '';
  String _jobTypeFilter = 'Any';
  double _minWage = 0;
  double _maxWage = 3000;

  String _text(dynamic value, [String fallback = '']) =>
      value?.toString() ?? fallback;

  double _wage(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<DateTime> _workDates(dynamic value) {
    if (value is! List) return [];
    final dates = <DateTime>[];
    for (final item in value) {
      DateTime? date;
      if (item is Timestamp) {
        date = item.toDate();
      } else if (item is DateTime) {
        date = item;
      } else if (item is String) {
        date = DateTime.tryParse(item);
      }
      if (date != null) dates.add(DateUtils.dateOnly(date));
    }
    dates.sort();
    return dates;
  }

  String _formatWorkDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _genderLabel(dynamic value) {
    if (value is List) {
      final genders = value
          .map((item) => item.toString())
          .where((item) => ['Male', 'Female'].contains(item))
          .toSet();
      if (genders.length == 2) return 'Male + Female';
      if (genders.length == 1) return genders.first;
    } else if (value is String && value.isNotEmpty) {
      if (value == 'Both') return 'Male + Female';
      if (['Male', 'Female'].contains(value)) return value;
    }
    return 'All genders';
  }

  Future<void> _callContractor(String phone) async {
    final number = phone.trim();
    if (number.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: number);
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the phone app.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start a phone call.')),
        );
      }
    }
  }

  DateTime? _readJobDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _isVisibleNow(Map<String, dynamic> job, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final startAt = _readJobDateTime(job['startAt']);
    final deadline = _readJobDateTime(job['applicationDeadline']);

    // Hide jobs that don't have a valid visibility window. New posts must
    // contain both timestamps; contractors can edit older posts to add them.
    if (startAt == null || deadline == null) return false;
    return !currentTime.isBefore(startAt) && currentTime.isBefore(deadline);
  }

  bool _matchesJob(Map<String, dynamic> job) {
    if (!_isVisibleNow(job)) return false;

    final title = _text(job['title'], 'Untitled job');
    final category = _text(job['category'], 'General work');
    final description = _text(job['description']);
    final location = _text(job['location']);
    final jobType = _text(job['jobType'], 'Daily wage');
    final searchable = '$title $category $description $location'.toLowerCase();

    if (_searchQuery.trim().isNotEmpty &&
        !searchable.contains(_searchQuery.trim().toLowerCase())) {
      return false;
    }
    if (_locationFilter.trim().isNotEmpty &&
        !location.toLowerCase().contains(
          _locationFilter.trim().toLowerCase(),
        )) {
      return false;
    }
    if (_jobTypeFilter != 'Any' &&
        jobType.toLowerCase() != _jobTypeFilter.toLowerCase()) {
      return false;
    }
    final wage = _wage(job['wageAmount']);
    if (wage < _minWage || wage > _maxWage) return false;
    return true;
  }

  Future<void> _showFilters() async {
    var location = _locationFilter;
    var jobType = _jobTypeFilter;
    var minWage = _minWage;
    var maxWage = _maxWage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter jobs',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: location,
                    decoration: InputDecoration(
                      hintText: 'Enter city or area',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => location = value,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Job type',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: jobType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Any',
                        child: Text('Any job type'),
                      ),
                      DropdownMenuItem(
                        value: 'Full-time',
                        child: Text('Full-time'),
                      ),
                      DropdownMenuItem(
                        value: 'Part-time',
                        child: Text('Part-time'),
                      ),
                      DropdownMenuItem(
                        value: 'Daily wage',
                        child: Text('Daily wage'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => jobType = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Wage range: ₹${minWage.round()} – ₹${maxWage.round()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RangeSlider(
                    values: RangeValues(minWage, maxWage),
                    min: 0,
                    max: 3000,
                    divisions: 30,
                    activeColor: workerGreen,
                    labels: RangeLabels(
                      '₹${minWage.round()}',
                      '₹${maxWage.round()}',
                    ),
                    onChanged: (values) => setSheetState(() {
                      minWage = values.start;
                      maxWage = values.end;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _locationFilter = '';
                              _jobTypeFilter = 'Any';
                              _minWage = 0;
                              _maxWage = 3000;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: workerGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _locationFilter = location.trim();
                              _jobTypeFilter = jobType;
                              _minWage = minWage;
                              _maxWage = maxWage;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Apply filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyForJob(
    String jobId,
    Map<String, dynamic> job,
    BuildContext sheetContext,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pop(sheetContext);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to apply for a job.')),
      );
      return;
    }

    // Recheck the window at the moment of applying, in case the job detail
    // sheet was opened before the start time or left open past the deadline.
    if (!_isVisibleNow(job)) {
      if (mounted && sheetContext.mounted) {
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          const SnackBar(
            content: Text('This job is not accepting applications right now.'),
          ),
        );
      }
      return;
    }

    final contractorId = job['contractorId']?.toString();

    if (contractorId == null || contractorId.isEmpty) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(
          content: Text('This job is missing contractor information.'),
        ),
      );
      return;
    }

    final applicationId = '${user.uid}_$jobId';

    final applicationRef = FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId);

    try {
      await applicationRef.set({
        'applicantId': user.uid,
        'jobId': jobId,
        'jobTitle': job['title'] ?? 'Untitled job',
        'location': job['location'] ?? 'Location not specified',
        'wageAmount': job['wageAmount'] ?? 0,
        'wageType': job['wageType'] ?? 'Daily',
        'contractorId': contractorId,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted || !sheetContext.mounted) return;

      Navigator.pop(sheetContext);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );
    } on FirebaseException catch (e) {
      if (!mounted || !sheetContext.mounted) return;

      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text('Application failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted || !sheetContext.mounted) return;

      ScaffoldMessenger.of(
        sheetContext,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    }
  }

  void _showJobDetails(String jobId, Map<String, dynamic> job) {
    final title = _text(job['title'], 'Untitled job');
    final location = _text(job['location'], 'Location not specified');
    final category = _text(job['category'], 'General work');
    final description = _text(job['description'], 'No description provided.');
    final jobType = _text(job['jobType'], 'Daily wage');
    final wageType = _text(job['wageType'], 'Daily');
    final wage = _wage(job['wageAmount']);
    final workDates = _workDates(job['workDates']);
    final genderLabel = _genderLabel(job['preferredGender']);
    final contactPhone = _text(job['contactPhone']).trim();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: workerDarkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$category • $jobType',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                _jobDetailRow(Icons.location_on_outlined, 'Location', location),
                _jobDetailRow(
                  Icons.currency_rupee,
                  'Wage',
                  '₹${wage.round()} / $wageType',
                ),
                _jobDetailRow(
                  Icons.people_alt_outlined,
                  'Workers needed',
                  _text(job['workersNeeded'], 'Not specified'),
                ),
                _jobDetailRow(
                  Icons.wc_outlined,
                  'Workers preferred',
                  genderLabel,
                ),
                if (workDates.isNotEmpty)
                  _jobDetailRow(
                    Icons.calendar_month_outlined,
                    'Work dates',
                    workDates.map(_formatWorkDate).join(', '),
                  )
                else
                  _jobDetailRow(
                    Icons.calendar_month_outlined,
                    'Work dates',
                    'Not specified',
                  ),
                if (contactPhone.isNotEmpty)
                  _jobDetailRow(
                    Icons.phone_outlined,
                    'Contractor contact',
                    contactPhone,
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Job description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(description),
                const SizedBox(height: 24),
                if (contactPhone.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _callContractor(contactPhone),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Call Contractor'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: workerGreen,
                        side: const BorderSide(color: workerGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: workerGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () => _applyForJob(jobId, job, sheetContext),
                    child: const Text('Apply for this job'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _jobDetailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: workerGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: workerBackground,
      appBar: AppBar(
        title: const Text(
          'Find Work',
          style: TextStyle(fontWeight: FontWeight.bold, color: workerDarkGreen),
        ),
        backgroundColor: workerBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilters,
            tooltip: 'Filter jobs',
            icon: const Icon(Icons.tune_rounded, color: workerGreen),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search jobs, skills or location',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: workerGreen,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Available jobs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: workerDarkGreen,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.filter_list_rounded, size: 18),
                  label: const Text('Filters'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _applicationsStream,
              builder: (context, applicationSnapshot) {
                if (applicationSnapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Unable to check your applications. Please try again.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (applicationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final appliedJobIds = (applicationSnapshot.data?.docs ?? [])
                    .map((doc) => doc.data()['jobId']?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toSet();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _jobsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Unable to load jobs. Please check your connection and try again.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final documents = snapshot.data?.docs ?? [];
                    final jobs = documents
                        .where(
                          (doc) =>
                              !appliedJobIds.contains(doc.id) &&
                              _matchesJob(doc.data()),
                        )
                        .toList();
                    if (jobs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.work_off_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                documents.isEmpty
                                    ? 'No jobs available yet'
                                    : 'No matching jobs found',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: workerDarkGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                documents.isEmpty
                                    ? 'New jobs posted by contractors will appear here.'
                                    : 'Try changing your search or filters.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              if (documents.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _locationFilter = '';
                                      _jobTypeFilter = 'Any';
                                      _minWage = 0;
                                      _maxWage = 3000;
                                    });
                                  },
                                  child: const Text('Clear all filters'),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: jobs.length,
                      separatorBuilder: (index, item) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final document = jobs[index];
                        final job = document.data();
                        final title = _text(job['title'], 'Untitled job');
                        final category = _text(job['category'], 'General work');
                        final location = _text(
                          job['location'],
                          'Location not specified',
                        );
                        final jobType = _text(job['jobType'], 'Daily wage');
                        final wageType = _text(job['wageType'], 'Daily');
                        final wage = _wage(job['wageAmount']);
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showJobDetails(document.id, job),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDDF1E5),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.work_outline_rounded,
                                          color: workerGreen,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: workerDarkGreen,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              category,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _FindWorkTag(label: jobType),
                                      _FindWorkTag(
                                        label: '₹${wage.round()} / $wageType',
                                        highlighted: true,
                                      ),
                                      _FindWorkTag(
                                        label: _genderLabel(
                                          job['preferredGender'],
                                        ),
                                      ),
                                      if (_workDates(
                                        job['workDates'],
                                      ).isNotEmpty)
                                        _FindWorkTag(
                                          label:
                                              '${_workDates(job['workDates']).length} work date(s)',
                                        ),
                                    ],
                                  ),
                                  if (_text(
                                    job['contactPhone'],
                                  ).trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _text(job['contactPhone']),
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'View details',
                                      style: TextStyle(
                                        color: workerGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _FindWorkTag extends StatelessWidget {
  const _FindWorkTag({required this.label, this.highlighted = false});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xFFDDF1E5) : const Color(0xFFF0F2F0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: highlighted ? workerGreen : Colors.grey.shade700,
      ),
    ),
  );
}
