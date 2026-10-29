import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../worker/worker_main_screen.dart';
import '../contractor/contractor_main_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.role,
    required this.isRegistration,
    this.profile = const {},
  });

  final String verificationId;
  final String phoneNumber;
  final String role;
  final bool isRegistration;
  final Map<String, dynamic> profile;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;

  static const Color green = Color(0xFF006B43);

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the 6-digit OTP')));
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = result.user;

      if (user == null) {
        throw Exception('Authentication failed. Please try again.');
      }

      final users = FirebaseFirestore.instance.collection('users');
      final userRef = users.doc(user.uid);
      final existingProfile = await userRef.get();

      if (widget.isRegistration) {
        if (existingProfile.exists) {
          await FirebaseAuth.instance.signOut();

          throw Exception('This account is already registered. Please log in.');
        }

        await userRef.set({
          ...widget.profile,
          'uid': user.uid,
          'phone': widget.phoneNumber,
          'role': widget.role.toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        if (!existingProfile.exists) {
          await FirebaseAuth.instance.signOut();

          throw Exception('Account not found. Please create an account first.');
        }

        final data = existingProfile.data()!;
        final savedRole = (data['role'] ?? '').toString().toLowerCase();

        if (savedRole != widget.role.toLowerCase()) {
          await FirebaseAuth.instance.signOut();

          throw Exception('This number is not registered as a ${widget.role}.');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isRegistration
                ? 'Account created successfully!'
                : 'Login successful!',
          ),
        ),
      );

      if (widget.role.toLowerCase() == 'worker') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WorkerMainScreen()),
          (route) => false,
        );
      } else if (widget.role.toLowerCase() == 'contractor') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ContractorMainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'OTP verification failed.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF092D20),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.verified_user_outlined, color: green, size: 54),
              const SizedBox(height: 20),
              const Text(
                'Enter verification code',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF092D20),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the 6-digit code for ${widget.phoneNumber}.',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'OTP',
                  prefixIcon: const Icon(Icons.lock_outline, color: green),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF7FAF8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
