import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../providers/number_line_provider.dart';

class NumberLineGameScreen extends StatefulWidget {
  final String locale;

  const NumberLineGameScreen({super.key, this.locale = 'en'});

  @override
  State<NumberLineGameScreen> createState() => _NumberLineGameScreenState();
}

class _NumberLineGameScreenState extends State<NumberLineGameScreen> {
  bool _isAnimating = false;

  /// How many counters have moved onto the number line so far this
  /// animation — or, on counting levels, how many positions have been
  /// counted along it.
  int _fillProgress = 0;

  /// The answer the player tapped (used to decide correct/wrong after anim).
  int? _animatingAnswer;

  NumberLineGameProvider? _provider;
  int _lastAudioRound = -1;
  int _lastAudioLevel = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NumberLineGameProvider>();
    if (_provider != provider) {
      _provider?.removeListener(_onProviderChanged);
      _provider = provider;
      _provider!.addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    final provider = _provider;
    if (provider == null) return;
    if (provider.showLevelSelect) return;
    if (provider.state == NumberLineGameState.won) return;
    if (provider.roundNumber == _lastAudioRound &&
        provider.levelNumber == _lastAudioLevel) {
      return;
    }

    _lastAudioRound = provider.roundNumber;
    _lastAudioLevel = provider.levelNumber;
    _playQuestionAudio(provider.currentLevel);
  }

  Future<void> _playQuestionAudio(NumberLineLevel level) async {
    if (level.countCakes) {
      await AudioService.speakWithMp3(
        '',
        mp3Path: 'number_line_how_many_cakes_do_you_see.mp3',
        locale: widget.locale,
      );
      return;
    }
    final numberFile = 'general_${level.targetNumber}.mp3';
    await AudioService.speakSequentialMp3s(
      'number_line_how_many_cakes_do_we_need_to_make.mp3',
      numberFile,
      leadMs: 240,
      locale: widget.locale,
    );
  }

  // ── Answer handling ──────────────────────────────────────────────────────────

  void _onAnswerTapped(int answer, NumberLineGameProvider provider) {
    if (_isAnimating) return;

    // If wrong, mark it in the provider immediately so _triedWrong is set.
    if (answer != provider.correctAnswer) {
      provider.selectAnswer(answer);
    }

    setState(() {
      _isAnimating = true;
      _fillProgress = 0;
      _animatingAnswer = answer;
    });

    if (provider.currentLevel.countCakes) {
      _fillNextSlot(1, answer, provider);
    } else {
      _countOnFrom(answer, provider);
    }
  }

  /// Make-N levels: say how many cakes are already on the line, pause,
  /// then count on as the new cakes are added.
  Future<void> _countOnFrom(int answer, NumberLineGameProvider provider) async {
    // Capped because completion events never fire on Android (SoundPool),
    // which would otherwise stall here for AudioService's 30 s timeout.
    await AudioService.playSpeechMp3('${provider.circleCount}',
            locale: widget.locale)
        .timeout(const Duration(milliseconds: 1500), onTimeout: () {});
    if (!mounted) return;
    _fillNextSlot(1, answer, provider,
        delay: const Duration(milliseconds: 600));
  }

