import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/role_selection_screen.dart';
import 'contractor_theme.dart';

class ContractorProfileTab extends StatelessWidget {
  const ContractorProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of ChawkLink?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RoleSelectionScreen(createAccount: false),
      ),
      (route) => false,
    );
  }

  Future<void> _editPersonalInformation(
    BuildContext context,
    String uid,
    String currentName,
    String currentEmail,
  ) async {
    final formKey = GlobalKey<FormState>();
    String editedName = currentName;
    String editedEmail = currentEmail == 'Not provided' ? '' : currentEmail;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Personal Information'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: currentName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required.';
                    }
                    return null;
                  },
                  onSaved: (value) => editedName = value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: editedEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address (optional)',
                    hintText: 'Enter email or leave blank',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    // Email is optional.
                    if (email.isEmpty) return null;

                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email address.';
                    }

                    return null;
                  },
                  onSaved: (value) => editedEmail = value?.trim() ?? '',
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '* Required field',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              formKey.currentState!.save();

              Navigator.pop(dialogContext, {
                'name': editedName,
                'email': editedEmail,
              });
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': result['name'],
        'email': result['email'],
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal information updated successfully.'),
          backgroundColor: contractorGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update information: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editWorkPreferences(
    BuildContext context,
    String uid,
    String businessName,
    String operatingArea,
  ) async {
    final businessController = TextEditingController(
      text: businessName == 'Not added' ? '' : businessName,
    );
    final areaController = TextEditingController(
      text: operatingArea == 'Not added' ? '' : operatingArea,
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Work Preferences'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: businessController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Business name',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: areaController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Operating area',
                    hintText: 'e.g. Jharia, Dhanbad',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your operating area.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(dialogContext, {
                'businessName': businessController.text.trim(),
                'operatingArea': areaController.text.trim(),
              });
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'businessName': result['businessName'],
        'operatingArea': result['operatingArea'],
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work preferences updated successfully.'),
          backgroundColor: contractorGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update work preferences.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, int>> _loadStats(String uid) async {
    final firestore = FirebaseFirestore.instance;

    final results = await Future.wait([
      firestore.collection('jobs').where('contractorId', isEqualTo: uid).get(),
      firestore
          .collection('applications')
          .where('contractorId', isEqualTo: uid)
          .get(),
    ]);

    final jobs = results[0].docs;
    final applications = results[1].docs;

    return {
      'total': jobs.length,
      'open': jobs.where((job) => job.data()['status'] == 'open').length,
      'closed': jobs.where((job) => job.data()['status'] == 'closed').length,
      'workers': applications
          .where((app) => app.data()['status'] == 'accepted')
          .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please sign in again.'));
    }

    return Scaffold(
      backgroundColor: contractorBackground,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: contractorDarkGreen,
          ),
        ),
        backgroundColor: contractorBackground,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load your profile.'));
          }

          final data = snapshot.data?.data() ?? {};

          final storedName = data['name']?.toString().trim() ?? '';
          final name = storedName.isNotEmpty ? storedName : 'Contractor';

          final storedPhone = data['phone']?.toString().trim() ?? '';
          final phone = storedPhone.isNotEmpty
              ? storedPhone
              : user.phoneNumber ?? 'Not provided';

          final storedEmail = data['email']?.toString().trim() ?? '';
          final email = storedEmail.isNotEmpty ? storedEmail : 'Not provided';

          final storedBusiness = data['businessName']?.toString().trim() ?? '';
          final businessName = storedBusiness.isNotEmpty
              ? storedBusiness
              : 'Not added';

          final storedArea = data['operatingArea']?.toString().trim() ?? '';
          final operatingArea = storedArea.isNotEmpty
              ? storedArea
              : 'Not added';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              // Profile header: initials only, no photo upload.
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: contractorDarkGreen,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 43,
                      backgroundColor: const Color(0xFFDDF1E5),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: contractorDarkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'CONTRACTOR ACCOUNT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 17,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            phone,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Personal Information
              _ExpandableSection(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                subtitle: 'Your contact details',
                children: [
                  _ProfileLine(
                    icon: Icons.person_outline_rounded,
                    label: 'Full name',
                    value: name,
                  ),
                  const Divider(height: 24),
                  _ProfileLine(
                    icon: Icons.phone_outlined,
                    label: 'Phone number',
                    value: phone,
                  ),
                  const Divider(height: 24),
                  _ProfileLine(
                    icon: Icons.email_outlined,
                    label: 'Email address',
                    value: email,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _editPersonalInformation(
                        context,
                        user.uid,
                        name,
                        email,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Information'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Note: Phone Number can\'t be changed for now!',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Work Preferences
              _ExpandableSection(
                icon: Icons.business_center_outlined,
                title: 'Work Preferences',
                subtitle: 'Your business and operating area',
                children: [
                  _ProfileLine(
                    icon: Icons.business_outlined,
                    label: 'Business name',
                    value: businessName,
                  ),
                  const Divider(height: 24),
                  _ProfileLine(
                    icon: Icons.location_on_outlined,
                    label: 'Operating area',
                    value: operatingArea,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _editWorkPreferences(
                        context,
                        user.uid,
                        businessName,
                        operatingArea,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Work Preferences'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // My Activities
              _ExpandableSection(
                icon: Icons.analytics_outlined,
                title: 'My Activities',
                subtitle: 'Overview of your jobs and workers',
                children: [
                  FutureBuilder<Map<String, int>>(
                    future: _loadStats(user.uid),
                    builder: (context, statsSnapshot) {
                      if (statsSnapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Unable to load activity statistics.'),
                        );
                      }

                      if (!statsSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final stats = statsSnapshot.data!;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Jobs',
                                  value: stats['total']!,
                                  icon: Icons.work_outline_rounded,
                                  color: contractorGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Open Jobs',
                                  value: stats['open']!,
                                  icon: Icons.work_history_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Closed Jobs',
                                  value: stats['closed']!,
                                  icon: Icons.task_alt_rounded,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Accepted Apps',
                                  value: stats['workers']!,
                                  icon: Icons.groups_outlined,
                                  color: contractorDarkGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Privacy Policy
              _ExpandableSection(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How ChawkLink handles your information',
                children: const [
                  Text(
                    'ChawkLink uses the information you provide to '
                    'support your account and job-related activities.',
                    style: TextStyle(height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Profile details and job application information '
                    'are stored in the app’s connected services and '
                    'are made available according to account permissions.',
                    style: TextStyle(height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Keep your account credentials secure. Contact '
                    'the ChawkLink team for questions about your data '
                    'or privacy.',
                    style: TextStyle(height: 1.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Note: This is an in-app informational summary, '
                    'not a substitute for the official published '
                    'privacy policy.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Logout
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.red),
                  ),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: const Text('Sign out of your account'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _logout(context),
                ),
              ),

              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'ChawkLink • Reliable Work. Fair Wages.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF1E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: contractorGreen),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: contractorDarkGreen,
              fontSize: 15,
            ),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          children: children,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: contractorBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: contractorDarkGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFDDF1E5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: contractorGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: contractorDarkGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
