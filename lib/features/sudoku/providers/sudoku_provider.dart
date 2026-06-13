import 'package:flutter/material.dart';

import '../models/sudoku_models.dart';

/// Puzzle index ranges per difficulty (into [kSudokuPuzzles]).
/// [SudokuDifficulty.mini] draws from [kMiniSudokuPuzzles] instead.
const Map<SudokuDifficulty, List<int>> _difficultyPuzzles = {
  SudokuDifficulty.normal:  [0, 1],
  SudokuDifficulty.hard:    [2, 3],
  SudokuDifficulty.extreme: [4],
};

class SudokuProvider extends ChangeNotifier {
  List<List<SudokuCell>> grid = [];

  int? selectedRow;
  int? selectedCol;

  /// Number highlighted/selected in the number picker (1–9), or null.
  int? selectedNumber;

  bool isComplete = false;

  bool showLevelSelect = true;

  /// When true, row/column/box and same-value highlighting is suppressed.
  bool expertMode = false;

  SudokuDifficulty _difficulty = SudokuDifficulty.normal;
  SudokuDifficulty get difficulty => _difficulty;

  /// Side length of the grid: 4 for mini, 6 for the 6×6 puzzles, 9 otherwise.
  int get gridSize => switch (_difficulty) {
        SudokuDifficulty.mini     => 4,
        SudokuDifficulty.sixBySix => 6,
        _                         => 9,
      };

  /// Width (columns) of each rectangular sub-grid.
  int get boxWidth => switch (_difficulty) {
        SudokuDifficulty.mini     => 2,
        SudokuDifficulty.sixBySix => 2,
        _                         => 3,
      };

  /// Height (rows) of each rectangular sub-grid.
  int get boxHeight => switch (_difficulty) {
        SudokuDifficulty.mini     => 2,
        SudokuDifficulty.sixBySix => 3,
        _                         => 3,
      };

  /// Tracks how far through the current difficulty's puzzle list we are.
  int _difficultyOffset = 0;

  // ── Public API ──────────────────────────────────────────────────────────────

  void selectDifficulty(SudokuDifficulty difficulty) {
    _difficulty = difficulty;
    _difficultyOffset = 0;
    showLevelSelect = false;
    _loadCurrentPuzzle();
  }

  void showLevelSelection() {
    showLevelSelect = true;
    selectedRow = null;
    selectedCol = null;
    selectedNumber = null;
    notifyListeners();
  }

  void toggleExpertMode() {
    expertMode = !expertMode;
    notifyListeners();
  }

  /// Advances to the next puzzle within the same difficulty.
  void nextPuzzle() {
    _difficultyOffset++;
    _loadCurrentPuzzle();
  }

  void selectCell(int row, int col) {
    if (selectedRow == row && selectedCol == col) {
      selectedRow = null;
      selectedCol = null;
    } else {
      selectedRow = row;
      selectedCol = col;
      if (selectedNumber != null && !grid[row][col].isGiven) {
        _placeValue(row, col, selectedNumber!);
        selectedNumber = null;
      }
    }
    notifyListeners();
  }

  void selectNumber(int n) {
    selectedNumber = (selectedNumber == n) ? null : n;
    if (selectedNumber != null && selectedRow != null && selectedCol != null) {
      final cell = grid[selectedRow!][selectedCol!];
      if (!cell.isGiven) {
        _placeValue(selectedRow!, selectedCol!, selectedNumber!);
        selectedNumber = null;
      }
    }
    notifyListeners();
  }

  void clearSelectedCell() {
    if (selectedRow == null || selectedCol == null) return;
    final cell = grid[selectedRow!][selectedCol!];
    if (cell.isGiven) return;
    cell.value = 0;
    cell.hasError = false;
    _validateErrors();
    isComplete = false;
    notifyListeners();
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  void _loadCurrentPuzzle() {
    final String s;
    switch (_difficulty) {
      case SudokuDifficulty.mini:
        s = kMiniSudokuPuzzles[_difficultyOffset % kMiniSudokuPuzzles.length];
        break;
      case SudokuDifficulty.sixBySix:
        s = kSixBySixPuzzles[_difficultyOffset % kSixBySixPuzzles.length];
        break;
      default:
        final indices = _difficultyPuzzles[_difficulty]!;
        final puzzleIndex = indices[_difficultyOffset % indices.length];
        s = kSudokuPuzzles[puzzleIndex];
    }
    final size = gridSize;
    grid = List.generate(size, (r) {
      return List.generate(size, (c) {
        final v = int.parse(s[r * size + c]);
        return SudokuCell(isGiven: v != 0, value: v);
      });
    });
    selectedRow = null;
    selectedCol = null;
    selectedNumber = null;
    isComplete = false;
    notifyListeners();
  }

  void _placeValue(int row, int col, int value) {
    grid[row][col].value = value;
    _validateErrors();
    _checkComplete();
  }

  void _validateErrors() {
    final size = gridSize;
    for (var row in grid) {
      for (var cell in row) {
        cell.hasError = false;
      }
    }
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final v = grid[r][c].value;
        if (v == 0) continue;
        if (_hasConflict(r, c, v)) grid[r][c].hasError = true;
      }
    }
  }

  bool _hasConflict(int row, int col, int val) {
    final size = gridSize;
    final bw = boxWidth;
    final bh = boxHeight;
    for (int c = 0; c < size; c++) {
      if (c != col && grid[row][c].value == val) return true;
    }
    for (int r = 0; r < size; r++) {
      if (r != row && grid[r][col].value == val) return true;
    }
    final br = (row ~/ bh) * bh;
    final bc = (col ~/ bw) * bw;
    for (int r = br; r < br + bh; r++) {
      for (int c = bc; c < bc + bw; c++) {
        if ((r != row || c != col) && grid[r][c].value == val) return true;
      }
    }
    return false;
  }

  void _checkComplete() {
    for (var row in grid) {
      for (var cell in row) {
        if (cell.value == 0 || cell.hasError) {
          isComplete = false;
          return;
        }
      }
    }
    isComplete = true;
  }
}
