import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/sign_system_toggle.dart';
import '../widgets/game_tile.dart';

/// Pairs a [GameTile] with its filter metadata.
class _GameEntry {
  final Widget tile;
  final GameCategory category;
  final Set<AgeGroup> ageGroups;
  const _GameEntry({required this.tile, required this.category, required this.ageGroups});
}


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
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.settings,
              arguments: 'en',
            ),
          ),
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
        fit: StackFit.expand,
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

                      // BSL/IAC sign system toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localizer('home.sign_system_label'),
                            style: const TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const SignSystemToggle(),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingSmall),

                      // Game tiles
                      _buildGameTiles(context, localizer, constraints.maxWidth, settings),
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

  Widget _buildGameTiles(
    BuildContext context,
    AppLocalizations localizer,
    double width,
    SettingsProvider settings,
  ) {
    return Builder(
      builder: (context) {
        final mq = MediaQuery.of(context);
        final isTabletLandscape =
            mq.size.width >= 768 && mq.orientation == Orientation.landscape;
        final crossAxisCount = isTabletLandscape
            ? 4
            : width < 400
                ? 2
                : 3;

        // Every game is tagged with a category and the school-year bands it
        // suits. Adjust these sets here if the difficulty/topic of a game changes.
        final allGames = <_GameEntry>[
          _GameEntry(
            tile: GameTile(
              title: localizer.translate(settings.signSystem == SignSystem.iac
                  ? 'iac_vowels.title'
                  : 'bsl_vowels.title'),
              imagePath: settings.signSystem == SignSystem.iac
                  ? 'assets/images/home_screen/iac-vowels.jpg'
                  : 'assets/images/home_screen/bsl-vowels.jpg',
              onTap: () => _navigateToVowelHand(context),
            ),
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('my_special_dog.title'),
              imagePath: 'assets/images/home_screen/my-special-dog.jpg',
              onTap: () => _navigateToMySpecialDog(context),
            ),
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('card_matching.title'),
              imagePath: 'assets/images/home_screen/card-match.jpg',
              onTap: () => _navigateToCardMatching(context),
            ),
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('bubble_pop.title'),
              imagePath: 'assets/images/home_screen/bubble-pop.jpg',
              onTap: () => _navigateToBubblePop(context),
            ),
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years1to3},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('colouring.title'),
              imagePath: 'assets/images/home_screen/colouring.jpg',
              onTap: () => _navigateToColouring(context),
            ),
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('counting.title'),
              imagePath: 'assets/images/home_screen/counting-game.jpg',
              onTap: () => Navigator.pushNamed(context, AppRoutes.countingGame,
                  arguments: 'en'),
            ),
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('number_line.title'),
              imagePath: 'assets/images/home_screen/make10.jpg',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.numberLineGame),
            ),
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('more_or_less.title'),
              imagePath: 'assets/images/home_screen/more-or-Less.png',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.moreLessGame),
            ),
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('bsl_maths.title'),
              imagePath: 'assets/images/home_screen/bsl-maths.jpg',
              onTap: () => _navigateToBslMaths(context),
            ),
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('bsl_sprint.title'),
              imagePath: 'assets/images/home_screen/speed-run.png',
              onTap: () => Navigator.pushNamed(context, AppRoutes.bslSprint,
                  arguments: 'en'),
            ),
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('letter_quest.title'),
              imagePath: 'assets/images/home_screen/letter-quest.jpg',
              onTap: () => _navigateToLetterQuest(context),
            ),
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('letter_bingo.title'),
              imagePath: 'assets/images/home_screen/letter-bingo.jpg',
              onTap: () => _navigateToLetterBingo(context),
            ),
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('character_id.title'),
              imagePath: 'assets/images/home_screen/who-am-i.jpg',
              onTap: () => _navigateToCharacterId(context),
            ),
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('clothes_line.title'),
              imagePath: 'assets/images/home_screen/clothesline-home.jpg',
              onTap: () => Navigator.pushNamed(context, AppRoutes.clothesLine),
            ),
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('sudoku.title'),
              imagePath: 'assets/images/home_screen/sudoku.jpg',
              onTap: () => Navigator.pushNamed(context, AppRoutes.sudoku),
            ),
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years5plus},
          ),
          _GameEntry(
            tile: GameTile(
              title: localizer.translate('sphere_runner.title'),
              imagePath: 'assets/images/home_screen/sphere-runner.jpg',
              onTap: () => Navigator.pushNamed(context, AppRoutes.sphereRunner),
            ),
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
          ),
          _GameEntry(
            tile: GameTile(
              title: 'BSL Word Search',
              imagePath: 'assets/images/home_screen/word-search.png',
              onTap: () => Navigator.pushNamed(context, AppRoutes.wordSearch),
            ),
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
          ),
        ];

        final gameTiles = allGames.where((g) {
          final catOk = settings.gameCategory == GameCategory.all ||
              g.category == settings.gameCategory;
          final ageOk = settings.ageGroup == AgeGroup.all ||
              g.ageGroups.contains(settings.ageGroup);
          return catOk && ageOk;
        }).map((g) => g.tile).toList();

        if (gameTiles.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No games match the current filters.\nOpen Settings to adjust.',
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Pad the last row with the logo so the grid stays even.
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
    Navigator.pushNamed(context, AppRoutes.bubblePop, arguments: 'en');
  }

  /// Navigates to the colouring game.
  void _navigateToColouring(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.colouring);
  }

  /// Navigates to the BSL vowel hand game.
  void _navigateToVowelHand(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.vowelHand, arguments: 'en');
  }

  void _navigateToMySpecialDog(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.mySpecialDog);
  }

  /// Navigates to the BSL maths game.
  void _navigateToBslMaths(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.bslMaths, arguments: 'en');
  }

  /// Navigates to the letter quest RPG game.
  void _navigateToLetterQuest(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.letterQuest);
  }

  /// Navigates to the letter bingo game.
  void _navigateToLetterBingo(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.letterBingo, arguments: 'en');
  }

  /// Navigates to the character identification game.
  void _navigateToCharacterId(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.characterId);
  }

}