  void _fillNextSlot(int next, int total, NumberLineGameProvider provider,
      {Duration delay = const Duration(milliseconds: 900)}) {
    Future.delayed(delay, () {
      if (!mounted) return;
      setState(() => _fillProgress = next);

      // A cake is off the line when it would overflow past the target
      // number. Counting levels add no cakes — they count along the line.
      final isOffLine = !provider.currentLevel.countCakes &&
          provider.circleCount + next > provider.currentLevel.targetNumber;
      if (isOffLine) {
        // 1200 ms matches the off-line drop animation duration in _NumberLineWidget.
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          AudioService.playMp3('number_line/cake_drop.mp3').ignore();
        });
      } else {
        // Make-N levels count on from the cakes already on the line (e.g.
        // 2 cakes showing → "3, 4, 5…"); counting levels count from 1.
        final spoken = provider.currentLevel.countCakes
            ? next
            : provider.circleCount + next;
        // playSpeechMp3 adds the 'general_' prefix itself → general_<n>.mp3.
        AudioService.playSpeechMp3('$spoken', locale: widget.locale).ignore();
      }

      if (next < total) {
        _fillNextSlot(next + 1, total, provider);
      } else {
        // All counters placed — wait then play feedback sound and advance.
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          final answer = _animatingAnswer!;
          final correct = provider.correctAnswer;
          if (answer == correct) {
            AudioService.playCorrect('number_line_game');
          } else if (answer > correct) {
            AudioService.speakWithMp3('', mp3Path: 'general_oops.mp3', locale: widget.locale).ignore();
          } else {
            AudioService.speakWithMp3('', mp3Path: 'number_line_we_need_more.mp3', locale: widget.locale).ignore();
          }

          Future.delayed(const Duration(milliseconds: 3000), () {
            if (!mounted) return;
            setState(() {
              _isAnimating = false;
              _fillProgress = 0;
              _animatingAnswer = null;
            });
            // Advance — selectAnswer handles scoring if not already wrong.
            provider.selectAnswer(provider.correctAnswer);
          });
        });
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Consumer<NumberLineGameProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('number_line.title'),
                  onBack: () => Navigator.of(context).pop(),
                )
              : null,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/backgrounds/felt-background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: provider.showLevelSelect
                      ? _buildLevelSelect(context, provider, localizer)
                      : _buildGame(context, provider, localizer),
                ),
                if (!provider.showLevelSelect &&
                    provider.state == NumberLineGameState.won)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'number_line_game',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () =>
                          provider.startGame(provider.levelNumber - 1),
                      onNextLevel:
                          provider.levelNumber < numberLineLevels.length
                              ? () => provider.startGame(provider.levelNumber)
                              : null,
                      onChangeLevel: () => provider.showLevelSelection(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Level select ─────────────────────────────────────────────────────────────

  Widget _buildLevelSelect(
      BuildContext context, NumberLineGameProvider provider, AppLocalizations localizer) {
    return LevelSelectScreen(
      subtitle: localizer('number_line.subtitle'),
      locale: localizer.locale,
      levels: List.generate(numberLineLevels.length, (i) {
        final level = numberLineLevels[i];
        return LevelSelectItem(
          number: level.number,
          name: localizer(level.name),
          color: levelColor(i),
          onTap: () {
            provider.startGame(i);
            //AudioService.playIntro('number_line_game'); //commented out  because instructions are duplicated in game. safe to remove
          },
        );
      }),
    );
  }

  // ── Game layout ──────────────────────────────────────────────────────────────

  Widget _buildGame(BuildContext context, NumberLineGameProvider provider,
      AppLocalizations localizer) {
    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showLevelSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.levelNumber,
          centerContent: Center(
            child: Text(
              '${localizer('number_line.round_label')} ${provider.roundNumber} '
              '${localizer('number_line.of_label')} ${provider.currentLevel.totalRounds}',
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Header illustration — full width in portrait, but sized to the
        // available height (not the full width) in landscape so it doesn't
        // push the question/answers off screen.
        Builder(builder: (context) {
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          final image = ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 503 / 345,
              child: Image.asset(
                'assets/images/make10_number_line/make10-screen.jpg',
                fit: BoxFit.cover,
              ),
            ),
          );
          if (isLandscape) {
            return Center(
              child: SizedBox(height: 110, child: image),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge),
            child: image,
          );
        }),

        const SizedBox(height: 16),

        // Question + number line + pool circles — all in one container
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _styledContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentLevel.countCakes
                      ? localizer('number_line.question_count')
                      : localizer('number_line.question').replaceAll(
                          '{n}', '${provider.currentLevel.targetNumber}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _NumberLineWidget(
                    originalCount: provider.circleCount,
                    filledCount: provider.currentLevel.countCakes
                        ? 0
                        : _fillProgress,
                    countedCount: provider.currentLevel.countCakes
                        ? _fillProgress
                        : 0,
                    divisions: provider.currentLevel.targetNumber + 1,
                    roundKey: '${provider.levelNumber}_${provider.roundNumber}',
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Answer buttons — square, side by side, leaving the vertical space
        // the old portrait stack took for the bigger BSL symbols. Capped at
        // 260 so the squares stay reasonable on wide screens.
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: _NumberAnswerButton(
                    n: provider.answerOptions[0],
                    disabled: _isAnimating,
                    showBslOnly: provider.currentLevel.showBslOnly,
                    onTap: () =>
                        _onAnswerTapped(provider.answerOptions[0], provider),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingSmall),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: _NumberAnswerButton(
                    n: provider.answerOptions[1],
                    disabled: _isAnimating,
                    showBslOnly: provider.currentLevel.showBslOnly,
                    onTap: () =>
                        _onAnswerTapped(provider.answerOptions[1], provider),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.spacingLarge),
      ],
    );
  }

  // ── Shared styled container (matches bubble_pop play area) ──────────────────

  Widget _styledContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.headerBackgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.headerBorderDark,
          width: 2,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.accentWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.headerBorderDark,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ── Number line widget ────────────────────────────────────────────────────────

