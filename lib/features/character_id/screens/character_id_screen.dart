import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/sign_question_video.dart';
import '../providers/character_id_provider.dart';
import '../models/dressed_character.dart';
import '../widgets/dressed_character_display.dart';
import '../widgets/recoloured_clothing_svg.dart';

/// Main screen for the Character Identification game.
///
/// Displays:
/// - Level selection screen
/// - Level 1: Red, blue and green only, with colour hints (5 to win)
/// - Level 2: All clothing colours with colour hints (10 to win)
/// - Level 3: All clothing colours without colour hints (10 to win)
/// - Level 4: Speed Round - 60 seconds
///
/// The player must answer questions about the character to score points.
class CharacterIdScreen extends StatefulWidget {
  const CharacterIdScreen({super.key});

  @override
  State<CharacterIdScreen> createState() => _CharacterIdScreenState();
}

class _CharacterIdScreenState extends State<CharacterIdScreen> {
  bool _showingIntro = false;

  /// Answer buttons stay hidden until the current question's BSL video has
  /// played once (except in the speed round). Reset whenever a new character
  /// — i.e. a new question — is shown.
  bool _videoPlayedOnce = false;
  DressedCharacter? _videoCharacter;

  /// Answer buttons are drawn at this fraction of the size that fits.
  static const double _answerButtonScale = 0.8;

  /// Answer buttons are never taller than this fraction of the play area
  /// (before [_answerButtonScale] is applied).
  static const double _answerAreaMaxFraction = 2 / 5;

  /// How the space left above the answer buttons is split between the video
  /// and character containers (percent).
  static const int _videoSharePercent = 40;
  static const int _characterSharePercent = 60;

