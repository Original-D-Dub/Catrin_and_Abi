import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/audio_service.dart';
import '../game/outdoor/outdoor_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';

/// Main screen for the Letter Quest Level 4 (outdoor adventure).
///
/// Hosts the Flame [GameWidget] for [OutdoorQuestGame] and registers
/// the same Flutter overlay widgets as Level 3 (HUD, word progress,
/// victory screen).
///
/// The [LetterQuestProvider] is accessed from the widget tree
/// (provided by the route in routes.dart).
class OutdoorQuestScreen extends StatefulWidget {
  /// UI language for HUD/overlay text ('en' or 'cy').
  final String locale;

  const OutdoorQuestScreen({super.key, this.locale = 'en'});

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

    AudioService.playIntro('letter_quest_4', locale: widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          // Top HUD with back button, progress, and stars
          'hud': (BuildContext context, OutdoorQuestGame game) {
            return GameHud(levelNumber: 4, locale: widget.locale);
          },
          // Victory overlay when all 5 words are collected
          'victory': (BuildContext context, OutdoorQuestGame game) {
            return VictoryOverlay(
              locale: widget.locale,
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
        initialActiveOverlays: const ['hud'],
      ),
    );
  }

  /// Convenience getter for the provider
  LetterQuestProvider get provider => context.read<LetterQuestProvider>();
}
