import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
// import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
import '../widgets/game_tile.dart';
// import '../widgets/placeholder_tile.dart';

/// Home screen displaying game selection tiles.
///
/// Shows 6 game options:
/// Match - Card Matching Game
/// Bubble Pop - Pop the bubbles with the letter corresponding to the sign
/// Colouring - colour in line drawings
/// BSL Vowels - tap the finger tips to sign the vowels
/// BSL Maths - simple maths using BSL signs
/// Letter Quest - search the map to find the letters to spell a given word
///
/// Only the Card Matching game is playable in this iteration.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'en');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/home-screen-background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Title
                  Text(
                    localizer.translate('home.title'),
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeHeading,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ComicRelief',
                      color: AppColors.accentWhite,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),

                  // Game tiles
                  Expanded(
                    child: _buildGameTiles(context, localizer),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a responsive grid of game tiles.
  ///
  /// Uses [LayoutBuilder] to adapt the column count based on
  /// available width:
  /// - Narrow (< 400px): 2 columns
  /// - Medium (400–599px): 3 columns
  /// - Wide (>= 600px): 3 columns (capped for child-friendly tap targets)
  Widget _buildGameTiles(BuildContext context, AppLocalizations localizer) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 400 ? 2 : 3;

        final gameTiles = <Widget>[
            GameTile(
              title: localizer.translate('home.card_matching'),
              imagePath: 'assets/images/home_screen/card-match.jpg',
              onTap: () => _navigateToCardMatching(context),
            ),
            GameTile(
              title: localizer.translate('home.bubble_pop'),
              imagePath: 'assets/images/home_screen/bubble-pop.jpg',
              onTap: () => _navigateToBubblePop(context),
            ),
            GameTile(
              title: 'Colouring',
              imagePath: 'assets/images/home_screen/colouring.jpg',
              onTap: () => _navigateToColouring(context),
            ),
            GameTile(
              title: 'BSL Vowels',
              imagePath: 'assets/images/home_screen/bsl-vowels.jpg',
              onTap: () => _navigateToVowelHand(context),
            ),
            GameTile(
              title: 'BSL Maths',
              imagePath: 'assets/images/home_screen/bsl-maths.jpg',
              onTap: () => _navigateToBslMaths(context),
            ),
            GameTile(
              title: 'Letter Quest',
              imagePath: 'assets/images/home_screen/letter-quest.jpg',
              onTap: () => _navigateToLetterQuest(context),
            ),
            GameTile(
              title: 'Letter Bingo',
              imagePath: 'assets/images/home_screen/letter-bingo.jpg',
              onTap: () => _navigateToLetterBingo(context),
            ),
            GameTile(
              title: 'Who Am I?',
              imagePath: 'assets/images/home_screen/who-am-i.jpg',
              onTap: () => _navigateToCharacterId(context),
            ),
            if (!kIsWeb)
              GameTile(
                title: 'Camera Vowels',
                imagePath: 'assets/images/home_screen/bsl-vowels.jpg',
                onTap: () => _navigateToCameraVowels(context),
              ),
            if (!kIsWeb)
              GameTile(
                title: 'Wave Hello!',
                imagePath: 'assets/images/home_screen/Hello.jpg',
                onTap: () => Navigator.pushNamed(context, AppRoutes.waveHello),
              ),
          ];

        // Add logo to fill the last row if it's not complete
        final remainder = gameTiles.length % crossAxisCount;
        if (remainder != 0) {
          gameTiles.add(
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingSmall),
              child: Image.asset(
                'assets/logos/english/Catrin_Abi_Logo_Eng_600x600.png',
                fit: BoxFit.contain,
              ),
            ),
          );
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: gameTiles,
        );
      },
    );
  }

  /// Navigates to the card matching game.
  void _navigateToCardMatching(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.cardMatching);
  }

  /// Navigates to the bubble pop game.
  void _navigateToBubblePop(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.bubblePop);
  }

  /// Navigates to the colouring game.
  void _navigateToColouring(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.colouring);
  }

  /// Navigates to the BSL vowel hand game.
  void _navigateToVowelHand(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.vowelHand);
  }

  /// Navigates to the BSL maths game.
  void _navigateToBslMaths(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.bslMaths);
  }

  /// Navigates to the letter quest RPG game.
  void _navigateToLetterQuest(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.letterQuest);
  }

  /// Navigates to the letter bingo game.
  void _navigateToLetterBingo(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.letterBingo);
  }

  /// Navigates to the character identification game.
  void _navigateToCharacterId(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.characterId);
  }

  /// Navigates to the BSL camera vowels game.
  void _navigateToCameraVowels(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.cameraVowels);
  }
}
