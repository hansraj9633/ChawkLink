import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.role});

  final String role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _skillsController = TextEditingController();
  final _workAreaController = TextEditingController();
  final _businessNameController = TextEditingController();

  static const Color green = Color(0xFF006B43);

  bool get isWorker => widget.role.toLowerCase() == 'worker';

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _skillsController.dispose();
    _workAreaController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+91${_mobileController.text.trim()}';

    final profile = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
    };

    if (isWorker) {
      profile['skills'] = _skillsController.text.trim();
      profile['preferredWorkArea'] = _workAreaController.text.trim();
    } else {
      profile['businessName'] = _businessNameController.text.trim();
      profile['operatingArea'] = _workAreaController.text.trim();
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) {},
        verificationFailed: (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Could not send OTP.')),
          );
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                verificationId: verificationId,
                phoneNumber: phone,
                role: widget.role,
                isRegistration: true,
                profile: profile,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: green),
      filled: true,
      fillColor: const Color(0xFFF7FAF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E8E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E8E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: green,
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF092D20),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/majdoor_setu_logo.png',
                    height: 90,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.engineering,
                        size: 75,
                        color: green,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create ${widget.role} Account',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF092D20),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your details to get started with Majdoor Setu.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                _sectionTitle('Basic Details'),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Full Name *',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                _gap(),

                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: _inputDecoration(
                    label: 'Mobile Number *',
                    icon: Icons.phone_outlined,
                    hint: '10-digit mobile number',
                  ).copyWith(counterText: ''),
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                      return 'Enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                _gap(),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  decoration: _inputDecoration(
                    label: 'Email Address (Optional)',
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isNotEmpty &&
                        !RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                _gap(),

                _sectionTitle(
                  isWorker ? 'Work Preferences' : 'Business Details',
                ),

                if (isWorker) ...[
                  TextFormField(
                    controller: _skillsController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Skills / Work Type (Optional)',
                      icon: Icons.construction_outlined,
                      hint: 'e.g. Mason, Helper, Painter',
                    ),
                  ),
                  _gap(),
                  TextFormField(
                    controller: _workAreaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Preferred Work Area (Optional)',
                      icon: Icons.location_on_outlined,
                      hint: 'Village, town or area',
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _businessNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Business Name (Optional)',
                      icon: Icons.business_outlined,
                    ),
                  ),
                  _gap(),
                  TextFormField(
                    controller: _workAreaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Operating Area (Optional)',
                      icon: Icons.location_on_outlined,
                      hint: 'Village, town or area',
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _createAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Continue with Mobile OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LoginScreen(role: widget.role),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
