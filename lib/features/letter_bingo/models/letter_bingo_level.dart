/// Data models and level configurations for the Letter Bingo game.
///
/// Defines [BingoTile] (a single tile on the board) and
/// [LetterBingoLevel] (level configuration including grid layout,
/// available letters, and win condition).
///
/// Five levels are defined for each [SignSystem]:
/// - **Level 1 — Learning Level**: 5 tiles in 1 row (a–e), clear all.
/// - **Level 2 — a to i**: 6 random tiles in 2×3 grid, complete a row.
/// - **Level 3 — a to o**: 9 random tiles in 3×3 grid, complete a row.
/// - **Level 4 — a to u**: 16 random tiles in 4×4 grid, complete a row.
/// - **Level 5 — full alphabet**: 16 random tiles in 4×4 grid, complete a row.
///
/// [SignSystem.iac] levels use the Welsh alphabet, introducing the digraphs
/// (ch, dd, ff, ng, ll, ph, rh, th) progressively in the same way as
/// [SignSystem.bsl] introduces letters.
///
/// When a tile is revealed the hand sign is replaced with the letter.
library;

import '../../../core/constants/game_filters.dart';

/// A single tile on the bingo board.
///
/// Each tile displays a hand sign for its [letter].
/// When the player taps the correct tile, [isRevealed] becomes true
/// and the letter is shown instead.
class BingoTile {
  /// The lowercase letter (or Welsh digraph) this tile represents
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
}

/// Configuration for a Letter Bingo level.
///
/// Defines the grid dimensions, available letters, and how
/// tiles are arranged on the board.
class LetterBingoLevel {
  /// Level number (1–5)
  final int number;

  /// Translation key for the display name shown in level select
  final String name;

  /// Number of rows in the tile grid
  final int rows;

  /// Number of columns in the tile grid
  final int cols;

  /// Letters (or, for IAC, digraphs) available for this level
  final List<String> availableLetters;

  /// Whether all tiles must be cleared to win (Level 1)
  /// or just one complete row (Level 2+)
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

  // ─────────────────────────────────────────
  // BSL levels (English alphabet)
  // ─────────────────────────────────────────

  /// Level 1 — Learning Level (a–e)
  ///
  /// 5 tiles in a single horizontal row.
  /// All 5 letters are used. Win by clearing all tiles.
  static const LetterBingoLevel bslLevel1 = LetterBingoLevel(
    number: 1,
    name: 'letter_bingo.bsl.level1.name',
    rows: 1,
    cols: 5,
    availableLetters: ['a', 'b', 'c', 'd', 'e'],
    winByCompletingAllTiles: true,
  );

  /// Level 2 — a to i
  ///
  /// 6 tiles randomly selected from a–i, arranged in a 2×3 grid.
  /// Win by completing any row (3 tiles in same row).
  static const LetterBingoLevel bslLevel2 = LetterBingoLevel(
    number: 2,
    name: 'letter_bingo.bsl.level2.name',
    rows: 2,
    cols: 3,
    availableLetters: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'],
    winByCompletingAllTiles: false,
  );

  /// Level 3 — a to o
  ///
  /// 9 tiles randomly selected from a–o, arranged in a 3×3 grid.
  /// Win by completing any row.
  static const LetterBingoLevel bslLevel3 = LetterBingoLevel(
    number: 3,
    name: 'letter_bingo.bsl.level3.name',
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
  static const LetterBingoLevel bslLevel4 = LetterBingoLevel(
    number: 4,
    name: 'letter_bingo.bsl.level4.name',
    rows: 4,
    cols: 4,
    availableLetters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g',
      'h', 'i', 'j', 'k', 'l', 'm', 'n',
      'o', 'p', 'q', 'r', 's', 't', 'u',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 5 — full alphabet
  ///
  /// 16 tiles randomly selected from a–z, arranged in a 4×4 grid.
  /// Win by completing any row.
  static const LetterBingoLevel bslLevel5 = LetterBingoLevel(
    number: 5,
    name: 'letter_bingo.bsl.level5.name',
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

  /// All BSL levels, in order.
  static const List<LetterBingoLevel> bslLevels = [
    bslLevel1, bslLevel2, bslLevel3, bslLevel4, bslLevel5,
  ];

  // ─────────────────────────────────────────
  // IAC levels (Welsh alphabet, incl. digraphs)
  // ─────────────────────────────────────────

  /// Level 1 — a to d (a, b, c, ch, d)
  ///
  /// Welsh alphabetical order treats `ch` as its own letter, between
  /// `c` and `d`. 5 tiles in a single row, win by clearing all.
  static const LetterBingoLevel iacLevel1 = LetterBingoLevel(
    number: 1,
    name: 'letter_bingo.iac.level1.name',
    rows: 1,
    cols: 5,
    availableLetters: ['a', 'b', 'c', 'ch', 'd'],
    winByCompletingAllTiles: true,
  );

  /// Level 2 — a to dd (a, b, c, ch, d, dd)
  ///
  /// Welsh alphabetical order treats `dd` as its own letter, between
  /// `d` and `e`. 6 tiles in a 2×3 grid, win by completing a row.
  static const LetterBingoLevel iacLevel2 = LetterBingoLevel(
    number: 2,
    name: 'letter_bingo.iac.level2.name',
    rows: 2,
    cols: 3,
    availableLetters: ['a', 'b', 'c', 'ch', 'd', 'dd'],
    winByCompletingAllTiles: false,
  );

  /// Level 3 — a to o, plus ng, ll
  ///
  /// 9 tiles randomly selected from the pool, arranged in a 3×3 grid.
  static const LetterBingoLevel iacLevel3 = LetterBingoLevel(
    number: 3,
    name: 'letter_bingo.iac.level3.name',
    rows: 3,
    cols: 3,
    availableLetters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 4 — a to u, plus ph, rh, th
  ///
  /// 16 tiles randomly selected from the pool, arranged in a 4×4 grid.
  static const LetterBingoLevel iacLevel4 = LetterBingoLevel(
    number: 4,
    name: 'letter_bingo.iac.level4.name',
    rows: 4,
    cols: 4,
    availableLetters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o', 'p', 'ph', 'r', 'rh', 's',
      't', 'th', 'u',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 5 — full Welsh alphabet (adds w, y)
  ///
  /// 16 tiles randomly selected from the pool, arranged in a 4×4 grid.
  static const LetterBingoLevel iacLevel5 = LetterBingoLevel(
    number: 5,
    name: 'letter_bingo.iac.level5.name',
    rows: 4,
    cols: 4,
    availableLetters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o', 'p', 'ph', 'r', 'rh', 's',
      't', 'th', 'u', 'w', 'y',
    ],
    winByCompletingAllTiles: false,
  );

  /// All IAC levels, in order.
  static const List<LetterBingoLevel> iacLevels = [
    iacLevel1, iacLevel2, iacLevel3, iacLevel4, iacLevel5,
  ];

  /// Returns the level list for the given sign system.
  static List<LetterBingoLevel> forSignSystem(SignSystem signSystem) =>
      signSystem == SignSystem.iac ? iacLevels : bslLevels;
}
