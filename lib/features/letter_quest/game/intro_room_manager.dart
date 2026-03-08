import 'dart:math';

import 'package:flame/components.dart';

import '../models/intro_room_config.dart';
import '../providers/letter_quest_provider.dart';
import 'intro_room_component.dart';
import 'letter_collectible.dart';

/// Manages the intro room and letter placement for Letter Quest Level 1.
///
/// Responsibilities:
/// - Generates the 900x1200 room with vertical divider wall
/// - Places only the 3 correct letters for the current word (no distractors)
/// - Clears and replaces letters when advancing to the next word
class IntroRoomManager {
  /// Reference to the game provider for word/state access
  final LetterQuestProvider provider;

  /// The Flame world to add components to
  final World gameWorld;

  /// Currently active letter collectibles (tracked for cleanup)
  final List<LetterCollectible> _activeLetters = [];

  /// Random number generator for letter placement
  final Random _random = Random();

  /// Creates an intro room manager.
  IntroRoomManager({
    required this.provider,
    required this.gameWorld,
  });

  /// The player's starting position (center of the room).
  Vector2 get playerStartPosition => IntroRoomConfig.mapCenter;

  /// Generates the intro room and adds it to the game world.
  void generateRoom() {
    gameWorld.add(IntroRoomComponent());
  }

  /// Places the 3 correct letters for the current word on the map.
  ///
  /// Level 1 shows only the letters in the target word — no distractors.
  void placeLettersForCurrentWord() {
    if (!provider.isInitialized) return;

    final word = provider.currentWord;
    final positions = List<Vector2>.from(IntroRoomConfig.letterPositions)
      ..shuffle(_random);

    // Place only the 3 correct letters
    for (int i = 0; i < word.word.length && i < positions.length; i++) {
      final letter = LetterCollectible(
        letter: word.word[i],
        position: positions[i],
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
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
