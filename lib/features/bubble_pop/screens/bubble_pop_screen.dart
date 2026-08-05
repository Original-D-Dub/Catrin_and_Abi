import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/bsl_alphabet_svg.dart';
import '../providers/bubble_pop_provider.dart';
import '../widgets/bubble_widget.dart';

/// Main screen for the Bubble Pop game.
///
/// Displays:
/// - Background image (math-background)
/// - Header bar: score circle (left), time (centre), level (right)
/// - White play area with purple border containing floating bubbles
/// - Letter sign overlapping bottom of play area (BSL or IAC)
/// - "Find the letter" label in purple rounded container
/// - Game over overlay when time runs out
///
/// [locale] controls UI text ('en' or 'cy'); the sign system (BSL/IAC) is
/// read from [BubblePopProvider.signSystem], set when the route is created
/// from the player's current [SettingsProvider] preference.
class BubblePopScreen extends StatefulWidget {
  final String locale;

  const BubblePopScreen({super.key, this.locale = 'en'});

  @override
  State<BubblePopScreen> createState() => _BubblePopScreenState();
}

class _BubblePopScreenState extends State<BubblePopScreen>
    with LevelTransitionMixin<BubblePopScreen> {
  bool _showingIntro = false;

  @override
  void initState() {
    super.initState();
    AudioService.playTitle('bubble_pop', locale: widget.locale);
    // Show level selection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BubblePopProvider>().showLevelSelection();
    });
  }

  @override
  void dispose() {
    AudioService.stopTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);

    return Consumer<BubblePopProvider>(
      builder: (context, provider, child) {
        final introGameId =
            provider.signSystem == SignSystem.iac ? 'welsh_bubble_pop' : 'bubble_pop';

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('bubble_pop.title'),
                  onBack: () {
                    provider.stopGame();
                    Navigator.pop(context);
                  },
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
                  child: Stack(
                    children: [
                      // Level select or game content
                      provider.showLevelSelect
                          ? _buildLevelSelectScreen(context, provider, localizer)
                          : _buildGameContent(context, provider, localizer),

                      // Easter egg overlay
                      if (!provider.showLevelSelect &&
                          provider.easterEggTriggered != null)
                        _buildEasterEggOverlay(provider.easterEggTriggered!),
                    ],
                  ),
                ),

                // Intro countdown — outside SafeArea, covers full screen
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: introGameId,
                    locale: widget.locale,
                    characterImage: 'assets/characters/space-jamjam.png',
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                    },
                    onBack: () {
                      setState(() => _showingIntro = false);
                      provider.showLevelSelection();
                    },
                  ),

                // Game over overlay — outside SafeArea, covers full screen
                if (!provider.showLevelSelect && provider.gameOver)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: introGameId,
                      locale: widget.locale,
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      imageAsset: 'assets/success/space-abi-jumping.png',
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () => provider.startGame(),
                      onNextLevel: provider.currentLevel.number <
                              provider.levels.length
                          ? () {
                              provider.setLevel(
                                  provider.currentLevel.number + 1);
                              provider.startGame();
                            }
                          : null,
                      onChangeLevel: () => provider.showLevelSelection(),
                    ),
                  ),

                Positioned.fill(
                  child: LevelTransitionOverlay(opacity: levelTransitionOpacity),
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
    BubblePopProvider provider,
    AppLocalizations localizer,
  ) {
    return LevelSelectScreen(
      locale: localizer.locale,
      levels: provider.levels.map((level) {
        return LevelSelectItem(
          number: level.number,
          name: localizer(level.name),
          color: levelColor(level.number - 1),
          onTap: () => startLevelWithTransition(
            gameId: 'bubble_pop',
            levelNumber: level.number,
            locale: widget.locale,
            signSystem: provider.signSystem,
            startLevel: () {
              provider.setLevel(level.number);
              provider.prepareForIntro();
              setState(() => _showingIntro = true);
            },
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────
  // Game Content
  // ─────────────────────────────────────────

  /// Builds the main game content matching the mockup layout.
  ///
  /// Layout (Stack over background image):
  /// - Background: math-background-1080x1920.jpg
  /// - Header bar: score circle (left), time (centre), level (right)
  /// - Play area: white bg, purple border, contains bubbles
  /// - Letter sign: overlapping bottom of play area
  /// - "Find the letter" label: purple rounded container below sign
  Widget _buildGameContent(
    BuildContext context,
    BubblePopProvider provider,
    AppLocalizations localizer,
  ) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/backgrounds/math-background-1080x1920.jpg',
            fit: BoxFit.cover,
          ),
        ),

        // Game layout
        Column(
          children: [
            const SizedBox(height: 8),

            // Header bar with score, time, level
            GameHeaderBar(
              onBack: () {
                provider.stopGame();
                Navigator.pop(context);
              },
              scoreValue: '${provider.score}',
              levelNumber: provider.currentLevel.number,
              centerContent: GameTimerDisplay(
                formattedTime: _formatTime(provider.timeRemaining),
              ),
            ),

            const SizedBox(height: 12),

            // Play area + sign + label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPlayAreaWithSign(provider, localizer),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),

      ],
    );
  }

  /// Formats seconds into M:SS display.
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Returns the sign scale factor based on screen width.
  ///
  /// > 768 px → 2×  |  > 600 px → 1.5×  |  ≤ 600 px → 1×
  double _signScale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 768) return 2.0;
    if (w > 600) return 1.5;
    return 1.0;
  }

  /// Builds the play area with the letter sign overlapping the top.
  Widget _buildPlayAreaWithSign(
      BubblePopProvider provider, AppLocalizations localizer) {
    final scale = _signScale(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // White play area with outer wrapper
        Positioned.fill(
          top: 80 * scale,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.headerBackgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.headerBorderDark,
                width: 2,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.headerBorderDark,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Floating bubbles
                      ...provider.bubbles.map((bubble) {
                        final bubbleSize = BubbleSizes.defaultSize * scale;
                        return Positioned(
                          left: bubble.x * constraints.maxWidth -
                              bubbleSize / 2,
                          top: bubble.y * (constraints.maxHeight - 100) -
                              bubbleSize / 2,
                          child: BubbleWidget(
                            letter: bubble.letter,
                            color: bubble.color,
                            size: bubbleSize,
                            isPopping:
                                bubble.id == provider.lastPoppedBubbleId,
                            onTap: () {
                              if (provider.isPlaying) {
                                final isCorrect = provider.tapBubble(bubble.id);
                                if (isCorrect) {
                                  AudioService.playCorrect('bubble_pop');
                                } else {
                                  AudioService.playWrong('bubble_pop');
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            ),
          ),
        ),

        // Letter sign + "Find the letter" label at top
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _buildSignArea(provider, scale, localizer),
        ),
      ],
    );
  }

  /// Builds the letter sign overlapping the play area, with "Find the
  /// letter" label in a purple rounded container below.
  ///
  /// [scale] is 1×, 1.5×, or 2× depending on screen width.
  Widget _buildSignArea(
    BubblePopProvider provider,
    double scale,
    AppLocalizations localizer,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Letter sign in rounded container
        Center(
          child: Container(
            width: 140 * scale,
            height: 120 * scale,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: AppColors.headerBorderDark,
                width: 4 * scale,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21 * scale),
              child: provider.targetLetter.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.all(8 * scale),
                      child: BslAlphabetSvg(
                        letter: provider.targetLetter,
                        signSystem: provider.signSystem,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),

        SizedBox(height: 4 * scale),

        // "Find the letter" label in purple container
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 20 * scale, vertical: 6 * scale),
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Text(
              localizer('bubble_pop.find_label'),
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the easter egg overlay when cat or dog is spelled.
  Widget _buildEasterEggOverlay(String animal) {
    final isCat = animal == 'cat';
    return IgnorePointer(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.5),
            duration: const Duration(milliseconds: 300),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Text(
              isCat ? '🐱 Meow!' : '🐕 Woof!',
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