class _NumberLineWidget extends StatelessWidget {
  final int originalCount;
  final int filledCount;

  /// Counting levels: how many positions have been counted so far. Each
  /// counted cake gives a little hop and each counted number turns
  /// [_countedColour] — including numbers past the last cake, so an
  /// over-count shows where it went too far.
  final int countedCount;
  final int divisions;
  final String roundKey;

  const _NumberLineWidget({
    required this.originalCount,
    required this.filledCount,
    required this.roundKey,
    this.countedCount = 0,
    this.divisions = 10,
  });

  static const Color _countedColour = AppColors.abiPink;

  // Per-pile-slot: x-drift, extra-y, rotation angle (radians).
  // Index 0 = first cake to fall, index 1 = second, etc.
  static const _pileX      = <double>[ 0.0, -14.0,  12.0,  -7.0,   9.0];
  static const _pileY      = <double>[ 0.0,   3.0,   1.0,   5.0,   2.0];
  static const _pileAngle  = <double>[
    pi, pi * 0.8, pi * 1.15, pi * 0.9, pi * 1.1,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cellWidth = w / divisions;

        // Scale cakes to fit the cell width — larger on level 1 (6 cells),
        // smaller on levels 2/3 (11 cells) so they don't overlap.
        final circleRadius = (cellWidth * 0.46).clamp(12.0, 16.0);
        const double lineY = 56.0;
        const double tickExtendAbove = 6.0;
        const double tickExtendBelow = 8.0;
        const double numberY       = lineY + tickExtendBelow + 4.0;
        const double totalHeight   = numberY + 24.0;
        const double dropDistance  = 80.0;

        final totalOnLine = originalCount + filledCount;
        final widgets = <Widget>[];

        // Horizontal line — one cell shorter to leave a drop-off zone at the end.
        widgets.add(Positioned(
          left: cellWidth * 0.5,
          width: cellWidth * (divisions - 2).toDouble(),
          top: lineY,
          child: Container(height: 3, color: Colors.black87),
        ));

        // Tick marks and number labels for on-line positions only.
        for (int i = 0; i < divisions - 1; i++) {
          final cx = cellWidth * (i + 0.5);
          widgets.add(Positioned(
            left: cx - 1.5,
            top: lineY - tickExtendAbove,
            child: Container(
              width: 3,
              height: tickExtendAbove + tickExtendBelow,
              color: Colors.black87,
            ),
          ));
          widgets.add(Positioned(
            left: cx - cellWidth * 0.45,
            top: numberY,
            width: cellWidth * 0.9,
            child: Text(
              '${i + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 15,
                fontWeight: i < countedCount ? FontWeight.w800 : FontWeight.w600,
                color: i < countedCount ? _countedColour : Colors.black87,
              ),
            ),
          ));
        }

        // Cakes — extend beyond divisions to show all overflow cakes.
        final cakeTop = lineY - tickExtendAbove - circleRadius * 2 - 4;
        // All off-line cakes share the same starting x (the tip of the line).
        final offLineCx = cellWidth * (divisions - 0.5);

        for (int i = 0; i < totalOnLine; i++) {
          final isOriginal = i < originalCount;
          final isOffLine  = i >= divisions - 1;

          final imageWidget = SizedBox(
            width: circleRadius * 2,
            height: circleRadius * 2,
            child: Image.asset(
              isOriginal
                  ? 'assets/images/make10_number_line/cacen-melyn.png'
                  : 'assets/images/make10_number_line/cacen-pinc.png',
              fit: BoxFit.contain,
            ),
          );

          if (isOffLine) {
            final offIdx = (i - (divisions - 1)).clamp(0, _pileX.length - 1);
            final dx    = _pileX[offIdx];
            final dy    = _pileY[offIdx];
            final angle = _pileAngle[offIdx];

            widgets.add(Positioned(
              left: offLineCx - circleRadius,
              top: cakeTop,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('offLine_${roundKey}_$i'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                builder: (_, t, _) {
                  final scale = Curves.easeOutBack
                      .transform((t / 0.25).clamp(0.0, 1.0));
                  final dropProgress = Curves.easeIn
                      .transform(((t - 0.35) / 0.65).clamp(0.0, 1.0));
                  return Transform.translate(
                    offset: Offset(
                      dx * dropProgress,
                      dropProgress * (dropDistance + dy),
                    ),
                    child: Transform.rotate(
                      angle: dropProgress * angle,
                      child: Transform.scale(
                        scale: scale,
                        child: imageWidget,
                      ),
                    ),
                  );
                },
              ),
            ));
          } else {
            final cx = cellWidth * (i + 0.5);
            widgets.add(Positioned(
              left: cx - circleRadius,
              top: cakeTop,
              child: isOriginal && i < countedCount
                  // Counted: a quick hop, keyed so it plays once per count.
                  ? TweenAnimationBuilder<double>(
                      key: ValueKey('counted_${roundKey}_$i'),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      builder: (_, t, child) => Transform.translate(
                        offset: Offset(0, -10 * sin(t * pi)),
                        child: child,
                      ),
                      child: imageWidget,
                    )
                  : isOriginal
                  ? imageWidget
                  : TweenAnimationBuilder<double>(
                      key: ValueKey('filled_${roundKey}_$i'),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: imageWidget,
                    ),
            ));
          }
        }

