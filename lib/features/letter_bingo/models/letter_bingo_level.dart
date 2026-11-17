/// Data models and level configurations for the Letter Bingo game.
///
/// Defines [BingoTile] (a single tile on the board) and
/// [LetterBingoLevel] (level configuration including grid layout,
/// available letters, and win condition).
///
/// Eight levels are defined for each [SignSystem]:
/// - **Level 1 — Learning Level**: 5 tiles in 1 row (a–e), clear all.
/// - **Level 2 — a to i**: 6 random tiles in 2×3 grid, complete a row.
/// - **Level 3 — a to o**: 3 rows of 4 with one random blank per row
///   (9 letter tiles), complete a row.
/// - **Level 4 — a to u**: 3 rows of 6 with two random blanks per row
///   (12 letter tiles), complete a row.
/// - **Level 5 — full alphabet**: 3 rows of 6 with two random blanks per
///   row (12 letter tiles), complete a row.
/// - **Levels 6–8 — a to m, n to z, full alphabet**: Level 5's layout, but
///   letters not on the board are called too (tap Next to skip them).
///
/// [SignSystem.iac] levels use the Welsh alphabet, introducing the digraphs
/// (ch, dd, ff, ng, ll, ph, rh, th) progressively in the same way as
/// [SignSystem.bsl] introduces letters.
///
/// When a tile is revealed the hand sign is replaced with the letter.
library;

import 'package:flutter/painting.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_filters.dart';

