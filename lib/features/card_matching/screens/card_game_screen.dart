import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/home/models/trail_node.dart';
import '../../../features/home/providers/trail_provider.dart';
import '../../../features/home/widgets/trail_navigation.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_instructions_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../providers/card_game_provider.dart';
import '../widgets/card_grid.dart';

/// Main screen for the card matching game.
///
/// Displays:
/// - Level selection screen (Choose a Level)
/// - Level title in app bar during gameplay
/// - Instructions
/// - Card grid
/// - Match counter
/// - Success overlay when game is won
///
/// [locale] controls UI text ('en' or 'cy'); the sign system (BSL/IAC) is
/// read from [CardGameProvider.signSystem], set when the route is created
/// from the player's current sign-system preference.
class CardGameScreen extends StatefulWidget {
  final String locale;

  /// Set when launched from the "Learn BSL trail" — the id of the trail
  /// node this session represents. Null for normal play from the game's
  /// own home tile.
  final String? trailNodeId;

  const CardGameScreen({super.key, this.locale = 'en', this.trailNodeId});

  @override
  State<CardGameScreen> createState() => _CardGameScreenState();
}

class _CardGameScreenState extends State<CardGameScreen>
    with LevelTransitionMixin<CardGameScreen> {
  final _tapInstructionBubbleKey = GlobalKey<_TapInstructionBubbleState>();
  final _instructionsService = GameInstructionsService();

  /// Whether the "tap the first/second card" bubble should show — false
  /// until [GameInstructionsService.hasSeenInstructions] resolves, so it
  /// never flashes on for a returning player.
  bool _showTapInstructions = false;

  static const _tapInstructionsGameId = 'card_matching_tap_instructions';

  @override
  void initState() {
    super.initState();
    _instructionsService.hasSeenInstructions(_tapInstructionsGameId).then((seen) {
      if (mounted && !seen) setState(() => _showTapInstructions = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CardGameProvider>();
      // A trail launch already starts at its target level (see
      // CardGameProvider's initialLevelNumber) — forcing level-select here
      // would undo that.
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
      }
      provider.onAnswerResult = (isMatch) {
        if (isMatch) {
          AudioService.playCorrect('card_matching');
        } else {
          AudioService.playWrong('card_matching');
        }
      };
      provider.onSecondCardFlipped = () {
        _tapInstructionBubbleKey.currentState?._dismiss();
      };
    });
  }

  /// Marks the tap instructions seen for good — via the bubble's "got it"
  /// link or by completing a first pair-matching attempt — and hides it.
  void _dismissTapInstructions() {
    _instructionsService.markInstructionsSeen(_tapInstructionsGameId);
    if (mounted) setState(() => _showTapInstructions = false);
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);

    return Consumer<CardGameProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('card_matching.title'),
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
                  child: Stack(
                    children: [
                      if (provider.showLevelSelect)
                        _buildLevelSelectScreen(context, provider, localizer)
                      else
                        _buildGameContent(context, provider, localizer),
                    ],
                  ),
                ),
                if (!provider.showLevelSelect && provider.hasWon)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'card_matching',
                      locale: widget.locale,
                      scoreStyle: SuccessScoreStyle.custom,
                      customScoreLine: localizer('card_matching.success_moves')
                          .replaceAll('{n}', '${provider.moveCount}'),
                      scoreAudioPrefix: 'card_matching_success_moves',
                      scoreAudioNumber: provider.moveCount,
                      scoreAudioSuffix: 'card_matching_moves_suffix',
                      personalBestSuffix: localizer('card_matching.moves_suffix'),
                      imageAsset: 'assets/success/Abi-as-Holmes.png',
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () => provider.resetGame(),
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
  bool _canAdvance(BuildContext context, CardGameProvider provider) {
    if (context.watch<TrailProvider>().activeNodeId != null) return true;
    return provider.level.levelNumber < provider.levels.length;
  }

  /// "Next Level" — advances the trail when this session came from it,
  /// otherwise behaves exactly as it always has (next level in this game).
  void _onNextLevel(BuildContext context, CardGameProvider provider) {
    final trail = context.read<TrailProvider>();
    if (trail.activeNodeId != null) {
      advanceTrail(context, trail);
    } else {
      provider.startLevel(provider.levels[provider.level.levelNumber]);
    }
  }

  /// Builds the level selection screen.
  Widget _buildLevelSelectScreen(
    BuildContext context,
    CardGameProvider provider,
    AppLocalizations localizer,
  ) {
    final introKey = provider.signSystem == SignSystem.iac
        ? 'card_matching.iac.intro'
        : 'card_matching.bsl.intro';

    return LevelSelectScreen(
      subtitle: localizer(introKey),
      locale: widget.locale,
      levels: provider.levels.map((level) {
        return LevelSelectItem(
          number: level.levelNumber,
          name: localizer(level.name),
          color: levelColor(level.levelNumber - 1),
          onTap: () => startLevelWithTransition(
            gameId: 'card_matching',
            levelNumber: level.levelNumber,
            locale: widget.locale,
            signSystem: provider.signSystem,
            startLevel: () => provider.startLevel(level),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the main game content with header bar.
  Widget _buildGameContent(
    BuildContext context,
    CardGameProvider provider,
    AppLocalizations localizer,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final isTabletLandscape = mediaQuery.size.width >= 768 &&
        mediaQuery.orientation == Orientation.landscape;

    final cardGrid = CardGrid(
      cards: provider.cards,
      levelNumber: provider.level.levelNumber,
      onCardTap: (cardId) => provider.selectCard(cardId: cardId),
      signSystem: provider.signSystem,
      locale: widget.locale,
    );

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),

            GameHeaderBar(
              onBack: () {
                final trail = context.read<TrailProvider>();
                if (trail.activeNodeId != null) {
                  advanceTrail(context, trail);
                } else {
                  provider.showLevelSelection();
                }
              },
              scoreLabel: localizer('card_matching.moves_label'),
              scoreValue: '${provider.moveCount}',
              scoreLabelFontSize: 12,
              scoreValueFontSize: 32,
              levelNumber: provider.level.levelNumber,
              centerContent: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizer(provider.level.name),
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${provider.matchCount}/${provider.totalPairs} ${localizer('card_matching.pairs_label')}',
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: isTabletLandscape
                  ? Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: cardGrid,
                    )
                  : LayoutBuilder(
                      // Captured here, before SingleChildScrollView gives its
                      // child unbounded height along the scroll axis.
                      builder: (context, playAreaConstraints) {
                        return SingleChildScrollView(
                          padding:
                              const EdgeInsets.all(AppSizes.paddingMedium),
                          child: CardGrid(
                            cards: provider.cards,
                            levelNumber: provider.level.levelNumber,
                            onCardTap: (cardId) =>
                                provider.selectCard(cardId: cardId),
                            signSystem: provider.signSystem,
                            locale: widget.locale,
                            availableHeight: playAreaConstraints.maxHeight -
                                AppSizes.paddingMedium * 2,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        if (_showTapInstructions)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              // 8px leading gap + GameHeaderBar's fixed 88px height + a
              // small breathing gap, so the bubble sits just below the
              // header bar instead of overlapping it.
              child: Padding(
                padding: const EdgeInsets.only(top: 8 + 88 + AppSizes.spacingSmall),
                child: _TapInstructionBubble(
                  key: _tapInstructionBubbleKey,
                  messageKey: provider.firstSelection != null
                      ? 'tap_second'
                      : 'tap_first',
                  text: provider.firstSelection != null
                      ? localizer('card_matching.tap_second')
                      : localizer('card_matching.tap_first'),
                  locale: widget.locale,
                  dismissLabel: localizer('card_matching.got_it'),
                  onDismiss: _dismissTapInstructions,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pink instruction bubble that stays visible for 3 seconds and then fades
/// out over 300ms. Switches from the "tap first" to the "tap second"
/// prompt (and reappears, playing that prompt's spoken clip) as soon as
/// the player flips their first card, then is dismissed for good — via
/// [onDismiss] — once they flip their second, since by then they've shown
/// they know how to play. Includes a "got it" link that dismisses it
/// immediately.
class _TapInstructionBubble extends StatefulWidget {
  final String text;

  /// Identifies which prompt [text] is — `'tap_first'` or `'tap_second'` —
  /// so the matching `card_matching_<messageKey>` clip can be played
  /// whenever it's the one being shown.
  final String messageKey;

  final String dismissLabel;
  final String locale;

  /// Called when the bubble is dismissed for good — via the "got it" link
  /// or by completing a first pair-matching attempt — used to persist that
  /// instructions shouldn't be shown again.
  final VoidCallback onDismiss;

  const _TapInstructionBubble({
    super.key,
    required this.text,
    required this.messageKey,
    required this.dismissLabel,
    required this.locale,
    required this.onDismiss,
  });

  @override
  State<_TapInstructionBubble> createState() => _TapInstructionBubbleState();
}

class _TapInstructionBubbleState extends State<_TapInstructionBubble> {
  static const _visibleDuration = Duration(milliseconds: 3000);
  static const _fadeDuration = Duration(milliseconds: 300);

  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _playMessageAudio();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(_TapInstructionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      setState(() => _visible = true);
      _playMessageAudio();
      _scheduleHide();
    }
  }

  void _playMessageAudio() {
    AudioService.playInstructionClip(
      'card_matching',
      widget.messageKey,
      locale: widget.locale,
    );
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_visibleDuration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _hide() {
    _hideTimer?.cancel();
    setState(() => _visible = false);
  }

  void _dismiss() {
    _hide();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: _fadeDuration,
      child: Container(
        width: isWideScreen ? 320 : 280,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentPurple,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              fit: StackFit.passthrough,
              children: [
                Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1
                      ..color = const Color(0xFF0F57DD),
                  ),
                ),
                Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _dismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.dismissLabel,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.thumb_up, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
