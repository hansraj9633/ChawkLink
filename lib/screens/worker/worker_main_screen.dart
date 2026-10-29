import 'package:flutter/material.dart';
import 'worker_theme.dart';
import 'worker_home_tab.dart';
import 'find_work_tab.dart';
import 'worker_my_jobs_tab.dart';
import 'worker_profile_tab.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    WorkerHomeTab(),
    FindWorkTab(),
    WorkerMyJobsTab(),
    WorkerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: workerBackground,
      body: SafeArea(child: screens[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDDF1E5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Find Work',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            label: 'My Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
