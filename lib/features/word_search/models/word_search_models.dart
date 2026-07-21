import 'dart:math';

enum WordSearchState { playing, correct, complete }

class WordSearchWord {
  final String word;
  final String videoAssetPath;
  const WordSearchWord({required this.word, required this.videoAssetPath});
}

class WordSearchLevel {
  final int number;

  /// Translation key for the level's category name (e.g. 'word_search.level1.name').
  final String category;
  final List<WordSearchWord> words;

  /// All letters that appear in the pool circle.
  /// Must include every unique letter needed across all words in this category.
  /// Letters that appear doubled in a word (e.g. the "ee" in green) must be
  /// listed twice so the player can drag through two separate tiles.
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

  // ── English (en) level definitions ──────────────────────────────────────────

  /// Level 1 — Questions: who, what, when, where, why, how
  /// Videos: assets/videos/word_search/questions/{word}.mp4
  static final WordSearchLevel questionsEn = WordSearchLevel(
    number: 1,
    category: 'word_search.level1.name',
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

  /// Level 2 — Colours (four pool variants, one chosen at random each
  /// session). Each pool spells 5 colours; together the variants cover
  /// red, gold, green, grey, brown, orange, yellow, blue and purple.
  ///
  /// Doubled letters (the "ee" in green, "ll" in yellow) get two tiles each.
  ///
  /// Option A — pool: d e g l l o p r u w y
  ///   Words: gold · grey · purple · red · yellow
  ///
  /// Option C — pool: a b d e e g l n o r w
  ///   Words: red · gold · green · brown · orange
  ///
  /// Option D — pool: a b d e e g n o r w y
  ///   Words: red · grey · green · brown · orange
  ///
  /// Option E — pool: b d e e g l n p r u y
  ///   Words: red · blue · grey · green · purple
  ///
  /// Videos: assets/colours_video2/{word}.mov
  static final WordSearchLevel coloursEn = WordSearchLevel(
    number: 2,
    category: 'word_search.level2.name',
    letterPool: [],
    words: const [],
    variants: [
      // Option A — 5 colours, includes purple
      WordSearchLevel(
        number: 2,
        category: 'word_search.level2.name',
        letterPool: ['d', 'e', 'g', 'l', 'l', 'o', 'p', 'r', 'u', 'w', 'y'],
        words: const [
          WordSearchWord(
            word: 'gold',
            videoAssetPath: 'assets/colours_video2/gold.mov',
          ),
          WordSearchWord(
            word: 'grey',
            videoAssetPath: 'assets/colours_video2/grey.mov',
          ),
          WordSearchWord(
            word: 'purple',
            videoAssetPath: 'assets/colours_video2/purple.mov',
          ),
          WordSearchWord(
            word: 'red',
            videoAssetPath: 'assets/colours_video2/red.mov',
          ),
          WordSearchWord(
            word: 'yellow',
            videoAssetPath: 'assets/colours_video2/yellow.mov',
          ),
        ],
      ),
      // Option C — 5 colours, no grey/yellow
      WordSearchLevel(
        number: 2,
        category: 'word_search.level2.name',
        letterPool: ['a', 'b', 'd', 'e', 'e', 'g', 'l', 'n', 'o', 'r', 'w'],
        words: const [
          WordSearchWord(
            word: 'red',
            videoAssetPath: 'assets/colours_video2/red.mov',
          ),
          WordSearchWord(
            word: 'gold',
            videoAssetPath: 'assets/colours_video2/gold.mov',
          ),
          WordSearchWord(
            word: 'green',
            videoAssetPath: 'assets/colours_video2/green.mov',
          ),
          WordSearchWord(
            word: 'brown',
            videoAssetPath: 'assets/colours_video2/brown.mov',
          ),
          WordSearchWord(
            word: 'orange',
            videoAssetPath: 'assets/colours_video2/orange.mov',
          ),
        ],
      ),
      // Option D — 5 colours, no gold/yellow
      WordSearchLevel(
        number: 2,
        category: 'word_search.level2.name',
        letterPool: ['a', 'b', 'd', 'e', 'e', 'g', 'n', 'o', 'r', 'w', 'y'],
        words: const [
          WordSearchWord(
            word: 'red',
            videoAssetPath: 'assets/colours_video2/red.mov',
          ),
          WordSearchWord(
            word: 'grey',
            videoAssetPath: 'assets/colours_video2/grey.mov',
          ),
          WordSearchWord(
            word: 'green',
            videoAssetPath: 'assets/colours_video2/green.mov',
          ),
          WordSearchWord(
            word: 'brown',
            videoAssetPath: 'assets/colours_video2/brown.mov',
          ),
          WordSearchWord(
            word: 'orange',
            videoAssetPath: 'assets/colours_video2/orange.mov',
          ),
        ],
      ),
      // Option E — 5 colours, includes blue/purple
      WordSearchLevel(
        number: 2,
        category: 'word_search.level2.name',
        letterPool: ['b', 'd', 'e', 'e', 'g', 'l', 'n', 'p', 'r', 'u', 'y'],
        words: const [
          WordSearchWord(
            word: 'red',
            videoAssetPath: 'assets/colours_video2/red.mov',
          ),
          WordSearchWord(
            word: 'blue',
            videoAssetPath: 'assets/colours_video2/blue.mov',
          ),
          WordSearchWord(
            word: 'grey',
            videoAssetPath: 'assets/colours_video2/grey.mov',
          ),
          WordSearchWord(
            word: 'green',
            videoAssetPath: 'assets/colours_video2/green.mov',
          ),
          WordSearchWord(
            word: 'purple',
            videoAssetPath: 'assets/colours_video2/purple.mov',
          ),
        ],
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
  static final WordSearchLevel weatherEn = WordSearchLevel(
    number: 3,
    category: 'word_search.level3.name',
    letterPool: [],
    words: const [],
    variants: [
      // Option A — easier (shorter words, includes "ice")
      WordSearchLevel(
        number: 3,
        category: 'word_search.level3.name',
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
        category: 'word_search.level3.name',
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

  // ── Welsh (cy) level definitions ─────────────────────────────────────────────
  //
  // Word lists are Welsh translations of the English lists above. Until
  // dedicated Welsh sign videos are recorded, each Welsh word reuses the
  // English word's video as a placeholder (e.g. 'pwy' ('who') plays the
  // 'who.mp4' sign video).

  /// Level 1 — Cwestiynau (Questions): pwy, beth, pryd, ble, pam, sut
  static final WordSearchLevel questionsCy = WordSearchLevel(
    number: 1,
    category: 'word_search.level1.name',
    letterPool: [
      'p', 'w', 'y', 'b', 'e', 't', 'h',
      'r', 'd', 'l', 'a', 'm', 's', 'u',
    ],
    words: const [
      WordSearchWord(
        word: 'pwy',
        videoAssetPath: 'assets/videos/word_search/questions/who.mp4',
      ),
      WordSearchWord(
        word: 'beth',
        videoAssetPath: 'assets/videos/word_search/questions/what.mp4',
      ),
      WordSearchWord(
        word: 'pryd',
        videoAssetPath: 'assets/videos/word_search/questions/when.mp4',
      ),
      WordSearchWord(
        word: 'ble',
        videoAssetPath: 'assets/videos/word_search/questions/where.mp4',
      ),
      WordSearchWord(
        word: 'pam',
        videoAssetPath: 'assets/videos/word_search/questions/why.mp4',
      ),
      WordSearchWord(
        word: 'sut',
        videoAssetPath: 'assets/videos/word_search/questions/how.mp4',
      ),
    ],
  );

  /// Level 2 — Lliwiau (Colours): coch, glas, gwyrdd, brown, melyn, oren, gwyn
  /// ("dd" in gwyrdd gets two tiles.)
  static final WordSearchLevel coloursCy = WordSearchLevel(
    number: 2,
    category: 'word_search.level2.name',
    letterPool: [
      'c', 'o', 'h', 'g', 'l', 'a', 's', 'w',
      'y', 'r', 'd', 'd', 'b', 'n', 'e', 'm',
    ],
    words: const [
      WordSearchWord(
        word: 'coch',
        videoAssetPath: 'assets/videos/word_search/colours/red.mp4',
      ),
      WordSearchWord(
        word: 'glas',
        videoAssetPath: 'assets/videos/word_search/colours/blue.mp4',
      ),
      WordSearchWord(
        word: 'gwyrdd',
        videoAssetPath: 'assets/videos/word_search/colours/green.mp4',
      ),
      WordSearchWord(
        word: 'brown',
        videoAssetPath: 'assets/videos/word_search/colours/brown.mp4',
      ),
      WordSearchWord(
        word: 'melyn',
        videoAssetPath: 'assets/videos/word_search/colours/yellow.mp4',
      ),
      WordSearchWord(
        word: 'oren',
        videoAssetPath: 'assets/videos/word_search/colours/orange.mp4',
      ),
      WordSearchWord(
        word: 'gwyn',
        videoAssetPath: 'assets/videos/word_search/colours/white.mp4',
      ),
    ],
  );

  /// Level 3 — Tywydd (Weather) — two variants chosen at random each session,
  /// mirroring the English [weatherEn] variants.
  ///
  /// The "ll" in rhewllyd gets two tiles.
  ///
  /// Option A — pool: r h e w l l y d g a n t o
  ///   Words: rhewllyd (icy) · glaw (rain) · rhew (ice) · gwynt (wind) ·
  ///   gwyntog (windy) · glawog (rainy)
  ///
  /// Option B — pool: r h e w l l y d g a n t o i
  ///   Words: rhewllyd (icy) · glaw (rain) · gwynt (wind) · gwyntog (windy) ·
  ///   glawog (rainy) · glawio (raining)
  static final WordSearchLevel weatherCy = WordSearchLevel(
    number: 3,
    category: 'word_search.level3.name',
    letterPool: [],
    words: const [],
    variants: [
      // Option A — mirrors weatherEn's Option A (includes "rhew"/ice)
      WordSearchLevel(
        number: 3,
        category: 'word_search.level3.name',
        letterPool: [
          'r', 'h', 'e', 'w', 'l', 'l', 'y', 'd', 'g', 'a', 'n', 't', 'o',
        ],
        words: [
          WordSearchWord(
            word: 'rhewllyd',
            videoAssetPath: 'assets/videos/word_search/weather/icy.mp4',
          ),
          WordSearchWord(
            word: 'glaw',
            videoAssetPath: 'assets/videos/word_search/weather/rain.mp4',
          ),
          WordSearchWord(
            word: 'rhew',
            videoAssetPath: 'assets/videos/word_search/weather/ice.mp4',
          ),
          WordSearchWord(
            word: 'gwynt',
            videoAssetPath: 'assets/videos/word_search/weather/wind.mp4',
          ),
          WordSearchWord(
            word: 'gwyntog',
            videoAssetPath: 'assets/videos/word_search/weather/windy.mp4',
          ),
          WordSearchWord(
            word: 'glawog',
            videoAssetPath: 'assets/videos/word_search/weather/rainy.mp4',
          ),
        ],
      ),
      // Option B — mirrors weatherEn's Option B (includes "glawio"/raining)
      WordSearchLevel(
        number: 3,
        category: 'word_search.level3.name',
        letterPool: [
          'r', 'h', 'e', 'w', 'l', 'l', 'y', 'd', 'g', 'a', 'n', 't', 'o', 'i',
        ],
        words: [
          WordSearchWord(
            word: 'rhewllyd',
            videoAssetPath: 'assets/videos/word_search/weather/icy.mp4',
          ),
          WordSearchWord(
            word: 'glaw',
            videoAssetPath: 'assets/videos/word_search/weather/rain.mp4',
          ),
          WordSearchWord(
            word: 'gwynt',
            videoAssetPath: 'assets/videos/word_search/weather/wind.mp4',
          ),
          WordSearchWord(
            word: 'gwyntog',
            videoAssetPath: 'assets/videos/word_search/weather/windy.mp4',
          ),
          WordSearchWord(
            word: 'glawog',
            videoAssetPath: 'assets/videos/word_search/weather/rainy.mp4',
          ),
          WordSearchWord(
            word: 'glawio',
            videoAssetPath: 'assets/videos/word_search/weather/raining.mp4',
          ),
        ],
      ),
    ],
  );

  /// Returns the levels for the given UI locale ('en' or 'cy').
  ///
  /// Welsh levels reuse the English sign videos as placeholders until
  /// dedicated Welsh sign videos are recorded.
  static List<WordSearchLevel> forLocale(String locale) => locale == 'cy'
      ? [questionsCy, coloursCy, weatherCy]
      : [questionsEn, coloursEn, weatherEn];
}
