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
/// - Sign alphabet (BSL & IAC hand signs, incl. Welsh digraphs)
/// - Game assets
class AssetPaths {
  // Private constructor to prevent instantiation
  AssetPaths._();

  // -------------------------
  // Base directories
  // -------------------------
  static const String _logos = 'assets/logos';
  static const String _characters = 'assets/characters';
  static const String _signAlphabetPng = 'assets/bsl_alphabet_png';
  static const String _games = 'assets/games';
  static const String _backgrounds = 'assets/backgrounds';

  // -------------------------
  // Shared UI icons
  // -------------------------

  /// Back-arrow used by all back buttons (see BackArrowIcon).
  static const String backArrowIcon = 'assets/icons/back_arrow.png';

  // -------------------------
  // Backgrounds
  // -------------------------

  /// Park with sun background
  static const String backgroundParkSun = '$_backgrounds/park-sun.jpg';

  // -------------------------
  // Logos - Animated
  // -------------------------

  /// Animated Catrin & Abi logo video, shown on the returning-user welcome screen.
  static const String logoAnimated = '$_logos/catrin_abi_logo-animated.mp4';

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
  // Sign Alphabet (BSL & IAC)
  // -------------------------

  /// Gets the asset path for an alphabet sign PNG.
  ///
  /// One folder serves both BSL and IAC: it holds the single letters a–z
  /// plus the Welsh digraphs (ch, dd, ff, ll, ng, ph, rh, th).
  ///
  /// Example:
  /// ```dart
  /// AssetPaths.signLetterPng('A');  // 'assets/bsl_alphabet_png/bsl-sign-alp-a.png'
  /// AssetPaths.signLetterPng('ch'); // 'assets/bsl_alphabet_png/bsl-sign-alp-ch.png'
  /// ```
  static String signLetterPng(String letter) {
    return '$_signAlphabetPng/bsl-sign-alp-${letter.toLowerCase()}.png';
  }

  // -------------------------
  // BSL Numbers (for maths game)
  // -------------------------

  /// Base directory for BSL number sign PNG images
  static const String _bslNumbersPng = 'assets/bsl_numbers_png';

  /// Gets the asset path for a BSL number sign PNG.
  ///
  /// [number] should be between 0 and 9. The sign for 10 is two-handed —
  /// compose it from [bslNumber10LeftPng] and [bslNumber10RightPng].
  static String bslNumberPng(int number) {
    if (number < 0 || number > 9) {
      throw ArgumentError('bslNumberPng expects 0-9, got: $number');
    }
    return '$_bslNumbersPng/bsl-sign-number-$number.png';
  }

  /// Left hand of the two-handed BSL sign for 10.
  static const String bslNumber10LeftPng =
      '$_bslNumbersPng/bsl-sign-number-10-left.png';

  /// Right hand of the two-handed BSL sign for 10.
  static const String bslNumber10RightPng =
      '$_bslNumbersPng/bsl-sign-number-10-right.png';

  /// One of the three frames of the moving BSL sign for 11 or 12.
  ///
  /// [number] must be 11 or 12 and [part] 1–3. All frames share the same
  /// framing, so they can be swapped in place to animate the sign.
  static String bslNumberPartPng(int number, int part) {
    if (number != 11 && number != 12) {
      throw ArgumentError('bslNumberPartPng expects 11 or 12, got: $number');
    }
    if (part < 1 || part > 3) {
      throw ArgumentError('bslNumberPartPng expects part 1-3, got: $part');
    }
    return '$_bslNumbersPng/bsl-sign-number-$number-part-$part.png';
  }

  // -------------------------
  // Game Assets
  // -------------------------

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
  // Rive Animations
  // -------------------------

  /// Open palm hand Rive animation — used as the hand guide in Camera Vowels
  static const String handPalmRiv = 'assets/hand_palm.riv';

  /// Pointing finger Rive animation — used to select vowels on the Camera Vowels game
  static const String pointerRiv = 'assets/pointer.riv';

  /// Catrin vector outline Rive animation — used in the Wave Hello game
  /// State machine: "State Machine 1"; trigger input: "wave"; duration: 2s
  static const String catrinVectorOutlineRiv = 'assets/catrin-wave.riv';

  // -------------------------
  // Vowel Hand Game Assets (BSL vowel learning)
  // -------------------------

  /// Base directory for vowel hand game SVGs
  static const String _vowelHand = '$_games/vowel_hand';

  /// Open left hand PNG - displays fingertip vowel positions (a,e,i,o,u)
  static const String vowelHandOpen = '$_vowelHand/open_hand_left.png';

  /// Pointy finger PNG - cursor that follows player touch position
  static const String vowelHandPointer = '$_vowelHand/pointy_finger_right.png';

  /// "E" hand pose - shown on the intro screen before starting the game
  static const String vowelHandIntroImage = '$_vowelHand/hand_e.png';

  /// IAC 'w' / 'y' sign images for the vowel badges (no fingertip target)
  static String vowelHandBadge(String vowel) =>
      vowel == 'y' ? '$_vowelHand/y_square.png' : '$_vowelHand/$vowel.png';

  // -------------------------
  // Letter Quest Audio (RPG game sound effects)
  // -------------------------

  /// Base directory for letter quest audio files
  static const String _letterQuestAudio = 'assets/audio/letter_quest';

  /// Ascending chime for correct letter collection
  static const String letterQuestCorrect =
      '$_letterQuestAudio/collect_correct.wav';

  /// Descending buzz for wrong letter collection
  static const String letterQuestWrong = '$_letterQuestAudio/collect_wrong.wav';

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
  static String wordThumbnail({required String word, required String vowel}) {
    return '$_wordThumbnails/$vowel/$word.jpg';
  }

  /// BSL question video for a zoo quiz animal ([ZooAnimalZone.id]).
  ///
  /// Example: 'assets/games/zoo/videos/lion.mp4'
  static String zooQuizVideo(String animalId) {
    return 'assets/games/zoo/videos/$animalId.mp4';
  }

  /// Photo of a zoo animal ([ZooAnimalZone.id]), revealed when the player
  /// takes a correct picture in the zoo quiz.
  ///
  /// Example: 'assets/games/zoo/photos/lion.png'
  static String zooAnimalPhoto(String animalId) {
    return 'assets/games/zoo/photos/$animalId.png';
  }
}
