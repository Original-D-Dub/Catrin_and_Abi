import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../models/welsh_game_level.dart';
import '../providers/welsh_card_game_provider.dart';
import '../widgets/welsh_card_grid.dart';

class WelshCardGameScreen extends StatefulWidget {
  const WelshCardGameScreen({super.key});

  @override
  State<WelshCardGameScreen> createState() => _WelshCardGameScreenState();
}

class _WelshCardGameScreenState extends State<WelshCardGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WelshCardGameProvider>();
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
    final localizer = AppLocalizations(locale: 'cy');

    return Consumer<WelshCardGameProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('welsh_card_matching.title'),
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
                  child: provider.showLevelSelect
                      ? _buildLevelSelect(context, provider, localizer)
                      : _buildGame(context, provider, localizer),
                ),
                if (!provider.showLevelSelect && provider.hasWon)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'welsh_card_matching',
                      scoreStyle: SuccessScoreStyle.custom,
                      customScoreLine:
                          'Wnaethoch chi hi mewn ${provider.moveCount} symudiad!',
                      imageAsset: 'assets/success/Abi-as-Holmes.png',
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      personalBestSuffix: ' symudiad',
                      onPlayAgain: () => provider.resetGame(),
                      onNextLevel: provider.level.levelNumber <
                              WelshGameLevel.allLevels().length
                          ? () {
                              provider.startLevel(WelshGameLevel.allLevels()[
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

  Widget _buildLevelSelect(
    BuildContext context,
    WelshCardGameProvider provider,
    AppLocalizations localizer,
  ) {
    return LevelSelectScreen(
      subtitle: localizer('welsh_card_matching.instructions'),
      levels: WelshGameLevel.allLevels().map((level) {
        return LevelSelectItem(
          number: level.levelNumber,
          name: localizer('welsh_card_matching.level${level.levelNumber}.name'),
          color: levelColor(level.levelNumber - 1),
          onTap: () {
            provider.startLevel(level);
            AudioService.playIntro('card_matching');
          },
        );
      }).toList(),
    );
  }

  Widget _buildGame(
    BuildContext context,
    WelshCardGameProvider provider,
    AppLocalizations localizer,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final isTabletLandscape = mediaQuery.size.width >= 768 &&
        mediaQuery.orientation == Orientation.landscape;

    final cardGrid = WelshCardGrid(
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
              scoreLabel: 'Symudiadau',
              scoreValue: '${provider.moveCount}',
              scoreLabelFontSize: 12,
              scoreValueFontSize: 32,
              levelNumber: provider.level.levelNumber,
              centerContent: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizer(
                          'welsh_card_matching.level${provider.level.levelNumber}.name'),
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${provider.matchCount}/${provider.totalPairs} parau',
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
                  ? localizer('welsh_card_matching.tap_second')
                  : localizer('welsh_card_matching.tap_first'),
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
