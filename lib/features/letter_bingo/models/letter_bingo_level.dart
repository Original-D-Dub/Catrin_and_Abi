/// Data models and level configurations for the Letter Bingo game.
///
/// Defines [BingoTile] (a single tile on the board) and
/// [LetterBingoLevel] (level configuration including grid layout,
/// available letters, and win condition).
///
/// Five levels are defined:
/// - **Level 1 — Learning Level**: 5 tiles in 1 row (a–e), clear all.
/// - **Level 2 — a to i**: 6 random in 2×3 grid, complete a row.
/// - **Level 3 — a to o**: 9 random in 3×3 grid, complete a row.
/// - **Level 4 — a to u**: 16 random in 4×4 grid, complete a row.
/// - **Level 5 — a to z**: 16 random in 4×4 grid, complete a row.
library;

/// A single tile on the bingo board.
///
/// Each tile displays a BSL hand sign for its [letter].
/// When the player taps the correct tile, [isRevealed] becomes true
/// and a placeholder object is shown instead.
class BingoTile {
  /// The lowercase letter this tile represents (a–z)
  final String letter;

  /// Grid position — row index (0-based)
  final int row;

  /// Grid position — column index (0-based)
  final int col;

  /// Whether the tile has been correctly matched and revealed
  bool isRevealed;

  /// Creates a bingo tile at the given grid position.
  BingoTile({
    required this.letter,
    required this.row,
    required this.col,
    this.isRevealed = false,
  });

  /// The placeholder object name revealed when this tile is cleared.
  ///
  /// Example: letter 'a' → 'Apple', 'b' → 'Ball', etc.
  String get objectName => objectForLetter(letter);

  /// The emoji representing the placeholder object.
  ///
  /// These are temporary placeholders — will be replaced with
  /// real images in a future iteration.
  String get objectEmoji => emojiForLetter(letter);

  /// Maps a letter to its placeholder object name.
  ///
  /// Returns the object that starts with that letter,
  /// used as placeholder until real images are added.
  static String objectForLetter(String letter) {
    const objects = {
      'a': 'Apple',
      'b': 'Ball',
      'c': 'Cat',
      'd': 'Dog',
      'e': 'Egg',
      'f': 'Fish',
      'g': 'Grapes',
      'h': 'Hat',
      'i': 'Ice cream',
      'j': 'Jelly',
      'k': 'Kite',
      'l': 'Lion',
      'm': 'Moon',
      'n': 'Nest',
      'o': 'Orange',
      'p': 'Pig',
      'q': 'Queen',
      'r': 'Rainbow',
      's': 'Star',
      't': 'Tree',
      'u': 'Umbrella',
      'v': 'Violin',
      'w': 'Whale',
      'x': 'Xylophone',
      'y': 'Yacht',
      'z': 'Zebra',
    };
    return objects[letter.toLowerCase()] ?? letter.toUpperCase();
  }

  /// Maps a letter to its placeholder emoji.
  static String emojiForLetter(String letter) {
    const emojis = {
      'a': '🍎',
      'b': '⚽',
      'c': '🐱',
      'd': '🐕',
      'e': '🥚',
      'f': '🐟',
      'g': '🍇',
      'h': '🎩',
      'i': '🍦',
      'j': '🍮',
      'k': '🪁',
      'l': '🦁',
      'm': '🌙',
      'n': '🪹',
      'o': '🍊',
      'p': '🐷',
      'q': '👑',
      'r': '🌈',
      's': '⭐',
      't': '🌳',
      'u': '☂️',
      'v': '🎻',
      'w': '🐋',
      'x': '🎵',
      'y': '⛵',
      'z': '🦓',
    };
    return emojis[letter.toLowerCase()] ?? '❓';
  }
}

/// Configuration for a Letter Bingo level.
///
/// Defines the grid dimensions, available letters, and how
/// tiles are arranged on the board.
class LetterBingoLevel {
  /// Level number (1–5)
  final int number;

  /// Display name shown in level select
  final String name;

  /// Number of rows in the tile grid
  final int rows;

  /// Number of columns in the tile grid
  final int cols;

  /// Letters available for this level
  final List<String> availableLetters;

  /// Whether all tiles must be cleared to win (Level 1)
  /// or just one complete row (Level 2)
  final bool winByCompletingAllTiles;

  const LetterBingoLevel({
    required this.number,
    required this.name,
    required this.rows,
    required this.cols,
    required this.availableLetters,
    required this.winByCompletingAllTiles,
  });

  /// Total number of tiles on the board
  int get tileCount => rows * cols;

  /// Level 1 — Learning Level (a–e)
  ///
  /// 5 tiles in a single horizontal row.
  /// All 5 letters are used. Win by clearing all tiles.
  static const LetterBingoLevel level1 = LetterBingoLevel(
    number: 1,
    name: 'Learning Level',
    rows: 1,
    cols: 5,
    availableLetters: ['a', 'b', 'c', 'd', 'e'],
    winByCompletingAllTiles: true,
  );

  /// Level 2 — a to i
  ///
  /// 6 tiles randomly selected from a–i, arranged in a 2×3 grid.
  /// Win by completing any row (3 tiles in same row).
  static const LetterBingoLevel level2 = LetterBingoLevel(
    number: 2,
    name: 'a to i',
    rows: 2,
    cols: 3,
    availableLetters: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'],
    winByCompletingAllTiles: false,
  );

  /// Level 3 — a to o
  ///
  /// 9 tiles randomly selected from a–o, arranged in a 3×3 grid.
  /// Win by completing any row.
  static const LetterBingoLevel level3 = LetterBingoLevel(
    number: 3,
    name: 'a to o',
    rows: 3,
    cols: 3,
    availableLetters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g',
      'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 4 — a to u
  ///
  /// 16 tiles randomly selected from a–u, arranged in a 4×4 grid.
  /// Win by completing any row.
  static const LetterBingoLevel level4 = LetterBingoLevel(
    number: 4,
    name: 'a to u',
    rows: 4,
    cols: 4,
    availableLetters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g',
      'h', 'i', 'j', 'k', 'l', 'm', 'n',
      'o', 'p', 'q', 'r', 's', 't', 'u',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 5 — a to z
  ///
  /// 16 tiles randomly selected from a–z, arranged in a 4×4 grid.
  /// Win by completing any row.
  static const LetterBingoLevel level5 = LetterBingoLevel(
    number: 5,
    name: 'a to z',
    rows: 4,
    cols: 4,
    availableLetters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g',
      'h', 'i', 'j', 'k', 'l', 'm', 'n',
      'o', 'p', 'q', 'r', 's', 't', 'u',
      'v', 'w', 'x', 'y', 'z',
    ],
    winByCompletingAllTiles: false,
  );

  /// All levels in order.
  static const List<LetterBingoLevel> allLevels = [
    level1, level2, level3, level4, level5,
  ];
}
