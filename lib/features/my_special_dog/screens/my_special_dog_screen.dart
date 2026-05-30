import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../models/vowel_target.dart';
import '../providers/my_special_dog_provider.dart';
import '../widgets/hand_display.dart';
import '../widgets/multi_vowel_word_display.dart';
import '../widgets/pointy_finger_cursor.dart';

/// Main screen for the BSL vowel hand learning game.
///
/// Players must tap the correct fingertip on the open hand SVG that
/// corresponds to the vowel displayed at the bottom of the screen.
/// The game runs for 60 seconds and tracks the player's score.
///
/// **Level 1 (Vowel Match)**: Shows a vowel letter; tap the matching fingertip.
/// **Level 2 (Vowel Words)**: Shows a CVC word with missing vowel; tap the correct fingertip.
///
/// Fingertip mapping (BSL vowels on left hand):
/// - Thumb: a
/// - Index finger: e
/// - Middle finger: i
/// - Ring finger: o
/// - Little finger: u
class MySpecialDogScreen extends StatefulWidget {
  const MySpecialDogScreen({super.key});

  @override
  State<MySpecialDogScreen> createState() => _MySpecialDogScreenState();
}

class _MySpecialDogScreenState extends State<MySpecialDogScreen> {
  bool _showingIntro = false;

  /// Current size of the hand display widget (for coordinate calculations)
  Size _handSize = Size.zero;

  /// Key for the hand display to get its render box position
  final GlobalKey _handKey = GlobalKey();