/// The bright brand colours the bingo board uses — tile borders (via
/// `tileColorForIndex`) and the solid blank squares.
const List<Color> bingoTilePalette = [
  AppColors.accentRed,
  AppColors.accentNavyBlue,
  AppColors.accentLimeGreen,
  AppColors.accentOrange,
  AppColors.accentPurple,
  AppColors.abiPink,
  AppColors.connectorGold,
  AppColors.schoolGreen,
];

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

  /// Squares per row left blank (a solid colour, no letter), placed at
  /// random each game. Blanks can't be tapped and don't count towards
  /// completing a row.
  final int blanksPerRow;

  /// Whether letters from [availableLetters] that aren't on the board can
  /// be called too. The player taps Next to move past them.
  final bool callsOffGridLetters;

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
    this.blanksPerRow = 0,
    this.callsOffGridLetters = false,
    required this.availableLetters,
    required this.winByCompletingAllTiles,
  });

  /// Number of letter tiles on the board (every square except the blanks)
  int get tileCount => rows * (cols - blanksPerRow);

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
  /// 3 rows of 4 squares, one square per row left blank at random:
  /// 9 letter tiles randomly selected from a–o. Win by completing any row.
  static const LetterBingoLevel bslLevel3 = LetterBingoLevel(
    number: 3,
    name: 'letter_bingo.bsl.level3.name',
    rows: 3,
    cols: 4,
    blanksPerRow: 1,
    availableLetters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g',
      'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 4 — a to u
  ///
  /// 3 rows of 6 squares, two squares per row left blank at random:
  /// 12 letter tiles randomly selected from a–u.
  /// Win by completing any row.
  static const LetterBingoLevel bslLevel4 = LetterBingoLevel(
    number: 4,
    name: 'letter_bingo.bsl.level4.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    availableLetters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g',
      'h', 'i', 'j', 'k', 'l', 'm', 'n',
      'o', 'p', 'q', 'r', 's', 't', 'u',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 5 — full alphabet
  ///
  /// 3 rows of 6 squares, two squares per row left blank at random:
  /// 12 letter tiles randomly selected from a–z.
  /// Win by completing any row.
  static const LetterBingoLevel bslLevel5 = LetterBingoLevel(
    number: 5,
    name: 'letter_bingo.bsl.level5.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    availableLetters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g',
      'h', 'i', 'j', 'k', 'l', 'm', 'n',
      'o', 'p', 'q', 'r', 's', 't', 'u',
      'v', 'w', 'x', 'y', 'z',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 6 — a to m
  ///
  /// Level 5's layout (3 rows of 6, two random blanks per row, 12 letters
  /// from a–m). Letters not on the board are called too.
  static const LetterBingoLevel bslLevel6 = LetterBingoLevel(
    number: 6,
    name: 'letter_bingo.bsl.level6.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    callsOffGridLetters: true,
    availableLetters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g',
      'h', 'i', 'j', 'k', 'l', 'm',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 7 — n to z
  ///
  /// Level 5's layout (12 letters from n–z). Letters not on the board are
  /// called too.
  static const LetterBingoLevel bslLevel7 = LetterBingoLevel(
    number: 7,
    name: 'letter_bingo.bsl.level7.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    callsOffGridLetters: true,
    availableLetters: [
      'n', 'o', 'p', 'q', 'r', 's', 't',
      'u', 'v', 'w', 'x', 'y', 'z',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 8 — full alphabet
  ///
  /// Level 5's layout (12 letters from a–z). Letters not on the board are
  /// called too.
  static const LetterBingoLevel bslLevel8 = LetterBingoLevel(
    number: 8,
    name: 'letter_bingo.bsl.level8.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    callsOffGridLetters: true,
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
    bslLevel6, bslLevel7, bslLevel8,
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
  /// 3 rows of 4 squares, one square per row left blank at random:
  /// 9 letter tiles randomly selected from the pool.
  static const LetterBingoLevel iacLevel3 = LetterBingoLevel(
    number: 3,
    name: 'letter_bingo.iac.level3.name',
    rows: 3,
    cols: 4,
    blanksPerRow: 1,
    availableLetters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 4 — a to u, plus ph, rh, th
  ///
  /// 3 rows of 6 squares, two squares per row left blank at random:
  /// 12 letter tiles randomly selected from the pool.
  static const LetterBingoLevel iacLevel4 = LetterBingoLevel(
    number: 4,
    name: 'letter_bingo.iac.level4.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    availableLetters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o', 'p', 'ph', 'r', 'rh', 's',
      't', 'th', 'u',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 5 — full Welsh alphabet (adds w, y)
  ///
  /// 3 rows of 6 squares, two squares per row left blank at random:
  /// 12 letter tiles randomly selected from the pool.
  static const LetterBingoLevel iacLevel5 = LetterBingoLevel(
    number: 5,
    name: 'letter_bingo.iac.level5.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    availableLetters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o', 'p', 'ph', 'r', 'rh', 's',
      't', 'th', 'u', 'w', 'y',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 6 — a to m (Welsh alphabet, with ch, dd, ff, ng, ll)
  ///
  /// Level 5's layout (3 rows of 6, two random blanks per row, 12 letters
  /// from the pool). Letters not on the board are called too.
  static const LetterBingoLevel iacLevel6 = LetterBingoLevel(
    number: 6,
    name: 'letter_bingo.iac.level6.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    callsOffGridLetters: true,
    availableLetters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 7 — n to y (the end of the Welsh alphabet, with ph, rh, th)
  ///
  /// Level 5's layout. The pool is exactly 12 letters, so every letter is
  /// on the board and no off-board letters can come up.
  static const LetterBingoLevel iacLevel7 = LetterBingoLevel(
    number: 7,
    name: 'letter_bingo.iac.level7.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    callsOffGridLetters: true,
    availableLetters: [
      'n', 'o', 'p', 'ph', 'r', 'rh', 's', 't', 'th', 'u', 'w', 'y',
    ],
    winByCompletingAllTiles: false,
  );

  /// Level 8 — full Welsh alphabet
  ///
  /// Level 5's layout. Letters not on the board are called too.
  static const LetterBingoLevel iacLevel8 = LetterBingoLevel(
    number: 8,
    name: 'letter_bingo.iac.level8.name',
    rows: 3,
    cols: 6,
    blanksPerRow: 2,
    callsOffGridLetters: true,
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
    iacLevel6, iacLevel7, iacLevel8,
  ];

  /// Returns the level list for the given sign system.
  static List<LetterBingoLevel> forSignSystem(SignSystem signSystem) =>
      signSystem == SignSystem.iac ? iacLevels : bslLevels;
}
