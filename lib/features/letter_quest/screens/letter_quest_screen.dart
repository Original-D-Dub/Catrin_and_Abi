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

/// Main screen for the Letter Quest RPG game.
///
/// Hosts the Flame [GameWidget] and registers Flutter overlay widgets
/// for the HUD, word progress bar, and victory screen.
///
/// The [LetterQuestProvider] is accessed from the widget tree
/// (provided by the route in routes.dart).
class LetterQuestScreen extends StatefulWidget {
  /// UI language for HUD/overlay text ('en' or 'cy').
  final String locale;

  const LetterQuestScreen({super.key, this.locale = 'en'});

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

    AudioService.playIntro('letter_quest_3', locale: widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          // Top HUD with back button, progress, and stars
          'hud': (BuildContext context, LetterQuestGame game) {
            return GameHud(levelNumber: 3, locale: widget.locale);
          },
          // Victory overlay when all 5 words are collected
          'victory': (BuildContext context, LetterQuestGame game) {
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
              onPlayLevel4: () {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.letterQuestLevel4,
                  arguments: widget.locale,
                );
              },
              signInBanner: const SignInBannerButton(),
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
