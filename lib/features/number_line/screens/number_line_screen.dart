import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  const NumberLineGameScreen({super.key});

  @override
  State<NumberLineGameScreen> createState() => _NumberLineGameScreenState();
}

class _NumberLineGameScreenState extends State<NumberLineGameScreen> {
  bool _isAnimating = false;

  /// How many counters have moved onto the number line so far this animation.
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
    _playQuestionAudio(provider.levelNumber);
  }

  Future<void> _playQuestionAudio(int levelNumber) async {
    final numberFile = levelNumber == 1 ? 'general_5.mp3' : 'general_10.mp3';
    await AudioService.speakSequentialMp3s(
      'number_line_how_many_cakes_do_we_need_to_make.mp3',
      numberFile,
      leadMs: 240,
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

    _fillNextSlot(1, answer, provider);
  }

  void _fillNextSlot(int next, int total, NumberLineGameProvider provider) {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _fillProgress = next);

      // A cake is off the line when it would overflow past the target number.
      final isOffLine = provider.circleCount + next > provider.currentLevel.targetNumber;
      if (isOffLine) {
        // 1200 ms matches the off-line drop animation duration in _NumberLineWidget.
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          AudioService.playMp3('number_line/cake_drop.mp3').ignore();
        });
      } else {
        AudioService.playSpeechMp3('$next').ignore();
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
            AudioService.speakWithMp3('', mp3Path: 'general_oops.mp3').ignore();
          } else {
            AudioService.speakWithMp3('', mp3Path: 'number_line_we_need_more.mp3').ignore();
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
    final localizer = AppLocalizations(locale: 'en');
    return Consumer<NumberLineGameProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: 'Number Line',
                  onBack: () => Navigator.of(context).pop(),
                )
              : null,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/backgrounds/math-background-1080x1920.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: provider.showLevelSelect
                      ? _buildLevelSelect(context, provider, localizer)
                      : _buildGame(context, provider),
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

  Widget _buildGame(BuildContext context, NumberLineGameProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showLevelSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.levelNumber,
          centerContent: Center(
            child: Text(
              'Round ${provider.roundNumber} of ${provider.currentLevel.totalRounds}',
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

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
                  'How many cakes do we need to make ${provider.currentLevel.targetNumber}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _NumberLineWidget(
                    originalCount: provider.circleCount,
                    filledCount: _fillProgress,
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

        // Answer buttons — side by side in landscape, stacked in portrait.
        Builder(builder: (context) {
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          final buttons = [
            _NumberAnswerButton(
              n: provider.answerOptions[0],
              disabled: _isAnimating,
              showBslOnly: provider.currentLevel.showBslOnly,
              onTap: () => _onAnswerTapped(provider.answerOptions[0], provider),
            ),
            _NumberAnswerButton(
              n: provider.answerOptions[1],
              disabled: _isAnimating,
              showBslOnly: provider.currentLevel.showBslOnly,
              onTap: () => _onAnswerTapped(provider.answerOptions[1], provider),
            ),
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge),
            child: isLandscape
                ? Row(
                    children: [
                      Expanded(child: buttons[0]),
                      const SizedBox(width: AppSizes.spacingSmall),
                      Expanded(child: buttons[1]),
                    ],
                  )
                : Column(
                    children: [
                      buttons[0],
                      const SizedBox(height: AppSizes.spacingSmall),
                      buttons[1],
                    ],
                  ),
          );
        }),

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
  final int divisions;
  final String roundKey;

  const _NumberLineWidget({
    required this.originalCount,
    required this.filledCount,
    required this.roundKey,
    this.divisions = 10,
  });

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
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
                  : 'assets/images/make10_number_line/cacen-siocled.png',
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
              child: isOriginal
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

class _NumberAnswerButton extends StatelessWidget {
  final int n;
  final bool disabled;
  final bool showBslOnly;
  final VoidCallback onTap;

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
        child: Container(
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingMedium,
              vertical: AppSizes.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.headerBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.headerBorderDark,
                width: 2,
              ),
            ),
            child: showBslOnly
                ? SvgPicture.asset(
                    AssetPaths.bslNumber(n),
                    height: 56,
                    fit: BoxFit.contain,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$n',
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: AppSizes.fontSizeHeading,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingMedium),
                      SvgPicture.asset(
                        AssetPaths.bslNumber(n),
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
