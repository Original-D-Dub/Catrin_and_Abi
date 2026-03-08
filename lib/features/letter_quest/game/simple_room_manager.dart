import 'dart:math';

import 'package:flame/components.dart';

import '../models/letter_quest_word.dart';
import '../models/simple_room_config.dart';
import '../providers/letter_quest_provider.dart';
import 'letter_collectible.dart';
import 'simple_room_component.dart';

/// Manages the simple room and letter placement for Letter Quest Level 2.
///
/// Responsibilities:
/// - Generates the simple 1200x1200 room with divider wall
/// - Places correct letters for the current word
/// - Places distractor letters in the room
/// - Clears and replaces letters when advancing to the next word
class SimpleRoomManager {
  /// Reference to the game provider for word/state access
  final LetterQuestProvider provider;

  /// The Flame world to add components to
  final World gameWorld;

  /// Currently active letter collectibles (tracked for cleanup)
  final List<LetterCollectible> _activeLetters = [];

  /// Random number generator for letter placement
  final Random _random = Random();

  /// All consonants used as distractors
  static const String _consonants = 'bcdfghjklmnpqrstvwxyz';

  /// Creates a simple room manager.
  SimpleRoomManager({
    required this.provider,
    required this.gameWorld,
  });

  /// The player's starting position (center of the room).
  Vector2 get playerStartPosition => SimpleRoomConfig.mapCenter;

  /// Generates the simple room and adds it to the game world.
  void generateRoom() {
    gameWorld.add(SimpleRoomComponent());
  }

  /// Places letters for the current word on the map.
  ///
  /// The 3 correct letters are placed randomly in the room.
  /// Additional distractor (wrong) letters are also placed.
  void placeLettersForCurrentWord() {
    if (!provider.isInitialized) return;

    final word = provider.currentWord;
    final positions = List<Vector2>.from(SimpleRoomConfig.letterPositions)
      ..shuffle(_random);

    // Place the 3 correct letters
    for (int i = 0; i < word.word.length && i < positions.length; i++) {
      final letter = LetterCollectible(
        letter: word.word[i],
        position: positions[i],
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
    }

    // Place distractor letters in remaining positions
    _placeDistractors(word, positions.sublist(word.word.length.clamp(0, positions.length)));
  }

  /// Places distractor letters in the given positions.
  ///
  /// Distractors are random consonants NOT present in the current word,
  /// ensuring the player can't accidentally collect them.
  void _placeDistractors(LetterQuestWord word, List<Vector2> availablePositions) {
    final wordLetters = word.uniqueLetters;

    // Get consonants not in the current word
    final availableDistractors = _consonants
        .split('')
        .where((c) => !wordLetters.contains(c))
        .toList()
      ..shuffle(_random);

    // Place 4-6 distractors
    final distractorCount = 4 + _random.nextInt(3);
    int distractorIdx = 0;

    for (int i = 0; i < distractorCount && i < availablePositions.length; i++) {
      if (distractorIdx >= availableDistractors.length) {
        distractorIdx = 0; // Wrap around if needed
      }

      final letter = LetterCollectible(
        letter: availableDistractors[distractorIdx],
        position: availablePositions[i],
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
      distractorIdx++;
    }
  }

  /// Removes all current letter collectibles and places new ones
  /// for the next word.
  void clearAndReplaceLetters() {
    // Remove all active letters from the world
    for (final letter in _activeLetters) {
      if (letter.isMounted) {
        letter.removeFromParent();
      }
    }
    _activeLetters.clear();

    // Place letters for the new current word
    placeLettersForCurrentWord();
  }
}
