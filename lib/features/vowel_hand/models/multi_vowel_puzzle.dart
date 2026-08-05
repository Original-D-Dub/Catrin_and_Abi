/// A word puzzle where every vowel is hidden and the player reveals them
/// one vowel-character at a time.
///
/// All instances of the same vowel character are revealed together:
/// tapping 'a' fills every 'a' in the word simultaneously.
class MultiVowelPuzzle {
  static const _vowelSet = {'a', 'e', 'i', 'o', 'u'};

  /// The word as it should appear when complete (preserves original casing).
  final String word;

  /// The set of unique lowercase vowel characters present in [word].
  final Set<String> vowelsInWord;

  /// The set of lowercase vowel characters correctly guessed so far.
  final Set<String> guessedVowels;

  MultiVowelPuzzle._({
    required this.word,
    required this.vowelsInWord,
    required this.guessedVowels,
  });

  factory MultiVowelPuzzle.fromWord(String word) {
    final vowels = <String>{};
    for (final ch in word.toLowerCase().split('')) {
      if (_vowelSet.contains(ch)) vowels.add(ch);
    }
    return MultiVowelPuzzle._(
      word: word,
      vowelsInWord: vowels,
      guessedVowels: {},
    );
  }

  /// Whether [vowel] is in the word and has not yet been guessed.
  bool hasUnguessedVowel(String vowel) {
    final v = vowel.toLowerCase();
    return vowelsInWord.contains(v) && !guessedVowels.contains(v);
  }

  /// Returns a new puzzle with [vowel] added to the guessed set.
  MultiVowelPuzzle withVowelGuessed(String vowel) => MultiVowelPuzzle._(
        word: word,
        vowelsInWord: vowelsInWord,
        guessedVowels: {...guessedVowels, vowel.toLowerCase()},
      );

  /// True when every vowel in the word has been guessed.
  bool get isComplete => guessedVowels.containsAll(vowelsInWord);

  /// The word with unguessed vowels replaced by underscores.
  /// Spaces and already-guessed vowels are shown as-is.
  String get displayWord {
    final buf = StringBuffer();
    for (final ch in word.split('')) {
      final lower = ch.toLowerCase();
      if (_vowelSet.contains(lower) && !guessedVowels.contains(lower)) {
        buf.write('_');
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }
}
