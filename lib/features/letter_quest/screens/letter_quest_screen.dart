import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/sign_in_banner_button.dart';
import '../game/letter_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';
import '../widgets/word_progress_bar.dart';

/// Main screen for the Letter Quest RPG game.
///
/// Hosts the Flame [GameWidget] and registers Flutter overlay widgets
/// for the HUD, word progress bar, and victory screen.
///
/// The [LetterQuestProvider] is accessed from the widget tree
/// (provided by the route in routes.dart).
class LetterQuestScreen extends StatefulWidget {
  const LetterQuestScreen({super.key});

  @override
  State<LetterQuestScreen> createState() => _LetterQuestScreenState();
}

class _LetterQuestScreenState extends State<LetterQuestScreen> {
  /// The Flame game instance
  late final LetterQuestGame _game;

  @override
  void initState() {
    super.initState();

    // Initialize the game with the provider from the widget tree
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame();
    _game = LetterQuestGame(provider: provider);

    AudioService.playIntro('letter_quest_3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          // Top HUD with back button, progress, and stars
          'hud': (BuildContext context, LetterQuestGame game) {
            return const GameHud(levelNumber: 3);
          },
          // Bottom word progress bar with letter tiles
          'wordProgress': (BuildContext context, LetterQuestGame game) {
            return const WordProgressBar();
          },
          // Victory overlay when all 5 words are collected
          'victory': (BuildContext context, LetterQuestGame game) {
            return VictoryOverlay(
              onPlayAgain: () {
                game.overlays.remove('victory');
                provider.resetGame();
                game.roomManager.clearAndReplaceLetters();
              },
              onHome: () {
                Navigator.of(context).pop();
              },
              onPlayLevel4: () {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.letterQuestLevel4,
                );
              },
              signInBanner: const SignInBannerButton(),
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
