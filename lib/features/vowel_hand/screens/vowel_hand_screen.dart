import 'dart:async';
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
import '../../../shared/services/auth_provider.dart';
import '../../../shared/services/game_stats_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_level_map.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../profile/models/profile_catalog.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/vowel_target.dart';
import '../providers/vowel_hand_provider.dart';
import '../services/vowel_hand_map_prefs.dart';
import '../widgets/badge_award_dialog.dart';
import '../widgets/hand_display.dart';
import '../widgets/hint_flash.dart';
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

  /// The ages 1–3 level map's treasure chests: the level 4 chest guards
  /// the Vowels profile badge, the level 8 chest the Spelling badge.
  static const int _vowelsChestLevel = 4;
  static const int _spellingChestLevel = 8;

  /// Map progress for the ages 1–3 level map.
  final _mapPrefs = VowelHandMapPrefs();
  final _statsService = GameStatsService();

  /// Highest toddler level completed (0 if none) — done levels show gold
  /// on the map and the character stands on the next one.
  int _highestCompleted = 0;

  /// The level just finished, when it moved the player on — the map then
  /// shows the character walking from it to the next one.
  int? _movedFromLevel;

  /// Whether the ages 1–3 "Try again" message is showing after a wrong tap.
  bool _showTryAgain = false;

  /// Hides [_showTryAgain] a few seconds after the latest wrong tap.
  Timer? _tryAgainTimer;

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
      _mapPrefs.highestCompleted().then((level) {
        if (mounted) setState(() => _highestCompleted = level);
      });
      // Finished levels feed the ages 1–3 map's progress, and the Learn
      // BSL trail (when playing from it) advances its node.
      provider.onLevelComplete = (score) {
        _recordMapProgress(provider);
        if (widget.trailNodeId != null) {
          final node = bslTrail.firstWhere((n) => n.id == widget.trailNodeId);
          if (node.minScore == null || score >= node.minScore!) {
            context.read<TrailProvider>().completeNode(widget.trailNodeId!);
          }
        }
      };
      if (widget.trailNodeId != null) {
        final node = bslTrail.firstWhere((n) => n.id == widget.trailNodeId);
        context.read<TrailProvider>().enterTrail(widget.trailNodeId!);
        provider.prepareForIntro(
          level: VowelHandLevel.forSignSystem(provider.signSystem)[node.level - 1],
        );
        setState(() => _showingIntro = true);
      } else if (provider.availableLevels.length <= 1) {
        // Only one level available — skip level selection and go straight
        // into the intro countdown.
        provider.prepareForIntro(level: provider.availableLevels.first);
        setState(() => _showingIntro = true);
      } else {
        provider.showLevelSelection();
      }
      provider.onTryAgain = _handleTryAgain;
    });
  }

  /// Records a finished level on the ages 1–3 map's progress, and sets the
  /// character walking from it when that moved the player on.
  Future<void> _recordMapProgress(VowelHandProvider provider) async {
    if (provider.ageGroup != AgeGroup.years1to3) return;
    // Any level from the age group's list — including the timed CCVC level
    // at position 8 — feeds the map. Its map position, not the level's
    // internal number, is the key here.
    if (!provider.availableLevels.contains(provider.selectedLevel)) return;
    final level = provider.displayNumberOf(provider.selectedLevel);
    await _mapPrefs.recordCompleted(level);
    if (!mounted) return;
    final levelCount = provider.availableLevels.length;
    setState(() {
      if (level > _highestCompleted && level < levelCount) {
        _movedFromLevel = level;
      }
      _highestCompleted = math.max(_highestCompleted, level);
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

  /// Shows "Try again" (in the UI language) with its matching audio after
  /// a wrong tap. Further wrong taps while it is showing keep it up for
  /// longer but don't restart the audio over itself.
  void _handleTryAgain() {
    if (!mounted) return;
    if (!_showTryAgain) {
      AudioService.playTryAgain(locale: widget.locale);
      setState(() => _showTryAgain = true);
    }
    _tryAgainTimer?.cancel();
    _tryAgainTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showTryAgain = false);
    });
  }

  @override
  void dispose() {
    _tryAgainTimer?.cancel();
    AudioService.stopTts();
    super.dispose();
  }

  /// The `<gameId>[.levelN]` id used to look up both the instruction text
  /// (`'<id>.intro'`) and its matching audio for the current level.
  String _introGameId(VowelHandProvider provider) {
    final level = provider.selectedLevel;
    if (provider.isIacWarmUp) return 'iac_vowels.warmup';
    if (level.isToddler) {
      final base =
          provider.signSystem == SignSystem.iac ? 'iac_vowels' : 'vowel_hand';
      return '$base.toddler.level${level.number}';
    }
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
                    'assets/backgrounds/felt-background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  // The ages 1–3 level map paints its own meadow, so it
                  // runs full-bleed to the bottom edge — the grass covers
                  // the safe area. Everything else keeps the inset.
                  bottom: !(provider.showLevelSelect &&
                      provider.ageGroup == AgeGroup.years1to3),
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
                                  levelNumber: provider.displayNumberOf(
                                      provider.selectedLevel),
                                  centerContent: provider.selectedLevel.isToddler
                                      // Untimed — show letters done instead.
                                      ? Center(
                                          child: Text(
                                            '${provider.score} / ${provider.totalRounds}',
                                            style: const TextStyle(
                                              fontFamily: 'Quicksand',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : provider.selectedLevel.isMultiVowel
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
                    // Recorded level-name clips only exist for the main
                    // levels; an id with no clips keeps toddler levels silent
                    // rather than announcing the main level of that number.
                    levelNameGameId: provider.selectedLevel.isToddler
                        ? 'vowel_hand_toddler'
                        : 'vowel_hand',
                    signSystem: provider.signSystem,
                    locale: widget.locale,
                    characterImage: AssetPaths.vowelHandIntroImage,
                    backgroundImage:
                        'assets/backgrounds/felt-background.jpg',
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
                          : provider.nextLevel == null
                              ? null
                              : () {
                                  // Ages 1–3 return to the level map: the
                                  // character walks on to the next level
                                  // there, and its chest state updates.
                                  if (provider.ageGroup == AgeGroup.years1to3) {
                                    provider.showLevelSelection();
                                    return;
                                  }
                                  // Ends at the last level for the player's
                                  // age group (see VowelHandLevel.forAgeGroup).
                                  provider.prepareForIntro(
                                      level: provider.nextLevel);
                                  setState(() => _showingIntro = true);
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
    // Ages 1–3 pick from the winding level map (with the level 4 treasure
    // chest); everyone else uses the standard level list.
    if (provider.ageGroup == AgeGroup.years1to3) {
      return _buildToddlerLevelMap(provider, l);
    }
    return LevelSelectScreen(
      locale: widget.locale,
      levels: provider.availableLevels.map((level) {
        final number = provider.displayNumberOf(level);
        return LevelSelectItem(
          number: number,
          name: level == VowelHandLevel.toddlerVowels &&
                  provider.availableLevels.first == level
              // Ages 3+ warm-up Level 1 — named separately from the same
              // level's place as ages 1–3 Level 2.
              ? l.translate('vowel_hand.warmup.name')
              : _levelText(l, provider.signSystem, level, 'name'),
          // description: _levelText(l, provider.signSystem, level, 'description'),
          color: levelColor(number - 1),
          onTap: () {
            provider.prepareForIntro(level: level);
            setState(() => _showingIntro = true);
          },
        );
      }).toList(),
    );
  }

  /// Looks up the level-select label for [field] ('name'/'description') for
  /// [level], preferring an IAC-specific override (`vowel_hand.iac.levelN.*`)
  /// when one exists and falling back to the shared BSL/English text
  /// otherwise (e.g. Levels 1 & 2, whose wording already fits both sign
  /// systems). Toddler levels use `vowel_hand[.iac].toddler.levelN.*`.
  String _levelText(AppLocalizations l, SignSystem signSystem,
      VowelHandLevel level, String field) {
    final levelKey = level.isToddler
        ? 'toddler.level${level.number}'
        : 'level${level.number}';
    if (signSystem == SignSystem.iac) {
      final iacKey = 'vowel_hand.iac.$levelKey.$field';
      final iacText = l.translate(iacKey);
      if (iacText != iacKey) return iacText;
    }
    return l.translate('vowel_hand.$levelKey.$field');
  }

  /// The ages 1–3 level map: the eight toddler-and-CCVC levels along a
  /// winding path, with treasure chests guarding profile badges — the
  /// Vowels badge at level 4, the Spelling badge at level 8.
  Widget _buildToddlerLevelMap(
    VowelHandProvider provider,
    AppLocalizations localizer,
  ) {
    final stats = context.watch<ProfileProvider>().stats;
    String playLabel(int level) => localizer('vowel_hand.play_level')
        .replaceAll('{n}', '$level');
    return GameLevelMap(
      levelCount: provider.availableLevels.length,
      highestCompleted: _highestCompleted,
      characterThumb: 'assets/images/characters/abi_thumb.png',
      characterLabel: 'Abi',
      isChestLevel: (level) =>
          level == _vowelsChestLevel || level == _spellingChestLevel,
      chestState: (level) {
        if (_chestBadgeEarned(level, stats)) return ChestState.opened;
        return _highestCompleted >= level
            ? ChestState.ready
            : ChestState.locked;
      },
      onLevelSelected: (level) => _startMapLevel(provider, level),
      onChestTapped: (level) => _onChestTapped(provider, level, localizer),
      levelLabel: playLabel,
      movedFromLevel: _movedFromLevel,
      chestLabel: (level) =>
          '${playLabel(level)}, ${localizer('vowel_hand.chest_title')}',
    );
  }

  /// The badge guarded by the chest on [level].
  ProfileBadge _chestBadge(int level) =>
      badgeById(level == _spellingChestLevel ? 'spelling' : 'vowels');

  /// The `player_stats` game id that records opening the chest on [level].
  String _chestBadgeGameId(int level) => level == _spellingChestLevel
      ? spellingBadgeGameId
      : vowelsBadgeGameId;

  /// The award-dialog heading for the chest on [level].
  String _chestBadgeHeadingKey(int level) => level == _spellingChestLevel
      ? 'vowel_hand.spelling_badge_won'
      : 'vowel_hand.badge_won';

  /// Whether the badge guarded by the chest on [level] has been earned.
  bool _chestBadgeEarned(int level, List<Map<String, dynamic>> stats) =>
      _chestBadge(level).isEarned(stats);

  void _startMapLevel(VowelHandProvider provider, int level) {
    // The walk has been seen; don't replay it on the next visit to the map.
    _movedFromLevel = null;
    provider.prepareForIntro(level: provider.availableLevels[level - 1]);
    setState(() => _showingIntro = true);
  }

  /// A chest level: once the level is finished and its badge not yet
  /// earned, opens the chest (awarding the profile badge); once open — or
  /// still locked — plays the level, like any other level.
  Future<void> _onChestTapped(
    VowelHandProvider provider,
    int level,
    AppLocalizations localizer,
  ) async {
    final profile = context.read<ProfileProvider>();
    if (_chestBadgeEarned(level, profile.stats) || _highestCompleted < level) {
      _startMapLevel(provider, level);
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.userId == null || auth.isAnonymous) {
      await showBadgeMapMessage(
        context,
        message: localizer('general.sign_in_to_save_scores'),
        localizer: localizer,
      );
      return;
    }
    // The badge award is a player_stats row under the chest's game id —
    // the same store every profile badge reads its earned state from.
    await _statsService.recordGameResult(_chestBadgeGameId(level), 1);
    await profile.refresh();
    if (!mounted) return;
    AudioService.playCorrect('vowel_hand');
    await showBadgeAwardDialog(
      context,
      badge: _chestBadge(level),
      heading: localizer(_chestBadgeHeadingKey(level)),
      localizer: localizer,
    );
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

    if (provider.selectedLevel.isMultiVowel) {
      if (provider.currentMultiPuzzle == null) return null;
      return MultiVowelWordDisplay(
        puzzle: provider.currentMultiPuzzle!,
        isCorrect: provider.isGuessCorrect,
      );
    }

    if (!provider.selectedLevel.isVowelMatch) {
      if (provider.currentPuzzle == null) return null;
      // No thumbnail artwork exists for the Welsh CVC word list (IAC).
      // The fixed-word levels and ages 1–3 Level 8 use English words with
      // pictures for both sign systems, so their thumbnails always apply.
      final hasThumbnail = provider.selectedLevel.isFixedWords ||
          provider.isPictureWordLevel ||
          (provider.selectedLevel.isShortWords &&
              provider.signSystem == SignSystem.bsl);
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
          fontFamily: 'OpenDyslexic',
          fontSize: AppSizes.fontSizeTitle * 2,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Size of the open hand box: 95% of the screen width (80% when the W/Y
  /// badges are shown, leaving room for them) at the image's aspect ratio.
  /// Derived purely from the screen size and level, so it is known up front
  /// and never changes as content elsewhere on the screen appears.
  Size _handSizeFor(BuildContext context, VowelHandProvider provider) {
    final widthFraction = provider.showsWyBadges ? 0.8 : 0.95;
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
                      child: Stack(
                        children: [
                          HandDisplay(
                            key: _handKey,
                            // IAC: drop the sleeve below the cuff so it
                            // overlaps the W/Y badges less.
                            clipBelowCuff: provider.showsWyBadges,
                          ),
                          // Toddler-level hint: the correct fingertip
                          // flashes red.
                          if (_hintTarget(provider) case final target?)
                            Positioned.fill(
                              child: HintFlash(
                                key: ValueKey(provider.hintToken),
                                child: CustomPaint(
                                  painter: FingertipHintPainter(target),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // W and Y vowel badges (IAC only) — bottom corners
          if (provider.showsWyBadges) ...[
            Positioned(
              left: 16,
              bottom: 0,
              child: VowelBadge(
                vowel: 'w',
                onTap: () => provider.onTapAdditionalVowel('w'),
                hintToken:
                    provider.hintVowel == 'w' ? provider.hintToken : null,
              ),
            ),
            Positioned(
              right: 16,
              bottom: 0,
              child: VowelBadge(
                vowel: 'y',
                onTap: () => provider.onTapAdditionalVowel('y'),
                hintToken:
                    provider.hintVowel == 'y' ? provider.hintToken : null,
              ),
            ),
          ],

          // "Try again" after a wrong tap, over the palm so it doesn't
          // cover any fingertip. Ignores touches so taps still reach the
          // hand underneath.
          Align(
            alignment: const Alignment(0, 0.35),
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showTryAgain &&
                        provider.gameState == VowelHandGameState.playing
                    ? 1.0
                    : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge,
                    vertical: AppSizes.paddingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusXLarge),
                    border: Border.all(color: AppColors.accentRed, width: 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh,
                          color: AppColors.accentRed, size: 28),
                      const SizedBox(width: AppSizes.spacingSmall),
                      Text(
                        AppLocalizations(locale: widget.locale)
                            .translate('general.try_again'),
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

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

  /// The fingertip currently flashing as a hint, or null (no hint, or the
  /// hint is on a w/y badge instead).
  VowelTarget? _hintTarget(VowelHandProvider provider) {
    final vowel = provider.hintVowel;
    if (vowel == null) return null;
    for (final target in VowelHandConstants.targets) {
      if (target.vowel == vowel) return target;
    }
    return null;
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
