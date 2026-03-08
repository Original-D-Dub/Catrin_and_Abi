import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/tts_helper.dart';
import 'package:provider/provider.dart';

import '../game/simple_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/victory_overlay.dart';
import '../widgets/word_progress_bar.dart';

/// Screen for Letter Quest Level 2 (simple room).
///
/// Hosts the Flame [GameWidget] with a simpler 1200x1200 room layout.
/// Uses the same overlay widgets as Level 3 (HUD, word bar, victory).
///
/// The [LetterQuestProvider] is accessed from the widget tree
/// (provided by the route in routes.dart).
class SimpleQuestScreen extends StatefulWidget {
  const SimpleQuestScreen({super.key});

  @override
  State<SimpleQuestScreen> createState() => _SimpleQuestScreenState();
}

class _SimpleQuestScreenState extends State<SimpleQuestScreen> {
  /// The Flame game instance
  late final SimpleQuestGame _game;

  /// TTS engine for level instruction
  FlutterTts? _tts;

  @override
  void initState() {
    super.initState();

    // Initialize the game with the provider from the widget tree
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame(wordCount: 3);
    _game = SimpleQuestGame(provider: provider);

    _speakInstruction();
  }

  /// Speaks the Level 2 instruction using a British female TTS voice.
  Future<void> _speakInstruction() async {
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
      await _tts!.speak(
        'Move Pero to find the letters to spell the word. Avoid the extra letters!',
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
          'hud': (BuildContext context, SimpleQuestGame game) {
            return const GameHud();
          },
          // Bottom word progress bar with letter tiles
          'wordProgress': (BuildContext context, SimpleQuestGame game) {
            return const WordProgressBar();
          },
          // Victory overlay when all 5 words are collected
          'victory': (BuildContext context, SimpleQuestGame game) {
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
