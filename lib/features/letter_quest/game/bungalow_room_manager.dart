import 'dart:math';

import 'package:flame/components.dart';

import '../models/bungalow_config.dart';
import '../models/letter_quest_word.dart';
import '../providers/letter_quest_provider.dart';
import 'letter_collectible.dart';

/// Manages letter placement for the bungalow level.
class BungalowRoomManager {
  final LetterQuestProvider provider;
  final World gameWorld;
  final List<LetterCollectible> _activeLetters = [];
  final Random _random = Random();

  String get _consonants => provider.consonants;

  BungalowRoomManager({required this.provider, required this.gameWorld});

  Vector2 get playerStartPosition => BungalowConfig.playerStart;

  void placeLettersForCurrentWord() {
    if (!provider.isInitialized) return;

    final word = provider.currentWord;
    final allRooms = BungalowRoom.values;
    final targetRoom = allRooms[_random.nextInt(allRooms.length)];
    final positions = List<Vector2>.from(
        BungalowConfig.letterPositionsFor(targetRoom))
      ..shuffle(_random);

    for (int i = 0; i < word.word.length && i < positions.length; i++) {
      final letter = LetterCollectible(
        letter: word.word[i],
        position: positions[i],
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
    }

    _placeDistractors(word, targetRoom);
  }

  void _placeDistractors(LetterQuestWord word, BungalowRoom targetRoom) {
    final wordLetters = word.uniqueLetters;
    final distractors = _consonants
        .split('')
        .where((c) => !wordLetters.contains(c))
        .toList()
      ..shuffle(_random);

    int idx = 0;
    for (final room in BungalowRoom.values) {
      if (room == targetRoom) continue;
      final positions = List<Vector2>.from(
          BungalowConfig.letterPositionsFor(room))
        ..shuffle(_random);
      final count = 1 + _random.nextInt(2);
      for (int i = 0; i < count && i < positions.length; i++) {
        if (idx >= distractors.length) idx = 0;
        final letter = LetterCollectible(
          letter: distractors[idx],
          position: positions[i],
        );
        gameWorld.add(letter);
        _activeLetters.add(letter);
        idx++;
      }
    }
  }

  void clearAndReplaceLetters() {
    for (final letter in _activeLetters) {
      if (letter.isMounted) letter.removeFromParent();
    }
    _activeLetters.clear();
    placeLettersForCurrentWord();
  }
}
