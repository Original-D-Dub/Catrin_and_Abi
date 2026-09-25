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
import '../../../shared/services/auth_provider.dart';
import '../../../shared/services/game_instructions_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../providers/letter_bingo_provider.dart';
import 'animal_collection_screen.dart';
import '../widgets/bingo_celebration.dart';
import '../widgets/bingo_tile.dart';
import '../widgets/called_letter_display.dart';

/// Main screen for the Letter Bingo game.
///
/// Switches between two views based on the provider's phase:
/// - **Level select**: 2-column grid of level buttons (same style as
///   Bubble Pop and BSL Maths level selectors).
/// - **Gameplay**: Tile grid + called letter display at bottom,
///   with BINGO overlay on win.
///
/// The [LetterBingoProvider] is accessed from the widget tree
/// (provided by the route in routes.dart).
///
/// [locale] controls UI text ('en' or 'cy'); the sign system (BSL/IAC) is
/// read from [LetterBingoProvider.signSystem], set when the route is
/// created from the player's current sign-system preference.
class LetterBingoScreen extends StatefulWidget {
  final String locale;

  /// Set when launched from the "Learn BSL trail" — the id of the trail
  /// node this session represents. Null for normal play from the game's
  /// own home tile.
  final String? trailNodeId;

  const LetterBingoScreen({super.key, this.locale = 'en', this.trailNodeId});

  @override
  State<LetterBingoScreen> createState() => _LetterBingoScreenState();
}

