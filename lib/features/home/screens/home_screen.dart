import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/auth_provider.dart';
import '../widgets/game_tile.dart';


/// Home screen displaying game selection tiles.
///
/// Shows 8 game options:
/// Match - Card Matching Game
/// Bubble Pop - Pop the bubbles with the letter corresponding to the sign
/// Colouring - colour in line drawings
/// BSL Vowels - tap the finger tips to sign the vowels
/// BSL Maths - simple maths using BSL signs
/// Letter Quest - search the map to find the letters to spell a given word
/// Letter Bingo - find the sign for each letter.
/// Who Am I? - who is wearing which clothes?
///
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FileLoader? _chooseGameLoader;
  int _animCycle = 0;
  Timer? _animTimer;
  FileLoader _makeLoader() => FileLoader.fromAsset(
        'assets/choose_a_game.riv',
        riveFactory: Factory.flutter,
      );

  void _triggerAnim() {
    if (!mounted) return;
    final old = _chooseGameLoader;
    setState(() {
      _chooseGameLoader = _makeLoader();
      _animCycle++;
    });
    old?.dispose();
  }

  @override
  void initState() {
    super.initState();
    _chooseGameLoader = _makeLoader();
    // Play the animation after 3 s, then repeat every 6 s.
    Timer(const Duration(seconds: 3), () {
      _triggerAnim();
      _animTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        _triggerAnim();
      });
    });
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _chooseGameLoader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'en');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) => IconButton(
              tooltip: auth.isAnonymous ? 'Save your scores' : 'My account',
              icon: Icon(
                auth.isAnonymous ? Icons.person_outline : Icons.person,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.linkAccount),
            ),
          ),
        ],
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
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: Column(
                    children: [
                      // Title — Rive animation
                      SizedBox(
                        width: constraints.maxWidth.clamp(0.0, 360.0),
                        height: 80,
                        child: RiveWidgetBuilder(
                          key: ValueKey(_animCycle),
                          fileLoader: _chooseGameLoader!,
                          builder: (context, state) => switch (state) {
                            RiveLoading() => const SizedBox.shrink(),
                            RiveFailed() => const SizedBox.shrink(),
                            RiveLoaded(:final controller) => RiveWidget(
                                controller: controller,
                                fit: Fit.contain,
                              ),
                          },
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingSmall),

                      // Game tiles
                      _buildGameTiles(context, localizer, constraints.maxWidth),
                    ],
                  ),
                ),
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
  Widget _buildGameTiles(BuildContext context, AppLocalizations localizer, double width) {
    return Builder(
      builder: (context) {
        final constraints = BoxConstraints(maxWidth: width);
        final mq = MediaQuery.of(context);
        final isTabletLandscape = mq.size.width >= 768 &&
            mq.orientation == Orientation.landscape;
        final crossAxisCount = isTabletLandscape
            ? 4
            : constraints.maxWidth < 400
                ? 2
                : 3;

        final gameTiles = <Widget>[
            GameTile(
              title: localizer.translate('bsl_vowels.title'),
              imagePath: 'assets/images/home_screen/bsl-vowels.jpg',
              onTap: () => _navigateToVowelHand(context),
            ),
            GameTile(
              title: localizer.translate('my_special_dog.title'),
              imagePath: 'assets/images/home_screen/my-special-dog.jpg',
              onTap: () => _navigateToMySpecialDog(context),
            ),
            GameTile(
              title: localizer.translate('card_matching.title'),
              imagePath: 'assets/images/home_screen/card-match.jpg',
              onTap: () => _navigateToCardMatching(context),
            ),
            GameTile(
              title: localizer.translate('bubble_pop.title'),
              imagePath: 'assets/images/home_screen/bubble-pop.jpg',
              onTap: () => _navigateToBubblePop(context),
            ),
            GameTile(
              title: localizer.translate('colouring.title'),
              imagePath: 'assets/images/home_screen/colouring.jpg',
              onTap: () => _navigateToColouring(context),
            ),
            GameTile(
              title: localizer.translate('counting.title'),
              imagePath: 'assets/images/home_screen/counting-game.jpg',
              onTap: () => Navigator.pushNamed(context, AppRoutes.countingGame),
            ),
            GameTile(
              title: localizer.translate('number_line.title'),
              imagePath: 'assets/images/home_screen/make10.jpg',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.numberLineGame),
            ),
            GameTile(
              title: localizer.translate('more_or_less.title'),
              imagePath: 'assets/images/home_screen/more-or-Less.png',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.moreLessGame),
            ),
            // GameTile(
            //   title: 'Counting Back',
            //   imagePath: 'assets/images/home_screen/counting-back.jpg',
            //   onTap: () =>
            //       Navigator.pushNamed(context, AppRoutes.countingBackGame),
            // ),
GameTile(
              title: localizer.translate('bsl_maths.title'),
              imagePath: 'assets/images/home_screen/bsl-maths.jpg',
              onTap: () => _navigateToBslMaths(context),
            ),
            GameTile(
              title: localizer.translate('bsl_sprint.title'),
              imagePath: 'assets/images/home_screen/speed-run.png',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.bslSprint),
            ),
            GameTile(
              title: localizer.translate('letter_quest.title'),
              imagePath: 'assets/images/home_screen/letter-quest.jpg',
              onTap: () => _navigateToLetterQuest(context),
            ),
            GameTile(
              title: localizer.translate('letter_bingo.title'),
              imagePath: 'assets/images/home_screen/letter-bingo.jpg',
              onTap: () => _navigateToLetterBingo(context),
            ),
            GameTile(
              title: localizer.translate('character_id.title'),
              imagePath: 'assets/images/home_screen/who-am-i.jpg',
              onTap: () => _navigateToCharacterId(context),
            ),
            GameTile(
              title: localizer.translate('clothes_line.title'),
              imagePath: 'assets/images/home_screen/clothesline-home.jpg',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.clothesLine),
            ),
            GameTile(
              title: 'BSL Sudoku',
              imagePath: 'assets/images/home_screen/sudoku.jpg',
              onTap: () => Navigator.pushNamed(context, AppRoutes.sudoku),
            ),
            GameTile(
              title: localizer.translate('sphere_runner.title'),
              imagePath: 'assets/images/home_screen/sphere-runner.jpg',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.sphereRunner),
            ),
            GameTile(
              title: 'BSL Word Search',
              imagePath: 'assets/images/home_screen/word-search.png',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.wordSearch),
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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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

  void _navigateToMySpecialDog(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.mySpecialDog);
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

}
