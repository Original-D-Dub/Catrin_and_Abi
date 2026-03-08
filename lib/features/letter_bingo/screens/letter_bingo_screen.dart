import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/tts_helper.dart';
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
  /// TTS engine for game instructions
  FlutterTts? _tts;

  /// Tracks the last phase to detect transitions to playing
  LetterBingoPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  /// Initializes the TTS engine with a British female voice.
  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
    }
  }

  /// Speaks game instructions when a level starts.
  void _speakInstructions() {
    try {
      _tts?.speak(
        'Find the letters. Get all the letters in a row for Bingo!',
      );
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  @override
  void dispose() {
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LetterBingoProvider>(
      builder: (context, provider, _) {
        // Detect transition to playing phase and speak instructions
        if (provider.phase == LetterBingoPhase.playing &&
            _lastPhase != LetterBingoPhase.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakInstructions();
          });
        }
        _lastPhase = provider.phase;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              provider.phase == LetterBingoPhase.levelSelect
                  ? 'Letter Bingo'
                  : 'Level ${provider.currentLevel?.number ?? ""}',
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.accentWhite,
              ),
            ),
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: AppColors.accentWhite),
              onPressed: () => _handleBack(context, provider),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/backgrounds/math-background-1080x1920.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: _buildBody(context, provider),
            ),
          ),
        );
      },
    );
  }

  /// Handles the back button press.
  ///
  /// During gameplay, returns to level select.
  /// During level select, pops back to home.
  void _handleBack(BuildContext context, LetterBingoProvider provider) {
    if (provider.phase == LetterBingoPhase.levelSelect) {
      Navigator.of(context).pop();
    } else {
      provider.showLevelSelection();
    }
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
  ///
  /// Same visual pattern as Bubble Pop and BSL Maths level selectors.
  Widget _buildLevelSelect(
      BuildContext context, LetterBingoProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'Choose a Level',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),

            // Subtitle
            const Text(
              'Match the BSL signs to the called letters!',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeBody,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingLarge),

            // Level buttons in 2-column grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.spacingMedium,
              crossAxisSpacing: AppSizes.spacingMedium,
              childAspectRatio: 1.3,
              children: [
                _buildLevelButton(
                  levelNumber: 1,
                  name: 'Learning Level',
                  subtitle: 'Letters a – e',
                  color: AppColors.connectorGold,
                  onTap: () => provider.startLevel(levelNumber: 1),
                ),
                _buildLevelButton(
                  levelNumber: 2,
                  name: 'a to i',
                  subtitle: '2 × 3 grid',
                  color: AppColors.abiPink,
                  onTap: () => provider.startLevel(levelNumber: 2),
                ),
                _buildLevelButton(
                  levelNumber: 3,
                  name: 'a to o',
                  subtitle: '3 × 3 grid',
                  color: AppColors.accentNavyBlue,
                  onTap: () => provider.startLevel(levelNumber: 3),
                ),
                _buildLevelButton(
                  levelNumber: 4,
                  name: 'a to u',
                  subtitle: '4 × 4 grid',
                  color: AppColors.schoolGreen,
                  onTap: () => provider.startLevel(levelNumber: 4),
                ),
                _buildLevelButton(
                  levelNumber: 5,
                  name: 'a to z',
                  subtitle: '4 × 4 grid',
                  color: AppColors.accentPurple,
                  onTap: () => provider.startLevel(levelNumber: 5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a level selection button.
  ///
  /// Parameters:
  /// - [levelNumber]: The level number to display
  /// - [name]: The level name/description
  /// - [subtitle]: Additional info text
  /// - [color]: Background color for the button
  /// - [onTap]: Callback when button is tapped
  Widget _buildLevelButton({
    required int levelNumber,
    required String name,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
        elevation: 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Level $levelNumber',
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXSmall),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeBody,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacingXSmall),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeSmall,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Gameplay
  // ─────────────────────────────────────────

  /// Builds the gameplay view with tile grid and called letter display.
  ///
  /// Layout (Column):
  /// - Expanded center: tile grid (Row of 5 for L1, GridView 2×3 for L2)
  /// - Bottom: [CalledLetterDisplay] widget
  /// - Overlay: [BingoCelebration] when phase == bingo
  Widget _buildGameplay(BuildContext context, LetterBingoProvider provider) {
    return Stack(
      children: [
        // Main gameplay content
        Column(
          children: [
            // Tile grid area (expanded to fill available space)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  child: _buildTileGrid(provider),
                ),
              ),
            ),

            // Called letter display at bottom
            if (provider.calledLetter != null)
              CalledLetterDisplay(letter: provider.calledLetter!),
          ],
        ),

        // BINGO celebration overlay
        if (provider.phase == LetterBingoPhase.bingo)
          Positioned.fill(
            child: BingoCelebration(
              onDismiss: () => provider.showLevelSelection(),
              alignment: _bingoAlignment(provider),
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
                  hideRevealedText: true,
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

  /// Determines the BINGO celebration alignment.
  ///
  /// - **Level 1**: Centered on screen.
  /// - **Level 2**: Positioned towards the completed row
  ///   (top half for row 0, bottom half for row 1).
  Alignment _bingoAlignment(LetterBingoProvider provider) {
    if (provider.currentLevel?.winByCompletingAllTiles == true) {
      return Alignment.center;
    }

    // Level 2: align to the completed row
    final completedRow = provider.completedRow;
    if (completedRow == 0) {
      return const Alignment(0, -0.3);
    } else {
      return const Alignment(0, 0.3);
    }
  }
}
