import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/button.dart';

/// What a level's introduction shows before its countdown: an instruction,
/// then (optionally) the BSL signs for [numbers] one at a time, each with
/// its digit and spoken number.
class LevelIntroConfig {
  /// Instruction shown at the top; also the name of its audio clip,
  /// `number_race_<name>` (silent if not recorded yet).
  final String name;

  /// Numbers whose signs are shown in turn.
  final List<int> numbers;

  /// How long each sign is shown on the first pass. Fixed — the spoken
  /// number (all clips < 1s) plays alongside but isn't waited on.
  final Duration hold;

  /// When true, [numbers] are shown a second time, each held for
  /// [LevelIntro.slowHold].
  final bool repeatSlowly;

  const LevelIntroConfig(
    this.name, {
    this.numbers = const [],
    this.hold = LevelIntro.normalHold,
    this.repeatSlowly = false,
  });

  static LevelIntroConfig? forLevel(int level) => switch (level) {
    1 => const LevelIntroConfig('level1_intro', numbers: [1, 2, 3, 4, 5]),
    3 => const LevelIntroConfig(
      'level3_intro',
      numbers: [6],
      hold: Duration(seconds: 4),
    ),
    4 => const LevelIntroConfig(
      'level4_intro',
      numbers: [7, 8],
      repeatSlowly: true,
    ),
    6 => const LevelIntroConfig(
      'level6_intro',
      numbers: [9, 10],
      repeatSlowly: true,
    ),
    _ => null,
  };

  String get textKey => 'number_race.$name';
}

/// Full-screen introduction for a level (see [LevelIntroConfig]). Calls
/// [onComplete] once the sequence finishes or the player taps Skip.
class LevelIntro extends StatefulWidget {
  final LevelIntroConfig config;
  final String locale;
  final VoidCallback onComplete;

  const LevelIntro({
    super.key,
    required this.config,
    required this.locale,
    required this.onComplete,
  });

  /// Default for [LevelIntroConfig.hold].
  static const normalHold = Duration(seconds: 1);

  /// How long each sign is shown on the slow repeat.
  static const slowHold = Duration(seconds: 4);

  /// How long an instruction with no signs stays up.
  static const textOnlyHold = Duration(seconds: 3);

  @override
  State<LevelIntro> createState() => _LevelIntroState();
}

class _LevelIntroState extends State<LevelIntro> {
  static const _bgGradient = RadialGradient(
    colors: [Color(0xFF3A6FD1), Color(0xFF041F50)],
    radius: 0.85,
  );

  int? _current;
  bool _cancelled = false;
  bool _done = false;

  bool _isCancelled() => _cancelled || !mounted;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _cancelled = true;
    AudioService.stopAll();
    super.dispose();
  }

  Future<void> _run() async {
    final config = widget.config;
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isCancelled()) return;
    await Future.wait([
      AudioService.playInstructionClipAndWait(
        'number_race',
        config.name,
        locale: widget.locale,
        isCancelled: _isCancelled,
      ),
      Future.delayed(
        config.numbers.isEmpty
            ? LevelIntro.textOnlyHold
            : const Duration(milliseconds: 1000),
      ),
    ]);

    final passes = [
      if (config.numbers.isNotEmpty) config.hold,
      if (config.repeatSlowly) LevelIntro.slowHold,
    ];
    for (final hold in passes) {
      for (final n in config.numbers) {
        if (_isCancelled()) return;
        setState(() => _current = n);
        // Fire-and-forget: FlameAudio plays in low-latency mode, which on
        // Android never fires a completion event, so awaiting the clip
        // stalled each number until playSpeechMp3's 30s timeout. The hold
        // alone sets the pace.
        unawaited(AudioService.playSpeechMp3('$n', locale: widget.locale));
        await Future.delayed(hold);
      }
      if (_isCancelled()) return;
      setState(() => _current = null);
      await Future.delayed(const Duration(milliseconds: 600));
    }
    _finish();
  }

  Future<void> _skip() async {
    _cancelled = true;
    await AudioService.stopAll();
    _finish();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              children: [
                const SizedBox(height: AppSizes.spacingLarge),
                Text(
                  localizer(widget.config.textKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.6, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: _current == null
                          ? const SizedBox.shrink(key: ValueKey('empty'))
                          // Shrinks the wide two-handed 10 to fit narrow screens.
                          : FittedBox(
                              key: ValueKey(_current),
                              fit: BoxFit.scaleDown,
                              child: _SignCard(number: _current!),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TertiaryButton(
                    label: localizer('general.skip'),
                    onPressed: _skip,
                    expanded: true,
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

/// A large BSL number sign with its digit beneath.
class _SignCard extends StatelessWidget {
  final int number;

  const _SignCard({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(color: AppColors.catrinBlue, width: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (number == 10)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AssetPaths.bslNumber10LeftPng, height: 200),
                const SizedBox(width: 8),
                Image.asset(AssetPaths.bslNumber10RightPng, height: 200),
              ],
            )
          else
            Image.asset(AssetPaths.bslNumberPng(number), height: 200),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            '$number',
            style: const TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
