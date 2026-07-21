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
import '../models/home_game_entry.dart';

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
        final allGames = <HomeGameEntry>[
          homeGameEntry(
            route: AppRoutes.vowelHand,
            titleKey: settings.signSystem == SignSystem.iac
                ? 'iac_vowels.title'
                : 'bsl_vowels.title',
            imagePath: settings.signSystem == SignSystem.iac
                ? 'assets/images/home_screen/iac-vowels.jpg'
                : 'assets/images/home_screen/bsl-vowels.jpg',
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
            arguments: 'en',
          ),
          homeGameEntry(
            route: AppRoutes.mySpecialDog,
            titleKey: 'my_special_dog.title',
            imagePath: 'assets/images/home_screen/my-special-dog.jpg',
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          homeGameEntry(
            route: AppRoutes.cardMatching,
            titleKey: 'card_matching.title',
            imagePath: 'assets/images/home_screen/card-match.jpg',
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          homeGameEntry(
            route: AppRoutes.bubblePop,
            titleKey: 'bubble_pop.title',
            imagePath: 'assets/images/home_screen/bubble-pop.jpg',
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years1to3},
            arguments: 'en',
          ),
          homeGameEntry(
            route: AppRoutes.colouring,
            titleKey: 'colouring.title',
            imagePath: 'assets/images/home_screen/colouring.jpg',
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3},
          ),
          // A/B test duplicate of colouring — delete with lib/features/colouring2/.
          homeGameEntry(
            route: AppRoutes.colouring2,
            titleKey: 'colouring2.title',
            imagePath: 'assets/images/home_screen/colouring.jpg',
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3},
          ),
          homeGameEntry(
            route: AppRoutes.numberRace,
            titleKey: 'number_race.title',
            imagePath: 'assets/images/home_screen/number-race.png',
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
            arguments: 'en',
          ),
          homeGameEntry(
            route: AppRoutes.countingGame,
            titleKey: 'counting.title',
            imagePath: 'assets/images/home_screen/counting-game.jpg',
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
            arguments: 'en',
          ),
          homeGameEntry(
            route: AppRoutes.numberLineGame,
            titleKey: 'number_line.title',
            imagePath: 'assets/images/home_screen/make10.jpg',
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          homeGameEntry(
            route: AppRoutes.moreLessGame,
            titleKey: 'more_or_less.title',
            imagePath: 'assets/images/home_screen/more-or-Less.png',
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          homeGameEntry(
            route: AppRoutes.bslMaths,
            titleKey: 'bsl_maths.title',
            imagePath: 'assets/images/home_screen/bsl-maths.jpg',
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
            arguments: 'en',
          ),
          homeGameEntry(
            route: AppRoutes.bslSprint,
            titleKey: 'bsl_sprint.title',
            imagePath: 'assets/images/home_screen/speed-run.png',
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
            arguments: 'en',
          ),
          homeGameEntry(
            route: AppRoutes.letterQuest,
            titleKey: 'letter_quest.title',
            imagePath: 'assets/images/home_screen/letter-quest.jpg',
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
            arguments: 'en',
          ),
          homeGameEntry(
            route: AppRoutes.letterBingo,
            titleKey: 'letter_bingo.title',
            imagePath: 'assets/images/home_screen/letter-bingo.jpg',
            category: GameCategory.alphabet,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
            arguments: 'en',
          ),
          homeGameEntry(
            route: AppRoutes.characterId,
            titleKey: 'character_id.title',
            imagePath: 'assets/images/home_screen/who-am-i.jpg',
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          homeGameEntry(
            route: AppRoutes.clothesLine,
            titleKey: 'clothes_line.title',
            imagePath: 'assets/images/home_screen/clothesline-home.jpg',
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
          ),
          homeGameEntry(
            route: AppRoutes.sudoku,
            titleKey: 'sudoku.title',
            imagePath: 'assets/images/home_screen/sudoku.jpg',
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years5plus},
          ),
          homeGameEntry(
            route: AppRoutes.sphereRunner,
            titleKey: 'sphere_runner.title',
            imagePath: 'assets/images/home_screen/sphere-runner.jpg',
            category: GameCategory.numeracy,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
          ),
          homeGameEntry(
            route: AppRoutes.wordSearch,
            titleKey: 'word_search.title',
            imagePath: 'assets/images/home_screen/word-search.png',
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
          ),
          homeGameEntry(
            route: AppRoutes.zoo,
            titleKey: 'zoo.title',
            imagePath: 'assets/images/home_screen/zoo.png',
            category: GameCategory.vocabulary,
            ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
            arguments: 'en',
          ),
        ];

        final gameTiles = buildGameTiles(context, allGames, settings, localizer);

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
}
