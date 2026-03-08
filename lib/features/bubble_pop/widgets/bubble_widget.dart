import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A floating bubble widget with a letter inside.
///
/// Displays a colorful bubble that can be tapped. When tapped,
/// it triggers a pop animation before disappearing.
///
/// Usage:
/// ```dart
/// BubbleWidget(
///   letter: 'a',
///   color: Colors.red,
///   onTap: () => handleBubbleTap(),
///   isPopping: false,
/// )
/// ```
class BubbleWidget extends StatefulWidget {
  /// The letter displayed inside the bubble
  final String letter;

  /// The bubble's color
  final Color color;

  /// Callback when bubble is tapped
  final VoidCallback onTap;

  /// Whether the bubble is currently in pop animation
  final bool isPopping;

  /// Size of the bubble
  final double size;

  const BubbleWidget({
    super.key,
    required this.letter,
    required this.color,
    required this.onTap,
    this.isPopping = false,
    this.size = BubbleSizes.defaultSize,
  });

  @override
  State<BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget>
    with SingleTickerProviderStateMixin {
  /// Animation controller for the pop effect
  late AnimationController _popController;

  /// Scale animation for the pop effect
  late Animation<double> _scaleAnimation;

  /// Opacity animation for fade out
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  /// Sets up the pop animation controller and animations.
  void _setupAnimations() {
    _popController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Scale up then down for pop effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOut,
    ));

    // Fade out during pop
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _popController,
      curve: const Interval(0.5, 1.0),
    ));
  }

  @override
  void didUpdateWidget(BubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger pop animation and haptic feedback when isPopping changes to true
    if (widget.isPopping && !oldWidget.isPopping) {
      HapticFeedback.lightImpact();
      _popController.forward();
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _popController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPopping ? _scaleAnimation.value : 1.0,
          child: Opacity(
            opacity: widget.isPopping ? _opacityAnimation.value : 1.0,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: 0.9,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [
                    _lightenColor(widget.color, 0.4),
                    widget.color,
                    _darkenColor(widget.color, 0.2),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.letter.toLowerCase(),
                  style: TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: widget.size * 0.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Lightens a color by the given amount (0.0 to 1.0).
  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Darkens a color by the given amount (0.0 to 1.0).
  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Bubble size constants for the game.
class BubbleSizes {
  BubbleSizes._();

  /// Default bubble diameter (10% larger than original 70.0)
  static const double defaultSize = 70;

  /// Small bubble for dense layouts (10% larger than original 55.0)
  static const double smallSize = 60.5;

  /// Large bubble for emphasis (10% larger than original 85.0)
  static const double largeSize = 93.5;
}
