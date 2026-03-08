import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/tts_helper.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
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

  /// TTS engine for level instruction
  FlutterTts? _tts;

  @override
  void initState() {
    super.initState();

    // Initialize the game with the provider from the widget tree
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame();
    _game = LetterQuestGame(provider: provider);

    _speakInstruction();
  }

  /// Speaks the Level 3 instruction using a British female TTS voice.
  Future<void> _speakInstruction() async {
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
      await _tts!.speak(
        'Move Pero to search the rooms and find the letters to spell the words at the bottom of the screen.',
      );
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  @override
  void dispose() {
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          // Top HUD with back button, progress, and stars
          'hud': (BuildContext context, LetterQuestGame game) {
            return const GameHud();
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
