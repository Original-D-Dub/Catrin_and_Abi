import 'package:flutter/material.dart';

/// Red notification dot shown over the home screen's profile icon while
/// the player has earned badges they haven't seen on the profile screen
/// yet (see [ProfileProvider.hasUnseenBadges] for the state behind it).
class ProfileDot extends StatelessWidget {
  const ProfileDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
