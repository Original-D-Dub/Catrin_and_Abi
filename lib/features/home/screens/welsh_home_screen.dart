import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/sign_system_toggle.dart';
import '../widgets/game_tile.dart';

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
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.settings,
              arguments: 'cy',
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
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/home-screen-background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mq = MediaQuery.of(context);
                  final isTabletLandscape = mq.size.width >= 768 &&
                      mq.orientation == Orientation.landscape;
                  final crossAxisCount = isTabletLandscape
                      ? 4
                      : constraints.maxWidth < 400
                          ? 2
                          : 3;

                  final List<({
                    String route,
                    String titleKey,
                    String imagePath,
                    GameCategory category,
                    Set<AgeGroup> ageGroups,
                    String? arguments,
                  })> allGames = [
                    (
                      route: AppRoutes.vowelHand,
                      titleKey: settings.signSystem == SignSystem.iac
                          ? 'iac_vowels.title'
                          : 'bsl_vowels.title',
                      imagePath: settings.signSystem == SignSystem.iac
                          ? 'assets/images/home_screen/llafariaid-iac.jpg'
                          : 'assets/images/home_screen/llafariaid-bsl.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.cardMatching,
                      titleKey: 'card_matching.title',
                      imagePath: 'assets/images/home_screen/paru-cardiau.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.bubblePop,
                      titleKey: 'bubble_pop.title',
                      imagePath: 'assets/images/home_screen/popio-swigod.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.letterBingo,
                      titleKey: 'letter_bingo.title',
                      imagePath: 'assets/images/home_screen/letter-bingo.jpg',
                      category: GameCategory.alphabet,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.clothesLine,
                      titleKey: 'clothes_line.title',
                      imagePath: 'assets/images/home_screen/pa-liw-sanau.jpg',
                      category: GameCategory.vocabulary,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.numberLineGame,
                      titleKey: 'number_line.title',
                      imagePath: 'assets/images/home_screen/gwenud10.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.moreLessGame,
                      titleKey: 'more_or_less.title',
                      imagePath: 'assets/images/home_screen/mwy-neu-lai.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.countingGame,
                      titleKey: 'counting.title',
                      imagePath: 'assets/images/home_screen/counting-game.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.bslMaths,
                      titleKey: 'bsl_maths.title',
                      imagePath: settings.signSystem == SignSystem.iac
                          ? 'assets/images/home_screen/maths-iac.jpg'
                          : 'assets/images/home_screen/maths-bsl.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: <AgeGroup>{AgeGroup.years1to3, AgeGroup.years3to5},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.sudoku,
                      titleKey: 'sudoku.title',
                      imagePath: 'assets/images/home_screen/sudoku.jpg',
                      category: GameCategory.numeracy,
                      ageGroups: <AgeGroup>{AgeGroup.years5plus},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.bslSprint,
                      titleKey: 'bsl_sprint.title',
                      imagePath: 'assets/images/home_screen/speed-run.png',
                      category: GameCategory.alphabet,
                      ageGroups: <AgeGroup>{AgeGroup.years3to5, AgeGroup.years5plus},
                      arguments: 'cy',
                    ),
                    (
                      route: AppRoutes.wordSearch,
                      titleKey: 'word_search.title',
                      imagePath: 'assets/images/home_screen/word-search.png',
                      category: GameCategory.vocabulary,
                      ageGroups: <AgeGroup>{AgeGroup.years3to5, AgeGroup.years5plus},
                      arguments: 'cy',
                    ),
                  ];

                  final gameTiles = allGames.where((g) {
                    final catOk = settings.gameCategory == GameCategory.all ||
                        g.category == settings.gameCategory;
                    final ageOk = settings.ageGroup == AgeGroup.all ||
                        g.ageGroups.contains(settings.ageGroup);
                    return catOk && ageOk;
                  }).map<Widget>((g) => GameTile(
                        title: localizer(g.titleKey),
                        imagePath: g.imagePath,
                        onTap: () => Navigator.pushNamed(context, g.route, arguments: g.arguments),
                      )).toList();

                  final signSystemRow = Row(
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
                  );

                  if (gameTiles.isEmpty) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          signSystemRow,
                          const SizedBox(height: AppSizes.spacingSmall),
                          const SizedBox(
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
                            'assets/logos/welsh/catacabi_font_colour_cym.png',
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
                        GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.85,
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
