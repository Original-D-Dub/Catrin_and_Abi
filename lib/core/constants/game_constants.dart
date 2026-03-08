/// Game-specific constants for card matching and other games.
///
/// Defines animation durations, game rules, and level configurations.
class GameConstants {
  // Private constructor to prevent instantiation
  GameConstants._();

  // -------------------------
  // Animation durations (milliseconds)
  // -------------------------

  /// Duration for card flip animation
  static const int cardFlipDurationMs = 300;

  /// Duration to show mismatched cards before flipping back
  static const int mismatchDelayMs = 1000;

  /// Confetti animation duration
  static const int confettiDurationMs = 3000;

  /// Speech bubble text animation speed (per character)
  static const int textAnimationDelayMs = 50;

  // -------------------------
  // Card game settings
  // -------------------------

  /// Number of cards that can be flipped at once
  static const int maxFlippedCards = 2;

  /// Grid columns for card layout (portrait)
  static const int cardGridColumnsPortrait = 4;

  /// Grid columns for card layout (landscape)
  static const int cardGridColumnsLandscape = 5;

  // -------------------------
  // Level 1 Configuration (Vowels)
  // -------------------------

  /// Letters included in Level 1
  static const List<String> level1Letters = ['a', 'e', 'i', 'o', 'u'];

  /// Level 1 name
  static const String level1Name = 'Vowels';

  /// Level 1 name in Welsh
  static const String level1NameCy = 'Llafariaid';

  // -------------------------
  // Level 2 Configuration (a-e)
  // -------------------------

  /// Letters included in Level 2
  static const List<String> level2Letters = ['a', 'b', 'c', 'd', 'e'];

  /// Level 2 name
  static const String level2Name = 'a to e';

  /// Level 2 name in Welsh
  static const String level2NameCy = 'a i e';

  // -------------------------
  // Level 3 Configuration (a-j)
  // -------------------------

  /// Letters included in Level 3
  static const List<String> level3Letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];

  /// Level 3 name
  static const String level3Name = 'a to j';

  /// Level 3 name in Welsh
  static const String level3NameCy = 'a i j';

  // -------------------------
  // Level 4 Configuration (i-r)
  // -------------------------

  /// Letters included in Level 4
  static const List<String> level4Letters = ['i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r'];

  /// Level 4 name
  static const String level4Name = 'i to r';

  /// Level 4 name in Welsh
  static const String level4NameCy = 'i i r';

  // -------------------------
  // Level 5 Configuration (q-z)
  // -------------------------

  /// Letters included in Level 5
  static const List<String> level5Letters = ['q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];

  /// Level 5 name
  static const String level5Name = 'q to z';

  /// Level 5 name in Welsh
  static const String level5NameCy = 'q i z';

  // -------------------------
  // Welcome screen settings
  // -------------------------

  /// Key for storing first launch status
  static const String firstLaunchKey = 'has_seen_welcome_intro';

  // -------------------------
  // Letter Quest settings
  // -------------------------

  /// Key for tracking whether Level 3 of Letter Quest has been completed.
  /// Used to unlock Level 4 (outdoor).
  static const String letterQuestLevel3CompletedKey =
      'letter_quest_level3_completed';
}
