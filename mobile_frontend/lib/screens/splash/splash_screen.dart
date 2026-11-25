import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_screen.dart';
import '../welcome/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openNextScreen();
  }

  // If storage fails, show the welcome screen instead of getting stuck
  Future<bool> _isWelcomeSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(welcomeSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  // The welcome screen is only shown on the first launch
  Future<void> _openNextScreen() async {
    final welcomeSeen = await _isWelcomeSeen();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, _, _) =>
            welcomeSeen ? const HomeScreen() : const WelcomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 160),
            const SizedBox(height: 8),
            Text(
              'Indiadits Crypto',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
