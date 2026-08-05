import 'dart:math';

enum WordWhirlState { playing, correct, complete }

class WordWhirlWord {
  final String word;
  final String videoAssetPath;
  const WordWhirlWord({required this.word, required this.videoAssetPath});
}

class WordWhirlLevel {
  final int number;

  /// Translation key for the level's category name (e.g. 'word_whirl.level1.name').
  final String category;
  final List<WordWhirlWord> words;

  /// All letters that appear in the pool circle.
  /// Must include every unique letter needed across all words in this category.
  /// Letters that appear doubled in a word (e.g. the "ee" in green) must be
  /// listed twice so the player can drag through two separate tiles.
  final List<String> letterPool;

  /// Optional pool/word variants. When non-empty, [randomVariant] picks one at
  /// random at level-select time so the player sees a different set each session.
  final List<WordWhirlLevel> variants;

  const WordWhirlLevel({
    required this.number,
    required this.category,
    required this.words,
    required this.letterPool,
    this.variants = const [],
  });

  /// Returns a random variant, or [this] if no variants are defined.
  WordWhirlLevel randomVariant() {
    if (variants.isEmpty) return this;
    return variants[Random().nextInt(variants.length)];
  }

  // ── English (en) level definitions ──────────────────────────────────────────

  /// Level 1 — Questions: who, what, when, where, why, how
  /// Videos: assets/videos/word_whirl/questions/{word}.mp4
  static final WordWhirlLevel questionsEn = WordWhirlLevel(
    number: 1,
    category: 'word_whirl.level1.name',
    letterPool: ['w', 'h', 'o', 'a', 't', 'e', 'n', 'r', 'y'],
    words: const [
      WordWhirlWord(
        word: 'who',
        videoAssetPath: 'assets/videos/word_whirl/questions/who.mp4',
      ),
      WordWhirlWord(
        word: 'what',
        videoAssetPath: 'assets/videos/word_whirl/questions/what.mp4',
      ),
      WordWhirlWord(
        word: 'when',
        videoAssetPath: 'assets/videos/word_whirl/questions/when.mp4',
      ),
      WordWhirlWord(
        word: 'where',
        videoAssetPath: 'assets/videos/word_whirl/questions/where.mp4',
      ),
      WordWhirlWord(
        word: 'why',
        videoAssetPath: 'assets/videos/word_whirl/questions/why.mp4',
      ),
      WordWhirlWord(
        word: 'how',
        videoAssetPath: 'assets/videos/word_whirl/questions/how.mp4',
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
  static final WordWhirlLevel coloursEn = WordWhirlLevel(
    number: 2,
    category: 'word_whirl.level2.name',
    letterPool: [],
    words: const [],
    variants: [
      // Option A — 5 colours, includes purple
      WordWhirlLevel(
        number: 2,
        category: 'word_whirl.level2.name',
        letterPool: ['d', 'e', 'g', 'l', 'l', 'o', 'p', 'r', 'u', 'w', 'y'],
        words: const [
          WordWhirlWord(
            word: 'gold',
            videoAssetPath: 'assets/colours_video2/gold.mov',
          ),
          WordWhirlWord(
            word: 'grey',
            videoAssetPath: 'assets/colours_video2/grey.mov',
          ),
          WordWhirlWord(
            word: 'purple',
            videoAssetPath: 'assets/colours_video2/purple.mov',
          ),
          WordWhirlWord(
            word: 'red',
            videoAssetPath: 'assets/colours_video2/red.mov',
          ),
          WordWhirlWord(
            word: 'yellow',
            videoAssetPath: 'assets/colours_video2/yellow.mov',
          ),
        ],
      ),
      // Option C — 5 colours, no grey/yellow
      WordWhirlLevel(
        number: 2,
        category: 'word_whirl.level2.name',
        letterPool: ['a', 'b', 'd', 'e', 'e', 'g', 'l', 'n', 'o', 'r', 'w'],
        words: const [
          WordWhirlWord(
            word: 'red',
            videoAssetPath: 'assets/colours_video2/red.mov',
          ),
          WordWhirlWord(
            word: 'gold',
            videoAssetPath: 'assets/colours_video2/gold.mov',
          ),
          WordWhirlWord(
            word: 'green',
            videoAssetPath: 'assets/colours_video2/green.mov',
          ),
          WordWhirlWord(
            word: 'brown',
            videoAssetPath: 'assets/colours_video2/brown.mov',
          ),
          WordWhirlWord(
            word: 'orange',
            videoAssetPath: 'assets/colours_video2/orange.mov',
          ),
        ],
      ),
      // Option D — 5 colours, no gold/yellow
      WordWhirlLevel(
        number: 2,
        category: 'word_whirl.level2.name',
        letterPool: ['a', 'b', 'd', 'e', 'e', 'g', 'n', 'o', 'r', 'w', 'y'],
        words: const [
          WordWhirlWord(
            word: 'red',
            videoAssetPath: 'assets/colours_video2/red.mov',
          ),
          WordWhirlWord(
            word: 'grey',
            videoAssetPath: 'assets/colours_video2/grey.mov',
          ),
          WordWhirlWord(
            word: 'green',
            videoAssetPath: 'assets/colours_video2/green.mov',
          ),
          WordWhirlWord(
            word: 'brown',
            videoAssetPath: 'assets/colours_video2/brown.mov',
          ),
          WordWhirlWord(
            word: 'orange',
            videoAssetPath: 'assets/colours_video2/orange.mov',
          ),
        ],
      ),
      // Option E — 5 colours, includes blue/purple
      WordWhirlLevel(
        number: 2,
        category: 'word_whirl.level2.name',
        letterPool: ['b', 'd', 'e', 'e', 'g', 'l', 'n', 'p', 'r', 'u', 'y'],
        words: const [
          WordWhirlWord(
            word: 'red',
            videoAssetPath: 'assets/colours_video2/red.mov',
          ),
          WordWhirlWord(
            word: 'blue',
            videoAssetPath: 'assets/colours_video2/blue.mov',
          ),
          WordWhirlWord(
            word: 'grey',
            videoAssetPath: 'assets/colours_video2/grey.mov',
          ),
          WordWhirlWord(
            word: 'green',
            videoAssetPath: 'assets/colours_video2/green.mov',
          ),
          WordWhirlWord(
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
  /// Videos: assets/videos/word_whirl/weather/{word}.mp4
  static final WordWhirlLevel weatherEn = WordWhirlLevel(
    number: 3,
    category: 'word_whirl.level3.name',
    letterPool: [],
    words: const [],
    variants: [
      // Option A — easier (shorter words, includes "ice")
      WordWhirlLevel(
        number: 3,
        category: 'word_whirl.level3.name',
        letterPool: ['a', 'c', 'd', 'e', 'i', 'n', 'r', 'w', 'y'],
        words: [
          WordWhirlWord(
            word: 'icy',
            videoAssetPath: 'assets/videos/word_whirl/weather/icy.mp4',
          ),
          WordWhirlWord(
            word: 'rain',
            videoAssetPath: 'assets/videos/word_whirl/weather/rain.mp4',
          ),
          WordWhirlWord(
            word: 'ice',
            videoAssetPath: 'assets/videos/word_whirl/weather/ice.mp4',
          ),
          WordWhirlWord(
            word: 'wind',
            videoAssetPath: 'assets/videos/word_whirl/weather/wind.mp4',
          ),
          WordWhirlWord(
            word: 'windy',
            videoAssetPath: 'assets/videos/word_whirl/weather/windy.mp4',
          ),
          WordWhirlWord(
            word: 'rainy',
            videoAssetPath: 'assets/videos/word_whirl/weather/rainy.mp4',
          ),
        ],
      ),
      // Option B — harder (includes "raining", drops "ice")
      WordWhirlLevel(
        number: 3,
        category: 'word_whirl.level3.name',
        letterPool: ['a', 'c', 'd', 'g', 'i', 'n', 'r', 'w', 'y'],
        words: [
          WordWhirlWord(
            word: 'icy',
            videoAssetPath: 'assets/videos/word_whirl/weather/icy.mp4',
          ),
          WordWhirlWord(
            word: 'rain',
            videoAssetPath: 'assets/videos/word_whirl/weather/rain.mp4',
          ),
          WordWhirlWord(
            word: 'wind',
            videoAssetPath: 'assets/videos/word_whirl/weather/wind.mp4',
          ),
          WordWhirlWord(
            word: 'windy',
            videoAssetPath: 'assets/videos/word_whirl/weather/windy.mp4',
          ),
          WordWhirlWord(
            word: 'rainy',
            videoAssetPath: 'assets/videos/word_whirl/weather/rainy.mp4',
          ),
          WordWhirlWord(
            word: 'raining',
            videoAssetPath: 'assets/videos/word_whirl/weather/raining.mp4',
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
  static final WordWhirlLevel questionsCy = WordWhirlLevel(
    number: 1,
    category: 'word_whirl.level1.name',
    letterPool: [
      'p', 'w', 'y', 'b', 'e', 't', 'h',
      'r', 'd', 'l', 'a', 'm', 's', 'u',
    ],
    words: const [
      WordWhirlWord(
        word: 'pwy',
        videoAssetPath: 'assets/videos/word_whirl/questions/who.mp4',
      ),
      WordWhirlWord(
        word: 'beth',
        videoAssetPath: 'assets/videos/word_whirl/questions/what.mp4',
      ),
      WordWhirlWord(
        word: 'pryd',
        videoAssetPath: 'assets/videos/word_whirl/questions/when.mp4',
      ),
      WordWhirlWord(
        word: 'ble',
        videoAssetPath: 'assets/videos/word_whirl/questions/where.mp4',
      ),
      WordWhirlWord(
        word: 'pam',
        videoAssetPath: 'assets/videos/word_whirl/questions/why.mp4',
      ),
      WordWhirlWord(
        word: 'sut',
        videoAssetPath: 'assets/videos/word_whirl/questions/how.mp4',
      ),
    ],
  );

  /// Level 2 — Lliwiau (Colours): coch, glas, gwyrdd, brown, melyn, oren, gwyn
  /// ("dd" in gwyrdd gets two tiles.)
  static final WordWhirlLevel coloursCy = WordWhirlLevel(
    number: 2,
    category: 'word_whirl.level2.name',
    letterPool: [
      'c', 'o', 'h', 'g', 'l', 'a', 's', 'w',
      'y', 'r', 'd', 'd', 'b', 'n', 'e', 'm',
    ],
    words: const [
      WordWhirlWord(
        word: 'coch',
        videoAssetPath: 'assets/videos/word_whirl/colours/red.mp4',
      ),
      WordWhirlWord(
        word: 'glas',
        videoAssetPath: 'assets/videos/word_whirl/colours/blue.mp4',
      ),
      WordWhirlWord(
        word: 'gwyrdd',
        videoAssetPath: 'assets/videos/word_whirl/colours/green.mp4',
      ),
      WordWhirlWord(
        word: 'brown',
        videoAssetPath: 'assets/videos/word_whirl/colours/brown.mp4',
      ),
      WordWhirlWord(
        word: 'melyn',
        videoAssetPath: 'assets/videos/word_whirl/colours/yellow.mp4',
      ),
      WordWhirlWord(
        word: 'oren',
        videoAssetPath: 'assets/videos/word_whirl/colours/orange.mp4',
      ),
      WordWhirlWord(
        word: 'gwyn',
        videoAssetPath: 'assets/videos/word_whirl/colours/white.mp4',
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
  static final WordWhirlLevel weatherCy = WordWhirlLevel(
    number: 3,
    category: 'word_whirl.level3.name',
    letterPool: [],
    words: const [],
    variants: [
      // Option A — mirrors weatherEn's Option A (includes "rhew"/ice)
      WordWhirlLevel(
        number: 3,
        category: 'word_whirl.level3.name',
        letterPool: [
          'r', 'h', 'e', 'w', 'l', 'l', 'y', 'd', 'g', 'a', 'n', 't', 'o',
        ],
        words: [
          WordWhirlWord(
            word: 'rhewllyd',
            videoAssetPath: 'assets/videos/word_whirl/weather/icy.mp4',
          ),
          WordWhirlWord(
            word: 'glaw',
            videoAssetPath: 'assets/videos/word_whirl/weather/rain.mp4',
          ),
          WordWhirlWord(
            word: 'rhew',
            videoAssetPath: 'assets/videos/word_whirl/weather/ice.mp4',
          ),
          WordWhirlWord(
            word: 'gwynt',
            videoAssetPath: 'assets/videos/word_whirl/weather/wind.mp4',
          ),
          WordWhirlWord(
            word: 'gwyntog',
            videoAssetPath: 'assets/videos/word_whirl/weather/windy.mp4',
          ),
          WordWhirlWord(
            word: 'glawog',
            videoAssetPath: 'assets/videos/word_whirl/weather/rainy.mp4',
          ),
        ],
      ),
      // Option B — mirrors weatherEn's Option B (includes "glawio"/raining)
      WordWhirlLevel(
        number: 3,
        category: 'word_whirl.level3.name',
        letterPool: [
          'r', 'h', 'e', 'w', 'l', 'l', 'y', 'd', 'g', 'a', 'n', 't', 'o', 'i',
        ],
        words: [
          WordWhirlWord(
            word: 'rhewllyd',
            videoAssetPath: 'assets/videos/word_whirl/weather/icy.mp4',
          ),
          WordWhirlWord(
            word: 'glaw',
            videoAssetPath: 'assets/videos/word_whirl/weather/rain.mp4',
          ),
          WordWhirlWord(
            word: 'gwynt',
            videoAssetPath: 'assets/videos/word_whirl/weather/wind.mp4',
          ),
          WordWhirlWord(
            word: 'gwyntog',
            videoAssetPath: 'assets/videos/word_whirl/weather/windy.mp4',
          ),
          WordWhirlWord(
            word: 'glawog',
            videoAssetPath: 'assets/videos/word_whirl/weather/rainy.mp4',
          ),
          WordWhirlWord(
            word: 'glawio',
            videoAssetPath: 'assets/videos/word_whirl/weather/raining.mp4',
          ),
        ],
      ),
    ],
  );

  /// Returns the levels for the given UI locale ('en' or 'cy').
  ///
  /// Welsh levels reuse the English sign videos as placeholders until
  /// dedicated Welsh sign videos are recorded.
  static List<WordWhirlLevel> forLocale(String locale) => locale == 'cy'
      ? [questionsCy, coloursCy, weatherCy]
      : [questionsEn, coloursEn, weatherEn];
}
