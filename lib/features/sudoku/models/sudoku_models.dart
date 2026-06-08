/// Difficulty levels for BSL Sudoku.
enum SudokuDifficulty { mini, sixBySix, normal, hard, extreme }

/// A single cell in the Sudoku grid.
class SudokuCell {
  /// 0 = empty, 1–9 = filled.
  int value;

  /// True for cells that were pre-filled by the puzzle — cannot be changed.
  final bool isGiven;

  /// True when this cell conflicts with another cell in its row, column, or box.
  bool hasError;

  SudokuCell({required this.isGiven, this.value = 0, this.hasError = false});
}

/// Pre-defined puzzles. Each string is 81 characters: row-major order,
/// '0' = empty, '1'–'9' = given digit. All have verified unique solutions.
const List<String> kSudokuPuzzles = [
  // Puzzle 1 — easy (40 clues), solvable with basic singles
  '059000060000025417104300025500009000800603209002180053318596742000002800407800006',
  // Puzzle 2 — easy (38 clues)
  '930000520604000839005390006009800042001530007000400900402053798097600315010900000',
  // Puzzle 3 — Project Euler 96, harder (30 clues)
  '200080300060070084030500209000105408000000000402706000301007040720040060004010003',
  // Puzzle 4 — Project Euler 96, hard (28 clues)
  '000000907000420180000705026100904000050000040000507009920108000034059000507000000',
  // Puzzle 5 — Project Euler 96, extreme (30 clues, very few starting points)
  '030050040008010500460000012070502080000603000040109030250000098001020600080060020',
];

/// Pre-defined mini (4×4) puzzles for Level 1. Each string is 16 characters:
/// row-major order, '0' = empty, '1'–'4' = given digit.
///
/// The 4×4 grid is divided into four 2×2 sub-grids; every row, column and
/// sub-grid must contain each of 1–4 exactly once. Generated and verified to
/// have a unique solution.
const List<String> kMiniSudokuPuzzles = [
  '0401203000404213',
  '1000402121033000',
  '3402020023000023',
  '4013004200000320',
];

/// Pre-defined 6×6 puzzles for Level 2. Each string is 36 characters:
/// row-major order, '0' = empty, '1'–'6' = given digit.
///
/// The 6×6 grid is divided into six 2×3 sub-grids (two cells wide, three
/// cells high); every row, column and sub-grid must contain each of 1–6
/// exactly once. Generated and verified to have a unique solution.
const List<String> kSixBySixPuzzles = [
  '506241643152000463001005002014124000',
  '315460021035063001042000056304004020',
  '403000300005210406006300630501542060',
  '203104506032340201000000100040000605',
];
