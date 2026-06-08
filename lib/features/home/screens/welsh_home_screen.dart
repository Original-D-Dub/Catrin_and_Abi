import 'package:flutter/material.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../widgets/game_tile.dart';

/// Welsh-language home screen showing Welsh games.
class WelshHomeScreen extends StatelessWidget {
  const WelshHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'cy');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
      ),
      body: Stack(
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

                  final gameTiles = <Widget>[
                    GameTile(
                      title: localizer('bsl_maths.title'),
                      imagePath: 'assets/images/home_screen/bsl-maths.jpg',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.welshMaths),
                    ),
                    GameTile(
                      title: localizer('welsh_card_matching.title'),
                      imagePath: 'assets/images/home_screen/card-match.jpg',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.welshCardMatching),
                    ),
                  ];

                  // Fill last row with Welsh logo
                  final remainder = gameTiles.length % crossAxisCount;
                  if (remainder != 0) {
                    final fill = crossAxisCount - remainder;
                    for (int i = 0; i < fill; i++) {
                      gameTiles.add(
                        Padding(
                          padding:
                              const EdgeInsets.all(AppSizes.paddingSmall),
                          child: Image.asset(
                            'assets/logos/welsh/catacabi_font_colour_cym.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }
                  }

                  return SingleChildScrollView(
                    child: GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: gameTiles,
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
