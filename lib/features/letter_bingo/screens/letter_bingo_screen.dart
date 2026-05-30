import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../providers/letter_bingo_provider.dart';
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
class LetterBingoScreen extends StatefulWidget {
  const LetterBingoScreen({super.key});

  @override
  State<LetterBingoScreen> createState() => _LetterBingoScreenState();
}

class _LetterBingoScreenState extends State<LetterBingoScreen> {
  LetterBingoPhase? _lastPhase;
  Future<void>? _introFuture;
  bool _showTryAgain = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LetterBingoProvider>();
      provider.onCorrect = () => AudioService.playCorrect('letter_bingo');
      provider.onWrongTap = _handleWrongTap;
    });
  }

  void _handleWrongTap() {
    if (!mounted) return;
    setState(() => _showTryAgain = true);
    AudioService.speak('Try again');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTryAgain = false);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LetterBingoProvider>(
      builder: (context, provider, _) {
        // Detect transition to playing phase and play intro
        if (provider.phase == LetterBingoPhase.playing &&
            _lastPhase != LetterBingoPhase.playing) {
          _introFuture = AudioService.playIntroAndWait('letter_bingo');
        }
        _lastPhase = provider.phase;

        final auth = context.read<AuthProvider>();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.phase == LetterBingoPhase.levelSelect
              ? GameAppBar(
                  title: 'Letter Bingo',
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
                  child: _buildBody(context, provider),
                ),
                if (provider.phase == LetterBingoPhase.bingo)
                  Positioned.fill(
                    child: BingoCelebration(
                      animal: auth.isAnonymous ? null : provider.rewardAnimal,
                      playerId: auth.userId,
                      levelNumber: provider.currentLevel?.number ?? 1,
                      onPlayAgain: () {
                        final levelNumber = provider.currentLevel?.number ?? 1;
                        final isNarrow =
                            MediaQuery.of(context).size.width < 441;
                        provider.startLevel(
                          levelNumber: levelNumber,
                          tileCountOverride:
                              (levelNumber == 1 && isNarrow) ? 3 : null,
                        );
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

/// Builds the appropriate body widget based on the current phase.
  Widget _buildBody(BuildContext context, LetterBingoProvider provider) {
    switch (provider.phase) {
      case LetterBingoPhase.levelSelect:
        return _buildLevelSelect(context, provider);
      case LetterBingoPhase.playing:
      case LetterBingoPhase.bingo:
        return _buildGameplay(context, provider);
    }
  }

  // ─────────────────────────────────────────
  // Level Select
  // ─────────────────────────────────────────

  /// Builds the level selection view with title and 2-column grid.
  Widget _buildLevelSelect(
      BuildContext context, LetterBingoProvider provider) {
    return LevelSelectScreen(
      subtitle: 'Match the B.S.L. signs to the called letters!',
      levels: [
        LevelSelectItem(
          number: 1,
          name: 'a to e',
          color: levelColor(0),
          onTap: () {
            final isNarrow = MediaQuery.of(context).size.width < 441;
            provider.startLevel(
              levelNumber: 1,
              tileCountOverride: isNarrow ? 3 : null,
            );
          },
        ),
        LevelSelectItem(
          number: 2,
          name: 'a to i',
          color: levelColor(1),
          onTap: () => provider.startLevel(levelNumber: 2),
        ),
        LevelSelectItem(
          number: 3,
          name: 'a to o',
          color: levelColor(2),
          onTap: () => provider.startLevel(levelNumber: 3),
        ),
        LevelSelectItem(
          number: 4,
          name: 'a to u',
          color: levelColor(3),
          onTap: () => provider.startLevel(levelNumber: 4),
        ),
        LevelSelectItem(
          number: 5,
          name: 'a to z',
          color: levelColor(4),
          onTap: () => provider.startLevel(levelNumber: 5),
        ),
      ],
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
  Widget _buildGameplay(BuildContext context, LetterBingoProvider provider) {
    return Stack(
      children: [
        // Main gameplay content
        Column(
          children: [
            const SizedBox(height: 8),

            // Header bar with back arrow and level number
            GameHeaderBar(
              onBack: () => provider.showLevelSelection(),
              showScore: false,
              levelNumber: provider.currentLevel?.number ?? 1,
              centerContent: Center(
                child: Text(
                  provider.currentLevel?.name ?? '',
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tile grid area (expanded to fill available space)
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    child: _buildTileGrid(provider),
                  ),
                ),
              ),
            ),

            // Wrong-tap feedback shown below the grid
            if (_showTryAgain)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Try again!',
                  style: TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Called letter display at bottom
            if (provider.calledLetter != null)
              CalledLetterDisplay(
                letter: provider.calledLetter!,
                introFuture: _introFuture,
              ),
          ],
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
            onTap: () => provider.tapTile(index: index),
          );
        },
      );
    }
  }


}
