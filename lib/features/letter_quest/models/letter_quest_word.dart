import 'dart:math';

import '../../vowel_hand/models/word_puzzle.dart';

/// Represents a word the player must collect letters for in Letter Quest.
///
/// Tracks which letters have been collected; letters must be collected in order.
///
/// Example:
/// ```dart
/// final word = LetterQuestWord(word: 'cat', vowel: 'a');
/// print(word.nextNeededLetter); // 'c'
/// word.collectLetterAt(0);
/// print(word.nextNeededLetter); // 'a'
/// ```
class LetterQuestWord {
  /// The word to collect (e.g., 'cat', 'clock')
  final String word;

  /// The primary vowel in the word (e.g., 'a', 'e'). Used by Level 2.
  /// Auto-computed from [word] if not provided.
  final String vowel;

  /// Tracks which letter positions have been collected.
  final List<bool> collected;

  static const _vowels = 'aeiou';

  static String _firstVowel(String w) {
    for (final c in w.split('')) {
      if (_vowels.contains(c)) return c;
    }
    return w.isNotEmpty ? w[0] : 'a';
  }

  /// The room category this word belongs to (e.g. 'bedroom', 'kitchen').
  /// Used by Level 5 to bias letter placement toward the matching room.
  final String? category;

  /// Creates a word for the letter quest game.
  ///
  /// [vowel] defaults to the first vowel found in [word].
  /// [category] is optional — sourced from Supabase for Level 5.
  LetterQuestWord({
    required this.word,
    String? vowel,
    this.category,
  })  : vowel = vowel ?? _firstVowel(word),
        collected = List.filled(word.length, false);

  /// Returns the letter at [index] (0, 1, or 2).
  String letterAt(int index) => word[index];

  /// Whether all letters have been collected.
  bool get isComplete => collected.every((c) => c);

  /// Returns the next letter the player needs to collect,
  /// or null if the word is complete.
  ///
  /// Letters are collected left-to-right.
  String? get nextNeededLetter {
    for (int i = 0; i < word.length; i++) {
      if (!collected[i]) return word[i];
    }
    return null;
  }

  /// Returns the index of the next uncollected letter, or -1 if complete.
  int get nextNeededIndex {
    for (int i = 0; i < word.length; i++) {
      if (!collected[i]) return i;
    }
    return -1;
  }

  /// Marks the letter at [index] as collected.
  void collectLetterAt(int index) {
    if (index >= 0 && index < word.length) {
      collected[index] = true;
    }
  }

  /// Returns all unique letters in this word (for placing on the map).
  Set<String> get uniqueLetters => word.split('').toSet();
}

/// Constants and utilities for selecting words in Letter Quest.
class LetterQuestConstants {
  LetterQuestConstants._();

  /// All 5 vowels used in the game
  static const List<String> vowels = ['a', 'e', 'i', 'o', 'u'];

  /// Selects random words for a game, one per vowel.
  ///
  /// [count] limits how many words to return (defaults to all 5 vowels).
  /// Returns a shuffled list of [LetterQuestWord]s.
  static List<LetterQuestWord> selectWordsForGame({
    int? count,
    Random? random,
  }) {
    final rng = random ?? Random();

    final words = <LetterQuestWord>[];

    // Shuffle vowels so the subset varies when count < 5
    final shuffledVowels = List<String>.from(vowels)..shuffle(rng);

    for (final vowel in shuffledVowels) {
      final wordList = WordPuzzleConstants.wordsByVowel[vowel];
      if (wordList == null || wordList.isEmpty) continue;

      final chosen = wordList[rng.nextInt(wordList.length)];
      words.add(LetterQuestWord(word: chosen, vowel: vowel));
    }

    // Trim to requested count
    if (count != null && count < words.length) {
      words.removeRange(count, words.length);
    }

    // Shuffle so play order varies each game
    words.shuffle(rng);

    return words;
  }
}
