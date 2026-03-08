import 'dart:math';

import 'package:flutter/material.dart';

/// Represents a CVC (consonant-vowel-consonant) word puzzle for the
/// Vowel Words level of the BSL Vowels game.
///
/// The puzzle displays the word with its middle vowel replaced by an
/// underscore. The player must identify and tap the correct vowel
/// fingertip on the BSL hand.
///
/// Example:
/// ```dart
/// final puzzle = WordPuzzle(word: 'cat');
/// print(puzzle.vowel);       // 'a'
/// print(puzzle.displayWord); // 'c_t'
/// print(puzzle.displayWithLetter(letter: 'a')); // 'cat'
/// print(puzzle.displayWithLetter(letter: 'o')); // 'cot'
/// ```
class WordPuzzle {
  /// The complete 3-letter CVC word (e.g., 'cat', 'bed', 'pig')
  final String word;

  /// Creates a word puzzle from a 3-letter CVC word.
  const WordPuzzle({required this.word});

  /// The vowel in position 1 (middle letter) of the CVC word.
  ///
  /// All CVC words have the structure consonant-vowel-consonant,
  /// so the vowel is always at index 1.
  String get vowel => word[1];

  /// The word displayed with the vowel replaced by an underscore.
  ///
  /// Example: 'cat' becomes 'c_t'
  String get displayWord => '${word[0]}_${word[2]}';

  /// Returns the word with a specific letter filling the vowel gap.
  ///
  /// Used to show the player's guess in the word display:
  /// - Correct guess: shows the correct completed word
  /// - Wrong guess: shows the word with the wrong vowel inserted
  ///
  /// [letter] is the vowel character to insert at position 1.
  String displayWithLetter({required String letter}) =>
      '${word[0]}$letter${word[2]}';
}

/// Constants and word lists for the Vowel Words game level.
///
/// Contains 75 CVC (consonant-vowel-consonant) words:
/// 15 words per vowel (a, e, i, o, u).
///
/// All words are real English 3-letter words suitable for children.
class WordPuzzleConstants {
  WordPuzzleConstants._();

  /// Duration to show wrong answer feedback before reverting (milliseconds)
  static const int wrongAnswerDisplayDurationMs = 3000;

  /// Maximum number of recent words to track for repeat avoidance
  static const int maxRecentWords = 10;

  /// CVC words containing the vowel 'a' (15 words)
  static const List<String> wordsWithA = [
    'cat', 'bat', 'hat', 'mat', 'man',
    'bag', 'tag', 'wag', 'map', 'cap',
    'can', 'fan', 'pan', 'van', 'jam',
  ];

  /// CVC words containing the vowel 'e' (11 words)
  static const List<String> wordsWithE = [
    'bed', 'red', 'wet',
    'hen', 'pen', 'ten', 'den', 'men',
    'jet', 'net', 'pet',
  ];

  /// CVC words containing the vowel 'i' (13 words)
  static const List<String> wordsWithI = [
    'pig', 'big', 'dig', 'bib', 'wig',
    'bin', 'fin', 'pin', 'tin', 'win',
    'fit', 'hit', 'sit',
  ];

  /// CVC words containing the vowel 'o' (14 words)
  static const List<String> wordsWithO = [
    'dog', 'fog', 'hog', 'jog', 'log',
    'dot', 'got', 'hot', 'lot', 'pot',
    'box', 'fox', 'hop', 'top',
  ];

  /// CVC words containing the vowel 'u' (15 words)
  static const List<String> wordsWithU = [
    'bug', 'dug', 'hug', 'jug', 'mug',
    'bus', 'nut', 'cut', 'cup',
    'bun', 'fun', 'gun', 'run', 'sun',
  ];

  /// Map of vowel to its word list for efficient lookup.
  static const Map<String, List<String>> wordsByVowel = {
    'a': wordsWithA,
    'e': wordsWithE,
    'i': wordsWithI,
    'o': wordsWithO,
    'u': wordsWithU,
  };

  /// Returns a random word puzzle, choosing a random vowel group first
  /// then picking a random word, avoiding recently used words.
  ///
  /// [random] is the Random instance to use for selection.
  /// [recentWords] is the list of recently used words to avoid.
  /// [vowels] is the list of vowels to choose from.
  static WordPuzzle getRandomPuzzle({
    required Random random,
    required List<String> recentWords,
    required List<String> vowels,
  }) {
    try {
      // Pick a random vowel
      final vowel = vowels[random.nextInt(vowels.length)];

      // Get words for this vowel
      final wordList = wordsByVowel[vowel];
      if (wordList == null || wordList.isEmpty) {
        return const WordPuzzle(word: 'cat');
      }

      // Filter out recently used words
      final available = wordList.where(
        (w) => !recentWords.contains(w),
      ).toList();

      // If all words used recently, use the full list
      final candidates = available.isNotEmpty ? available : wordList;

      // Pick a random word
      final word = candidates[random.nextInt(candidates.length)];
      return WordPuzzle(word: word);
    } catch (e) {
      debugPrint('Error selecting random puzzle: $e');
      return const WordPuzzle(word: 'cat');
    }
  }
}
