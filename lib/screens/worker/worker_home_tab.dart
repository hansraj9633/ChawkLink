import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_theme.dart';

class WorkerHomeTab extends StatefulWidget {
  const WorkerHomeTab({super.key});

  @override
  State<WorkerHomeTab> createState() => _WorkerHomeTabState();
}

class _WorkerHomeTabState extends State<WorkerHomeTab> {
  final TextEditingController searchController = TextEditingController();

  String selectedLocation = '';
  String selectedJobType = 'Any';
  double minimumWage = 0;
  double maximumWage = 3000;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<String> getWorkerName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 'Worker';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    final fullName = data?['name']?.toString().trim() ?? '';

    if (fullName.isEmpty) return 'Worker';

    return fullName.split(RegExp(r'\s+')).first;
  }

  bool _matchesJob(Map<String, dynamic> job) {
    final query = searchController.text.trim().toLowerCase();
    final title = (job['title'] ?? '').toString().toLowerCase();
    final category = (job['category'] ?? '').toString().toLowerCase();
    final location = (job['location'] ?? '').toString().toLowerCase();
    final description = (job['description'] ?? '').toString().toLowerCase();
    final jobType = (job['jobType'] ?? job['wageType'] ?? '')
        .toString()
        .toLowerCase();
    final skills = (job['skills'] ?? '').toString().toLowerCase();

    // Also match common variations, e.g. "mason" and "masonry".
    final searchText =
        '$title $category $location $description $jobType $skills';
    final queryMatches =
        query.isEmpty ||
        searchText.contains(query) ||
        (query == 'mason' && searchText.contains('masonry')) ||
        (query == 'masonry' && searchText.contains('mason'));

    final locationMatches =
        selectedLocation.isEmpty ||
        location.contains(selectedLocation.toLowerCase());
    final type = selectedJobType.toLowerCase();
    final actualType = jobType;
    final typeMatches =
        selectedJobType == 'Any' ||
        actualType.contains(type) ||
        (type == 'daily wage' &&
            (actualType.contains('daily') || actualType.contains('wage')));

    final wageValue = job['wageAmount'];
    final wage = wageValue is num ? wageValue.toDouble() : 0.0;
    final wageMatches =
        (wageValue is! num) || (wage >= minimumWage && wage <= maximumWage);

    // Respect the job's published application window when those fields exist.
    final now = DateTime.now();
    final startValue = job['startAt'];
    final deadlineValue = job['applicationDeadline'];
    final startAt = startValue is Timestamp ? startValue.toDate() : null;
    final deadline = deadlineValue is Timestamp ? deadlineValue.toDate() : null;
    final withinWindow =
        (startAt == null || !now.isBefore(startAt)) &&
        (deadline == null || !now.isAfter(deadline));

    return queryMatches &&
        locationMatches &&
        typeMatches &&
        wageMatches &&
        withinWindow;
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {});
  }

  void openFilters() {
    final locationController = TextEditingController(text: selectedLocation);
    String jobType = selectedJobType;
    double minWage = minimumWage;
    double maxWage = maximumWage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Filter Jobs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: workerDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Preferred location',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter city or area',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Any', child: Text('Any')),
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
                        if (value != null) {
                          setSheetState(() => jobType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Daily wage: ₹${minWage.round()} – ₹${maxWage.round()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    RangeSlider(
                      values: RangeValues(minWage, maxWage),
                      min: 0,
                      max: 3000,
                      divisions: 30,
                      activeColor: workerGreen,
                      onChanged: (values) {
                        setSheetState(() {
                          minWage = values.start;
                          maxWage = values.end;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedLocation = '';
                                selectedJobType = 'Any';
                                minimumWage = 0;
                                maximumWage = 3000;
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
                            ),
                            onPressed: () {
                              setState(() {
                                selectedLocation = locationController.text
                                    .trim();
                                selectedJobType = jobType;
                                minimumWage = minWage;
                                maximumWage = maxWage;
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
            );
          },
        );
      },
    ).whenComplete(locationController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF1E5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.engineering_rounded,
                color: workerGreen,
                size: 27,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ChawkLink',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: workerDarkGreen,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications will be available soon.'),
                  ),
                );
              },
              tooltip: 'Notifications',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: workerDarkGreen,
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 26),
        FutureBuilder<String>(
          future: getWorkerName(),
          builder: (context, snapshot) {
            final name = snapshot.data ?? 'Worker';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Namaste, $name 👋',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: workerDarkGreen,
                  ),
                ),
                const SizedBox(height: 5),
                // const Text(
                //   'Find work that fits your skills.',
                //   style: TextStyle(fontSize: 14, color: Colors.black54),
                // ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE5EAE6)),
                ),
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search job, skill, or location',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: workerGreen,
                    ),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              width: 52,
              child: OutlinedButton(
                onPressed: openFilters,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE0E7E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Icon(Icons.tune_rounded, color: workerGreen),
              ),
            ),
          ],
        ),
        if (selectedLocation.isNotEmpty ||
            selectedJobType != 'Any' ||
            minimumWage > 0 ||
            maximumWage < 3000) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (selectedLocation.isNotEmpty)
                _FilterChipLabel(label: selectedLocation),
              if (selectedJobType != 'Any')
                _FilterChipLabel(label: selectedJobType),
              if (minimumWage > 0 || maximumWage < 3000)
                _FilterChipLabel(
                  label: '₹${minimumWage.round()}–₹${maximumWage.round()}/day',
                ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        const Text(
          'Your Work Overview',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: workerDarkGreen,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseAuth.instance.currentUser == null
              ? null
              : FirebaseFirestore.instance
                    .collection('applications')
                    .where(
                      'applicantId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                    )
                    .snapshots(),
          builder: (context, snapshot) {
            var pending = 0;
            var accepted = 0;
            var declined = 0;
            for (final doc in snapshot.data?.docs ?? []) {
              final status = (doc.data()['status'] ?? '')
                  .toString()
                  .toLowerCase();
              if (status == 'pending') pending++;
              if (status == 'accepted') accepted++;
              if (status == 'rejected' || status == 'declined') declined++;
            }
            return Row(
              children: [
                Expanded(
                  child: _WorkOverviewCard(
                    label: 'Pending',
                    count: pending,
                    icon: Icons.schedule_rounded,
                    background: const Color(0xFFEAF2FF),
                    foreground: const Color(0xFF315EA8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WorkOverviewCard(
                    label: 'Accepted',
                    count: accepted,
                    icon: Icons.check_circle_outline_rounded,
                    background: const Color(0xFFE4F4E9),
                    foreground: workerGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WorkOverviewCard(
                    label: 'Declined',
                    count: declined,
                    icon: Icons.cancel_outlined,
                    background: const Color(0xFFFCEBE8),
                    foreground: const Color(0xFFB54738),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const Row(
          children: [
            Expanded(
              child: Text(
                'Latest Jobs',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: workerDarkGreen,
                ),
              ),
            ),
            Icon(Icons.access_time_rounded, color: Colors.black45, size: 20),
          ],
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .where('status', isEqualTo: 'open')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Unable to load jobs. Please try again later.');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final allJobs = snapshot.data?.docs ?? [];
            final jobs =
                allJobs
                    .where((document) => _matchesJob(document.data()))
                    .toList()
                  ..sort((a, b) {
                    final aTime = a.data()['createdAt'];
                    final bTime = b.data()['createdAt'];
                    final aDate = aTime is Timestamp
                        ? aTime.toDate()
                        : DateTime.fromMillisecondsSinceEpoch(0);
                    final bDate = bTime is Timestamp
                        ? bTime.toDate()
                        : DateTime.fromMillisecondsSinceEpoch(0);
                    return bDate.compareTo(aDate);
                  });

            if (jobs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.work_history_outlined,
                      size: 36,
                      color: workerGreen,
                    ),
                    SizedBox(height: 10),
                    Text(
                      searchController.text.trim().isNotEmpty ||
                              selectedLocation.isNotEmpty ||
                              selectedJobType != 'Any' ||
                              minimumWage > 0 ||
                              maximumWage < 3000
                          ? 'No matching jobs found'
                          : 'No jobs available yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: workerDarkGreen,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      searchController.text.trim().isNotEmpty ||
                              selectedLocation.isNotEmpty ||
                              selectedJobType != 'Any' ||
                              minimumWage > 0 ||
                              maximumWage < 3000
                          ? 'Try a different keyword or adjust your filters.'
                          : 'New jobs posted by contractors will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: jobs.map((document) {
                final job = document.data();

                final title = job['title']?.toString() ?? 'Untitled job';
                final location =
                    job['location']?.toString() ?? 'Location not specified';
                final category = job['category']?.toString() ?? 'General work';
                final wage = job['wageAmount'];
                final wageType = job['wageType']?.toString() ?? 'Daily';

                return Container(
                  height: 142,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7ECE8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.15,
                          fontWeight: FontWeight.bold,
                          color: workerDarkGreen,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$category • $location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 17,
                            color: workerGreen,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              wage is num
                                  ? '₹${wage.toStringAsFixed(0)} / $wageType'
                                  : 'Wage not specified',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: workerGreen,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: Colors.black38,
                          ),
                        ],
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

class _WorkOverviewCard extends StatelessWidget {
  const _WorkOverviewCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Extra vertical room prevents a RenderFlex overflow on smaller screens
      // and when the device uses a larger system font size.
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: foreground, size: 21),
          const SizedBox(height: 5),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipLabel extends StatelessWidget {
  const _FilterChipLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFFE4F2E8),
      side: BorderSide.none,
      labelStyle: const TextStyle(color: workerDarkGreen, fontSize: 12),
      visualDensity: VisualDensity.compact,
    );
  }
}
