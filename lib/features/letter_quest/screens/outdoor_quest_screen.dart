import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/outdoor/outdoor_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';
import '../widgets/word_progress_bar.dart';

/// Main screen for the Letter Quest Level 4 (outdoor adventure).
///
/// Hosts the Flame [GameWidget] for [OutdoorQuestGame] and registers
/// the same Flutter overlay widgets as Level 3 (HUD, word progress,
/// victory screen).
///
/// The [LetterQuestProvider] is accessed from the widget tree
/// (provided by the route in routes.dart).
class OutdoorQuestScreen extends StatefulWidget {
  const OutdoorQuestScreen({super.key});

  @override
  State<OutdoorQuestScreen> createState() => _OutdoorQuestScreenState();
}

class _OutdoorQuestScreenState extends State<OutdoorQuestScreen> {
  /// The Flame game instance
  late final OutdoorQuestGame _game;

  @override
  void initState() {
    super.initState();

    // Initialize the game with the provider from the widget tree
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame();
    _game = OutdoorQuestGame(provider: provider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          // Top HUD with back button, progress, and stars
          'hud': (BuildContext context, OutdoorQuestGame game) {
            return const GameHud();
          },
          // Bottom word progress bar with letter tiles
          'wordProgress': (BuildContext context, OutdoorQuestGame game) {
            return const WordProgressBar();
          },
          // Victory overlay when all 5 words are collected
          'victory': (BuildContext context, OutdoorQuestGame game) {
            return VictoryOverlay(
              onPlayAgain: () {
                game.overlays.remove('victory');
                provider.resetGame();
                // Regenerate map, place letters, reposition player
                game.restartWithNewMap();
              },
              onHome: () {
                Navigator.of(context).pop();
              },
            );
          },
        },
        initialActiveOverlays: const ['hud', 'wordProgress'],
      ),
    );
  }

  /// Convenience getter for the provider
  LetterQuestProvider get provider => context.read<LetterQuestProvider>();
}
