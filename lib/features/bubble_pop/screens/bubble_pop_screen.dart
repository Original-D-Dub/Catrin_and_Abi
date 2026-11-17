import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_filters.dart';
import '../../../features/home/models/trail_node.dart';
import '../../../features/home/providers/trail_provider.dart';
import '../../../features/home/widgets/trail_navigation.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/sign_letter_image.dart';
import '../../../shared/widgets/champion_rosette.dart';
import '../../bsl_maths/widgets/champion_mode_explainer.dart';
import '../../bsl_maths/widgets/champion_mode_unlocked_banner.dart';
import '../providers/bubble_pop_provider.dart';
import '../widgets/bubble_widget.dart';
import '../widgets/champion_feedback.dart';

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

  /// Set when launched from the "Learn BSL trail" — the id of the trail
  /// node this session represents. Null for normal play from the game's
  /// own home tile.
  final String? trailNodeId;

  const BubblePopScreen({super.key, this.locale = 'en', this.trailNodeId});

  @override
  State<BubblePopScreen> createState() => _BubblePopScreenState();
}

class _BubblePopScreenState extends State<BubblePopScreen>
    with LevelTransitionMixin<BubblePopScreen> {
  bool _showingIntro = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BubblePopProvider>();
      if (widget.trailNodeId == null) {
        provider.showLevelSelection();
      } else {
        context.read<TrailProvider>().enterTrail(widget.trailNodeId!);
        provider.onLevelComplete = (score) {
          final node = bslTrail.firstWhere((n) => n.id == widget.trailNodeId);
          if (node.minScore == null || score >= node.minScore!) {
            context.read<TrailProvider>().completeNode(widget.trailNodeId!);
          }
        };
        // BubblePopProvider's initialLevelNumber already prepared this
        // level (bubbles spawned, timer not running) — show the same
        // intro countdown normal play gets before starting the clock.
        setState(() => _showingIntro = true);
      }
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
                    'assets/backgrounds/felt-background.jpg'),
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

                // Intro countdown — outside SafeArea, covers full screen.
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: introGameId,
                    levelNumber: provider.currentLevel.number,
                    levelNameGameId: 'bubble_pop',
                    signSystem: provider.signSystem,
                    locale: widget.locale,
                    characterImage: 'assets/characters/space-jamjam.png',
                    backgroundImage:
                        'assets/backgrounds/felt-background.jpg',
                    topText: localizer('bubble_pop.intro_heading'),
                    roundedBubble: true,
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                    },
                    onBack: () {
                      setState(() => _showingIntro = false);
                      if (widget.trailNodeId != null) {
                        advanceTrail(context, context.read<TrailProvider>());
                      } else {
                        provider.showLevelSelection();
                      }
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
                      onNextLevel: _canAdvance(context, provider)
                          ? () => _onNextLevel(context, provider)
                          : null,
                      onChangeLevel: () {
                        final trail = context.read<TrailProvider>();
                        if (trail.activeNodeId != null) {
                          advanceTrail(context, trail);
                        } else {
                          provider.showLevelSelection();
                        }
                      },
                    ),
                  ),

                // Shown over the game-over overlay the first time level 6
                // is completed.
                if (!provider.showLevelSelect &&
                    provider.gameOver &&
                    provider.justUnlockedChampionMode)
                  Positioned.fill(
                    child: ChampionModeUnlockedBanner(
                      locale: widget.locale,
                      textKey: 'bubble_pop.champion_mode.unlocked_banner',
                      onContinue: () {
                        provider.dismissChampionModeUnlockedBanner();
                        provider.showLevelSelection();
                        showChampionModeExplainer(
                          context,
                          locale: widget.locale,
                          bodyKey: provider.signSystem == SignSystem.iac
                              ? 'bubble_pop.champion_mode.explainer_iac'
                              : 'bubble_pop.champion_mode.explainer_bsl',
                          demo: ChampionScoringDemo(localizer: localizer),
                        );
                      },
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

  /// Whether "Next Level" has anywhere to go — either the next trail node
  /// (when launched from the trail) or the next level in this game.
  bool _canAdvance(BuildContext context, BubblePopProvider provider) {
    if (context.watch<TrailProvider>().activeNodeId != null) return true;
    return provider.currentLevel.number < provider.levels.length;
  }

  /// "Next Level" — advances the trail when this session came from it,
  /// otherwise behaves exactly as it always has (next level in this game).
  void _onNextLevel(BuildContext context, BubblePopProvider provider) {
    final trail = context.read<TrailProvider>();
    if (trail.activeNodeId != null) {
      advanceTrail(context, trail);
    } else {
      provider.setLevel(provider.currentLevel.number + 1);
      provider.startGame();
    }
  }

  /// Builds the level selection screen.
  Widget _buildLevelSelectScreen(
    BuildContext context,
    BubblePopProvider provider,
    AppLocalizations localizer,
  ) {
    return LevelSelectScreen(
      locale: localizer.locale,
      titleBadge: provider.isChampionModeUnlocked
          ? ChampionRosette(
              value: provider.championMode,
              onChanged: provider.setChampionMode,
              localizer: localizer,
            )
          : null,
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
  /// - Background: felt-background.jpg
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
            'assets/backgrounds/felt-background.jpg',
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
                final trail = context.read<TrailProvider>();
                if (trail.activeNodeId != null) {
                  advanceTrail(context, trail);
                } else {
                  provider.showLevelSelection();
                }
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

                      // Champion Mode "x2 multiplier" labels, following the
                      // path of the bubble they replaced. Not tappable.
                      ...provider.multiplierLabels.map((label) {
                        return Positioned(
                          key: ValueKey(label.id),
                          left: 0,
                          right: 0,
                          top: label.y * (constraints.maxHeight - 100),
                          child: IgnorePointer(
                            child: FractionalTranslation(
                              translation: const Offset(0, -0.5),
                              // Align (rather than an absolute left) keeps
                              // the wide text inside the play area when the
                              // bubble was near an edge.
                              child: Align(
                                alignment: Alignment(label.x * 2 - 1, 0),
                                child: Opacity(
                                  opacity: label.opacity,
                                  child: MultiplierLabelText(
                                    multiplier: label.multiplier,
                                    localizer: localizer,
                                  ),
                                ),
                              ),
                            ),
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
    final signHeight = 120 * scale;
    return SizedBox(
      height: signHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Letter sign in rounded container
          Center(
            child: Container(
              width: 140 * scale,
              height: signHeight,
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
                        child: SignLetterImage(
                          letter: provider.targetLetter,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // Champion Mode: floating "+20" / "-5" points feedback on the
          // right of the sign.
          if (provider.championMode && provider.lastPointsDelta != null)
            Positioned(
              right: 8 * scale,
              top: 24 * scale,
              child: ChampionPointsPopup(
                delta: provider.lastPointsDelta!,
                serial: provider.pointsDeltaSerial,
                scale: scale,
              ),
            ),

          // "Find the letter" label, vertically centered on the sign's
          // bottom edge via a translation by half its own height.
          Positioned(
            left: 0,
            right: 0,
            top: signHeight,
            child: Center(
              child: FractionalTranslation(
                translation: const Offset(0, -0.5),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20 * scale, vertical: 6 * scale),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple,
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  child: Text(
                    localizer('bubble_pop.find_label'),
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
                fontFamily: 'Quicksand',
                fontSize: 60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
