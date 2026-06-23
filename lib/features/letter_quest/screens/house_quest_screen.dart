import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/house_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';
import '../widgets/word_progress_bar.dart';

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
          'wordProgress': (BuildContext context, HouseQuestGame game) {
            return const WordProgressBar();
          },
          'jumpButton': (BuildContext context, HouseQuestGame game) {
            return Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100, left: 20),
                child: SizedBox(
                  width: 128,
                  height: 128,
                  child: FloatingActionButton(
                    heroTag: 'jump',
                    shape: const CircleBorder(),
                    onPressed: () => game.player.jump(),
                    backgroundColor: Colors.blue,
                    child: const Text('Jump', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ),
            );
          },
          'victory': (BuildContext context, HouseQuestGame game) {
            return VictoryOverlay(
              onPlayAgain: () {
                game.overlays.remove('victory');
                provider.resetGame();
                game.roomManager.clearAndReplaceLetters();
              },
              onHome: () => Navigator.of(context).pop(),
            );
          },
        },
        initialActiveOverlays: const ['hud', 'wordProgress', 'jumpButton'],
      ),
    );
  }

  LetterQuestProvider get provider => context.read<LetterQuestProvider>();
}