class _LetterBingoScreenState extends State<LetterBingoScreen>
    with LevelTransitionMixin<LetterBingoScreen> {
  LetterBingoPhase? _lastPhase;
  Future<void>? _introFuture;
  bool _showTryAgain = false;
  final _tapInstructionBubbleKey = GlobalKey<_TapInstructionBubbleState>();
  final _instructionsService = GameInstructionsService();

  /// Whether the "tap the first/second tile" bubble should show — false
  /// until [GameInstructionsService.hasSeenInstructions] resolves, so it
  /// never flashes on for a returning player.
  bool _showTapInstructions = false;

  static const _tapInstructionsGameId = 'letter_bingo_tap_instructions';

  /// Resolve when the tap_first/tap_second instruction bubble's spoken clip
  /// finishes, so [CalledLetterDisplay] can hold the first/second letter's
  /// sound until the relevant instruction has finished playing. Replaced
  /// with fresh completers on every level (re)start — see the phase
  /// transition in [build].
  Completer<void> _tapFirstAudioCompleter = Completer<void>();
  Completer<void> _tapSecondAudioCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    _instructionsService.hasSeenInstructions(_tapInstructionsGameId).then((seen) {
      if (mounted && !seen) setState(() => _showTapInstructions = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LetterBingoProvider>();
      provider.onCorrect = () => AudioService.playCorrect('letter_bingo');
      provider.onWrongTap = _handleWrongTap;
      if (widget.trailNodeId != null) {
        context.read<TrailProvider>().enterTrail(widget.trailNodeId!);
        provider.onLevelComplete = (score) {
          final node = bslTrail.firstWhere((n) => n.id == widget.trailNodeId);
          if (node.minScore == null || score >= node.minScore!) {
            context.read<TrailProvider>().completeNode(widget.trailNodeId!);
          }
        };
      }
    });
  }

  /// Marks the tap instructions seen for good — via the bubble's "got it"
  /// link or by finishing a level without tapping it — and hides it.
  void _dismissTapInstructions() {
    if (!_showTapInstructions) return;
    _instructionsService.markInstructionsSeen(_tapInstructionsGameId);
    if (mounted) setState(() => _showTapInstructions = false);
  }

  void _handleWrongTap() {
    if (!mounted) return;
    setState(() => _showTryAgain = true);
    AudioService.playTryAgain(locale: widget.locale);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTryAgain = false);
    });
  }

  /// Releases the matching gate future once the tap_first/tap_second
  /// bubble's clip finishes, so [CalledLetterDisplay] can speak the letter
  /// it was holding for.
  void _handleTapInstructionAudioComplete(String messageKey) {
    switch (messageKey) {
      case 'tap_first':
        if (!_tapFirstAudioCompleter.isCompleted) {
          _tapFirstAudioCompleter.complete();
        }
        break;
      case 'tap_second':
        if (!_tapSecondAudioCompleter.isCompleted) {
          _tapSecondAudioCompleter.complete();
        }
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);

    return Consumer<LetterBingoProvider>(
      builder: (context, provider, _) {
        // Detect transition to playing phase and play intro
        if (provider.phase == LetterBingoPhase.playing &&
            _lastPhase != LetterBingoPhase.playing) {
          final introGameId = provider.signSystem == SignSystem.iac
              ? 'letter_bingo.iac'
              : 'letter_bingo.bsl';
          _introFuture = AudioService.playIntroAndWait(introGameId);
          // Fresh completers each (re)start — the previous ones may already
          // be completed from the last playthrough.
          _tapFirstAudioCompleter = Completer<void>();
          _tapSecondAudioCompleter = Completer<void>();
        }
        // Finishing a level counts as "first play" done, even if the player
        // never tapped "got it" — otherwise the instructions would show
        // again on every later level, not just the one they were shown on.
        // Deferred to after this frame since dismissing calls setState, and
        // other parts of this same tree (the tap instruction bubble) are
        // still mid-build here.
        if (provider.phase == LetterBingoPhase.bingo &&
            _lastPhase == LetterBingoPhase.playing &&
            _showTapInstructions) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _dismissTapInstructions();
          });
        }
        _lastPhase = provider.phase;

        final auth = context.read<AuthProvider>();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.phase == LetterBingoPhase.levelSelect
              ? GameAppBar(
                  title: localizer('letter_bingo.title'),
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
                  child: _buildBody(context, provider, localizer),
                ),
                if (provider.phase == LetterBingoPhase.bingo)
                  Positioned.fill(
                    child: BingoCelebration(
                      locale: widget.locale,
                      signSystem: provider.signSystem,
                      animal: auth.isAnonymous ? null : provider.rewardAnimal,
                      playerId: auth.userId,
                      levelNumber: provider.currentLevel?.number ?? 1,
                      onPlayAgain: () => _playAgain(provider),
                      onSeeCollection: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnimalCollectionScreen(
                            onPlayAgain: () => _playAgain(provider),
                            locale: widget.locale,
                            signSystem: provider.signSystem,
                          ),
                        ),
                      ),
                      onNextLevel: _nextLevelCallback(context, provider),
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

  /// Restarts the current level (shared by the celebration's "Play Again"
  /// and the collection screen's "Play Again").
  void _playAgain(LetterBingoProvider provider) {
    final levelNumber = provider.currentLevel?.number ?? 1;
    final isNarrow = MediaQuery.of(context).size.width < 441;
    provider.startLevel(
      levelNumber: levelNumber,
      tileCountOverride: (levelNumber == 1 && isNarrow) ? 3 : null,
    );
  }

  /// "Next Level" for [BingoCelebration] — advances the trail when this
  /// session came from it, otherwise behaves exactly like every other
  /// game's next-level button (next level in this game, null on the last).
  VoidCallback? _nextLevelCallback(
      BuildContext context, LetterBingoProvider provider) {
    if (context.watch<TrailProvider>().activeNodeId != null) {
      return () => advanceTrail(context, context.read<TrailProvider>());
    }
    final current = provider.currentLevel?.number ?? 1;
    if (current >= provider.levels.length) return null;
    return () => provider.startLevel(levelNumber: current + 1);
  }

