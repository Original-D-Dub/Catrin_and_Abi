import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/game_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro =
        prefs.getBool(GameConstants.firstLaunchKey) ?? false;
    final destination =
        hasSeenIntro ? AppRoutes.home : AppRoutes.welcome;

    await Future.delayed(const Duration(milliseconds: 4000));
    if (!mounted) return;
    await _controller.forward();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        body: Stack(
          children: [
            // Background image — cover, pinned top-left
            Positioned.fill(
              child: Image.asset(
                'assets/backgrounds/park1920x1400.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topLeft,
                width: orientation == Orientation.landscape
                    ? MediaQuery.of(context).size.width
                    : null,
                height: orientation == Orientation.portrait
                    ? MediaQuery.of(context).size.height
                    : null,
              ),
            ),

            // Logo — top left
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Image.asset(
                'assets/logos/english/Catrin_Abi_Logo_Eng_600x600.png',
                height: 140,
              ),
            ),

            // Group image — bottom right, 60% screen height
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/characters/group photo.png',
                height: MediaQuery.of(context).size.height * 0.6,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
