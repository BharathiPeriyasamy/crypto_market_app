import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

const welcomeSeenKey = 'welcome_seen';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _openHome(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(welcomeSeenKey, true);
    } catch (_) {
      // Still open the app; the welcome screen will just show again next time
    }
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Neon_cube.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                Text(
                  'Trade smarter\nfaster safer',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 44,
                    fontVariations: [FontVariation('wght', 700)],
                    height: 1.25,
                    color: offWhite,
                  ),
                ),
                const SizedBox(height: 40),
                _StartButton(onPressed: () => _openHome(context)),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Dark pill whose green border fades from left to right
class _StartButton extends StatefulWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  late final _arrowOffset = Tween(
    begin: Offset.zero,
    end: const Offset(0.5, 0),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [neonGreen, deepGreen]),
      ),
      child: Material(
        color: darkGreen,
        borderRadius: BorderRadius.circular(29),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(29),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Get Start Now',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontVariations: [FontVariation('wght', 300)],
                    color: offWhite,
                  ),
                ),
                const SizedBox(width: 12),
                SlideTransition(
                  position: _arrowOffset,
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: offWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
