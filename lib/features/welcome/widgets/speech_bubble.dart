import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// A styled speech bubble for character dialogue.
///
/// Features a rounded rectangle with a triangular pointer
/// indicating the speaker direction.
///
/// Usage:
/// ```dart
/// SpeechBubble(
///   text: 'Hello! I am Catrin.',
///   pointDirection: PointDirection.left,
/// )
/// ```
class SpeechBubble extends StatelessWidget {
  /// The text to display in the bubble.
  final String text;

  /// Direction the speech bubble pointer faces.
  /// Indicates where the speaker is positioned.
  final PointDirection pointDirection;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional text color override.
  final Color? textColor;

  const SpeechBubble({
    super.key,
    required this.text,
    this.pointDirection = PointDirection.left,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 160,
        maxWidth: AppSizes.speechBubbleMaxWidth,
      ),
      child: CustomPaint(
        painter: _SpeechBubblePainter(
          color: backgroundColor ?? AppColors.accentWhite,
          pointDirection: pointDirection,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.speechBubblePadding),
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppSizes.fontSizeBody,
              color: textColor ?? AppColors.textPrimary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Direction the speech bubble pointer faces.
enum PointDirection {
  left,
  right,
  bottom,
}

/// Custom painter for the speech bubble shape.
class _SpeechBubblePainter extends CustomPainter {
  final Color color;
  final PointDirection pointDirection;

  _SpeechBubblePainter({
    required this.color,
    required this.pointDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final radius = AppSizes.speechBubbleRadius;
    const pointerSize = 12.0;

    // Draw shadow
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width, size.height),
      Radius.circular(radius),
    );
    canvas.drawRRect(shadowRect, shadowPaint);

    // Draw main bubble
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    canvas.drawRRect(bubbleRect, paint);

    // Draw pointer based on direction
    final path = Path();
    switch (pointDirection) {
      case PointDirection.left:
        final centerY = size.height / 2;
        path.moveTo(0, centerY - pointerSize);
        path.lineTo(-pointerSize, centerY);
        path.lineTo(0, centerY + pointerSize);
        break;
      case PointDirection.right:
        final centerY = size.height / 2;
        path.moveTo(size.width, centerY - pointerSize);
        path.lineTo(size.width + pointerSize, centerY);
        path.lineTo(size.width, centerY + pointerSize);
        break;
      case PointDirection.bottom:
        final centerX = size.width / 2;
        path.moveTo(centerX - pointerSize, size.height);
        path.lineTo(centerX, size.height + pointerSize);
        path.lineTo(centerX + pointerSize, size.height);
        break;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.pointDirection != pointDirection;
  }
}
