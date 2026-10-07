import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Full-screen celebratory banner shown the first time the player scores
/// enough on the Competition level to unlock Champion Mode.
///
/// Styled to match [GameSuccessOverlay]'s personal-best badge: a thick
/// coloured stroke + solid fill heading, double-pulsing every 3 seconds.
/// The padlock icon animates from closed to open once, on entry. Tap
/// anywhere to dismiss.
class ChampionModeUnlockedBanner extends StatefulWidget {
  final String locale;
  final VoidCallback onDismiss;

  const ChampionModeUnlockedBanner({
    super.key,
    required this.locale,
    required this.onDismiss,
  });

  @override
  State<ChampionModeUnlockedBanner> createState() =>
      _ChampionModeUnlockedBannerState();
}

class _ChampionModeUnlockedBannerState
    extends State<ChampionModeUnlockedBanner> with TickerProviderStateMixin {
  static const Color _gold = Color(0xFFFFC73A);
  static const Color _orange = Color(0xFFFF6F00);

  late final AnimationController _lockController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // One-shot: padlock crossfades from closed to open, with a small pop
    // as the open icon settles in.
    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    // Double pulse (two quick beats) every 3 s, then hold flat until the
    // next cycle — same TweenSequence as GameSuccessOverlay's personal-best
    // celebration.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 200,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 200,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 200,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 200,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 2200),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _lockController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    final text = localizer('bsl_maths.champion_mode.unlocked_banner');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPadlock(),
              const SizedBox(height: AppSizes.spacingMedium),
              ScaleTransition(
                scale: _pulseAnimation,
                child: _buildHeading(text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Crossfades a closed padlock into an open one, with the open icon
  /// popping in slightly (scale 0.8 → 1.0) as it fades in.
  Widget _buildPadlock() {
    return AnimatedBuilder(
      animation: _lockController,
      builder: (context, child) {
        final t = _lockController.value;
        return SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - t,
                child: const Icon(Icons.lock, color: _gold, size: 72),
              ),
              Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * t,
                  child: const Icon(Icons.lock_open, color: _gold, size: 72),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// "Maths Champion Mode / Unlocked!" heading — same stroke-behind-fill
  /// layering as the "Well Done!" heading and personal-best badge.
  Widget _buildHeading(String text) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTheme.celebrationAt(AppSizes.fontSizeLarge * 1.3).copyWith(
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = _orange,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTheme.celebrationAt(AppSizes.fontSizeLarge * 1.3).copyWith(
            fontWeight: FontWeight.bold,
            color: _gold,
          ),
        ),
      ],
    );
  }
}
