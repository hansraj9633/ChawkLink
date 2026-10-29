import 'package:flutter/material.dart';
import 'contractor_applications_tab.dart';
import 'contractor_home_tab.dart';
import 'contractor_jobs_tab.dart';
import 'contractor_profile_tab.dart';
import 'contractor_theme.dart';

class ContractorMainScreen extends StatefulWidget {
  const ContractorMainScreen({super.key});

  @override
  State<ContractorMainScreen> createState() => _ContractorMainScreenState();
}

class _ContractorMainScreenState extends State<ContractorMainScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ContractorHomeTab(onOpenJobs: () => setState(() => selectedIndex = 2)),
      const ContractorJobsTab(),
      const ContractorApplicationsTab(),
      const ContractorProfileTab(),
    ];

    return Scaffold(
      backgroundColor: contractorBackground,
      body: SafeArea(
        child: IndexedStack(index: selectedIndex, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDDF1E5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            label: 'Post Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Applications',
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
