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
    final preferred = BungalowConfig.categoryRooms(word.category);

    // Pre-compute shuffled position pools so multiple letters in the same room
    // get distinct positions.
    final pools = <BungalowRoom, List<Vector2>>{
      for (final r in BungalowRoom.values) r: _safePositions(r),
    };

    final correctRooms = <BungalowRoom>{};
    for (int i = 0; i < word.word.length; i++) {
      final room = _pickRoom(preferred, pools);
      if (room == null) continue;
      final pos = pools[room]!.removeLast();

      correctRooms.add(room);
      final letter = LetterCollectible(letter: word.word[i], position: pos);
      gameWorld.add(letter);
      _activeLetters.add(letter);
    }

    _placeDistractors(word, correctRooms);
  }

  /// Picks a room for a letter. 80 % chance of choosing one of [preferred]
  /// rooms (if any have positions left), otherwise picks any available room.
  BungalowRoom? _pickRoom(
    List<BungalowRoom> preferred,
    Map<BungalowRoom, List<Vector2>> pools,
  ) {
    final availablePreferred =
        preferred.where((r) => pools[r]!.isNotEmpty).toList();

    if (availablePreferred.isNotEmpty && _random.nextDouble() < 0.8) {
      availablePreferred.shuffle(_random);
      return availablePreferred.first;
    }

    final anyAvailable = BungalowRoom.values
        .where((r) => pools[r]!.isNotEmpty)
        .toList()
      ..shuffle(_random);
    return anyAvailable.isEmpty ? null : anyAvailable.first;
  }

  void _placeDistractors(LetterQuestWord word, Set<BungalowRoom> correctRooms) {
    final wordLetters = word.uniqueLetters;
    final distractors = _consonants
        .split('')
        .where((c) => !wordLetters.contains(c))
        .toList()
      ..shuffle(_random);

    int idx = 0;
    for (final room in BungalowRoom.values) {
      if (correctRooms.contains(room)) continue;
      final positions = _safePositions(room);
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

  List<Vector2> _safePositions(BungalowRoom room) {
    return List<Vector2>.from(BungalowConfig.letterPositionsFor(room))
      ..shuffle(_random)
      ..removeWhere((p) => BungalowConfig.isPositionBlocked(p));
  }

  void clearAndReplaceLetters() {
    if (!provider.isInitialized) return;
    final needed = provider.currentWord.word.split('');
    final kept = <LetterCollectible>[];

    for (final letter in _activeLetters) {
      final idx = needed.indexOf(letter.letter);
      if (idx >= 0 && letter.isMounted) {
        needed.removeAt(idx);
        kept.add(letter);
      } else if (letter.isMounted) {
        letter.removeFromParent();
      }
    }
    _activeLetters
      ..clear()
      ..addAll(kept);

    _placeRemainingLetters(
      needed,
      preferred: BungalowConfig.categoryRooms(provider.currentWord.category),
    );
  }

  void _placeRemainingLetters(
    List<String> letters, {
    List<BungalowRoom> preferred = const [],
  }) {
    if (letters.isEmpty) return;
    final pools = <BungalowRoom, List<Vector2>>{
      for (final r in BungalowRoom.values) r: _safePositions(r),
    };
    for (final letter in letters) {
      final room = _pickRoom(preferred, pools);
      if (room == null) continue;
      final pos = pools[room]!.removeLast();
      final collectible = LetterCollectible(letter: letter, position: pos);
      gameWorld.add(collectible);
      _activeLetters.add(collectible);
    }
  }
}
