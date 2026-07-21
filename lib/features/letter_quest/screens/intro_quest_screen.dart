import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/audio_service.dart';

import '../game/intro_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';

/// Screen for Letter Quest Level 1 (intro room).
///
/// Hosts the Flame [GameWidget] with a 900x1200 room divided by a
/// vertical wall. Only the 3 correct letters are shown.
/// Uses the same overlay widgets as Level 2 (HUD, word bar, victory).
///
/// The [LetterQuestProvider] is accessed from the widget tree
/// (provided by the route in routes.dart).
class IntroQuestScreen extends StatefulWidget {
  /// UI language for HUD/overlay text ('en' or 'cy').
  final String locale;

  const IntroQuestScreen({super.key, this.locale = 'en'});

  @override
  State<IntroQuestScreen> createState() => _IntroQuestScreenState();
}

class _IntroQuestScreenState extends State<IntroQuestScreen> {
  /// The Flame game instance
  late final IntroQuestGame _game;

  @override
  void initState() {
    super.initState();

    // Initialize the game with the provider from the widget tree
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame(wordCount: 3);
    _game = IntroQuestGame(provider: provider);

    AudioService.playIntro('letter_quest_1', locale: widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          // Top HUD with back button, progress, and stars
          'hud': (BuildContext context, IntroQuestGame game) {
            return GameHud(levelNumber: 1, locale: widget.locale);
          },
          // Victory overlay when all 3 words are collected
          'victory': (BuildContext context, IntroQuestGame game) {
            return VictoryOverlay(
              locale: widget.locale,
              onPlayAgain: () {
                game.overlays.remove('victory');
                provider.resetGame();
                game.roomManager.clearAndReplaceLetters();
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
