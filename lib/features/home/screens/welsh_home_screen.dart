import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/learn_sign_system_tile.dart';
import '../../../shared/widgets/sign_system_toggle.dart';
import '../models/home_game_entry.dart';

/// Welsh-language home screen showing Welsh games.
class WelshHomeScreen extends StatelessWidget {
  const WelshHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'cy');
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          localizer('home.title'),
          style: AppTheme.title.copyWith(fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: localizer('profile.menu.settings'),
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.settings,
              arguments: 'cy',
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => IconButton(
              tooltip: auth.isAnonymous
                  ? localizer('profile.save_scores_heading')
                  : localizer('profile.title'),
              icon: Icon(
                auth.isAnonymous ? Icons.person_outline : Icons.person,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.profile,
                arguments: 'cy',
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/background_purple.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount =
                      gameGridCrossAxisCount(context, constraints.maxWidth);
                  final learnTileHeight =
                      gameGridTileHeight(context, constraints.maxWidth);

                  final allGames = <HomeGameEntry>[
                    homeGameEntry(
                      route: AppRoutes.vowelHand,
                      titleKey: settings.signSystem == SignSystem.iac
                          ? 'iac_vowels.title'
                          : 'bsl_vowels.title',
                      imagePath: settings.signSystem == SignSystem.iac
                          ? 'assets/images/home_screen/llafariaid-iac.jpg'
                          : 'assets/images/home_screen/llafariaid-bsl.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.cardMatching,
                      titleKey: 'card_matching.title',
                      imagePath: 'assets/images/home_screen/paru-cardiau.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.bubblePop,
                      titleKey: 'bubble_pop.title',
                      imagePath: 'assets/images/home_screen/popio-swigod.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.letterBingo,
                      titleKey: 'letter_bingo.title',
                      imagePath: 'assets/images/home_screen/letter-bingo.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.letterQuest,
                      titleKey: 'letter_quest.title',
                      imagePath: 'assets/images/home_screen/cwest-llythren.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.clothesLine,
                      titleKey: 'clothes_line.title',
                      imagePath: 'assets/images/home_screen/pa-liw-sanau.jpg',
                      category: GameCategory.vocabulary,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.numberLineGame,
                      titleKey: 'number_line.title',
                      imagePath: 'assets/images/home_screen/gwenud10.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.moreLessGame,
                      titleKey: 'more_or_less.title',
                      imagePath: 'assets/images/home_screen/mwy-neu-lai.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.numberRace,
                      titleKey: 'number_race.title',
                      imagePath: 'assets/images/home_screen/number-race.png',
                      category: GameCategory.numeracy,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.countingGame,
                      titleKey: 'counting.title',
                      imagePath: 'assets/images/home_screen/counting-game.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.bslMaths,
                      titleKey: 'bsl_maths.title',
                      imagePath: settings.signSystem == SignSystem.iac
                          ? 'assets/images/home_screen/maths-iac.jpg'
                          : 'assets/images/home_screen/maths-bsl.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.sudoku,
                      titleKey: 'sudoku.title',
                      imagePath: 'assets/images/home_screen/sudoku.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: const {AgeGroup.years5plus},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.bslSprint,
                      titleKey: 'bsl_sprint.title',
                      imagePath: 'assets/images/home_screen/speed-run.png',
                      category: GameCategory.alphabet,
                      ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.wordSearch,
                      titleKey: 'word_whirl.title',
                      imagePath: 'assets/images/home_screen/word-search.png',
                      category: GameCategory.vocabulary,
                      ageGroups: const {AgeGroup.years3to5, AgeGroup.years5plus},
                      arguments: 'cy',
                    ),
                    homeGameEntry(
                      route: AppRoutes.zoo,
                      titleKey: 'zoo.title',
                      imagePath: 'assets/images/home_screen/zoo.png',
                      category: GameCategory.vocabulary,
                      ageGroups: const {AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                  ];

                  final gameTiles = buildGameTiles(context, allGames, settings, localizer);

                  final signSystemRow = Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localizer('home.sign_system_label'),
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SignSystemToggle(),
                    ],
                  );

                  if (gameTiles.isEmpty) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          signSystemRow,
                          const SizedBox(height: AppSizes.spacingSmall),
                          LearnSignSystemTile(locale: 'cy', height: learnTileHeight),
                          const SizedBox(height: AppSizes.spacingSmall),
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(
                                localizer('home.no_games_match'),
                                style: const TextStyle(
                                  fontFamily: 'Quicksand',
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Fill last row with Welsh logo
                  final remainder = gameTiles.length % crossAxisCount;
                  if (remainder != 0) {
                    final fill = crossAxisCount - remainder;
                    for (int i = 0; i < fill; i++) {
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
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        signSystemRow,
                        const SizedBox(height: AppSizes.spacingSmall),
                        LearnSignSystemTile(locale: 'cy', height: learnTileHeight),
                        const SizedBox(height: AppSizes.spacingSmall),
                        GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: gameGridSpacing,
                          mainAxisSpacing: gameGridSpacing,
                          childAspectRatio: gameGridChildAspectRatio,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: gameTiles,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
