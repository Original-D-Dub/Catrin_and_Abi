import 'package:flutter/material.dart';

/// The zoo's "Take a Picture" button: `assets/icons/Camera.png` pinned to
/// the bottom right of the screen. Pulses its size once when it first
/// appears (the player enters an enclosure/zone) to draw the eye to it.
///
/// Sized 56px wide on phones and 80px wide on tablets (width > 600px).
class ZooCameraButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const ZooCameraButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  /// Width/height breakpoint: screens wider than this use the tablet size.
  static const double _tabletBreakpoint = 600;
  static const double _phoneSize = 56;
  static const double _tabletSize = 80;

  @override
  State<ZooCameraButton> createState() => _ZooCameraButtonState();
}

class _ZooCameraButtonState extends State<ZooCameraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet =
        MediaQuery.of(context).size.width > ZooCameraButton._tabletBreakpoint;
    final size =
        isTablet ? ZooCameraButton._tabletSize : ZooCameraButton._phoneSize;

    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onPressed,
          child: Tooltip(
            message: widget.tooltip,
            child: Image.asset(
              'assets/icons/Camera.png',
              width: size,
              height: size,
            ),
          ),
        ),
      ),
    );
  }
}
