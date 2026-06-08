import 'package:flutter/material.dart';

/// Brand color palette for the Catrin & Abi BSL app.
///
/// Colors are derived from the official brand guide and
/// character designs with a felt/textured aesthetic.
///
/// Usage:
/// ```dart
/// Container(color: AppColors.catrinBlue)
/// Text('Hello', style: TextStyle(color: AppColors.textPrimary))
/// ```
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // -------------------------
  // Primary Brand Colors
  // -------------------------

  /// Sky blue - Catrin's name color in the logo
  static const Color catrinBlue = Color(0xFF87CEEB);

  /// Rose pink - Abi's name color in the logo
  static const Color abiPink = Color(0xFFE91E63);

  /// Rose pink - Abi's name color in the logo
  static const Color lightPink = Color(0xFFf56Ea3);

  /// Mustard gold - connector "&" / "ac" color in logo
  static const Color connectorGold = Color(0xFFDAA520);

  /// Kelly green - school jumper color
  static const Color schoolGreen = Color(0xFF2E7D32);

  /// Charcoal grey - school skirt color
  static const Color schoolGrey = Color(0xFF424242);

  // -------------------------
  // Accent Colors (patchwork patterns)
  // -------------------------

  static const Color accentRed = Color(0xFFE53935);
  static const Color accentOrange = Color(0xFFFF6F00);
  static const Color accentYellow = Color(0xFFFDD835);
  static const Color accentLimeGreen = Color(0xFF7CB342);
  static const Color accentNavyBlue = Color(0xFF1565C0);
  static const Color accentPurple = Color(0xFF8E24AA);
  static const Color accentWhite = Color(0xFFFFFFFF);

  // -------------------------
  // Character-Specific Colors
  // -------------------------

  /// Abi's golden hair color
  static const Color abiHair = Color(0xFFDAA520);

  /// Abi's pink bow color
  static const Color abiBows = Color(0xFFE91E63);

  /// Catrin's brown hair color
  static const Color catrinHair = Color(0xFF6D4C41);

  /// Pero's tan/golden fur color
  static const Color peroFur = Color(0xFFD2691E);

  /// Pero's hearing dog jacket (burgundy/magenta)
  static const Color peroJacket = Color(0xFFC2185B);

  /// Skin colour for Catrin & Abi felt puppets (warm peach)
  static const Color skinColour = Color(0xFFFFCBA4);

  /// Light grey for colouring palette
  static const Color lightGrey = Color(0xFFBDBDBD);

  /// Dark grey for colouring palette
  static const Color darkGrey = Color(0xFF616161);

  // -------------------------
  // Card Game Colors (for matching pairs)
  // -------------------------

  /// Color assignments for vowel pairs in Level 1.
  /// Each vowel has a distinct color to help children match pairs.
  static const Map<String, Color> vowelPairColors = {
    'a': accentRed,
    'e': accentNavyBlue,
    'i': accentLimeGreen,
    'o': accentOrange,
    'u': accentPurple,
  };

  /// Color assignments for Welsh vowel pairs (a, e, i, o, u, w, y).
  static const Map<String, Color> welshVowelPairColors = {
    'a': accentRed,
    'e': accentNavyBlue,
    'i': accentLimeGreen,
    'o': accentOrange,
    'u': accentPurple,
    'w': abiPink,
    'y': catrinBlue,
  };

  /// Color assignments for Welsh digraph pairs (ch, dd, ff, ll, ng, ph, rh, th).
  static const Map<String, Color> welshDigraphPairColors = {
    'ch': connectorGold,
    'dd': schoolGreen,
    'ff': peroFur,
    'ng': peroJacket,
    'll': catrinHair,
    'ph': accentYellow,
    'rh': Color(0xFF00BCD4),
    'th': Color(0xFF9C27B0),
  };

  // -------------------------
  // Math Game Colors
  // -------------------------

  ///Clear button
  static const Color clearButton = Color(0xFFFFC99F);

  /// maths game background - brand colour
  static const Color mathBackground = Color(0xFF3bc4fe);

  /// Color assignments for all letters a-z used in card matching levels.
  /// Each letter has a distinct color to help children match pairs.
  static const Map<String, Color> letterPairColors = {
    'a': accentRed,
    'b': accentNavyBlue,
    'c': accentLimeGreen,
    'd': accentOrange,
    'e': accentPurple,
    'f': abiPink,
    'g': catrinBlue,
    'h': connectorGold,
    'i': schoolGreen,
    'j': peroFur,
    'k': peroJacket,
    'l': catrinHair,
    'm': accentYellow,
    'n': Color(0xFF00BCD4), // Cyan
    'o': Color(0xFF9C27B0), // Deep Purple
    'p': Color(0xFF009688), // Teal
    'q': Color(0xFF3F51B5), // Indigo
    'r': Color(0xFFFF5722), // Deep Orange
    's': Color(0xFFFF4081), // Pink A200
    't': Color(0xFF795548), // Brown
    'u': Color(0xFF607D8B), // Blue Grey
    'v': Color(0xFF4CAF50), // Green
    'w': Color(0xFF2196F3), // Blue
    'x': Color(0xFFCDDC39), // Lime
    'y': Color(0xFFFFC107), // Amber
    'z': Color(0xFF880E4F), // Pink 900
  };

  // -------------------------
  // Bubble Pop Game Colours
  // -------------------------

  /// Game header
  static const Color headerBackground = Color(0xFFDA16E1);
  static const Color headerBackgroundLight = Color(0xFFFB7DFF);
  static const Color headerBorderDark = Color(0xFF8F0693);
  static const Color timeContainer = Color(0xFF8F0693);

  

  // -------------------------
  // UI Colors
  // -------------------------

  /// Warm cream background - gentle on young eyes
  static const Color background = Color(0xFFFFF8E1);

  /// Card back color - felt-like brown
  static const Color cardBack = Color(0xFF5D4037);

  /// Primary text color - dark grey for readability
  static const Color textPrimary = Color(0xFF424242);

  /// Primary text color - dark grey for readability
  static const Color textDark = Color(0xFF222222);

  /// Secondary text color - medium grey
  static const Color textSecondary = Color(0xFF424242);

  /// Success color - for correct matches
  static const Color success = Color(0xFF4CAF50);

  /// Button primary color
  static const Color buttonPrimary = abiPink;

  /// Button text color
  static const Color buttonText = accentWhite;

  // -------------------------
  // BSL Colors 
  // -------------------------

    /// learning colours in BSL 
    static const Color bslBlack = Color(0xFF282828);
    static const Color bslBlue = Color(0xFF3979a8);
    static const Color bslBrown = Color(0xFF7e5137);
    static const Color bslGold = Color(0xFFFFb700);
    static const Color bslGreen = Color(0xFF20b020);
    static const Color bslGrey = Color(0xFF808080);
    static const Color bslOrange = Color(0xFFf15a24);
    static const Color bslPink = Color(0xFFFFC0CB);
    static const Color bslPurple = Color(0xFF800080);
    static const Color bslRed = Color(0xFFdf382d);
    static const Color bslSilver = Color(0xFFccccee);
    static const Color bslWhite = Color(0xFFfdfdfc);
    static const Color bslYellow = Color(0xFFe5bd22);

    static const Color bslBlackOutline = Color(0xFFaaaaaa);
    static const Color bslBlueOutline = Color(0xFF0f3a59);
    static const Color bslBrownOutline = Color(0xFF442615);
    static const Color bslGoldOutline = Color(0xFFaa7700);
    static const Color bslGreenOutline = Color(0xFF008000);
    static const Color bslGreyOutline = Color(0xFF404040);
    static const Color bslOrangeOutline = Color(0xFF7b2506);
    static const Color bslPinkOutline = Color(0xFFAB6DAD);
    static const Color bslPurpleOutline = Color(0xFF301050);
    static const Color bslRedOutline = Color(0xFF7c130c);
    static const Color bslSilverOutline = Color(0xFF555599);
    static const Color bslWhiteOutline = Color(0xFF453123);
    static const Color bslYellowOutline = Color(0xFF554a23);

}