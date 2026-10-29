import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/role_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MajdoorSetuApp());
}

const green = Color(0xFF006B43);
const darkGreen = Color(0xFF064A32);

class MajdoorSetuApp extends StatelessWidget {
  const MajdoorSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Majdoor Setu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: const Color(0xFFF0F5EF)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x33000000),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Image.asset(
                  'assets/images/majdoor_setu_logo.png',
                  width: 155,
                  height: 135,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.engineering,
                    size: 115,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Majdoor Setu',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Connecting Work. Building Lives.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: darkGreen,
                  ),
                ),
                const Spacer(flex: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/get_started_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.white),
          ),
          Container(color: Colors.white.withValues(alpha: 0.12)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 4),
                  const Text(
                    'Welcome to\nMajdoor Setu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      height: 1.18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF092D20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Find work or hire skilled and\nunskilled workers easily.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF424B46),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => openNext(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => openNext(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: green,
                        side: const BorderSide(color: green),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Login'),
                    ),
                  ),
                  const Spacer(flex: 5),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 25),
                    child: Text(
                      'Fast. Simple. Reliable.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF263A30)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openNext(BuildContext context, bool createAccount) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(createAccount: createAccount),
      ),
    );
  }
}
