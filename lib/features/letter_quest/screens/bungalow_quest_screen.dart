import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/bungalow_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';
import '../widgets/word_progress_bar.dart';

/// Screen for Letter Quest Level 5 — Bungalow.
class BungalowQuestScreen extends StatefulWidget {
  final String locale;
  const BungalowQuestScreen({super.key, this.locale = 'en'});

  @override
  State<BungalowQuestScreen> createState() => _BungalowQuestScreenState();
}

class _BungalowQuestScreenState extends State<BungalowQuestScreen> {
  late final BungalowQuestGame _game;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame();
    _game = BungalowQuestGame(provider: provider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (BuildContext context, BungalowQuestGame game) {
            return GameHud(levelNumber: 5, locale: widget.locale);
          },
          'wordProgress': (BuildContext context, BungalowQuestGame game) {
            return const WordProgressBar();
          },
          'victory': (BuildContext context, BungalowQuestGame game) {
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
        initialActiveOverlays: const ['hud', 'wordProgress'],
      ),
    );
  }

  LetterQuestProvider get provider => context.read<LetterQuestProvider>();
}
