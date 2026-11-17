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
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/instruction_bubble.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../../../shared/widgets/rotate_device_overlay.dart';
import '../../card_matching/widgets/player_mode_tabs.dart';
import '../models/letter_bingo_level.dart';
import '../providers/letter_bingo_provider.dart';
import 'animal_collection_screen.dart';
import '../widgets/bingo_celebration.dart';
import '../widgets/bingo_tile.dart';
import '../widgets/called_letter_display.dart';
import '../widgets/caller_view.dart';
import '../widgets/winner_fireworks.dart';

/// Main screen for the Letter Bingo game.
///
/// Switches between two views based on the provider's phase:
/// - **Level select**: 1 Player / Multiplayer tabs (as in Card Match).
///   1 Player shows the grid of level buttons; Multiplayer shows two tiles,
///   Caller and Player.
/// - **Caller** (multiplayer): [CallerView] — the called letter's sign and
///   a scrolling list of letters already called.
/// - **Player** (multiplayer): a 3×6 bingo card of printed letters (two
///   blanks per row, Level 8's layout) to tap-mark; a full row is BINGO.
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

  /// Bumped by the multiplayer Winner button to set off [WinnerFireworks].
  int _winnerFireworks = 0;

  /// After Winner, returns to the level select once the fireworks have had
  /// their moment — see [_onWinner].
  Timer? _winnerTimer;
  static const _winnerReturnDelay = Duration(seconds: 6);
  final _tapInstructionBubbleKey = GlobalKey<InstructionBubbleState>();
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
    _instructionsService.hasSeenInstructions(_tapInstructionsGameId).then((
      seen,
    ) {
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
    _winnerTimer?.cancel();
    super.dispose();
  }

  /// Winner tapped: counts the win, sets off the fireworks, and after
  /// [_winnerReturnDelay] goes back to the level select (still on
  /// Multiplayer). Tapping Winner again in the meantime replays the
  /// fireworks without restarting the wait. Nothing happens at the end if
  /// the player has already left the checking view (Keep Playing or back).
  void _onWinner(LetterBingoProvider provider) {
    provider.recordWin();
    setState(() => _winnerFireworks++);
    _winnerTimer ??= Timer(_winnerReturnDelay, () {
      _winnerTimer = null;
      if (!mounted || provider.checkingRow == null) return;
      provider.showLevelSelection();
    });
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
                image: AssetImage('assets/backgrounds/felt-background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            // The game is best played landscape — in portrait a
            // RotateDeviceOverlay replaces it (level select works either
            // way), matching BSL Number Builder.
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (provider.phase != LetterBingoPhase.levelSelect &&
                    orientation == Orientation.portrait) {
                  return RotateDeviceOverlay(
                    locale: widget.locale,
                    onBack: () => _leaveGame(context, provider),
                  );
                }
                return _buildContent(context, provider, localizer, auth);
              },
            ),
          ),
        );
      },
    );
  }

  /// Leaves gameplay: advances the trail when this session came from it,
  /// otherwise returns to the level select.
  void _leaveGame(BuildContext context, LetterBingoProvider provider) {
    if (_isMultiplayerPhase(provider.phase)) {
      provider.showLevelSelection();
      return;
    }
    final trail = context.read<TrailProvider>();
    if (trail.activeNodeId != null) {
      advanceTrail(context, trail);
    } else {
      provider.showLevelSelection();
    }
  }

  static bool _isMultiplayerPhase(LetterBingoPhase phase) =>
      phase == LetterBingoPhase.caller ||
      phase == LetterBingoPhase.player ||
      phase == LetterBingoPhase.playerBingo;

  /// The body, BINGO celebration and level-transition fade, stacked.
  Widget _buildContent(
    BuildContext context,
    LetterBingoProvider provider,
    AppLocalizations localizer,
    AuthProvider auth,
  ) {
    return Stack(
      children: [
        SafeArea(child: _buildBody(context, provider, localizer)),
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
              onChangeLevel: () => _leaveGame(context, provider),
            ),
          ),
        // Multiplayer player card BINGO — no reward animal or next level;
        // Play Again deals a fresh card.
        if (provider.phase == LetterBingoPhase.playerBingo)
          Positioned.fill(
            child: BingoCelebration(
              locale: widget.locale,
              signSystem: provider.signSystem,
              levelNumber: provider.currentLevel?.number ?? 1,
              onPlayAgain: provider.startPlayerCard,
              onCheck: provider.checkPlayerCard,
              onSeeCollection: () {},
              onChangeLevel: provider.showLevelSelection,
            ),
          ),

        Positioned.fill(
          child: LevelTransitionOverlay(opacity: levelTransitionOpacity),
        ),
      ],
    );
  }

  /// Restarts the current level (shared by the celebration's "Play Again"
  /// and the collection screen's "Play Again").
  void _playAgain(LetterBingoProvider provider) {
    provider.startLevel(levelNumber: provider.currentLevel?.number ?? 1);
  }

  /// "Next Level" for [BingoCelebration] — advances the trail when this
  /// session came from it, otherwise behaves exactly like every other
  /// game's next-level button (next level in this game, null on the last).
  VoidCallback? _nextLevelCallback(
    BuildContext context,
    LetterBingoProvider provider,
  ) {
    if (context.watch<TrailProvider>().activeNodeId != null) {
      return () => advanceTrail(context, context.read<TrailProvider>());
    }
    final current = provider.currentLevel?.number ?? 1;
    if (current >= provider.levels.length) return null;
    return () => provider.startLevel(levelNumber: current + 1);
  }

  /// Builds the appropriate body widget based on the current phase.
  Widget _buildBody(
    BuildContext context,
    LetterBingoProvider provider,
    AppLocalizations localizer,
  ) {
    switch (provider.phase) {
      case LetterBingoPhase.levelSelect:
        return _buildLevelSelect(context, provider, localizer);
      case LetterBingoPhase.playing:
      case LetterBingoPhase.bingo:
        return _buildGameplay(context, provider, localizer);
      case LetterBingoPhase.caller:
        return _buildMultiplayerScreen(
          context,
          provider,
          title: localizer('letter_bingo.caller'),
          child: CallerView(
            letter: provider.callerLetter,
            calledLetters: provider.calledHistory,
            totalLetters: provider.alphabetSize,
            onNext: provider.callerNext,
            locale: widget.locale,
          ),
        );
      case LetterBingoPhase.player:
      case LetterBingoPhase.playerBingo:
        // Checking view (after Check): the green Winner button is laid over
        // the card (see _buildTileGrid); tapping it sets off fireworks over
        // the whole screen.
        return Stack(
          children: [
            _buildMultiplayerScreen(
              context,
              provider,
              title: localizer('letter_bingo.player'),
              scoreLabel: localizer('letter_bingo.won'),
              scoreValue: provider.gamesWon,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Center(child: _buildTileGrid(provider, localizer)),
              ),
            ),
            Positioned.fill(child: WinnerFireworks(trigger: _winnerFireworks)),
          ],
        );
    }
  }

  // ─────────────────────────────────────────
  // Level Select
  // ─────────────────────────────────────────

  /// Builds the level selection view: 1 Player / Multiplayer tabs above the
  /// title, then either the level grid (4 columns on a landscape tablet) or
  /// the Caller and Player tiles side by side.
  Widget _buildLevelSelect(
    BuildContext context,
    LetterBingoProvider provider,
    AppLocalizations localizer,
  ) {
    final tabs = PlayerModeTabs(
      isTwoPlayer: provider.isMultiplayer,
      onChanged: provider.setMultiplayer,
      localizer: localizer,
      onePlayerLabel: localizer('letter_bingo.one_player'),
      twoPlayerLabel: localizer('letter_bingo.multiplayer'),
    );

    if (provider.isMultiplayer) {
      return LevelSelectScreen(
        locale: widget.locale,
        aboveTitle: tabs,
        fixedColumns: 2,
        levels: [
          LevelSelectItem(
            number: 1,
            displayLabel: localizer('letter_bingo.caller'),
            name: localizer('letter_bingo.caller_description'),
            color: levelColor(0),
            onTap: provider.startCaller,
          ),
          LevelSelectItem(
            number: 2,
            displayLabel: localizer('letter_bingo.player'),
            name: localizer('letter_bingo.player_description'),
            color: levelColor(1),
            onTap: provider.startPlayerCard,
          ),
        ],
      );
    }

    return LevelSelectScreen(
      locale: widget.locale,
      aboveTitle: tabs,
      tabletLandscapeColumns: 4,
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
            // Gameplay is landscape, so even phones fit Level 1's full row
            // of 5 — no narrow-screen tile reduction needed.
            startLevel: () => provider.startLevel(levelNumber: level.number),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────
  // Multiplayer
  // ─────────────────────────────────────────

  /// Header bar (back arrow + [title]) above [child], for the multiplayer
  /// Caller and Player screens. Back returns to the level select. With
  /// [scoreValue] set, the header's score box shows it under [scoreLabel].
  Widget _buildMultiplayerScreen(
    BuildContext context,
    LetterBingoProvider provider, {
    required String title,
    required Widget child,
    String? scoreLabel,
    int? scoreValue,
  }) {
    return Column(
      children: [
        const SizedBox(height: 8),
        GameHeaderBar(
          onBack: provider.showLevelSelection,
          showScore: scoreValue != null,
          scoreLabel: scoreLabel ?? '',
          scoreValue: '${scoreValue ?? 0}',
          showLevel: false,
          levelNumber: 1,
          centerContent: Center(
            child: Text(
              title,
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
        Expanded(child: child),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Gameplay
  // ─────────────────────────────────────────

  /// Builds the gameplay view with tile grid and called letter display.
  ///
  /// Landscape layout (portrait shows [RotateDeviceOverlay] instead):
  /// - Top: [GameHeaderBar]
  /// - Left: [CalledLetterDisplay] with the "try again" feedback
  /// - Right (expanded): tile grid, scaled to fit
  /// - Overlay: [BingoCelebration] when phase == bingo
  Widget _buildGameplay(
    BuildContext context,
    LetterBingoProvider provider,
    AppLocalizations localizer,
  ) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide > 600;
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
    final secondLetterGate = showTapInstructions
        ? _tapSecondAudioCompleter.future
        : null;

    return Stack(
      children: [
        // Main gameplay content (landscape): header across the top,
        // called letter + feedback on the left, tile grid filling the right.
        Column(
          children: [
            const SizedBox(height: 8),

            // Header bar with back arrow and level number
            GameHeaderBar(
              onBack: () => _leaveGame(context, provider),
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

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => _buildPlayArea(
                  provider,
                  localizer,
                  constraints,
                  isTablet: isTablet,
                  firstLetterGate: firstLetterGate,
                  secondLetterGate: secondLetterGate,
                ),
              ),
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
                padding: const EdgeInsets.only(
                  top: 8 + 88 + AppSizes.spacingSmall,
                ),
                child: InstructionBubble(
                  key: _tapInstructionBubbleKey,
                  audioGameId: tappingFirst
                      ? tapFirstAudioGameId
                      : 'letter_bingo',
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

  /// The called-letter panel beside the tile grid.
  ///
  /// Both share one height — the grid's actual fitted height — so on levels
  /// with a Next button ([LetterBingoLevel.callsOffGridLetters]) the button,
  /// pinned to the panel's bottom, sits level with the bottom of the grid.
  Widget _buildPlayArea(
    LetterBingoProvider provider,
    AppLocalizations localizer,
    BoxConstraints constraints, {
    required bool isTablet,
    required Future<void>? firstLetterGate,
    required Future<void>? secondLetterGate,
  }) {
    const gridPadding = AppSizes.paddingMedium;
    // Each grid cell has 2px padding around its tile.
    const tileInset = 2.0;
    final panelWidth = isTablet ? 300.0 : 220.0;
    final level = provider.currentLevel;
    final hasNext = level?.callsOffGridLetters ?? false;

    // Height the grid will actually take: it keeps square cells, so it's
    // limited by whichever of width or height runs out first.
    final cols = level == null
        ? 1
        : (level.rows == 1 ? provider.tiles.length : level.cols);
    final rows = level?.rows ?? 1;
    final maxGridWidth = constraints.maxWidth - panelWidth - gridPadding * 2;
    final maxGridHeight = constraints.maxHeight - gridPadding * 2;
    final widthBoundHeight = cols == 0 ? 0.0 : maxGridWidth * rows / cols;
    final gridHeight =
        (widthBoundHeight < maxGridHeight ? widthBoundHeight : maxGridHeight)
            .clamp(0.0, double.infinity);

    // Always reserves its space (via Opacity, not a conditional) so nothing
    // shifts when it appears.
    final tryAgain = Opacity(
      opacity: _showTryAgain ? 1.0 : 0.0,
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
    );

    final Widget panel;
    if (provider.calledLetter == null) {
      panel = Center(child: tryAgain);
    } else if (hasNext) {
      // Fills the row; inset like the grid's tiles so the Next button's
      // bottom meets the bottom of the last row of tiles.
      panel = Padding(
        padding: const EdgeInsets.symmetric(vertical: gridPadding + tileInset),
        child: CalledLetterDisplay(
          letter: provider.calledLetter!,
          signSystem: provider.signSystem,
          introFuture: firstLetterGate,
          secondCallGateFuture: secondLetterGate,
          locale: widget.locale,
          onNext: provider.nextLetter,
          belowLetter: tryAgain,
        ),
      );
    } else {
      // Called letter with the wrong-tap feedback beneath it, centred;
      // scales down rather than overflowing on short landscape phones.
      panel = Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CalledLetterDisplay(
                letter: provider.calledLetter!,
                signSystem: provider.signSystem,
                introFuture: firstLetterGate,
                secondCallGateFuture: secondLetterGate,
                locale: widget.locale,
              ),
              tryAgain,
            ],
          ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        height: gridHeight + gridPadding * 2,
        child: Row(
          children: [
            SizedBox(width: panelWidth, child: panel),
            // Tile grid, sized to fit the space without scrolling.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(gridPadding),
                child: Center(child: _buildTileGrid(provider, localizer)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the tile grid for the current level ([level.rows] ×
  /// [level.cols]; Level 1 is a single row of 5). Squares with no letter
  /// tile are the level's blanks, drawn as solid palette colours.
  ///
  /// The grid keeps square tiles and scales to fit the space it's given in
  /// both directions, so it never needs to scroll in landscape.
  Widget _buildTileGrid(
    LetterBingoProvider provider, [
    AppLocalizations? localizer,
  ]) {
    final level = provider.currentLevel;
    if (level == null) return const SizedBox.shrink();

    final tiles = provider.tiles;
    final blankColours = provider.blankColours;
    final cols = level.rows == 1 ? tiles.length : level.cols;
    if (cols == 0) return const SizedBox.shrink();
    final rows = level.rows;

    // Grid position → index into [tiles] (the index tapTile expects).
    final tileAt = <int, int>{
      for (var i = 0; i < tiles.length; i++)
        tiles[i].row * cols + tiles[i].col: i,
    };

    final isPlayerCard =
        provider.phase == LetterBingoPhase.player ||
        provider.phase == LetterBingoPhase.playerBingo;

    // Multiplayer: after Check, the completed row is outlined in gold
    // (drawn over the grid so the tiles don't move or resize) and the
    // other rows' letters are dimmed.
    final checkingRow = isPlayerCard ? provider.checkingRow : null;

    Widget cellContent(int position, int? index) {
      if (index != null && isPlayerCard) {
        return PlayerBingoTile(
          tile: tiles[index],
          tileColor: tileColorForIndex(index),
          onTap: () => provider.togglePlayerTile(index: index),
          // Checking view: outside the row being checked, letters drop to
          // 50% opacity and borders go 50% paler.
          dimmed: checkingRow != null && position ~/ cols != checkingRow,
          showSign: provider.isSignShown(index),
        );
      }
      if (index != null) {
        return BingoTileWidget(
          tile: tiles[index],
          tileColor: tileColorForIndex(index),
          signSystem: provider.signSystem,
          onTap: () => provider.tapTile(index: index),
        );
      }
      final colour = blankColours[position];
      if (colour != null) {
        // Checking view: blanks outside the row being checked go 50% paler.
        final pale = checkingRow != null && position ~/ cols != checkingRow;
        final blank = bingoTilePalette[colour];
        return BingoBlankTile(color: pale ? paleBingoColour(blank) : blank);
      }
      return const SizedBox.shrink();
    }

    Widget cell(int position) => cellContent(position, tileAt[position]);

    final grid = Column(
      children: List.generate(rows, (row) {
        return Expanded(
          child: Row(
            children: List.generate(cols, (col) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: cell(row * cols + col),
                ),
              );
            }),
          ),
        );
      }),
    );

    return AspectRatio(
      aspectRatio: cols / rows,
      child: checkingRow == null
          ? grid
          : LayoutBuilder(
              builder: (context, constraints) {
                final rowHeight = constraints.maxHeight / rows;
                const outset = 6.0;
                // Winner button: over whichever side of the checked row has
                // more rows (below on a tie), clear of its outline.
                final rowsAbove = checkingRow;
                final rowsBelow = rows - 1 - checkingRow;
                final below = rowsBelow >= rowsAbove;
                final regionTop = below
                    ? rowHeight * (checkingRow + 1) + outset
                    : 0.0;
                final regionHeight =
                    rowHeight * (below ? rowsBelow : rowsAbove) - outset;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    grid,
                    Positioned(
                      left: -outset,
                      right: -outset,
                      top: rowHeight * checkingRow - outset,
                      height: rowHeight + outset * 2,
                      // A white edge outside a thick gold border, so the
                      // outline stands out against both the felt and the
                      // gold tiles.
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.celebrationGold,
                                  width: 5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (localizer != null && regionHeight > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: regionTop,
                        height: regionHeight,
                        child: Center(
                          child: _buildCheckingButtons(
                            provider,
                            localizer,
                            regionHeight,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  /// The checking view's buttons, side by side at double their normal
  /// size: normal-size buttons scaled up as a whole (labels, icons and
  /// padding) to twice their 64px height — or less, to fit [maxHeight] on
  /// a short screen, or the card's width.
  /// - Left, secondary Keep Playing: leaves the checking view so mistakes
  ///   can be unmarked and play carries on.
  /// - Right, green Winner: counts the win and sets off [WinnerFireworks].
  Widget _buildCheckingButtons(
    LetterBingoProvider provider,
    AppLocalizations localizer,
    double maxHeight,
  ) {
    const normalHeight = 64.0;
    final height = maxHeight < normalHeight * 2 ? maxHeight : normalHeight * 2;
    return SizedBox(
      height: height,
      child: FittedBox(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecondaryButton(
              label: localizer('letter_bingo.keep_playing'),
              icon: Icons.play_arrow,
              onPressed: () {
                // Cancel any pending return from an earlier Winner tap.
                _winnerTimer?.cancel();
                _winnerTimer = null;
                provider.keepPlaying();
              },
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            PrimaryButton(
              label: localizer('letter_bingo.winner'),
              icon: Icons.emoji_events,
              onPressed: () => _onWinner(provider),
            ),
          ],
        ),
      ),
    );
  }
}
