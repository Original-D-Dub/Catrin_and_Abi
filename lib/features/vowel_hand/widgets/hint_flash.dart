import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/vowel_target.dart';

/// Repeatedly fades [child] in and out while it is on screen.
///
/// Used for the red hint in the ages 1–3 vowel hand levels. The provider
/// decides how long the hint lasts by removing it; give each new flash a
/// fresh key so the animation restarts from the start.
class HintFlash extends StatefulWidget {
  final Widget child;

  const HintFlash({super.key, required this.child});

  @override
  State<HintFlash> createState() => _HintFlashState();
}

class _HintFlashState extends State<HintFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(opacity: _controller, child: widget.child),
    );
  }
}

/// Paints [target]'s fingertip outline in red, scaled to the hand's size.
class FingertipHintPainter extends CustomPainter {
  final VowelTarget target;

  const FingertipHintPainter(this.target);

  @override
  void paint(Canvas canvas, Size size) {
    final path = target.pathForSize(size);
    canvas.drawPath(
      path,
      Paint()..color = AppColors.accentRed.withValues(alpha: 0.6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accentRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(FingertipHintPainter oldDelegate) =>
      oldDelegate.target != target;
}
