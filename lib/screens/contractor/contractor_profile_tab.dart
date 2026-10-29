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
        content: const Text('Are you sure you want to log out?'),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please sign in again.'));
    return Scaffold(
      backgroundColor: contractorBackground,
      appBar: AppBar(
        title: const Text(
          'Profile',
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
          final name = data['name']?.toString() ?? 'Contractor';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFDDF1E5),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: contractorGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: contractorDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['phone']?.toString() ??
                          user.phoneNumber ??
                          'Phone not provided',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const Divider(height: 28),
                    _ProfileLine(
                      label: 'Email',
                      value: data['email']?.toString() ?? 'Not provided',
                    ),
                    _ProfileLine(
                      label: 'Business name',
                      value: data['businessName']?.toString() ?? 'Not provided',
                    ),
                    _ProfileLine(
                      label: 'Operating area',
                      value:
                          data['operatingArea']?.toString() ?? 'Not provided',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: contractorDarkGreen,
            ),
          ),
        ),
      ],
    ),
  );
}
