import 'package:flutter/material.dart';

/// Scaffold shared by the zoo start / pick-a-player / player screens:
/// the zoo photo background filling the screen with [child] in a SafeArea.
class ZooBackgroundScaffold extends StatelessWidget {
  final Widget child;

  const ZooBackgroundScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/games/zoo/zoo_game_background.jpg',
            fit: BoxFit.cover,
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Heading text style for the zoo menu screens: LuckiestGuy, white with a
/// dark shadow so it stays readable over the photo background.
class ZooHeading extends StatelessWidget {
  final String text;

  const ZooHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'LuckiestGuy',
        fontSize: 40,
        height: 1.2,
        color: Colors.white,
        shadows: [
          Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 6),
          Shadow(color: Colors.black54, offset: Offset(0, 0), blurRadius: 12),
        ],
      ),
    );
  }
}
