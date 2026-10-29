import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key, required this.createAccount});

  final bool createAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/get_started_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          Container(color: Colors.white.withValues(alpha: 0.18)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Select Your Role',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF092D20),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how you want to use the app',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 30),

                _roleCard(
                  context,
                  title: 'I am a Worker',
                  description: 'Find jobs in your area and apply directly.',
                  image: 'assets/images/worker.png',
                  role: 'Worker',
                ),

                const SizedBox(height: 22),

                _roleCard(
                  context,
                  title: 'I am a Contractor',
                  description: 'Post job requirements and hire workers.',
                  image: 'assets/images/contractor.png',
                  role: 'Contractor',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required String title,
    required String description,
    required String image,
    required String role,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (createAccount) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterScreen(role: role),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen(role: role)),
            );
          }
        },
        child: Container(
          height: 125,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECE8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                height: 105,
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.engineering,
                      color: Color(0xFF006B43),
                      size: 65,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF17352A)),
            ],
          ),
        ),
      ),
    );
  }
}
