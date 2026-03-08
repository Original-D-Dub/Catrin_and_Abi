import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/game_level.dart';
import '../providers/card_game_provider.dart';
import '../widgets/card_grid.dart';
import '../widgets/confetti_overlay.dart';

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
    // Show level selection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardGameProvider>().showLevelSelection();
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
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.accentWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    'Match',
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentWhite,
                    ),
                  ),
                  centerTitle: true,
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
            child: SafeArea(
              child: Stack(
                children: [
                  // Level selection screen
                  if (provider.showLevelSelect)
                    _buildLevelSelectScreen(context, provider)
                  else ...[
                    // Main game content
                    _buildGameContent(context, provider, localizer),

                    // Confetti overlay when won
                    if (provider.hasWon)
                      ConfettiOverlay(
                        message: localizer.translate('card_game.well_done'),
                        playAgainLabel:
                            localizer.translate('card_game.play_again'),
                        homeLabel: localizer.translate('card_game.home'),
                        onPlayAgain: () => provider.resetGame(),
                        onHome: () => _navigateToHome(context),
                        onChangeLevel: () => provider.showLevelSelection(),
                      ),
                  ],
                ],
              ),
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
  ) {
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
                fontSize: AppSizes.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            const Text(
              'Match BSL signs with their letters!',
              style: TextStyle(
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
              children: GameLevel.allLevels().map((level) {
                return _buildLevelButton(
                  context: context,
                  provider: provider,
                  level: level,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a level selection button.
  Widget _buildLevelButton({
    required BuildContext context,
    required CardGameProvider provider,
    required GameLevel level,
  }) {
    final levelColors = [
      AppColors.abiPink,
      AppColors.accentNavyBlue,
      AppColors.accentLimeGreen,
      AppColors.accentOrange,
      AppColors.accentPurple,
      AppColors.catrinBlue,
    ];
    final color = levelColors[(level.levelNumber - 1) % levelColors.length];

    return ElevatedButton(
      onPressed: () => provider.startLevel(level),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Level ${level.levelNumber}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXSmall),
          Text(
            level.name,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeBody,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the main game content with header bar.
  Widget _buildGameContent(
    BuildContext context,
    CardGameProvider provider,
    AppLocalizations localizer,
  ) {
    return Stack(
      children: [
        // Game layout
        Column(
          children: [
            const SizedBox(height: 8),

            // Header bar with score, level title, level number
            _buildHeaderBar(provider),

            const SizedBox(height: 12),

            // Card grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Center(
                  child: CardGrid(
                    cards: provider.cards,
                    onCardTap: (cardId) =>
                        provider.selectCard(cardId: cardId),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Back button overlay (top-left)
        Positioned(
          top: 4,
          left: 4,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              provider.showLevelSelection();
            },
          ),
        ),
      ],
    );
  }

  /// Builds the header bar with score circle, level title, and level number.
  Widget _buildHeaderBar(CardGameProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: SizedBox(
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Purple header rectangle
            Positioned(
              left: 40,
              right: 0,
              top: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.headerBackgroundLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.headerBorderDark,
                    width: 2,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.headerBorderDark,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Spacer for score circle area
                      const SizedBox(width: 48),

                      // Level title (centred)
                      Expanded(
                        child: Center(
                          child: Text(
                            provider.level.name,
                            style: const TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Level section (right)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Level',
                              style: TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${provider.level.levelNumber}',
                              style: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Score circle (overlapping left edge)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.headerBackgroundLight,
                    border: Border.all(
                      color: AppColors.headerBorderDark,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.headerBackground,
                      border: Border.all(
                        color: AppColors.headerBorderDark,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Matches',
                          style: TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${provider.matchCount}/${provider.totalPairs}',
                          style: const TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates back to the home screen.
  void _navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }
}