/// Builds the appropriate body widget based on the current phase.
  Widget _buildBody(BuildContext context, LetterBingoProvider provider,
      AppLocalizations localizer) {
    switch (provider.phase) {
      case LetterBingoPhase.levelSelect:
        return _buildLevelSelect(context, provider, localizer);
      case LetterBingoPhase.playing:
      case LetterBingoPhase.bingo:
        return _buildGameplay(context, provider, localizer);
    }
  }

  // ─────────────────────────────────────────
  // Level Select
  // ─────────────────────────────────────────

  /// Builds the level selection view with title and 2-column grid.
  Widget _buildLevelSelect(BuildContext context, LetterBingoProvider provider,
      AppLocalizations localizer) {
    return LevelSelectScreen(
      locale: widget.locale,
      levels: provider.levels.map((level) {
        return LevelSelectItem(
          number: level.number,
          name: localizer(level.name),
          color: levelColor(level.number - 1),
          onTap: () => startLevelWithTransition(
            gameId: 'letter_bingo',
            levelNumber: level.number,
            locale: widget.locale,
            signSystem: provider.signSystem,
            startLevel: () {
              if (level.number == 1) {
                final isNarrow = MediaQuery.of(context).size.width < 441;
                provider.startLevel(
                  levelNumber: 1,
                  tileCountOverride: isNarrow ? 3 : null,
                );
              } else {
                provider.startLevel(levelNumber: level.number);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────
  // Gameplay
  // ─────────────────────────────────────────

  /// Builds the gameplay view with tile grid and called letter display.
  ///
  /// Layout (Column):
  /// - Expanded center: tile grid (Row of 3 for L1, GridView 2×3 for L2)
  /// - Bottom: [CalledLetterDisplay] widget
  /// - Overlay: [BingoCelebration] when phase == bingo
  Widget _buildGameplay(BuildContext context, LetterBingoProvider provider,
      AppLocalizations localizer) {
    final levelName = provider.currentLevel != null
        ? localizer(provider.currentLevel!.name)
        : '';
    final showTapInstructions =
        provider.phase == LetterBingoPhase.playing && _showTapInstructions;
    final tappingFirst = provider.tappedLetters.isEmpty;
    final tapFirstKey = provider.signSystem == SignSystem.iac
        ? 'letter_bingo.iac.tap_first'
        : 'letter_bingo.bsl.tap_first';
    final tapFirstAudioGameId = provider.signSystem == SignSystem.iac
        ? 'letter_bingo_iac'
        : 'letter_bingo_bsl';

    // Hold the first letter's sound until both the intro and the tap_first
    // bubble's clip have finished; hold the second letter's sound until the
    // tap_second bubble's clip has finished. Only relevant while the
    // instructions are actually showing — once dismissed, letters play as
    // soon as they're called, same as before this bubble existed.
    final firstLetterGate = showTapInstructions
        ? Future.wait([
            _introFuture ?? Future<void>.value(),
            _tapFirstAudioCompleter.future,
          ]).then((_) {})
        : _introFuture;
    final secondLetterGate =
        showTapInstructions ? _tapSecondAudioCompleter.future : null;

    return Stack(
      children: [
        // Main gameplay content
        Column(
          children: [
            const SizedBox(height: 8),

            // Header bar with back arrow and level number
            GameHeaderBar(
              onBack: () {
                final trail = context.read<TrailProvider>();
                if (trail.activeNodeId != null) {
                  advanceTrail(context, trail);
                } else {
                  provider.showLevelSelection();
                }
              },
              showScore: false,
              levelNumber: provider.currentLevel?.number ?? 1,
              centerContent: Center(
                child: Text(
                  levelName,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tile grid area (expanded to fill available space)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingLarge),
                          child: _buildTileGrid(provider),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Wrong-tap feedback shown below the grid. Always reserves its
            // space (via Opacity, not a conditional) so the grid above
            // doesn't shift when the message appears/disappears.
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: _showTryAgain ? 1.0 : 0.0,
                child: Text(
                  localizer('general.try_again'),
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Called letter display at bottom
            if (provider.calledLetter != null)
              CalledLetterDisplay(
                letter: provider.calledLetter!,
                signSystem: provider.signSystem,
                introFuture: firstLetterGate,
                secondCallGateFuture: secondLetterGate,
                locale: widget.locale,
              ),
          ],
        ),

        if (showTapInstructions)
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
                  audioGameId:
                      tappingFirst ? tapFirstAudioGameId : 'letter_bingo',
                  messageKey: tappingFirst ? 'tap_first' : 'tap_second',
                  text: tappingFirst
                      ? localizer(tapFirstKey)
                      : localizer('letter_bingo.tap_second'),
                  locale: widget.locale,
                  dismissLabel: localizer('letter_bingo.got_it'),
                  onDismiss: _dismissTapInstructions,
                  onAudioComplete: _handleTapInstructionAudioComplete,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the tile grid based on the current level.
  ///
  /// - **Level 1**: Single horizontal row of 5 tiles.
  /// - **Levels 2–5**: Grid using [level.cols] columns, 4px spacing.
  Widget _buildTileGrid(LetterBingoProvider provider) {
    final level = provider.currentLevel;
    if (level == null) return const SizedBox.shrink();

    final tiles = provider.tiles;

    if (level.rows == 1) {
      // Single row layout (Level 1)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(tiles.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: BingoTileWidget(
                  tile: tiles[index],
                  tileColor: tileColorForIndex(index),
                  signSystem: provider.signSystem,
                  onTap: () => provider.tapTile(index: index),
                ),
              ),
            ),
          );
        }),
      );
    } else {
      // Multi-row grid (Levels 2–5)
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: level.cols,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.0,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, index) {
          return BingoTileWidget(
            tile: tiles[index],
            tileColor: tileColorForIndex(index),
            signSystem: provider.signSystem,
            onTap: () => provider.tapTile(index: index),
          );
        },
      );
    }
  }

}

/// Pink instruction bubble, pinned to the top of the screen, that stays
/// visible until explicitly dismissed via its "got it" link — no auto-hide
/// timer. Same visual style as card_matching's tap instruction bubble:
/// switches from the "tap first" to the "tap second" prompt (and replays
/// that prompt's spoken clip) as soon as the player lands their first
/// correct tap. Dismissing via [onDismiss] persists so it doesn't show
/// again.
class _TapInstructionBubble extends StatefulWidget {
  final String text;

  /// The gameId prefix passed to [AudioService.playInstructionClip] — the
  /// tap_first prompt differs by sign system (`letter_bingo_bsl` /
  /// `letter_bingo_iac`) while tap_second is common (`letter_bingo`).
  final String audioGameId;

  /// Identifies which prompt [text] is — `'tap_first'` or `'tap_second'`.
  final String messageKey;

  final String dismissLabel;
  final String locale;

  /// Called when the bubble is dismissed for good — via the "got it" link
  /// or by landing a second correct tap — used to persist that instructions
  /// shouldn't be shown again.
  final VoidCallback onDismiss;

  /// Called with [messageKey] once the clip currently playing for [text]
  /// finishes — lets the screen hold the matching called letter's sound
  /// until the instruction has finished.
  final void Function(String messageKey)? onAudioComplete;

  const _TapInstructionBubble({
    super.key,
    required this.text,
    required this.audioGameId,
    required this.messageKey,
    required this.dismissLabel,
    required this.locale,
    required this.onDismiss,
    this.onAudioComplete,
  });

  @override
  State<_TapInstructionBubble> createState() => _TapInstructionBubbleState();
}

class _TapInstructionBubbleState extends State<_TapInstructionBubble> {
  static const _fadeDuration = Duration(milliseconds: 300);

  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _playMessageAudio();
  }

  @override
  void didUpdateWidget(_TapInstructionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _playMessageAudio();
    }
  }

  Future<void> _playMessageAudio() async {
    final messageKey = widget.messageKey;
    await AudioService.playInstructionClipAndWait(
      widget.audioGameId,
      messageKey,
      locale: widget.locale,
    );
    widget.onAudioComplete?.call(messageKey);
  }

  void _dismiss() {
    setState(() => _visible = false);
    widget.onDismiss();
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