        // Clip.none lets falling cakes overflow below the widget's bounds.
        return ClipRect(
          clipBehavior: Clip.none,
          child: SizedBox(
            height: totalHeight,
            child: Stack(children: widgets),
          ),
        );
      },
    );
  }
}

// ── Answer button ─────────────────────────────────────────────────────────────

/// One answer: a square button in the app's nested double-frame design —
/// a light purple outer frame around a dark purple inner field — holding
/// the BSL number sign inside a light purple sign box. The sign scales to
/// fill the box vertically with no padding, and the numeral is printed
/// below, centred. On [showBslOnly] levels the numeral is hidden and the
/// sign must be read alone.
class _NumberAnswerButton extends StatelessWidget {
  final int n;
  final bool disabled;
  final bool showBslOnly;
  final VoidCallback onTap;

  /// Base height of the BSL number sign before [BoxFit.contain] scales it
  /// to fill the square button — larger buttons render proportionally
  /// larger signs. The sign art is square, so it fills the white box
  /// edge to edge.
  static const double _bslSignHeight = 120.0;

  /// Light purple for the outer frame's ring and the sign box border, so
  /// the nested frames read as two distinct frames against the dark
  /// purple field (mirroring the light-ring-around-saturated-field effect
  /// of the app's header container pair).
  static const Color _frameLight = Color(0xFFBA68C8);

  /// The BSL sign for [n], rendered from the PNG number-sign art in
  /// assets/bsl_numbers_png. The two-handed "10" is composed from its
  /// left and right hand images.
  static Widget _bslSign(int n, {required double height}) {
    if (n == 10) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AssetPaths.bslNumber10LeftPng, height: height),
          const SizedBox(width: 4),
          Image.asset(AssetPaths.bslNumber10RightPng, height: height),
        ],
      );
    }
    return Image.asset(AssetPaths.bslNumberPng(n), height: height);
  }

  const _NumberAnswerButton({
    required this.n,
    required this.onTap,
    this.disabled = false,
    this.showBslOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              // Square: the Row gives the button its width; this matches
              // the height to it.
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                // ── Outer frame ── light purple, so the 2px padding ring
                // between the two frames reads as its own frame layer.
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _frameLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.bslPurpleOutline,
                    width: 2,
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  // ── Inner frame — dark purple field, 0 padding ──
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: AppColors.bslPurple,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.bslPurpleOutline,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    // ── Sign box ── light purple border; the 2px margin
                    // keeps it inside the inner frame's own border so the
                    // double frame stays visible. No `alignment` here on
                    // purpose: alignment would hand the FittedBox loose
                    // constraints, letting it collapse-wrap the sign at
                    // its base 120px — with tight fill constraints,
                    // BoxFit.contain scales the sign up to fill the box.
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _frameLight, width: 2),
                    ),
                    child: FittedBox(
                      // Contain: the sign grows to fill the square
                      // vertically, and still shrinks when a wide sign
                      // (the two-handed "10") needs the width.
                      fit: BoxFit.contain,
                      child: _bslSign(n, height: _bslSignHeight),
                    ),
                  ),
                ),
              ),
            ),
            // The numeral sits below the button, centred — hidden on
            // BSL-only levels, where the sign must be read alone.
            if (!showBslOnly) ...[
              const SizedBox(height: AppSizes.spacingSmall),
              Text(
                '$n',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: AppSizes.fontSizeHeading,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
