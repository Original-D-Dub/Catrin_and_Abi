import 'dart:math';

import 'package:flame/components.dart';

import '../models/house_room_config.dart';
import '../models/letter_quest_word.dart';
import '../providers/letter_quest_provider.dart';
import 'house_room_component.dart';
import 'letter_collectible.dart';

/// Manages the house rooms and letter placement for the house level.
class HouseRoomManager {
  final LetterQuestProvider provider;
  final World gameWorld;
  final List<LetterCollectible> _activeLetters = [];
  final Random _random = Random();

  String get _consonants => provider.consonants;

  HouseRoomManager({required this.provider, required this.gameWorld});

  Vector2 get playerStartPosition => HouseRoomConfig.playerStart;

  void generateRoom() {
    gameWorld.add(HouseRoomComponent());
  }

  void placeLettersForCurrentWord() {
    if (!provider.isInitialized) return;

    final word = provider.currentWord;
    final positions = List<Vector2>.from(HouseRoomConfig.letterPositions)
      ..shuffle(_random);

    for (int i = 0; i < word.word.length && i < positions.length; i++) {
      final letter = LetterCollectible(
        letter: word.word[i],
        position: positions[i],
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
    }

    _placeDistractors(
        word, positions.sublist(word.word.length.clamp(0, positions.length)));
  }

  void _placeDistractors(
      LetterQuestWord word, List<Vector2> availablePositions) {
    final wordLetters = word.uniqueLetters;
    final availableDistractors = _consonants
        .split('')
        .where((c) => !wordLetters.contains(c))
        .toList()
      ..shuffle(_random);

    final distractorCount = 4 + _random.nextInt(3);
    int distractorIdx = 0;

    for (int i = 0;
        i < distractorCount && i < availablePositions.length;
        i++) {
      if (distractorIdx >= availableDistractors.length) distractorIdx = 0;
      final letter = LetterCollectible(
        letter: availableDistractors[distractorIdx],
        position: availablePositions[i],
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
      distractorIdx++;
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
