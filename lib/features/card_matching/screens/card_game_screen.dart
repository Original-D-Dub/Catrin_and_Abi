import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../models/game_level.dart';
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
/// - Confetti overlay when game is won
///
/// Uses [CardGameProvider] for state management.
class CardGameScreen extends StatefulWidget {
  const CardGameScreen({super.key});

  @override
  State<CardGameScreen> createState() => _CardGameScreenState();
}

class _CardGameScreenState extends State<CardGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CardGameProvider>();
      provider.showLevelSelection();
      provider.onAnswerResult = (isMatch) {
        if (isMatch) {
          AudioService.playCorrect('card_matching');
        } else {
          AudioService.playWrong('card_matching');
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'en');

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
                      scoreStyle: SuccessScoreStyle.custom,
                      customScoreLine:
                          'You did it in ${provider.moveCount} moves!',
                      imageAsset: 'assets/success/Abi-as-Holmes.png',
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      personalBestSuffix: ' moves',
                      onPlayAgain: () => provider.resetGame(),
                      onNextLevel: provider.level.levelNumber <
                              GameLevel.allLevels().length
                          ? () {
                              provider.startLevel(GameLevel.allLevels()[
                                  provider.level.levelNumber]);
                            }
                          : null,
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

  /// Builds the level selection screen.
  Widget _buildLevelSelectScreen(
    BuildContext context,
    CardGameProvider provider,
    AppLocalizations localizer,
  ) {
    return LevelSelectScreen(
      subtitle: localizer('card_matching.instructions'),
      levels: GameLevel.allLevels().map((level) {
        return LevelSelectItem(
          number: level.levelNumber,
          name: localizer('card_matching.level${level.levelNumber}.name'),
          color: levelColor(level.levelNumber - 1),
          onTap: () {
            provider.startLevel(level);
            AudioService.playIntro('card_matching');
          },
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
    );

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),

            GameHeaderBar(
              onBack: () => provider.showLevelSelection(),
              scoreLabel: 'Moves',
              scoreValue: '${provider.moveCount}',
              scoreLabelFontSize: 12,
              scoreValueFontSize: 32,
              levelNumber: provider.level.levelNumber,
              centerContent: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizer('card_matching.level${provider.level.levelNumber}.name'),
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${provider.matchCount}/${provider.totalPairs} pairs',
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              provider.firstSelection != null
                  ? localizer('card_matching.tap_second')
                  : localizer('card_matching.tap_first'),
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Expanded(
              child: isTabletLandscape
                  ? Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: cardGrid,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: cardGrid,
                    ),
            ),
          ],
        ),
      ],
    );
  }


}
