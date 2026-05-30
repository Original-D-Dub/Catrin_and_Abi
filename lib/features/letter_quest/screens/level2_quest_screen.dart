import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../game/level2_quest_game.dart';
import '../providers/letter_quest_provider.dart';
import '../widgets/game_hud.dart';
import '../widgets/word_progress_bar.dart';

/// Screen for Letter Quest Level 2 — "Find Gary".
///
/// Uses the same five-room cross layout as Level 3, but the word challenge
/// in each room is revealed only when Pero enters it. The wordProgress overlay
/// is shown and hidden dynamically by [Level2QuestGame] rather than being
/// shown from the start.
class Level2QuestScreen extends StatefulWidget {
  const Level2QuestScreen({super.key});

  @override
  State<Level2QuestScreen> createState() => _Level2QuestScreenState();
}

class _Level2QuestScreenState extends State<Level2QuestScreen> {
  late final Level2QuestGame _game;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LetterQuestProvider>();
    provider.initializeGame(); // 5 words — one per vowel, one per room
    _game = Level2QuestGame(provider: provider);
    AudioService.playIntro('letter_quest_2');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (BuildContext context, Level2QuestGame game) {
            return const GameHud(levelNumber: 2);
          },
          // The word progress bar is added/removed by Level2QuestGame on room entry/exit.
          'wordProgress': (BuildContext context, Level2QuestGame game) {
            return const WordProgressBar();
          },
          'victory': (BuildContext context, Level2QuestGame game) {
            return Consumer<LetterQuestProvider>(
              builder: (ctx, provider, _) {
                final done = provider.completedWords;
                return GameSuccessOverlay(
                  gameId: 'letter_quest_2',
                  scoreStyle: SuccessScoreStyle.custom,
                  customScoreLine: 'You found Gary! Congratulations',
                  onPlayAgain: () => Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.letterQuestLevel2),
                  onChangeLevel: () => Navigator.of(context).pop(),
                  extraContent: done.isEmpty
                      ? null
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'words you found were:',
                              style: TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: AppSizes.fontSizeBody,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacingMedium),
                            ...done.map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSizes.spacingSmall),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: w.word.split('').map((letter) {
                                    return Container(
                                      width: 36,
                                      height: 36,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          letter.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: 'ComicRelief',
                                            fontSize: AppSizes.fontSizeLarge,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                );
              },
            );
          },
        },
        // wordProgress is intentionally absent — the game adds it on room entry.
        initialActiveOverlays: const ['hud'],
      ),
    );
  }
}
