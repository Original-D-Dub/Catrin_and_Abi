import 'dart:math';

import 'package:flutter/material.dart';

import 'welsh_letters.dart';

/// Represents a single-missing-vowel word puzzle for the Vowel Words level
/// of the BSL/IAC Vowels game.
///
/// The puzzle displays the word with its first vowel *letter* replaced by
/// an underscore. The player must identify and tap the correct vowel
/// fingertip (or, for 'w'/'y', badge) on the hand.
///
/// [useWelshAlphabet] selects which alphabet rules parse the word:
/// - **English (default, `false`)**: plain a/e/i/o/u vowel detection,
///   character by character. 'w' and 'y' are consonants — e.g. English
///   "wig"/"twig" must have their 'i' blanked, not their 'w'.
/// - **Welsh (`true`)**: words are split into letter units via
///   [splitWelshLetters], so consonant digraphs (ch, dd, ff, ng, ll, ph,
///   rh, th) are never split — blanking half a digraph would remove a
///   consonant, not a vowel — and 'w'/'y' (and circumflex vowels) are
///   recognised as vowels too.
///
/// These rulesets are mutually incompatible (Welsh's 'w'/'y'-as-vowel rule
/// would misidentify English "wig"'s vowel as 'w'), so the caller must pick
/// the right one based on which language the word actually came from —
/// not the UI locale.
///
/// Example:
/// ```dart
/// final puzzle = WordPuzzle(word: 'cat');
/// print(puzzle.vowel);       // 'a'
/// print(puzzle.displayWord); // 'c_t'
/// print(puzzle.displayWithLetter(letter: 'a')); // 'cat'
/// print(puzzle.displayWithLetter(letter: 'o')); // 'cot'
///
/// final welsh = WordPuzzle(word: 'bach', useWelshAlphabet: true);
/// print(welsh.vowel);       // 'a'
/// print(welsh.displayWord); // 'b_ch' — 'ch' stays intact as one letter
/// ```
class WordPuzzle {
  /// The complete word (e.g., 'cat', 'bed', 'pig', or a Welsh word like
  /// 'bach', 'drwg').
  final String word;

  /// Whether to parse [word] with Welsh alphabet rules rather than plain
  /// English a/e/i/o/u vowel detection. See the class doc for details.
  final bool useWelshAlphabet;

  /// Creates a word puzzle from a word with exactly one vowel letter.
  const WordPuzzle({required this.word, this.useWelshAlphabet = false});

  static const _englishVowels = {'a', 'e', 'i', 'o', 'u'};

  List<WelshLetter> get _letters {
    if (useWelshAlphabet) return splitWelshLetters(word);
    // English: every character is its own letter; only a/e/i/o/u are vowels.
    return [
      for (final ch in word.split(''))
        WelshLetter(
            ch, _englishVowels.contains(ch.toLowerCase()) ? ch.toLowerCase() : null),
    ];
  }

  /// Index (in letter units, not raw characters) of the first vowel letter
  /// in the word.
  int get _vowelUnitIndex {
    final letters = _letters;
    for (int i = 0; i < letters.length; i++) {
      if (letters[i].vowel != null) return i;
    }
    return 0;
  }

  /// The base vowel letter in the word ('a'/'e'/'i'/'o'/'u'/'w'/'y'), with
  /// any circumflex stripped so it matches the vowel fingertip/badge.
  String get vowel => _letters[_vowelUnitIndex].vowel ?? '';

  /// The word with its vowel letter replaced by an underscore.
  String get displayWord {
    final letters = _letters;
    final i = _vowelUnitIndex;
    final buffer = StringBuffer();
    for (int u = 0; u < letters.length; u++) {
      buffer.write(u == i ? '_' : letters[u].text);
    }
    return buffer.toString();
  }

  /// Returns the word with [letter] substituted for the vowel.
  String displayWithLetter({required String letter}) {
    final letters = _letters;
    final i = _vowelUnitIndex;
    final buffer = StringBuffer();
    for (int u = 0; u < letters.length; u++) {
      buffer.write(u == i ? letter : letters[u].text);
    }
    return buffer.toString();
  }
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
