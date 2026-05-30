import 'dart:math';

enum WordSearchState { playing, correct, complete }

class WordSearchWord {
  final String word;
  final String videoAssetPath;
  const WordSearchWord({required this.word, required this.videoAssetPath});
}

class WordSearchLevel {
  final int number;
  final String category;
  final List<WordSearchWord> words;

  /// All letters that appear in the pool circle.
  /// Must include every unique letter needed across all words in this category.
  final List<String> letterPool;

  /// Optional pool/word variants. When non-empty, [randomVariant] picks one at
  /// random at level-select time so the player sees a different set each session.
  final List<WordSearchLevel> variants;

  const WordSearchLevel({
    required this.number,
    required this.category,
    required this.words,
    required this.letterPool,
    this.variants = const [],
  });

  /// Returns a random variant, or [this] if no variants are defined.
  WordSearchLevel randomVariant() {
    if (variants.isEmpty) return this;
    return variants[Random().nextInt(variants.length)];
  }

  // ── Level definitions ───────────────────────────────────────────────────────

  /// Level 1 — Questions: who, what, when, where, why, how
  /// Videos: assets/videos/word_search/questions/{word}.mp4
  static final WordSearchLevel questions = WordSearchLevel(
    number: 1,
    category: 'Questions',
    letterPool: ['w', 'h', 'o', 'a', 't', 'e', 'n', 'r', 'y'],
    words: const [
      WordSearchWord(
        word: 'who',
        videoAssetPath: 'assets/videos/word_search/questions/who.mp4',
      ),
      WordSearchWord(
        word: 'what',
        videoAssetPath: 'assets/videos/word_search/questions/what.mp4',
      ),
      WordSearchWord(
        word: 'when',
        videoAssetPath: 'assets/videos/word_search/questions/when.mp4',
      ),
      WordSearchWord(
        word: 'where',
        videoAssetPath: 'assets/videos/word_search/questions/where.mp4',
      ),
      WordSearchWord(
        word: 'why',
        videoAssetPath: 'assets/videos/word_search/questions/why.mp4',
      ),
      WordSearchWord(
        word: 'how',
        videoAssetPath: 'assets/videos/word_search/questions/how.mp4',
      ),
    ],
  );

  /// Level 2 — Colours: red, blue, green, brown, yellow, orange, white
  /// Videos: assets/videos/word_search/colours/{word}.mp4
  static final WordSearchLevel colours = WordSearchLevel(
    number: 2,
    category: 'Colours',
    letterPool: ['a', 'b', 'e', 'l', 'n', 'o', 'r', 'w'],
    words: const [
      WordSearchWord(
        word: 'red',
        videoAssetPath: 'assets/videos/word_search/colours/red.mp4',
      ),
      WordSearchWord(
        word: 'blue',
        videoAssetPath: 'assets/videos/word_search/colours/blue.mp4',
      ),
      WordSearchWord(
        word: 'green',
        videoAssetPath: 'assets/videos/word_search/colours/green.mp4',
      ),
      WordSearchWord(
        word: 'brown',
        videoAssetPath: 'assets/videos/word_search/colours/brown.mp4',
      ),
      WordSearchWord(
        word: 'yellow',
        videoAssetPath: 'assets/videos/word_search/colours/yellow.mp4',
      ),
      WordSearchWord(
        word: 'orange',
        videoAssetPath: 'assets/videos/word_search/colours/orange.mp4',
      ),
      WordSearchWord(
        word: 'white',
        videoAssetPath: 'assets/videos/word_search/colours/white.mp4',
      ),
    ],
  );

  /// Level 3 — Weather (two variants chosen at random each session)
  ///
  /// Option A — pool: a c d e i n r w y
  ///   Words: icy · rain · ice · wind · windy · rainy
  ///
  /// Option B — pool: a c d g i n r w y
  ///   Words: icy · rain · wind · windy · rainy · raining
  ///
  /// Videos: assets/videos/word_search/weather/{word}.mp4
  static final WordSearchLevel weather = WordSearchLevel(
    number: 3,
    category: 'Weather',
    letterPool: [],
    words: const [],
    variants: [
      // Option A — easier (shorter words, includes "ice")
      WordSearchLevel(
        number: 3,
        category: 'Weather',
        letterPool: ['a', 'c', 'd', 'e', 'i', 'n', 'r', 'w', 'y'],
        words: [
          WordSearchWord(
            word: 'icy',
            videoAssetPath: 'assets/videos/word_search/weather/icy.mp4',
          ),
          WordSearchWord(
            word: 'rain',
            videoAssetPath: 'assets/videos/word_search/weather/rain.mp4',
          ),
          WordSearchWord(
            word: 'ice',
            videoAssetPath: 'assets/videos/word_search/weather/ice.mp4',
          ),
          WordSearchWord(
            word: 'wind',
            videoAssetPath: 'assets/videos/word_search/weather/wind.mp4',
          ),
          WordSearchWord(
            word: 'windy',
            videoAssetPath: 'assets/videos/word_search/weather/windy.mp4',
          ),
          WordSearchWord(
            word: 'rainy',
            videoAssetPath: 'assets/videos/word_search/weather/rainy.mp4',
          ),
        ],
      ),
      // Option B — harder (includes "raining", drops "ice")
      WordSearchLevel(
        number: 3,
        category: 'Weather',
        letterPool: ['a', 'c', 'd', 'g', 'i', 'n', 'r', 'w', 'y'],
        words: [
          WordSearchWord(
            word: 'icy',
            videoAssetPath: 'assets/videos/word_search/weather/icy.mp4',
          ),
          WordSearchWord(
            word: 'rain',
            videoAssetPath: 'assets/videos/word_search/weather/rain.mp4',
          ),
          WordSearchWord(
            word: 'wind',
            videoAssetPath: 'assets/videos/word_search/weather/wind.mp4',
          ),
          WordSearchWord(
            word: 'windy',
            videoAssetPath: 'assets/videos/word_search/weather/windy.mp4',
          ),
          WordSearchWord(
            word: 'rainy',
            videoAssetPath: 'assets/videos/word_search/weather/rainy.mp4',
          ),
          WordSearchWord(
            word: 'raining',
            videoAssetPath: 'assets/videos/word_search/weather/raining.mp4',
          ),
        ],
      ),
    ],
  );

  static List<WordSearchLevel> get all => [questions, colours, weather];
}