  @override
  void initState() {
    super.initState();
    // Recolour every SVG garment in every colour up front so rounds build
    // their clothing synchronously.
    RecolouredClothingSvg.precache(
      ClothingItem.all.where((c) => c.isSvg).map((c) => c.assetPath).toList(),
      clothingColours,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the image cache so swapping bodies/coat between rounds doesn't flash.
    for (final body in CharacterBody.all) {
      precacheImage(AssetImage(body.assetPath), context);
    }
    for (final item in ClothingItem.all.where((c) => !c.isSvg)) {
      precacheImage(AssetImage(item.assetPath), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CharacterIdProvider(),
      child: Consumer<CharacterIdProvider>(
        builder: (context, provider, child) {
          final localizer = AppLocalizations.of(context);
          provider.onAnswerResult ??= (isCorrect) {
            if (isCorrect) {
              AudioService.playCorrect('character_id');
            } else {
              AudioService.playWrong('character_id');
            }
          };
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: provider.showLevelSelect
                ? GameAppBar(
                    title: 'Character ID',
                    onBack: () => Navigator.pop(context),
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
                        ? _buildBody(context, provider)
                        : Column(
                            children: [
                              const SizedBox(height: 8),
                              GameHeaderBar(
                                onBack: () => provider.showLevelSelection(),
                                scoreValue: '${provider.score}',
                                levelNumber: provider.currentLevel.number,
                                centerContent: provider.isSpeedRound
                                    ? GameTimerDisplay(
                                        formattedTime: _formatTime(
                                          provider.remainingSeconds,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          localizer('character_id.level${provider.currentLevel.number}.name'),
                                          style: const TextStyle(
                                            fontFamily: 'Quicksand',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildBody(context, provider),
                              ),
                            ],
                          ),
                  ),
                  if (_showingIntro)
                    GameIntroCountdown(
                      gameId: 'character_id',
                      levelNumber: provider.currentLevel.number,
                      onComplete: () {
                        setState(() => _showingIntro = false);
                        provider.startSpeedRound();
                      },
                      onBack: () {
                        setState(() => _showingIntro = false);
                        provider.showLevelSelection();
                      },
                    ),
                  if (!provider.showLevelSelect &&
                      provider.gameState == CharacterIdGameState.finished)
                    Positioned.fill(
                      child: GameSuccessOverlay(
                        gameId: 'character_id',
                        scoreStyle: provider.isSpeedRound
                            ? SuccessScoreStyle.youScored
                            : SuccessScoreStyle.custom,
                        customScoreLine: localizer('general.got_n_correct')
                            .replaceAll('{score}', '${provider.score}'),
                        score: provider.score,
                        showPersonalBest: provider.isSpeedRound,
                        isNewPersonalBest:
                            provider.lastResult?.isNewPersonalBest ?? false,
                        personalBest: provider.lastResult?.personalBest,
                        onPlayAgain: () {
                          provider.resetGame();
                          if (provider.isSpeedRound) {
                            setState(() => _showingIntro = true);
                          }
                        },
                        onNextLevel: provider.currentLevel.number <
                                CharacterIdLevel.all.length
                            ? () => provider.selectLevel(
                                provider.currentLevel.number + 1)
                            : null,
                        onChangeLevel: () => provider.showLevelSelection(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Formats seconds as MM:SS.
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }


  /// Builds the main body content.
  Widget _buildBody(BuildContext context, CharacterIdProvider provider) {
    // Show level selection
    if (provider.showLevelSelect) {
      return _buildLevelSelectScreen(context, provider);
    }

    // All levels share the same clothing questions
    return _buildLevel1Content(context, provider);
  }

  /// Builds the level selection screen.
  Widget _buildLevelSelectScreen(
      BuildContext context, CharacterIdProvider provider) {
    final localizer = AppLocalizations.of(context);
    return LevelSelectScreen(
      levels: CharacterIdLevel.all.map((level) {
        return LevelSelectItem(
          number: level.number,
          name: localizer('character_id.level${level.number}.name'),
          // description: localizer('character_id.level${level.number}.description'),
          color: levelColor(level.number - 1),
          onTap: () {
            provider.selectLevel(level.number);
            if (provider.isSpeedRound) {
              setState(() => _showingIntro = true);
            }
            AudioService.playIntro('character_id');
          },
        );
      }).toList(),
    );
  }

  /// Builds the round content: the BSL question video and the character
  /// (stacked in portrait, side by side in landscape) above the answer
  /// buttons. The gap between video and character equals the gap between
  /// character and buttons; the video and character split the remaining
  /// space by [_videoSharePercent] / [_characterSharePercent].
  Widget _buildLevel1Content(
      BuildContext context, CharacterIdProvider provider) {
    final character = provider.currentCharacter;
    if (character == null) {
      return const Center(
        child: Text('No characters available'),
      );
    }

    if (!identical(character, _videoCharacter)) {
      _videoCharacter = character;
      _videoPlayedOnce = false;
    }
    final answersVisible = _videoPlayedOnce || provider.isSpeedRound;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final isCompact = constraints.maxHeight < 500;
        final padding =
            isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium;

        final video = Semantics(
          label: provider.currentQuestion,
          // Push the video against the character so any slack from its 4:3
          // shape doesn't widen the gap between them.
          child: Align(
            alignment:
                isLandscape ? Alignment.centerRight : Alignment.bottomCenter,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: SignQuestionVideo(
                key: ValueKey(character),
                videoAssetPath: provider.questionItem?.videoAssetPath,
                onPlayedOnce: () {
                  if (mounted) setState(() => _videoPlayedOnce = true);
                },
              ),
            ),
          ),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  Expanded(
                    child: Flex(
                      direction:
                          isLandscape ? Axis.horizontal : Axis.vertical,
                      children: [
                        Expanded(flex: _videoSharePercent, child: video),
                        SizedBox(width: padding, height: padding),
                        Expanded(
                          flex: _characterSharePercent,
                          child: DressedCharacterDisplay(character: character),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: padding),
                  AnimatedOpacity(
                    opacity: answersVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !answersVisible,
                      child: _buildColorChoiceButtons(
                        provider,
                        maxSize: constraints.maxHeight * _answerAreaMaxFraction -
                            padding * 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _FeedbackOverlay(gameState: provider.gameState),
          ],
        );
      },
    );
  }

  /// Builds the color choice buttons for all levels.
  ///
  /// Narrow screens (<600 px): 2 buttons (1 correct + 1 wrong), 2-column layout.
  /// Wide screens (≥600 px): 3 buttons, 3-column layout.
  ///
  /// Buttons are square, [_answerButtonScale] of the largest size that fits
  /// the width and [maxSize].
  Widget _buildColorChoiceButtons(
    CharacterIdProvider provider, {
    required double maxSize,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final choices = isNarrow
            ? _twoChoices(provider)
            : provider.answerChoices;
        final isDisabled = provider.gameState != CharacterIdGameState.playing;
        final showColourHint = provider.showsColourHints;

        // Square buttons scaled down from the largest size that fits.
        const gap = AppSizes.spacingMedium;
        final fitSize = math.min(
          (constraints.maxWidth - gap * (choices.length - 1)) / choices.length,
          maxSize,
        );
        final buttonSize = fitSize * _answerButtonScale;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < choices.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox.square(
                dimension: buttonSize,
                child: _buildColorButton(
                  colorName: choices[i],
                  isSelected: provider.selectedAnswer == choices[i],
                  isCorrect: provider.gameState == CharacterIdGameState.correct &&
                      provider.selectedAnswer == choices[i],
                  isWrong: provider.gameState == CharacterIdGameState.wrong &&
                      provider.selectedAnswer == choices[i],
                  isDisabled: isDisabled,
                  showColourHint: showColourHint,
                  onPressed: () => provider.selectLevel1Answer(choices[i]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Returns 2 choices (the correct answer + one wrong) in their original
  /// shuffled order, so the correct position is still random.
  List<String> _twoChoices(CharacterIdProvider provider) {
    final choices = provider.answerChoices;
    if (choices.length <= 2) return choices;
    final correct = provider.correctAnswer;
    final result = <String>[];
    bool wrongAdded = false;
    for (final c in choices) {
      if (c == correct) {
        result.add(c);
      } else if (!wrongAdded) {
        result.add(c);
        wrongAdded = true;
      }
      if (result.length == 2) break;
    }
    return result;
  }

  /// Builds a single color choice button with BSL image.
  ///
  /// When [showColourHint] is true (Levels 1 and 2), shows colour-coded
  /// background and border. When false (Levels 3 and 4), shows neutral styling.
  Widget _buildColorButton({
    required String colorName,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required bool isDisabled,
    required bool showColourHint,
    required VoidCallback onPressed,
  }) {
    Color backgroundColor;
    Color borderColor;

    if (isCorrect) {
      backgroundColor = AppColors.success;
      borderColor = AppColors.success;
    } else if (isWrong) {
      backgroundColor = AppColors.accentRed;
      borderColor = AppColors.accentRed;
    } else if (showColourHint) {
      final buttonColor = _getColorFromName(colorName);
      backgroundColor = buttonColor;
      borderColor = buttonColor;
    } else {
      backgroundColor = Colors.white.withValues(alpha: 0.5);
      borderColor = AppColors.catrinBlue.withValues(alpha: 0.5);
    }

    // Hinted levels have padding, the others have no padding with cover fit
    final buttonPadding = showColourHint
        ? const EdgeInsets.all(AppSizes.paddingSmall)
        : EdgeInsets.zero;

    // Scale up when correct or wrong to provide visual feedback without layout shift
    final scale = (isCorrect || isWrong) ? 1.1 : 1.0;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: buttonPadding,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: isDisabled && !isSelected ? 0.5 : 1.0,
            child: _BslColourRiveWidget(key: ValueKey(colorName.toLowerCase()), colourName: colorName.toLowerCase()),
          ),
        ),
      ),
    );
  }

  /// Converts a color name to a Color object.
  Color _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'pink':
        return AppColors.lightPink;
      case 'blue':
        return Colors.blue;
      case 'navy':
        return const Color(0xFF000080);
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'brown':
        return Colors.brown;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey.shade300;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return AppColors.catrinBlue;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BSL colour Rive widget
// ─────────────────────────────────────────────────────────────────────────────

/// Displays a BSL colour sign from a Rive file and re-triggers the animation
/// every 6 seconds so the sign replays periodically.
///
/// ## Rive spec
/// - File:          `assets/images/colours_BSL/{colourName}.riv`
/// - Artboard:      `{colourName}` (e.g. `green`, `blue`, `pink`, `purple`)
/// - State machine: `{colourName}_state_machine`
/// - Trigger input: `play_{colourName}`
class _BslColourRiveWidget extends StatefulWidget {
  const _BslColourRiveWidget({super.key, required this.colourName});

  final String colourName;

  @override
  State<_BslColourRiveWidget> createState() => _BslColourRiveWidgetState();
}

class _BslColourRiveWidgetState extends State<_BslColourRiveWidget> {
  late final FileLoader _fileLoader;
  ViewModelInstanceTrigger? _vmTrigger;
  TriggerInput? _playTrigger;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/images/colours_BSL/${widget.colourName}.riv',
      riveFactory: Factory.flutter,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fileLoader.dispose();
    super.dispose();
  }

  void _onLoaded(RiveLoaded state) {
    // Updated .riv files (e.g. green) expose the trigger via a view model;
    // the rest still use the deprecated state machine input.
    _vmTrigger =
        state.viewModelInstance?.trigger('play_${widget.colourName}');
    if (_vmTrigger == null) {
      _playTrigger = state.controller.stateMachine
          // ignore: deprecated_member_use
          .trigger('play_${widget.colourName}');
    }
    _triggerAnimation();
    _timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _triggerAnimation(),
    );
  }

  void _triggerAnimation() {
    if (_vmTrigger != null) {
      _vmTrigger!.trigger();
    } else {
      _playTrigger?.fire();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: _fileLoader,
      artboardSelector: ArtboardSelector.byName(widget.colourName),
      stateMachineSelector: StateMachineSelector.byName(
          '${widget.colourName}_state_machine'),
      dataBind: const AutoBind(),
      onLoaded: _onLoaded,
      builder: (context, state) => switch (state) {
        RiveLoading() => const SizedBox.shrink(),
        RiveFailed() => const SizedBox.shrink(),
        RiveLoaded() => RiveWidget(
            controller: state.controller,
            fit: Fit.contain,
          ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback overlay
// ─────────────────────────────────────────────────────────────────────────────

/// Centred pill overlay that shows "Correct!" or "Try again!" for 3.5 seconds
/// whenever the game transitions into a correct or wrong state.
///
/// Uses [IgnorePointer] so it never blocks taps on the buttons beneath it,
/// and [AnimatedOpacity] for a smooth fade-out.
class _FeedbackOverlay extends StatefulWidget {
  const _FeedbackOverlay({required this.gameState});

  final CharacterIdGameState gameState;

  @override
  State<_FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<_FeedbackOverlay> {
  bool _visible = false;
  bool _isCorrect = false;
  Timer? _hideTimer;

  @override
  void didUpdateWidget(_FeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameState == CharacterIdGameState.correct &&
        oldWidget.gameState != CharacterIdGameState.correct) {
      _show(correct: true);
    } else if (widget.gameState == CharacterIdGameState.wrong &&
        oldWidget.gameState != CharacterIdGameState.wrong) {
      _show(correct: false);
    }
  }

  void _show({required bool correct}) {
    _hideTimer?.cancel();
    setState(() {
      _visible = true;
      _isCorrect = correct;
    });
    _hideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: _isCorrect ? AppColors.success : AppColors.accentRed,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Correct!' : 'Try again!',
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
