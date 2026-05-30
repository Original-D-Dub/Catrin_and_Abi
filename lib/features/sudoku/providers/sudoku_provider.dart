import 'package:flutter/material.dart';

import '../models/sudoku_models.dart';

/// Puzzle index ranges per difficulty (into [kSudokuPuzzles]).
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
      }
    }
    notifyListeners();
  }

  void selectNumber(int n) {
    selectedNumber = (selectedNumber == n) ? null : n;
    if (selectedNumber != null && selectedRow != null && selectedCol != null) {
      final cell = grid[selectedRow!][selectedCol!];
      if (!cell.isGiven) _placeValue(selectedRow!, selectedCol!, selectedNumber!);
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
    final indices = _difficultyPuzzles[_difficulty]!;
    final puzzleIndex = indices[_difficultyOffset % indices.length];
    final s = kSudokuPuzzles[puzzleIndex];
    grid = List.generate(9, (r) {
      return List.generate(9, (c) {
        final v = int.parse(s[r * 9 + c]);
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
    for (var row in grid) {
      for (var cell in row) {
        cell.hasError = false;
      }
    }
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = grid[r][c].value;
        if (v == 0) continue;
        if (_hasConflict(r, c, v)) grid[r][c].hasError = true;
      }
    }
  }

  bool _hasConflict(int row, int col, int val) {
    for (int c = 0; c < 9; c++) {
      if (c != col && grid[row][c].value == val) return true;
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && grid[r][col].value == val) return true;
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
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