  /// Key for the gesture detector to get correct coordinate conversion
  final GlobalKey _gestureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MySpecialDogProvider>();
      provider.showLevelSelection();
      provider.onAnswerResult = (isCorrect) {
        if (isCorrect) {
          AudioService.playCorrect('my_special_dog');
        } else {
          AudioService.playWrong('my_special_dog');
        }
      };
    });
  }

  @override
  void dispose() {
    AudioService.stopTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MySpecialDogProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: AppLocalizations(locale: 'en').translate('my_special_dog.title'),
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
                      ? _buildLevelSelectScreen(context, provider)
                      : Stack(
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 8),

                                // Header bar with score, time/progress, level
                                GameHeaderBar(
                                  onBack: () => provider.showLevelSelection(),
                                  scoreValue: '${provider.score}',
                                  levelNumber: provider.selectedLevel.number,
                                  centerContent: provider.selectedLevel !=
                                          MySpecialDogLevel.vowelMatch
                                      ? Center(
                                          child: Text(
                                            '${provider.completedWords.length} / ${MySpecialDogProvider.targetWords} ${AppLocalizations(locale: 'en').translate('my_special_dog.words_label')}',
                                            style: const TextStyle(
                                              fontFamily: 'ComicRelief',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : GameTimerDisplay(
                                          formattedTime: provider.formattedTime,
                                        ),
                                ),

                                const SizedBox(height: 8),

                                // Letter (Level 1) or word (Level 2) just below header
                                _buildTopLetterDisplay(provider),

                                const SizedBox(height: 8),

                                // Main game area
                                Expanded(
                                  child: _buildGameArea(context, provider),
                                ),

                                const SizedBox(height: AppSizes.spacingLarge),
                              ],
                            ),

                          ],
                        ),
                ),
                // Intro countdown — outside SafeArea, covers full screen
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'my_special_dog.level${provider.selectedLevel.number}',
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                    },
                  ),
                if (!provider.showLevelSelect &&
                    provider.gameState == MySpecialDogGameState.finished)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'my_special_dog',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      backgroundImage:
                          'assets/success/my-very-special-dog-success.png',
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      extraContent: provider.completedWords.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.all(AppSizes.paddingMedium),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.borderRadiusLarge),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations(locale: 'en').translate('my_special_dog.words_completed'),
                                    style: TextStyle(
                                      fontFamily: 'ComicRelief',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF002D97),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...provider.completedWords.map(
                                    (w) => Text(
                                      w,
                                      style: const TextStyle(
                                        fontFamily: 'ComicRelief',
                                        fontSize: 20,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                      onPlayAgain: () => provider.startGame(),
                      onNextLevel: switch (provider.selectedLevel) {
                        MySpecialDogLevel.vowelMatch =>
                          () => provider.startGame(level: MySpecialDogLevel.vowelWords),
                        MySpecialDogLevel.vowelWords => () {
                            provider.startGame(level: MySpecialDogLevel.noMistakes);
                          },
                        MySpecialDogLevel.noMistakes => null,
                      },
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

  /// Builds the level selection screen.
  Widget _buildLevelSelectScreen(
    BuildContext context,
    MySpecialDogProvider provider,
  ) {
    final l = AppLocalizations(locale: 'en');
    return LevelSelectScreen(
      levels: MySpecialDogLevel.values.map((level) {
        return LevelSelectItem(
          number: level.number,
          name: l.translate('my_special_dog.level${level.number}.name'),
          description: l.translate('my_special_dog.level${level.number}.description'),
          color: levelColor(level.number - 1),
          onTap: () {
            if (level.number == 1) {
              provider.prepareForIntro(level: level);
              setState(() => _showingIntro = true);
            } else {
              provider.startGame(level: level);
            }
          },
        );
      }).toList(),
    );
  }


  /// Builds the letter (Level 1) or word (Level 2) display shown below the header bar.
  Widget _buildTopLetterDisplay(MySpecialDogProvider provider) {
    if (provider.gameState != MySpecialDogGameState.playing) {
      return const SizedBox.shrink();
    }

    if (provider.selectedLevel != MySpecialDogLevel.vowelMatch) {
      if (provider.currentMultiPuzzle == null) return const SizedBox.shrink();
      return MultiVowelWordDisplay(
        puzzle: provider.currentMultiPuzzle!,
        isCorrect: provider.isGuessCorrect,
      );
    }

    final letter = provider.displayLetter;
    if (letter.isEmpty) return const SizedBox.shrink();

    final isScoring = provider.showScoreAnimation;
    final color = isScoring
        ? AppColors.success
        : (AppColors.vowelPairColors[letter] ?? AppColors.abiPink);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge * 2,
          vertical: AppSizes.paddingMedium,
        ),
        decoration: BoxDecoration(
          color: isScoring
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusXLarge),
          border: Border.all(color: color, width: 5),
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: AppSizes.fontSizeTitle * 2,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Builds the main game area with hand display and touch detection.
  Widget _buildGameArea(BuildContext context, MySpecialDogProvider provider) {
    // Playing state - show hand with touch detection
    return GestureDetector(
      key: _gestureKey,
      onPanStart: (details) => _handleTouch(details.localPosition, provider),
      onPanUpdate: (details) => _handleTouch(details.localPosition, provider),
      onPanEnd: (details) => _handleTouchEnd(provider),
      child: Stack(
        children: [
          // Hand display centered
          Center(
            child: HandDisplay(
              key: _handKey,
              onSizeChanged: (size) {
                setState(() {
                  _handSize = size;
                });
              },
            ),
          ),

          // Pointy finger cursor (proportionally sized to hand)
          if (provider.isPointerVisible && provider.pointerPosition != null)
            PointyFingerCursor(
              position: _getGlobalToLocalPosition(provider.pointerPosition!),
              handSize: _handSize,
              isVisible: true,
            ),
        ],
      ),
    );
  }

  /// Handles touch events on the game area.
  void _handleTouch(Offset position, MySpecialDogProvider provider) {
    // Convert global position to position relative to the hand widget
    final handPosition = _getHandLocalPosition(position);
    if (handPosition != null) {
      provider.onTouchUpdate(handPosition);
    }
  }

  /// Handles touch end (finger lifted).
  void _handleTouchEnd(MySpecialDogProvider provider) {
    // debugPrint('_handleTouchEnd called');
    // debugPrint('pointerPosition: ${provider.pointerPosition}');
    // debugPrint('_handSize: $_handSize');
    if (provider.pointerPosition != null && _handSize != Size.zero) {
      provider.onTouchEnd(
        position: provider.pointerPosition!,
        handSize: _handSize,
      );
    } else {
      debugPrint('Skipping - pointerPosition null or handSize is zero');
    }
  }

  /// Converts a position relative to the gesture detector to
  /// a position relative to the hand widget.
  Offset? _getHandLocalPosition(Offset localPosition) {
    try {
      final RenderBox? handBox =
          _handKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? gestureBox =
          _gestureKey.currentContext?.findRenderObject() as RenderBox?;
      if (handBox != null && gestureBox != null) {
        // Convert from gesture detector local → global → hand local
        final globalPos = gestureBox.localToGlobal(localPosition);
        return handBox.globalToLocal(globalPos);
      }
    } catch (e) {
      // Ignore errors during coordinate conversion
    }
    return localPosition;
  }

  /// Converts pointer position back for display purposes.
  Offset _getGlobalToLocalPosition(Offset handLocalPosition) {
    try {
      final RenderBox? handBox =
          _handKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? gestureBox =
          _gestureKey.currentContext?.findRenderObject() as RenderBox?;
      if (handBox != null && gestureBox != null) {
        // Convert from hand local → global → gesture detector local
        final globalPos = handBox.localToGlobal(handLocalPosition);
        return gestureBox.globalToLocal(globalPos);
      }
    } catch (e) {
      // Ignore errors during coordinate conversion
    }
    return handLocalPosition;
  }

}
