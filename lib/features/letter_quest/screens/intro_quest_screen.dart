import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/tts_helper.dart';
import 'package:provider/provider.dart';

import '../game/intro_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';
import '../widgets/word_progress_bar.dart';

/// Screen for Letter Quest Level 1 (intro room).
///
/// Hosts the Flame [GameWidget] with a 900x1200 room divided by a
/// vertical wall. Only the 3 correct letters are shown.
/// Uses the same overlay widgets as Level 2 (HUD, word bar, victory).
///
/// The [LetterQuestProvider] is accessed from the widget tree
/// (provided by the route in routes.dart).
class IntroQuestScreen extends StatefulWidget {
  const IntroQuestScreen({super.key});

  @override
  State<IntroQuestScreen> createState() => _IntroQuestScreenState();
}

class _IntroQuestScreenState extends State<IntroQuestScreen> {
  /// The Flame game instance
  late final IntroQuestGame _game;

  /// TTS engine for level instruction
  FlutterTts? _tts;

  @override
  void initState() {
    super.initState();

    // Initialize the game with the provider from the widget tree
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame(wordCount: 3);
    _game = IntroQuestGame(provider: provider);

    _speakInstruction();
  }

  /// Speaks the Level 1 instruction using a British female TTS voice.
  Future<void> _speakInstruction() async {
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
      await _tts!.speak(
        'Move the dog to find the letters to spell the word at the bottom of the screen',
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
          'hud': (BuildContext context, IntroQuestGame game) {
            return const GameHud();
          },
          // Bottom word progress bar with letter tiles
          'wordProgress': (BuildContext context, IntroQuestGame game) {
            return const WordProgressBar();
          },
          // Victory overlay when all 3 words are collected
          'victory': (BuildContext context, IntroQuestGame game) {
            return VictoryOverlay(
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
        initialActiveOverlays: const ['hud', 'wordProgress'],
      ),
    );
  }

  /// Convenience getter for the provider
  LetterQuestProvider get provider => context.read<LetterQuestProvider>();
}
