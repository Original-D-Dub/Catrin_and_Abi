import 'dart:math';

import 'package:flame/components.dart';

import '../models/letter_quest_word.dart';
import '../models/room_config.dart';
import '../providers/letter_quest_provider.dart';
import 'letter_collectible.dart';
import 'room_component.dart';

/// Manages the room layout and letter placement for Letter Quest.
///
/// Responsibilities:
/// - Generates the 5-room cross layout
/// - Places correct letters for the current word in the appropriate room
/// - Places distractor letters in other rooms
/// - Clears and replaces letters when advancing to the next word
class RoomManager {
  /// Reference to the game provider for word/state access
  final LetterQuestProvider provider;

  /// The Flame world to add components to
  final World gameWorld;

  /// Pre-loaded room configurations
  late final List<RoomConfig> _roomConfigs;

  /// Currently active letter collectibles (tracked for cleanup)
  final List<LetterCollectible> _activeLetters = [];

  /// Random number generator for letter placement
  final Random _random = Random();

  /// All consonants used as distractors
  static const String _consonants = 'bcdfghjklmnpqrstvwxyz';

  /// Creates a room manager.
  RoomManager({
    required this.provider,
    required this.gameWorld,
  });

  /// The player's starting position (center of Room I, the hub).
  Vector2 get playerStartPosition {
    final hubRoom = _roomConfigs.firstWhere((r) => r.vowel == 'i');
    return hubRoom.center;
  }

  /// Generates all 5 rooms and adds them to the game world.
  void generateRooms() {
    _roomConfigs = RoomConfig.generateAllRooms();

    for (final config in _roomConfigs) {
      gameWorld.add(RoomComponent(config: config));
    }
  }

  /// Places letters for the current word on the map.
  ///
  /// The 3 correct letters are placed in the room matching the word's vowel.
  /// Each of the other 4 rooms gets 1-2 distractor (wrong) letters.
  void placeLettersForCurrentWord() {
    if (!provider.isInitialized) return;

    final word = provider.currentWord;
    final wordRoom = _getRoomForVowel(word.vowel);

    if (wordRoom == null) return;

    final positions = wordRoom.letterPositions;
    // Shuffle positions so letters appear in different spots each game
    final shuffledPositions = List<Vector2>.from(positions)..shuffle(_random);

    // Place the 3 correct letters in the word's room
    for (int i = 0; i < word.word.length && i < shuffledPositions.length; i++) {
      final letter = LetterCollectible(
        letter: word.word[i],
        position: wordRoom.worldPosition + shuffledPositions[i],
      );
      gameWorld.add(letter);
      _activeLetters.add(letter);
    }

    // Place distractor letters in other rooms
    _placeDistractors(word);
  }

  /// Places 1-2 distractor letters in each non-target room.
  ///
  /// Distractors are random consonants NOT present in the current word,
  /// ensuring the player can't accidentally collect them.
  void _placeDistractors(LetterQuestWord word) {
    final wordLetters = word.uniqueLetters;

    // Get consonants not in the current word
    final availableDistractors = _consonants
        .split('')
        .where((c) => !wordLetters.contains(c))
        .toList()
      ..shuffle(_random);

    int distractorIdx = 0;

    for (final config in _roomConfigs) {
      // Skip the room that has the correct letters
      if (config.vowel == word.vowel) continue;

      final positions = config.letterPositions;
      final shuffled = List<Vector2>.from(positions)..shuffle(_random);

      // Place 1-2 distractors per room
      final count = 1 + _random.nextInt(2); // 1 or 2
      for (int i = 0; i < count && i < shuffled.length; i++) {
        if (distractorIdx >= availableDistractors.length) {
          distractorIdx = 0; // Wrap around if needed
        }

        final letter = LetterCollectible(
          letter: availableDistractors[distractorIdx],
          position: config.worldPosition + shuffled[i],
        );
        gameWorld.add(letter);
        _activeLetters.add(letter);
        distractorIdx++;
      }
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

  /// Returns the room config for the given vowel, or null if not found.
  RoomConfig? _getRoomForVowel(String vowel) {
    try {
      return _roomConfigs.firstWhere((r) => r.vowel == vowel);
    } catch (e) {
      return null;
    }
  }
}
