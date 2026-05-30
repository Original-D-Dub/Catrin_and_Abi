/// Difficulty levels for BSL Sudoku.
enum SudokuDifficulty { normal, hard, extreme }

/// A single cell in the 9×9 Sudoku grid.
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
/// '0' = empty, '1'–'9' = given digit.
///
/// Puzzles sourced from Project Euler problem 96 (verified unique solutions).
const List<String> kSudokuPuzzles = [
  // Puzzle 1 — Wikipedia example
  '530070000600195000098000060800060003400803001700020006060000280000419005000080079',
  // Puzzle 2
  '003020600900305001001806400008102900700000008006708200002609500800203009005010300',
  // Puzzle 3
  '200080300060070084030500209000105408000000000402706000301007040720040060004010003',
  // Puzzle 4
  '000000907000420180000705026100904000050000040000507009920108000034059000507000000',
  // Puzzle 5
  '030050040008010500460000012070502080000603000040109030250000098001020600080060020',
];
