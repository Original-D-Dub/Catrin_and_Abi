import 'package:flutter/foundation.dart';

import '../models/letter_quest_word.dart';

/// Game phase for the Letter Quest RPG game.
///
/// Transitions:
/// ```
/// playing → wordComplete → playing → ... → victory
/// ```
enum LetterQuestPhase {
  /// Actively exploring rooms and collecting letters
  playing,

  /// Brief celebration after completing a word (before next word)
  wordComplete,

  /// All 5 words collected — game is won
  victory,
}

/// State management for the Letter Quest RPG game.
///
/// Manages the 5 words (one per vowel), tracks which letters have been
/// collected, and handles phase transitions between words.
///
/// This provider has NO Flame dependencies — it manages pure game logic.
/// The Flame game components call its methods and read its state.
///
/// Usage:
/// ```dart
/// final provider = LetterQuestProvider();
/// provider.initializeGame();
///
/// // When player walks over a BSL letter sign:
/// final isCorrect = provider.tryCollectLetter('c');
/// ```
class LetterQuestProvider extends ChangeNotifier {
  /// Current game phase
  LetterQuestPhase _phase = LetterQuestPhase.playing;

  /// The 5 words to collect (one per vowel)
  List<LetterQuestWord> _words = [];

  /// Index of the word currently being collected
  int _currentWordIndex = 0;

  // -------------------------
  // Public getters
  // -------------------------

  /// Current game phase
  LetterQuestPhase get phase => _phase;

  /// The word currently being collected
  LetterQuestWord get currentWord => _words[_currentWordIndex];

  /// All 5 words for display purposes (e.g., victory overlay)
  List<LetterQuestWord> get words => List.unmodifiable(_words);

  /// Number of words fully completed so far
  int get wordsCompleted => _words.where((w) => w.isComplete).length;

  /// Total number of words in the game
  int get totalWords => _words.length;

  /// Whether the game has been initialized with words
  bool get isInitialized => _words.isNotEmpty;

  // -------------------------
  // Game control
  // -------------------------

  /// Number of words for this game session (used by [resetGame]).
  int? _wordCount;

  /// Initializes a new game by selecting random words (one per vowel).
  ///
  /// [wordCount] limits the number of words (defaults to 5, all vowels).
  /// Must be called before any other game methods.
  void initializeGame({int? wordCount}) {
    _wordCount = wordCount;
    _words = LetterQuestConstants.selectWordsForGame(count: wordCount);
    _currentWordIndex = 0;
    _phase = LetterQuestPhase.playing;
  }

  /// Resets the game with new random words.
  ///
  /// Unlike [initializeGame], this notifies listeners since it's called
  /// after the widget tree is already built (e.g., from the victory overlay).
  /// Preserves the word count from the original [initializeGame] call.
  void resetGame() {
    initializeGame(wordCount: _wordCount);
    notifyListeners();
  }

  // -------------------------
  // Letter collection
  // -------------------------

  /// Attempts to collect a letter for the current word.
  ///
  /// Returns `true` if the letter matches the next needed letter
  /// in the current word (letters must be collected in order).
  /// Returns `false` if the letter is wrong or the game isn't in
  /// the playing phase.
  ///
  /// On correct collection:
  /// - Marks the letter position as collected
  /// - If the word is now complete, transitions to [LetterQuestPhase.wordComplete]
  /// - Calls [notifyListeners] to update overlays
  ///
  /// [letter] is the lowercase letter character (e.g., 'c', 'a', 't').
  bool tryCollectLetter(String letter) {
    if (_phase != LetterQuestPhase.playing) return false;
    if (!isInitialized) return false;

    final word = currentWord;
    final neededLetter = word.nextNeededLetter;

    if (neededLetter == null) return false;

    // Check if this letter matches the next needed one
    if (letter.toLowerCase() != neededLetter.toLowerCase()) {
      return false;
    }

    // Collect the letter at the next needed position
    final index = word.nextNeededIndex;
    word.collectLetterAt(index);
    notifyListeners();

    // Check if the word is now complete
    if (word.isComplete) {
      _phase = LetterQuestPhase.wordComplete;
      notifyListeners();
    }

    return true;
  }

  /// Advances to the next word after word completion celebration.
  ///
  /// Called by the Flame game after the word-complete animation finishes.
  /// If all 5 words are done, transitions to [LetterQuestPhase.victory].
  void advanceToNextWord() {
    if (_phase != LetterQuestPhase.wordComplete) return;

    if (_currentWordIndex >= _words.length - 1) {
      // All words collected — game won!
      _phase = LetterQuestPhase.victory;
    } else {
      // Move to next word
      _currentWordIndex++;
      _phase = LetterQuestPhase.playing;
    }

    notifyListeners();
  }
}
