import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/button.dart';
import '../game/house_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';

/// Screen for the house top-floor level of Letter Quest.
class HouseQuestScreen extends StatefulWidget {
  final String locale;
  const HouseQuestScreen({super.key, this.locale = 'en'});

  @override
  State<HouseQuestScreen> createState() => _HouseQuestScreenState();
}

class _HouseQuestScreenState extends State<HouseQuestScreen> {
  late final HouseQuestGame _game;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame(wordCount: 3);
    _game = HouseQuestGame(provider: provider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (BuildContext context, HouseQuestGame game) {
            return const GameHud(levelNumber: 3);
          },
          'jumpButton': (BuildContext context, HouseQuestGame game) {
            return Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100, left: 20),
                child: Primary2Button(
                  label:
                      AppLocalizations(locale: widget.locale)('letter_quest.jump_button'),
                  onPressed: () => game.player.jump(),
                ),
              ),
            );
          },
          'victory': (BuildContext context, HouseQuestGame game) {
            return VictoryOverlay(
              locale: widget.locale,
              onPlayAgain: () {
                game.overlays.remove('victory');
                provider.resetGame();
                game.roomManager.clearAndReplaceLetters();
              },
              onNextLevel: () => Navigator.of(context).pushReplacementNamed(
                AppRoutes.letterQuestLevel3,
                arguments: widget.locale,
              ),
              onHome: () => Navigator.of(context).pop(),
            );
          },
        },
        initialActiveOverlays: const ['hud', 'jumpButton'],
      ),
    );
  }

  LetterQuestProvider get provider => context.read<LetterQuestProvider>();
}
