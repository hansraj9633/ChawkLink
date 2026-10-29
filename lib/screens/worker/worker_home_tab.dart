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

  String selectedCategory = '';
  String selectedLocation = '';
  String selectedJobType = 'Any';
  double minimumWage = 0;
  double maximumWage = 3000;

  final List<Map<String, dynamic>> popularWorks = [
    {'name': 'Mason', 'icon': Icons.foundation_rounded},
    {'name': 'Painter', 'icon': Icons.format_paint_rounded},
    {'name': 'Electrician', 'icon': Icons.electrical_services_rounded},
    {'name': 'Plumber', 'icon': Icons.plumbing_rounded},
  ];

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
                'Majdoor Setu',
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
                const Text(
                  'Find work that fits your skills.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
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
                  onSubmitted: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Job search will be connected to live listings next.',
                        ),
                      ),
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search jobs or skills',
                    prefixIcon: Icon(Icons.search_rounded, color: workerGreen),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
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
        Row(
          children: [
            const Expanded(
              child: Text(
                'Popular Works',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: workerDarkGreen,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Explore all works in Find Work soon.'),
                  ),
                );
              },
              child: const Text(
                'View all',
                style: TextStyle(color: workerGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: popularWorks.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 94,
          ),
          itemBuilder: (context, index) {
            final work = popularWorks[index];
            final isSelected = selectedCategory == work['name'];

            return Material(
              color: isSelected ? const Color(0xFFE2F2E8) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    selectedCategory = isSelected ? '' : work['name'] as String;
                    searchController.text = selectedCategory;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? workerGreen : const Color(0xFFE7ECE8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5ED),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          work['icon'] as IconData,
                          color: workerGreen,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          work['name'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: workerDarkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

            final jobs = snapshot.data?.docs ?? [];

            if (jobs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.work_history_outlined,
                      size: 36,
                      color: workerGreen,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No jobs available yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: workerDarkGreen,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'New jobs posted by contractors will appear here.',
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
                  margin: const EdgeInsets.only(bottom: 12),
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
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: workerDarkGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$category  •  $location'),
                      const SizedBox(height: 8),
                      Text(
                        wage is num
                            ? '₹${wage.toStringAsFixed(0)} / $wageType'
                            : 'Wage not specified',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: workerGreen,
                        ),
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
