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

  Future<void> _editProfile(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditContractorProfileDialog(data: data),
    );

    if (result == null || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': result['name']!.trim(),
        'businessName': result['businessName']!.trim(),
        'operatingArea': result['operatingArea']!.trim(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: contractorGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update profile. Please try again.'),
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

    final openJobs = jobs.where((job) {
      return job.data()['status'] == 'open';
    }).length;

    final closedJobs = jobs.where((job) {
      return job.data()['status'] == 'closed';
    }).length;

    final acceptedApplications = applications.where((application) {
      return application.data()['status'] == 'accepted';
    }).length;

    return {
      'total': jobs.length,
      'open': openJobs,
      'closed': closedJobs,
      'workers': acceptedApplications,
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
          final name = data['name']?.toString().trim().isNotEmpty == true
              ? data['name'].toString()
              : 'Contractor';

          final phone = data['phone']?.toString().trim().isNotEmpty == true
              ? data['phone'].toString()
              : user.phoneNumber ?? 'Not provided';

          final email = data['email']?.toString().trim().isNotEmpty == true
              ? data['email'].toString()
              : user.email ?? 'Not provided';

          final businessName =
              data['businessName']?.toString().trim().isNotEmpty == true
              ? data['businessName'].toString()
              : 'Not added';

          final operatingArea =
              data['operatingArea']?.toString().trim().isNotEmpty == true
              ? data['operatingArea'].toString()
              : 'Not added';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              // Profile header
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
                        name.trim().isNotEmpty
                            ? name.trim()[0].toUpperCase()
                            : 'C',
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _editProfile(context, user.uid, data),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: contractorDarkGreen,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const _SectionHeading(
                title: 'My Activity',
                subtitle: 'An overview of your job listings and workers',
              ),

              const SizedBox(height: 14),

              FutureBuilder<Map<String, int>>(
                future: _loadStats(user.uid),
                builder: (context, statsSnapshot) {
                  if (statsSnapshot.hasError) {
                    return const Text(
                      'Unable to load activity statistics.',
                      style: TextStyle(color: Colors.black54),
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
                              color: Colors.blue.shade700,
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
                              color: Colors.orange.shade800,
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

              const SizedBox(height: 26),

              const _SectionHeading(
                title: 'Personal Information',
                subtitle: 'Your contact and business details',
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: Column(
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
                    const Divider(height: 24),
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
                  ],
                ),
              ),

              const SizedBox(height: 26),

              const _SectionHeading(
                title: 'Account',
                subtitle: 'Manage your ChawkLink account',
              ),

              const SizedBox(height: 14),

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

class _EditContractorProfileDialog extends StatefulWidget {
  const _EditContractorProfileDialog({required this.data});

  final Map<String, dynamic> data;

  @override
  State<_EditContractorProfileDialog> createState() =>
      _EditContractorProfileDialogState();
}

class _EditContractorProfileDialogState
    extends State<_EditContractorProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _businessController;
  late final TextEditingController _areaController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.data['name']?.toString() ?? '',
    );
    _businessController = TextEditingController(
      text: widget.data['businessName']?.toString() ?? '',
    );
    _areaController = TextEditingController(
      text: widget.data['operatingArea']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateRequired(value, 'your name'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _businessController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Business name',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _areaController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Operating area *',
                  hintText: 'e.g. Japla, Palamu',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    _validateRequired(value, 'your operating area'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            Navigator.pop(context, {
              'name': _nameController.text,
              'businessName': _businessController.text,
              'operatingArea': _areaController.text,
            });
          },
          style: FilledButton.styleFrom(backgroundColor: contractorGreen),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: contractorDarkGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: contractorDarkGreen,
            ),
          ),
          const SizedBox(height: 3),
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
