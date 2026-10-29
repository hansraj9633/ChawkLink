import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/role_selection_screen.dart';

const _profileGreen = Color(0xFF006B43);
const _profileDarkGreen = Color(0xFF064A32);
const _profileBackground = Color(0xFFF7F9F7);

class WorkerProfileTab extends StatelessWidget {
  const WorkerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _profileBackground,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: _profileDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _profileBackground,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view your profile.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to load your profile. Please try again.',
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data();
                if (data == null) {
                  return const Center(
                    child: Text('Profile details not found.'),
                  );
                }

                final name = _value(data['name'], 'Worker');
                final phone = _value(
                  data['phone'],
                  user.phoneNumber ?? 'Not available',
                );
                final email = _value(data['email'], 'Not added');
                final skills = _value(data['skills'], 'Not added');
                final area = _value(data['preferredWorkArea'], 'Not added');

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE4EAE5)),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFFDDF1E5),
                            child: Text(
                              name.trim().isEmpty
                                  ? 'W'
                                  : name.trim()[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: _profileGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: _profileDarkGreen,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Worker account',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _editProfile(context, user.uid, data),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit profile'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _profileGreen,
                                side: const BorderSide(color: _profileGreen),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionCard(
                      title: 'Personal information',
                      children: [
                        _detailRow(Icons.person_outline, 'Full name', name),
                        _detailRow(
                          Icons.phone_outlined,
                          'Mobile number',
                          phone,
                        ),
                        _detailRow(
                          Icons.email_outlined,
                          'Email address',
                          email,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sectionCard(
                      title: 'Work preferences',
                      children: [
                        _detailRow(
                          Icons.construction_outlined,
                          'Skills / work type',
                          skills,
                        ),
                        _detailRow(
                          Icons.location_on_outlined,
                          'Preferred work area',
                          area,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE4EAE5)),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Log out',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Sign out of your Majdoor Setu account',
                        ),
                        onTap: () => _confirmLogout(context),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  static String _value(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _profileDarkGreen,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  static Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _profileGreen, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) async {
    final nameController = TextEditingController(
      text: _value(data['name'], ''),
    );
    final emailController = TextEditingController(
      text: _value(data['email'], ''),
    );
    final skillsController = TextEditingController(
      text: _value(data['skills'], ''),
    );
    final areaController = TextEditingController(
      text: _value(data['preferredWorkArea'], ''),
    );

    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit profile'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full name *'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your name'
                        : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isNotEmpty &&
                          !RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: skillsController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Skills / work type',
                    ),
                  ),
                  TextFormField(
                    controller: areaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Preferred work area',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                              'name': nameController.text.trim(),
                              'email': emailController.text.trim(),
                              'skills': skillsController.text.trim(),
                              'preferredWorkArea': areaController.text.trim(),
                            });
                        // Unfocus text fields before closing the dialog to avoid
                        // disposing focused input widgets during the route transition.
                        if (!dialogContext.mounted) return;
                        FocusScope.of(dialogContext).unfocus();
                        Navigator.of(dialogContext).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully.'),
                            ),
                          );
                        }
                      } on FirebaseException catch (e) {
                        setDialogState(() => saving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not update profile: ${e.message ?? e.code}',
                            ),
                          ),
                        );
                      } catch (_) {
                        setDialogState(() => saving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Something went wrong. Please try again.',
                            ),
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );

    // Let the dialog's reverse transition finish before disposing controllers
    // that are still attached to its text fields.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameController.dispose();
    emailController.dispose();
    skillsController.dispose();
    areaController.dispose();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of Majdoor Setu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _profileGreen),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RoleSelectionScreen(createAccount: false),
      ),
      (route) => false,
    );
  }
}
