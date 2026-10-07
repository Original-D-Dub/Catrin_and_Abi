import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/game_filters.dart';
import '../../../features/home/models/trail_node.dart';
import '../../../features/home/providers/trail_provider.dart';
import '../../../features/home/widgets/trail_navigation.dart';
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
import '../widgets/multi_vowel_word_display.dart';
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

  /// Set when launched from the "Learn BSL trail" — the id of the trail
  /// node this session represents. Null for normal play from the game's
  /// own home tile.
  final String? trailNodeId;

  const VowelHandScreen({super.key, this.locale = 'en', this.trailNodeId});

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
      if (widget.trailNodeId != null) {
        final node = bslTrail.firstWhere((n) => n.id == widget.trailNodeId);
        context.read<TrailProvider>().enterTrail(widget.trailNodeId!);
        provider.onLevelComplete = (score) {
          if (node.minScore == null || score >= node.minScore!) {
            context.read<TrailProvider>().completeNode(widget.trailNodeId!);
          }
        };
        provider.prepareForIntro(
          level: VowelHandLevel.forSignSystem(provider.signSystem)[node.level - 1],
        );
        setState(() => _showingIntro = true);
      } else if (VowelHandLevel.forSignSystem(provider.signSystem).length <= 1) {
        // Only one level available — skip level selection and go straight
        // into the intro countdown.
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

  bool _imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the hand and pointer images up front so they are ready when
    // the intro ends / on the first touch, instead of popping in a frame late.
    if (!_imagesPrecached) {
      _imagesPrecached = true;
      precacheImage(const AssetImage(AssetPaths.vowelHandOpen), context);
      precacheImage(const AssetImage(AssetPaths.vowelHandPointer), context);
      for (final vowel in const ['w', 'y']) {
        precacheImage(AssetImage(AssetPaths.vowelHandBadge(vowel)), context);
      }
    }
  }

  @override
  void dispose() {
    AudioService.stopTts();
    super.dispose();
  }

  /// The `<gameId>[.levelN]` id used to look up both the instruction text
  /// (`'<id>.intro'`) and its matching audio for the current level.
  String _introGameId(VowelHandProvider provider) {
    return provider.signSystem == SignSystem.iac
        ? (provider.selectedLevel == VowelHandLevel.vowelMatch
            ? 'iac_vowels'
            : 'iac_vowels.level${provider.selectedLevel.number}')
        : 'vowel_hand.level${provider.selectedLevel.number}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VowelHandProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: AppLocalizations(locale: widget.locale).translate(
                      provider.signSystem == SignSystem.iac
                          ? 'vowel_hand.title_iac'
                          : 'vowel_hand.title'),
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
                                  onBack: () {
                                    final trail =
                                        context.read<TrailProvider>();
                                    if (trail.activeNodeId != null) {
                                      advanceTrail(context, trail);
                                    } else {
                                      provider.showLevelSelection();
                                    }
                                  },
                                  scoreValue: '${provider.score}',
                                  levelNumber: provider.selectedLevel.number,
                                  centerContent: (provider.selectedLevel ==
                                              VowelHandLevel.vowelWordsMulti ||
                                          provider.selectedLevel ==
                                              VowelHandLevel.noMistakes)
                                      ? Center(
                                          child: Text(
                                            '${provider.completedWords.length} / ${VowelHandProvider.targetWords} ${AppLocalizations(locale: widget.locale).translate('vowel_hand.words_label')}',
                                            style: const TextStyle(
                                              fontFamily: 'Quicksand',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
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
                // Intro countdown — outside SafeArea, covers full screen.
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: _introGameId(provider),
                    levelNumber: provider.selectedLevel.number,
                    levelNameGameId: 'vowel_hand',
                    signSystem: provider.signSystem,
                    locale: widget.locale,
                    characterImage: AssetPaths.vowelHandIntroImage,
                    backgroundImage:
                        'assets/backgrounds/math-background-1080x1920.jpg',
                    topText: AppLocalizations(locale: widget.locale)
                        .translate('vowel_hand.intro_heading'),
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
                                    AppLocalizations(locale: widget.locale)
                                        .translate('vowel_hand.words_completed'),
                                    style: const TextStyle(
                                      fontFamily: 'Quicksand',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF002D97),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...provider.completedWords.map(
                                    (w) => Text(
                                      w,
                                      style: const TextStyle(
                                        fontFamily: 'Quicksand',
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
                      onNextLevel: context.watch<TrailProvider>().activeNodeId != null
                          ? () => advanceTrail(context, context.read<TrailProvider>())
                          : switch (provider.selectedLevel) {
                        VowelHandLevel.vowelMatch =>
                          () => provider.startGame(level: VowelHandLevel.vowelWords),
                        VowelHandLevel.vowelWords => () {
                            provider.prepareForIntro(level: VowelHandLevel.ccvc);
                            setState(() => _showingIntro = true);
                          },
                        VowelHandLevel.ccvc => () {
                            provider.prepareForIntro(
                              level: provider.signSystem == SignSystem.iac
                                  ? VowelHandLevel.vowelWordsMulti
                                  : VowelHandLevel.cvcc,
                            );
                            setState(() => _showingIntro = true);
                          },
                        VowelHandLevel.cvcc => () {
                            provider.prepareForIntro(level: VowelHandLevel.vowelWordsMulti);
                            setState(() => _showingIntro = true);
                          },
                        VowelHandLevel.vowelWordsMulti => () {
                            provider.prepareForIntro(level: VowelHandLevel.noMistakes);
                            setState(() => _showingIntro = true);
                          },
                        VowelHandLevel.noMistakes => null,
                      },
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
          name: _levelText(l, provider.signSystem, level.number, 'name'),
          // description: _levelText(l, provider.signSystem, level.number, 'description'),
          color: levelColor(level.number - 1),
          onTap: () {
            provider.prepareForIntro(level: level);
            setState(() => _showingIntro = true);
          },
        );
      }).toList(),
    );
  }

  /// Looks up the level-select label for [field] ('name'/'description') at
  /// [number], preferring an IAC-specific override (`vowel_hand.iac.levelN.*`)
  /// when one exists and falling back to the shared BSL/English text
  /// otherwise (e.g. Levels 1 & 2, whose wording already fits both sign
  /// systems).
  String _levelText(AppLocalizations l, SignSystem signSystem, int number, String field) {
    if (signSystem == SignSystem.iac) {
      final iacKey = 'vowel_hand.iac.level$number.$field';
      final iacText = l.translate(iacKey);
      if (iacText != iacKey) return iacText;
    }
    return l.translate('vowel_hand.level$number.$field');
  }

  /// Height of the letter/word slot below the header: 13% of the screen
  /// height, kept between 64 and 128px. It depends only on the screen size,
  /// so it is the same before and during play and the game area below never
  /// resizes or moves when the letter or word appears.
  double _topSlotHeight(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.13).clamp(64.0, 128.0);

  /// Builds the letter (Level 1) or word (Level 2) display shown below the
  /// header bar. Always exactly [_topSlotHeight] tall; content is scaled down
  /// to fit (never up), so long words, thumbnails or large accessibility
  /// text sizes can't make the slot grow.
  Widget _buildTopLetterDisplay(VowelHandProvider provider) {
    final content = _buildTopLetterContent(provider);
    return SizedBox(
      height: _topSlotHeight(context),
      child: content == null
          ? null
          : FittedBox(fit: BoxFit.scaleDown, child: content),
    );
  }

  /// The letter badge or word display for the current level, or null when
  /// there is nothing to show yet (e.g. during the intro countdown).
  Widget? _buildTopLetterContent(VowelHandProvider provider) {
    if (provider.gameState != VowelHandGameState.playing) return null;

    if (provider.selectedLevel == VowelHandLevel.vowelWordsMulti ||
        provider.selectedLevel == VowelHandLevel.noMistakes) {
      if (provider.currentMultiPuzzle == null) return null;
      return MultiVowelWordDisplay(
        puzzle: provider.currentMultiPuzzle!,
        isCorrect: provider.isGuessCorrect,
      );
    }

    if (provider.selectedLevel != VowelHandLevel.vowelMatch) {
      if (provider.currentPuzzle == null) return null;
      // No thumbnail artwork exists for the Welsh CVC word list (IAC).
      final hasThumbnail = provider.selectedLevel == VowelHandLevel.vowelWords &&
          provider.signSystem == SignSystem.bsl;
      return WordDisplay(
        puzzle: provider.currentPuzzle!,
        guessedVowel: provider.guessedVowel,
        isCorrect: provider.isGuessCorrect,
        showThumbnail: hasThumbnail,
      );
    }

    final letter = provider.displayLetter;
    if (letter.isEmpty) return null;

    final isScoring = provider.showScoreAnimation;
    // IAC uses the Welsh palette so 'w'/'y' match their badge borders.
    final vowelColors = provider.signSystem == SignSystem.iac
        ? AppColors.welshVowelPairColors
        : AppColors.vowelPairColors;
    final color = isScoring
        ? AppColors.success
        : (vowelColors[letter] ?? AppColors.abiPink);

    return AnimatedContainer(
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
    );
  }

  /// Size of the open hand box: 95% of the screen width (80% for IAC, leaving
  /// room for the W/Y badges) at the image's aspect ratio. Derived purely from
  /// the screen size, so it is known up front and never changes as content
  /// elsewhere on the screen appears.
  Size _handSizeFor(BuildContext context, VowelHandProvider provider) {
    final widthFraction = provider.signSystem == SignSystem.iac ? 0.8 : 0.95;
    final width = MediaQuery.sizeOf(context).width * widthFraction;
    return Size(
      width,
      width * VowelHandConstants.imageHeight / VowelHandConstants.imageWidth,
    );
  }

  /// Builds the main game area with hand display and touch detection.
  Widget _buildGameArea(BuildContext context, VowelHandProvider provider) {
    // Calculated synchronously so the cursor and hit-testing use the correct
    // size from the first frame, with no post-layout rebuild.
    final handSize = _handSizeFor(context, provider);
    _handSize = handSize;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      key: _gestureKey,
      onPanStart: (details) => _handleTouch(details.localPosition, provider),
      onPanUpdate: (details) => _handleTouch(details.localPosition, provider),
      onPanEnd: (details) => _handleTouchEnd(provider),
      child: Stack(
        children: [
          // Hand display. Centred vertically when it fits; otherwise pinned
          // to the top so the fingertips stay visible and the sleeve is
          // clipped at the bottom of the game area. The game area's height
          // is fixed for the session (see _topSlotHeight), so this position
          // doesn't change when the game starts.
          LayoutBuilder(
            builder: (context, constraints) {
              // The rotation lifts the middle fingertip to the box's top
              // edge, so keep a small gap above it to avoid clipping.
              final minTop = handSize.height * 0.02;
              // Shifted right 4% of the screen width.
              final horizontalShift = screenWidth * 0.07;
              return Stack(
                children: [
                  Positioned(
                    left: (constraints.maxWidth - handSize.width) / 2 +
                        horizontalShift,
                    top: math.max(
                        minTop, (constraints.maxHeight - handSize.height) / 2),
                    width: handSize.width,
                    height: handSize.height,
                    // Rotated 15° anti-clockwise. The rotation sits above
                    // _handKey, so globalToLocal on the hand's RenderBox
                    // maps touches into the unrotated image space and the
                    // fingertip outlines still line up.
                    child: Transform.rotate(
                      angle: -15 * math.pi / 180,
                      child: HandDisplay(
                        key: _handKey,
                        // IAC: drop the sleeve below the cuff so it overlaps
                        // the W/Y badges less.
                        clipBelowCuff: provider.signSystem == SignSystem.iac,
                      ),
                    ),
                  ),
                ],
              );
            },
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
              handSize: handSize,
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
