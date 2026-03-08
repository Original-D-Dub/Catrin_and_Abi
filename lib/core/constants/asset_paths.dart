/// Centralized asset path constants for the Catrin & Abi BSL app.
///
/// All asset paths are defined here to:
/// - Avoid magic strings throughout the codebase
/// - Enable easy refactoring if asset locations change
/// - Provide autocomplete support in IDEs
///
/// Assets are organized by category:
/// - Logos (English and Welsh variants)
/// - Characters (Abi, Catrin, Pero)
/// - BSL Alphabet (A-Z hand signs)
/// - Game assets
class AssetPaths {
  // Private constructor to prevent instantiation
  AssetPaths._();

  // -------------------------
  // Base directories
  // -------------------------
  static const String _logos = 'assets/logos';
  static const String _characters = 'assets/characters';
  static const String _bslAlphabet = 'assets/bsl_alphabet';
  static const String _games = 'assets/games';
  static const String _backgrounds = 'assets/backgrounds';

  // -------------------------
  // Backgrounds
  // -------------------------

  /// Park with sun background
  static const String backgroundParkSun = '$_backgrounds/park-sun.jpg';

  // -------------------------
  // Logos - English
  // -------------------------

  /// Full colour Catrin & Abi logo (English)
  static const String logoEnglishColour =
      '$_logos/english/cat_abi_font_colour.png';

  // -------------------------
  // Logos - Welsh (Cymraeg)
  // -------------------------

  /// Full colour Catrin ac Abi logo (Welsh)
  static const String logoWelshColour =
      '$_logos/welsh/catacabi_font_colour_cym.png';

  // -------------------------
  // Characters - Abi (Deaf character)
  // -------------------------

  /// Abi default pose - friendly standing position
  static const String abiDefault = '$_characters/abi/abi_2025_001.png';

  /// Abi with arms folded pose
  static const String abiArmsFolded =
      '$_characters/abi/abi_arms_folded_2025_small.png';

  // -------------------------
  // Characters - Catrin (Abi's older sister)
  // -------------------------

  /// Catrin default pose - felt puppet style
  static const String catrinDefault =
      '$_characters/catrin/catrin_felt_puppet_001.png';

  /// Catrin with hands on hips pose
  static const String catrinHandsOnHips =
      '$_characters/catrin/catrin_hand_on_hips_2025.png';

  // -------------------------
  // Characters - Pero (hearing assistance dog)
  // -------------------------

  /// Pero default pose - with hearing dog jacket
  static const String peroDefault = '$_characters/pero/pero.png';

  /// Pero without his hearing dog jacket
  static const String peroWithoutJacket =
      '$_characters/pero/pero_without_jacket.png';

  /// Pero profile view
  static const String peroProfile = '$_characters/pero/pero_profile.png';

  // -------------------------
  // BSL Alphabet
  // -------------------------

  /// Base directory for BSL alphabet images
  static const String bslAlphabetDir = _bslAlphabet;

  /// Gets the asset path for a specific BSL letter image.
  ///
  /// [letter] should be a single letter (case-insensitive).
  /// Returns the path to the corresponding hand sign image.
  ///
  /// Example:
  /// ```dart
  /// final pathA = AssetPaths.bslLetter('a'); // 'assets/bsl_alphabet/A.png'
  /// final pathZ = AssetPaths.bslLetter('Z'); // 'assets/bsl_alphabet/Z.png'
  /// ```
  static String bslLetter(String letter) {
    if (letter.length != 1) {
      throw ArgumentError('bslLetter expects a single letter, got: $letter');
    }
    return '$_bslAlphabet/${letter.toUpperCase()}.png';
  }

  // -------------------------
  // BSL Numbers (for maths game)
  // -------------------------

  /// Base directory for BSL number sign SVG images
  static const String _bslNumbers = 'assets/bsl_numbers';

  /// Gets the asset path for a BSL number sign SVG.
  ///
  /// [number] should be between 0 and 10.
  /// Returns the path to the corresponding BSL number SVG.
  ///
  /// Example:
  /// ```dart
  /// final path0 = AssetPaths.bslNumber(0); // 'assets/bsl_numbers/0.svg'
  /// final path3 = AssetPaths.bslNumber(3); // 'assets/bsl_numbers/3.svg'
  /// final path10 = AssetPaths.bslNumber(10); // 'assets/bsl_numbers/10.svg'
  /// ```
  static String bslNumber(int number) {
    if (number < 0 || number > 10) {
      throw ArgumentError('bslNumber expects 0-10, got: $number');
    }
    return '$_bslNumbers/$number.svg';
  }

  // -------------------------
  // Game Assets
  // -------------------------

  /// Preview image for the ear game
  static const String earGamePreview =
      '$_games/ear_game/catabi_ear_game_for_website.jpg';

  // -------------------------
  // Colouring Game Assets
  // -------------------------

  /// Base directory for colouring game images
  static const String _colouring = '$_games/colouring';

  /// Abi colouring sheet
  static const String colouringAbi = '$_colouring/abi_colouring.jpg';

  /// Catrin colouring sheet
  static const String colouringCatrin = '$_colouring/catrin_colouring.jpg';

  /// Pero colouring sheet
  static const String colouringPero = '$_colouring/pero_colouring.jpg';

  /// List of all colouring sheet paths for iteration
  static const List<String> allColouringSheets = [
    colouringAbi,
    colouringCatrin,
    colouringPero,
  ];

  // -------------------------
  // Vowel Hand Game Assets (BSL vowel learning)
  // -------------------------

  /// Base directory for vowel hand game SVGs
  static const String _vowelHand = '$_games/vowel_hand';

  /// Open left hand SVG - displays fingertip vowel positions (a,e,i,o,u)
  static const String vowelHandOpen = '$_vowelHand/open_hand_left.svg';

  /// Pointy finger SVG - cursor that follows player touch position
  static const String vowelHandPointer = '$_vowelHand/pointy_finger_right.svg';

  // -------------------------
  // Letter Quest Audio (RPG game sound effects)
  // -------------------------

  /// Base directory for letter quest audio files
  static const String _letterQuestAudio = 'assets/audio/letter_quest';

  /// Ascending chime for correct letter collection
  static const String letterQuestCorrect =
      '$_letterQuestAudio/collect_correct.wav';

  /// Descending buzz for wrong letter collection
  static const String letterQuestWrong =
      '$_letterQuestAudio/collect_wrong.wav';

  /// Arpeggio for word completion
  static const String letterQuestWordComplete =
      '$_letterQuestAudio/word_complete.wav';

  /// Fanfare for game completion
  static const String letterQuestGameComplete =
      '$_letterQuestAudio/game_complete.wav';

  // -------------------------
  // Word Thumbnails (3-letter CVC word images)
  // -------------------------

  /// Base directory for word thumbnail images
  static const String _wordThumbnails = 'assets/images/word_thumbnails';

  /// Gets the asset path for a word thumbnail image.
  ///
  /// Images are organized by vowel in subdirectories (a, e, i, o, u).
  /// Each image is a JPG named after the word it represents.
  ///
  /// [word] is the 3-letter CVC word (e.g., 'cat', 'dog').
  /// [vowel] is the middle vowel character for the subdirectory.
  ///
  /// Example:
  /// ```dart
  /// final path = AssetPaths.wordThumbnail(word: 'cat', vowel: 'a');
  /// // Returns: 'assets/images/word_thumbnails/a/cat.jpg'
  /// ```
  static String wordThumbnail({
    required String word,
    required String vowel,
  }) {
    return '$_wordThumbnails/$vowel/$word.jpg';
  }
}
