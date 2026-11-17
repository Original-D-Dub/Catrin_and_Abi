import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/home/models/trail_node.dart';
import '../../../features/home/providers/trail_provider.dart';
import '../../../features/home/widgets/trail_navigation.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_instructions_service.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/instruction_bubble.dart';
import '../../../shared/widgets/choose_character_grid.dart';
import '../../../shared/widgets/champion_rosette.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../../bsl_maths/widgets/champion_mode_explainer.dart';
import '../../bsl_maths/widgets/champion_mode_unlocked_banner.dart';
import '../providers/card_game_provider.dart';
import '../widgets/champion_borders_demo.dart';
import '../widgets/champion_hint_overlay.dart';
import '../widgets/card_grid.dart';
import '../widgets/character_select_screen.dart';
import '../widgets/player_mode_tabs.dart';
import '../widgets/two_player_scores.dart';

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
  final _tapInstructionBubbleKey = GlobalKey<InstructionBubbleState>();
  final _instructionsService = GameInstructionsService();

  /// Whether the "tap the first/second card" bubble should show — false
  /// until [GameInstructionsService.hasSeenInstructions] resolves, so it
  /// never flashes on for a returning player.
  bool _showTapInstructions = false;

  static const _tapInstructionsGameId = 'card_matching_tap_instructions';

  /// Whether the Champion Mode hint overlay is open.
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _instructionsService.hasSeenInstructions(_tapInstructionsGameId).then((
      seen,
    ) {
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
        _tapInstructionBubbleKey.currentState?.dismiss();
      };
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tablets (shortest side ≥ 600) get their own two-player level set.
    context.read<CardGameProvider>().isTabletDevice =
        MediaQuery.sizeOf(context).shortestSide >= 600;
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
          appBar: provider.showLevelSelect && provider.pickingPlayer == null
              ? GameAppBar(
                  title: localizer('card_matching.title'),
                  onBack: () => Navigator.pop(context),
                )
              : null,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgrounds/felt-background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: Stack(
                    children: [
                      if (provider.showLevelSelect &&
                          provider.pickingPlayer != null)
                        _buildCharacterSelect(provider, localizer)
                      else if (provider.showLevelSelect)
                        _buildLevelSelectScreen(context, provider, localizer)
                      else
                        _buildGameContent(context, provider, localizer),
                    ],
                  ),
                ),
                if (!provider.showLevelSelect &&
                    provider.hasWon &&
                    provider.isTwoPlayer)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'card_matching',
                      locale: widget.locale,
                      headingOverride: _twoPlayerResult(provider, localizer),
                      extraContent: _TwoPlayerWinnerImage(
                        characters: [
                          if (provider.twoPlayerWinner != 2)
                            provider.player1Character,
                          if (provider.twoPlayerWinner != 1)
                            provider.player2Character,
                        ].whereType<CharacterThumb>().toList(),
                      ),
                      centerExtraContent: true,
                      onPlayAgain: () => provider.resetGame(),
                      onNextLevel: _canAdvance(context, provider)
                          ? () => _onNextLevel(context, provider)
                          : null,
                      onChangeLevel: () => provider.showLevelSelection(),
                    ),
                  )
                else if (!provider.showLevelSelect && provider.hasWon)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'card_matching',
                      locale: widget.locale,
                      scoreStyle: SuccessScoreStyle.custom,
                      customScoreLine: localizer(
                        'card_matching.success_moves',
                      ).replaceAll('{n}', '${provider.moveCount}'),
                      scoreAudioPrefix: 'card_matching_success_moves',
                      scoreAudioNumber: provider.moveCount,
                      scoreAudioSuffix: 'card_matching_moves_suffix',
                      personalBestSuffix: localizer(
                        'card_matching.moves_suffix',
                      ),
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
                // Shown once per player after Champion Mode unlocks: over
                // the success overlay when this game completed the set, or
                // over the level select when the unlock was found on
                // opening the game (e.g. levels finished before the banner
                // existed). Never mid-game or during character select.
                if (provider.justUnlockedChampionMode &&
                    (provider.showLevelSelect
                        ? provider.pickingPlayer == null
                        : provider.hasWon))
                  Positioned.fill(
                    child: ChampionModeUnlockedBanner(
                      locale: widget.locale,
                      textKey: 'card_matching.champion_mode.unlocked_banner',
                      onContinue: () {
                        provider.dismissChampionModeUnlockedBanner();
                        provider.showLevelSelection();
                        showChampionModeExplainer(
                          context,
                          locale: widget.locale,
                          bodyKey: 'card_matching.champion_mode.explainer',
                          demo: ChampionBordersDemo(
                            signSystem: provider.signSystem,
                          ),
                        );
                      },
                    ),
                  ),
                Positioned.fill(
                  child: LevelTransitionOverlay(
                    opacity: levelTransitionOpacity,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The chosen character's name for [player] (1 or 2), falling back to
  /// "Player N" if none was picked.
  String _playerName(
    CardGameProvider provider,
    int player,
    AppLocalizations localizer,
  ) {
    final character = player == 1
        ? provider.player1Character
        : provider.player2Character;
    return character != null
        ? character.name
        : localizer('card_matching.player$player');
  }

  /// "{name} wins!" or "It's a draw!" for a finished two-player game.
  String _twoPlayerResult(
    CardGameProvider provider,
    AppLocalizations localizer,
  ) {
    final winner = provider.twoPlayerWinner;
    if (winner == null) return localizer('card_matching.draw');
    return localizer(
      'card_matching.player_wins',
    ).replaceAll('{name}', _playerName(provider, winner, localizer));
  }

  /// Character select for whichever player is choosing; once player 2 has
  /// picked, the provider returns to the level select.
  Widget _buildCharacterSelect(
    CardGameProvider provider,
    AppLocalizations localizer,
  ) {
    final player = provider.pickingPlayer!;
    return CharacterSelectScreen(
      key: ValueKey('character_select_$player'),
      player: player,
      takenCharacter: player == 2 ? provider.player1Character : null,
      localizer: localizer,
      onBack: provider.backFromCharacterSelect,
      onPick: provider.pickCharacter,
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
      titleBadge: provider.isChampionModeUnlocked
          ? ChampionRosette(
              value: provider.championMode,
              onChanged: provider.setChampionMode,
              localizer: localizer,
            )
          : null,
      aboveTitle: PlayerModeTabs(
        isTwoPlayer: provider.isTwoPlayer,
        onChanged: provider.setTwoPlayer,
        localizer: localizer,
      ),
      locale: widget.locale,
      levels: provider.levels.map((level) {
        return LevelSelectItem(
          number: level.levelNumber,
          name: localizer(level.name),
          color: levelColor(level.levelNumber - 1),
          // Two-player characters are already chosen by now — picking them
          // happens when the Two Players tab is tapped.
          onTap: () => startLevelWithTransition(
            gameId: provider.levelNameAudioId,
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
    final isTabletLandscape =
        mediaQuery.size.width >= 768 &&
        mediaQuery.orientation == Orientation.landscape;

    final cardGrid = CardGrid(
      cards: provider.cards,
      levelNumber: provider.level.levelNumber,
      onCardTap: (cardId) => provider.selectCard(cardId: cardId),
      signSystem: provider.signSystem,
      locale: widget.locale,
      championMode: provider.championMode,
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
              // Two-player shows both players' scores in place of moves.
              showScore: !provider.isTwoPlayer,
              levelNumber: provider.level.levelNumber,
              centerContent: provider.isTwoPlayer
                  ? TwoPlayerScores(
                      player1Score: provider.player1Score,
                      player2Score: provider.player2Score,
                      player1Name: _playerName(provider, 1, localizer),
                      player2Name: _playerName(provider, 2, localizer),
                      currentPlayer: provider.currentPlayer,
                    )
                  : Center(
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

            // Champion Mode hint: reveals the pair of the card just turned
            // over. Enabled only while one card is waiting for its partner
            // and the player has hints left (see CardGameProvider.maxHints).
            if (provider.championMode)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                  right: AppSizes.paddingMedium,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TertiaryButton(
                    label: localizer(
                      'card_matching.hint',
                    ).replaceAll('{n}', '${provider.hintsRemaining}'),
                    icon: Icons.lightbulb,
                    fontSize: AppSizes.fontSizeBody,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium,
                      vertical: AppSizes.spacingXSmall,
                    ),
                    onPressed: provider.canShowHint
                        ? () {
                            if (provider.useHint()) {
                              setState(() => _showHint = true);
                            }
                          }
                        : null,
                  ),
                ),
              ),

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
                          padding: const EdgeInsets.all(AppSizes.paddingMedium),
                          child: CardGrid(
                            cards: provider.cards,
                            levelNumber: provider.level.levelNumber,
                            onCardTap: (cardId) =>
                                provider.selectCard(cardId: cardId),
                            signSystem: provider.signSystem,
                            locale: widget.locale,
                            championMode: provider.championMode,
                            availableHeight:
                                playAreaConstraints.maxHeight -
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
                padding: const EdgeInsets.only(
                  top: 8 + 88 + AppSizes.spacingSmall,
                ),
                child: InstructionBubble(
                  key: _tapInstructionBubbleKey,
                  audioGameId: 'card_matching',
                  autoHideAfter: const Duration(milliseconds: 3000),
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
        // Keyed on isAwaitingSecondCard, not canShowHint — spending the
        // last hint must not close the overlay it just opened.
        if (_showHint &&
            provider.isAwaitingSecondCard &&
            provider.hintPair != null)
          Positioned.fill(
            child: ChampionHintOverlay(
              card: provider.firstSelection!,
              pair: provider.hintPair!,
              signSystem: provider.signSystem,
              title: localizer('card_matching.hint_title'),
              dismissLabel: localizer('card_matching.got_it'),
              onDismiss: () => setState(() => _showHint = false),
            ),
          ),
      ],
    );
  }
}

/// The two-player winner's full character art on the success screen — or
/// both characters side by side for a draw. Falls back to the thumbnail
/// when a character has no full-size art yet (see
/// [CharacterThumb.fullAssetPath]).
class _TwoPlayerWinnerImage extends StatelessWidget {
  final List<CharacterThumb> characters;

  const _TwoPlayerWinnerImage({required this.characters});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final character in characters)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSmall,
              ),
              child: character.fullAssetPath != null
                  ? Image.asset(character.fullAssetPath!, fit: BoxFit.contain)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusMedium,
                      ),
                      child: Image.asset(
                        character.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
