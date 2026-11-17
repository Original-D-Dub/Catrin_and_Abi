import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import 'bubble_widget.dart';

/// Champion Mode "x2 multiplier" text shown in place of the bubble whose
/// pop reached a new multiplier tier.
class MultiplierLabelText extends StatelessWidget {
  final int multiplier;
  final AppLocalizations localizer;

  const MultiplierLabelText({
    super.key,
    required this.multiplier,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'x$multiplier ${localizer('bubble_pop.champion_mode.multiplier')}',
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(
        fontFamily: 'Quicksand',
        fontSize: AppSizes.fontSizeLarge,
        fontWeight: FontWeight.w700,
        color: AppColors.accentLimeGreen,
        shadows: [
          Shadow(color: Colors.white, blurRadius: 4),
          Shadow(color: Colors.white, blurRadius: 8),
        ],
      ),
    );
  }
}

/// Floating "+20" / "-5" that rises and fades out after each Champion Mode
/// pop. [serial] restarts the animation even when [delta] is unchanged.
class ChampionPointsPopup extends StatelessWidget {
  final int delta;
  final int serial;
  final double scale;

  const ChampionPointsPopup({
    super.key,
    required this.delta,
    required this.serial,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(serial),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -30 * scale * t),
            child: child,
          ),
        ),
        child: Text(
          positive ? '+$delta' : '$delta',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 28 * scale,
            fontWeight: FontWeight.w700,
            color: positive ? AppColors.accentLimeGreen : AppColors.accentRed,
            shadows: const [
              Shadow(color: Colors.white, blurRadius: 4),
              Shadow(color: Colors.white, blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Champion Mode demo for the explainer page: a bubble being popped over
/// and over, with the points each pop scores floating up — +10 at first,
/// then ×2, ×5 and ×10 as the streak grows, and finally a wrong pop's -5
/// resetting the streak.
class ChampionScoringDemo extends StatefulWidget {
  final AppLocalizations localizer;

  const ChampionScoringDemo({super.key, required this.localizer});

  @override
  State<ChampionScoringDemo> createState() => _ChampionScoringDemoState();
}

class _ChampionScoringDemoState extends State<ChampionScoringDemo> {
  /// (streak after the pop, points scored, multiplier). The last step is a
  /// wrong pop, which costs 5 and resets the streak.
  static const List<(int streak, int delta, int multiplier)> _steps = [
    (1, 10, 1),
    (5, 20, 2),
    (10, 50, 5),
    (20, 100, 10),
    (0, -5, 1),
  ];

  static const Duration _stepDuration = Duration(milliseconds: 1600);

  Timer? _timer;
  int _serial = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_stepDuration, (_) => setState(() => _serial++));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (streak, delta, multiplier) = _steps[_serial % _steps.length];
    final wrong = delta < 0;

    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 44,
            child: ChampionPointsPopup(delta: delta, serial: _serial),
          ),
          // Bounces on each pop; a wrong pop shows a red bubble.
          TweenAnimationBuilder<double>(
            key: ValueKey(_serial),
            tween: Tween(begin: 1.25, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: BubbleWidget(
              letter: wrong ? 'b' : 'a',
              color: wrong ? AppColors.accentRed : AppColors.accentNavyBlue,
              onTap: () {},
              size: BubbleSizes.defaultSize * 1.2,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          SizedBox(
            height: 40,
            child: multiplier > 1
                ? MultiplierLabelText(
                    multiplier: multiplier,
                    localizer: widget.localizer,
                  )
                : null,
          ),
          Text(
            streak > 0
                ? widget.localizer('bubble_pop.champion_mode.in_a_row')
                    .replaceAll('{n}', '$streak')
                : '',
            style: const TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
