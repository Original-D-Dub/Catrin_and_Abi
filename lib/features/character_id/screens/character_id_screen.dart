import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/circular_video_container.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../providers/character_id_provider.dart';
import '../widgets/mixed_character_display.dart';

/// Main screen for the Character Identification game.
///
/// Displays:
/// - Level selection screen
/// - Level 1: Clothing colours with colour hints (10 to win)
/// - Level 2: Clothing colours without colour hints (10 to win)
/// - Level 3: Speed Round - 60 seconds
/// - Level 4: Compare Characters (10 to win)
///
/// The player must answer questions about the character to score points.
class CharacterIdScreen extends StatefulWidget {
  const CharacterIdScreen({super.key});

  @override
  State<CharacterIdScreen> createState() => _CharacterIdScreenState();
}

class _CharacterIdScreenState extends State<CharacterIdScreen> {
  bool _showingIntro = false;
  bool _titlePlayed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_titlePlayed) {
      _titlePlayed = true;
      AudioService.playTitle('character_id',
          locale: AppLocalizations.of(context).locale);
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
                      'assets/backgrounds/math-background-1080x1920.jpg'),
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
                                centerContent: provider.isLevel3
                                    ? GameTimerDisplay(
                                        formattedTime: _formatTime(
                                          provider.remainingSeconds,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          localizer('character_id.level${provider.currentLevel.number}.name'),
                                          style: const TextStyle(
                                            fontFamily: 'ComicRelief',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
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
                        scoreStyle: provider.isLevel3
                            ? SuccessScoreStyle.youScored
                            : SuccessScoreStyle.got10Correct,
                        score: provider.score,
                        showPersonalBest: provider.isLevel3,
                        isNewPersonalBest:
                            provider.lastResult?.isNewPersonalBest ?? false,
                        personalBest: provider.lastResult?.personalBest,
                        onPlayAgain: () {
                          provider.resetGame();
                          if (provider.isLevel3) {
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
    // Show loading indicator
    if (provider.gameState == CharacterIdGameState.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error if loading failed
    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentRed,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            ElevatedButton(
              onPressed: () => provider.loadCharacterData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show level selection
    if (provider.showLevelSelect) {
      return _buildLevelSelectScreen(context, provider);
    }

    // Show Level 1, 2, or 3 content (same clothing questions)
    if (provider.isLevel1 || provider.isLevel2 || provider.isLevel3) {
      return _buildLevel1Content(context, provider);
    }

    // Show Level 4 content (Compare Characters)
    return _buildLevel4Content(context, provider);
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
            if (level.number == 3) {
              setState(() => _showingIntro = true);
            }
            AudioService.playIntro('character_id');
          },
        );
      }).toList(),
    );
  }

  /// Builds Level 1 content (trouser colour question).
  Widget _buildLevel1Content(
      BuildContext context, CharacterIdProvider provider) {
    if (provider.currentMixedCharacter == null) {
      return const Center(
        child: Text('No characters available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final isCompact = constraints.maxHeight < 500;

        if (isLandscape) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: MixedCharacterDisplay(
                        character: provider.currentMixedCharacter!,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingMedium),
                          child: Text(
                            provider.currentQuestion,
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.paddingMedium),
                            child: _buildColorChoiceButtons(provider),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _FeedbackOverlay(gameState: provider.gameState),
            ],
          );
        }

        // Portrait layout
        return Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(
                    isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
                  ),
                  child: Text(
                    provider.currentQuestion,
                    style: TextStyle(
                      fontSize: isCompact
                          ? AppSizes.fontSizeBody
                          : AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: isCompact ? 2 : 3,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMedium,
                      ),
                      child: MixedCharacterDisplay(
                        character: provider.currentMixedCharacter!,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(
                      isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
                    ),
                    child: _buildColorChoiceButtons(provider),
                  ),
                ),
              ],
            ),
            _FeedbackOverlay(gameState: provider.gameState),
          ],
        );
      },
    );
  }

  /// Builds the color choice buttons for Levels 1, 2, and 3.
  ///
  /// Narrow screens (<600 px): 2 buttons (1 correct + 1 wrong), 2-column layout.
  /// Wide screens (≥600 px): 3 buttons, 3-column layout.
  Widget _buildColorChoiceButtons(CharacterIdProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final choices = isNarrow
            ? _twoChoices(provider)
            : provider.answerChoices;
        final isDisabled = provider.gameState != CharacterIdGameState.playing;
        final showColourHint = provider.isLevel1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < choices.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSizes.spacingMedium),
              Expanded(
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
  /// When [showColourHint] is true (Level 1), shows colour-coded background
  /// and border. When false (Level 2 and 3), shows neutral styling.
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

    // Level 1 has padding, Level 2 and 3 have no padding with cover fit
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

  /// Builds Level 4 content (compare two characters).
  Widget _buildLevel4Content(
      BuildContext context, CharacterIdProvider provider) {
    if (provider.currentMixedCharacter == null ||
        provider.secondMixedCharacter == null) {
      return const Center(
        child: Text('No characters available'),
      );
    }

    final char1 = provider.currentMixedCharacter!;
    final char2 = provider.secondMixedCharacter!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 500;
            final isVeryWide = constraints.maxWidth > 600;

            return Column(
              children: [
                // Question
                Padding(
                  padding: EdgeInsets.all(
                    isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
                  ),
                  child: Text(
                    provider.level4Question,
                    style: TextStyle(
                      fontSize: isCompact
                          ? AppSizes.fontSizeBody
                          : AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Two characters side by side with buttons below each
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVeryWide
                          ? constraints.maxWidth * 0.1
                          : AppSizes.paddingSmall,
                    ),
                    child: Row(
                      children: [
                        // First character
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingSmall,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: MixedCharacterDisplay(
                                    character: char1,
                                  ),
                                ),
                                SizedBox(
                                  height: isCompact
                                      ? AppSizes.spacingXSmall
                                      : AppSizes.spacingSmall,
                                ),
                                _buildLevel4AnswerButton(
                                  name: char1.identityName,
                                  isSelected: provider.selectedName == char1.identityName,
                                  isCorrect: provider.gameState == CharacterIdGameState.correct &&
                                      provider.selectedName == char1.identityName,
                                  isWrong: provider.gameState == CharacterIdGameState.wrong &&
                                      provider.selectedName == char1.identityName,
                                  isDisabled: provider.gameState != CharacterIdGameState.playing,
                                  onPressed: () => provider.selectLevel4Answer(char1.identityName),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Second character
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingSmall,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: MixedCharacterDisplay(
                                    character: char2,
                                  ),
                                ),
                                SizedBox(
                                  height: isCompact
                                      ? AppSizes.spacingXSmall
                                      : AppSizes.spacingSmall,
                                ),
                                _buildLevel4AnswerButton(
                                  name: char2.identityName,
                                  isSelected: provider.selectedName == char2.identityName,
                                  isCorrect: provider.gameState == CharacterIdGameState.correct &&
                                      provider.selectedName == char2.identityName,
                                  isWrong: provider.gameState == CharacterIdGameState.wrong &&
                                      provider.selectedName == char2.identityName,
                                  isDisabled: provider.gameState != CharacterIdGameState.playing,
                                  onPressed: () => provider.selectLevel4Answer(char2.identityName),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom zone: feedback on left, video circle overlays on right
                Container(
                  height: isCompact ? 96 : 140,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: AppSizes.paddingMedium),
                  child: _buildFeedback(provider),
                ),
              ],
            );
          },
        ),

        // Circular video — placeholder until assets are added
        Positioned(
          bottom: -50,
          right: -20,
          child: CircularVideoContainer(
            size: 200,
            videoAssetPath: null,
            label: 'BSL',
            autoPlay: false,
          ),
        ),
      ],
    );
  }

  /// Builds a single Level 4 answer button.
  Widget _buildLevel4AnswerButton({
    required String name,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required bool isDisabled,
    required VoidCallback onPressed,
  }) {
    Color outerColor;
    Color innerColor;
    Color borderColor;
    Color textColor;

    if (isCorrect) {
      outerColor = AppColors.success.withValues(alpha: 0.4);
      innerColor = AppColors.success.withValues(alpha: 0.2);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isWrong) {
      outerColor = AppColors.accentRed.withValues(alpha: 0.4);
      innerColor = AppColors.accentRed.withValues(alpha: 0.2);
      borderColor = AppColors.accentRed;
      textColor = AppColors.accentRed;
    } else {
      outerColor = AppColors.headerBackgroundLight;
      innerColor = AppColors.headerBackground;
      borderColor = AppColors.headerBorderDark;
      textColor = Colors.white;
    }

    final scale = (isCorrect || isWrong) ? 1.05 : 1.0;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: isDisabled && !isSelected ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: outerColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingMedium,
                vertical: AppSizes.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: innerColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the feedback message area.
  Widget _buildFeedback(CharacterIdProvider provider) {
    if (provider.gameState == CharacterIdGameState.correct) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 28),
          SizedBox(width: AppSizes.spacingSmall),
          Text(
            'Correct!',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      );
    }

    if (provider.gameState == CharacterIdGameState.wrong) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel, color: AppColors.accentRed, size: 28),
          SizedBox(width: AppSizes.spacingSmall),
          Text(
            'Try again!',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.accentRed,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
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
    // ignore: deprecated_member_use
    _playTrigger = state.controller.stateMachine.trigger('play_${widget.colourName}');
    _triggerAnimation();
    _timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _triggerAnimation(),
    );
  }

  void _triggerAnimation() {
    _playTrigger?.fire();
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: _fileLoader,
      artboardSelector: ArtboardSelector.byName(widget.colourName),
      stateMachineSelector: StateMachineSelector.byName('${widget.colourName}_state_machine'),
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
                    fontFamily: 'ComicRelief',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.bold,
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
