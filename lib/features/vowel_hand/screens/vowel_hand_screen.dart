import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/services/audio_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../models/vowel_target.dart';
import '../providers/vowel_hand_provider.dart';
import '../widgets/hand_display.dart';
import '../widgets/pointy_finger_cursor.dart';
import '../widgets/vowel_badge.dart';
import '../widgets/word_display.dart';

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
class VowelHandScreen extends StatefulWidget {
  /// UI locale ('en' or 'cy') used for titles, level info, and overlay text.
  final String locale;

  const VowelHandScreen({super.key, this.locale = 'en'});

  @override
  State<VowelHandScreen> createState() => _VowelHandScreenState();
}

class _VowelHandScreenState extends State<VowelHandScreen> {
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
      final provider = context.read<VowelHandProvider>();
      if (provider.signSystem == SignSystem.iac) {
        // IAC has only one level (Vowel Match) — skip level selection and
        // go straight into the intro countdown.
        provider.prepareForIntro(level: VowelHandLevel.vowelMatch);
        setState(() => _showingIntro = true);
      } else {
        provider.showLevelSelection();
      }
      provider.onAnswerResult = (isCorrect) {
        if (isCorrect) {
          AudioService.playCorrect('vowel_hand');
        } else {
          AudioService.playWrong('vowel_hand');
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
    return Consumer<VowelHandProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: AppLocalizations(locale: widget.locale).translate('vowel_hand.title'),
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

                                // Header bar with score, time, level
                                GameHeaderBar(
                                  onBack: provider.signSystem == SignSystem.iac
                                      ? () => Navigator.of(context).pop()
                                      : () => provider.showLevelSelection(),
                                  scoreValue: '${provider.score}',
                                  levelNumber: provider.selectedLevel.number,
                                  centerContent: GameTimerDisplay(
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
                    gameId: provider.signSystem == SignSystem.iac
                        ? 'iac_vowels'
                        : 'vowel_hand.level${provider.selectedLevel.number}',
                    locale: widget.locale,
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                    },
                  ),
                if (!provider.showLevelSelect &&
                    provider.gameState == VowelHandGameState.finished)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: provider.signSystem == SignSystem.iac
                          ? 'iac_vowels'
                          : 'vowel_hand',
                      locale: widget.locale,
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      imageAsset: 'assets/success/Star-glowing.png',
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: provider.signSystem == SignSystem.iac
                          ? () {
                              provider.prepareForIntro(level: VowelHandLevel.vowelMatch);
                              setState(() => _showingIntro = true);
                            }
                          : () => provider.startGame(),
                      onNextLevel: provider.signSystem == SignSystem.iac
                          ? null
                          : switch (provider.selectedLevel) {
                              VowelHandLevel.vowelMatch =>
                                () => provider.startGame(level: VowelHandLevel.vowelWords),
                              VowelHandLevel.vowelWords => () {
                                  provider.prepareForIntro(level: VowelHandLevel.ccvc);
                                  setState(() => _showingIntro = true);
                                },
                              VowelHandLevel.ccvc => () {
                                  provider.prepareForIntro(level: VowelHandLevel.cvcc);
                                  setState(() => _showingIntro = true);
                                },
                              VowelHandLevel.cvcc => null,
                            },
                      onChangeLevel: provider.signSystem == SignSystem.iac
                          ? () => Navigator.of(context).pop()
                          : () => provider.showLevelSelection(),
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
    VowelHandProvider provider,
  ) {
    final l = AppLocalizations(locale: widget.locale);
    return LevelSelectScreen(
      locale: widget.locale,
      levels: VowelHandLevel.forSignSystem(provider.signSystem).map((level) {
        return LevelSelectItem(
          number: level.number,
          name: l.translate('vowel_hand.level${level.number}.name'),
          description: l.translate('vowel_hand.level${level.number}.description'),
          color: levelColor(level.number - 1),
          onTap: () {
            provider.prepareForIntro(level: level);
            setState(() => _showingIntro = true);
          },
        );
      }).toList(),
    );
  }


  /// Builds the letter (Level 1) or word (Level 2) display shown below the header bar.
  Widget _buildTopLetterDisplay(VowelHandProvider provider) {
    if (provider.gameState != VowelHandGameState.playing) {
      return const SizedBox.shrink();
    }

    if (provider.selectedLevel != VowelHandLevel.vowelMatch) {
      if (provider.currentPuzzle == null) return const SizedBox.shrink();
      final hasThumbnail = provider.selectedLevel == VowelHandLevel.vowelWords;
      return WordDisplay(
        puzzle: provider.currentPuzzle!,
        guessedVowel: provider.guessedVowel,
        isCorrect: provider.isGuessCorrect,
        showThumbnail: hasThumbnail,
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
  Widget _buildGameArea(BuildContext context, VowelHandProvider provider) {
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
              sizeFactor: provider.signSystem == SignSystem.iac ? 0.7 : 1.0,
              onSizeChanged: (size) {
                setState(() {
                  _handSize = size;
                });
              },
            ),
          ),

          // W and Y vowel badges (IAC only) — bottom corners
          if (provider.signSystem == SignSystem.iac) ...[
            Positioned(
              left: 16,
              bottom: 0,
              child: VowelBadge(
                vowel: 'w',
                onTap: () => provider.onTapAdditionalVowel('w'),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 0,
              child: VowelBadge(
                vowel: 'y',
                onTap: () => provider.onTapAdditionalVowel('y'),
              ),
            ),
          ],

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
  void _handleTouch(Offset position, VowelHandProvider provider) {
    // Convert global position to position relative to the hand widget
    final handPosition = _getHandLocalPosition(position);
    if (handPosition != null) {
      provider.onTouchUpdate(handPosition);
    }
  }

  /// Handles touch end (finger lifted).
  void _handleTouchEnd(VowelHandProvider provider) {
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
