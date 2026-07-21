import 'dart:async';

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

  // ── Tutorial state (howToPlay only) ────────────────────────────────────────

  /// Current tutorial step. -1 = not active; 0 = intro message (3s timer);
  /// 1–4 = active steps with highlighting.
  int _tutorialStep = -1;
  int get tutorialStep => _tutorialStep;

  bool _showWellDone = false;
  Timer? _wellDoneTimer;

  String? _tutorialHintMessage;

  /// Whether [row],[col] should be highlighted blue by the tutorial.
  bool isTutorialHighlight(int row, int col) {
    switch (_tutorialStep) {
      case 1: // bottom-right 2×2 box
        return row >= 2 && col >= 2;
      case 2: // col 3 (0-based)
        return col == 3;
      case 3: // row 1 (0-based)
        return row == 1;
      case 4: // cells related to (0,0): row 0 + col 0 + top-left box
        return row == 0 || col == 0 || (row <= 1 && col <= 1);
      default:
        return false;
    }
  }

  /// Translation key for the current tutorial hint message.
  /// Returns '' when no message should be shown.
  String get tutorialMessageKey {
    if (_tutorialStep >= 1 && _hasAnyError()) {
      return 'sudoku.howtoplay.error';
    }
    if (_tutorialStep >= 1 && _showWellDone) {
      return 'sudoku.howtoplay.well_done';
    }
    if (_tutorialStep >= 1 && _tutorialStep <= 4 && _tutorialHintMessage != null) {
      return _tutorialHintMessage!;
    }
    switch (_tutorialStep) {
      case 0: return 'sudoku.howtoplay.step0';
      case 1: return 'sudoku.howtoplay.step1';
      case 2: return 'sudoku.howtoplay.step2';
      case 3: return 'sudoku.howtoplay.step3';
      case 4: return 'sudoku.howtoplay.step4';
      case 5: return 'sudoku.howtoplay.step5';
      default: return '';
    }
  }

  /// The number the player should tap in the current tutorial step, or null.
  int? get tutorialTargetNumber {
    switch (_tutorialStep) {
      case 1: return 2;
      case 2: return 4;
      case 3: return 1;
      default: return null;
    }
  }

  /// Called by the screen after the 3-second intro delay to move step 0 → 1.
  void advanceTutorialStep() {
    _doAdvanceTutorialStep();
    notifyListeners();
  }

  // Advances the step and auto-selects the relevant cell (no notify — caller handles it).
  void _doAdvanceTutorialStep() {
    _tutorialHintMessage = null;
    _tutorialStep++;
    switch (_tutorialStep) {
      case 1: selectedRow = 2; selectedCol = 3; break; // empty cell in bottom-right box
      case 2: selectedRow = 1; selectedCol = 3; break; // empty cell in col 3
      case 3: selectedRow = 1; selectedCol = 1; break; // empty cell in row 1
      case 4: selectedRow = 0; selectedCol = 0; break; // summary: show related cells
      case 5: selectedRow = null; selectedCol = null; break; // final: free play
      default: break;
    }
  }

  /// Checks whether the currently placed value completes a tutorial step.
  void _checkTutorialAdvance(int row, int col) {
    if (_difficulty != SudokuDifficulty.howToPlay) return;
    if (grid[row][col].hasError) return;
    if (_tutorialStep == 1 && row == 2 && col == 3) {
      _doAdvanceTutorialStep();
    } else if (_tutorialStep == 2 && row == 1 && col == 3) {
      _doAdvanceTutorialStep();
    } else if (_tutorialStep == 3 && row == 1 && col == 1) {
      _doAdvanceTutorialStep();
    } else if (_tutorialStep == 4 && row == 0 && col == 0) {
      _doAdvanceTutorialStep();
    }
  }

  /// Side length of the grid: 4 for howToPlay/mini, 6 for 6×6, 9 otherwise.
  int get gridSize => switch (_difficulty) {
        SudokuDifficulty.howToPlay => 4,
        SudokuDifficulty.mini      => 4,
        SudokuDifficulty.sixBySix  => 6,
        _                          => 9,
      };

  /// Width (columns) of each rectangular sub-grid.
  int get boxWidth => switch (_difficulty) {
        SudokuDifficulty.howToPlay => 2,
        SudokuDifficulty.mini      => 2,
        SudokuDifficulty.sixBySix  => 2,
        _                          => 3,
      };

  /// Height (rows) of each rectangular sub-grid.
  int get boxHeight => switch (_difficulty) {
        SudokuDifficulty.howToPlay => 2,
        SudokuDifficulty.mini      => 2,
        SudokuDifficulty.sixBySix  => 3,
        _                          => 3,
      };

  /// Tracks how far through the current difficulty's puzzle list we are.
  int _difficultyOffset = 0;

  // ── Public API ──────────────────────────────────────────────────────────────

  void selectDifficulty(SudokuDifficulty difficulty) {
    _difficulty = difficulty;
    _difficultyOffset = 0;
    showLevelSelect = false;
    _tutorialStep = (difficulty == SudokuDifficulty.howToPlay) ? 0 : -1;
    _loadCurrentPuzzle();
  }

  void showLevelSelection() {
    showLevelSelect = true;
    _tutorialStep = -1;
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
  /// For howToPlay, always stays on the first puzzle.
  void nextPuzzle() {
    if (_difficulty != SudokuDifficulty.howToPlay) _difficultyOffset++;
    _loadCurrentPuzzle();
  }

  void selectCell(int row, int col) {
    if (_tutorialStep >= 1 && _tutorialStep <= 4) {
      if (selectedRow == row && selectedCol == col) {
        // Re-tapping the selected tutorial cell: keep it selected, prompt keyboard.
        _tutorialHintMessage = 'sudoku.howtoplay.hint.tap_bsl';
      } else {
        // Tapping any other cell: block the interaction, prompt keyboard.
        _tutorialHintMessage = 'sudoku.howtoplay.hint.tap_keyboard';
      }
      notifyListeners();
      return;
    }
    _tutorialHintMessage = null;
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
      case SudokuDifficulty.howToPlay:
        s = kMiniSudokuPuzzles[0];
        break;
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
    _wellDoneTimer?.cancel();
    _wellDoneTimer = null;
    _showWellDone = false;
    _tutorialHintMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wellDoneTimer?.cancel();
    super.dispose();
  }

  void _placeValue(int row, int col, int value) {
    _tutorialHintMessage = null;
    final hadError = _tutorialStep >= 1 && _hasAnyError();
    grid[row][col].value = value;
    _validateErrors();
    if (_tutorialStep >= 1) {
      if (hadError && !_hasAnyError()) {
        _showWellDone = true;
        _wellDoneTimer?.cancel();
        _wellDoneTimer = Timer(const Duration(seconds: 4), () {
          _showWellDone = false;
          notifyListeners();
        });
      } else if (_hasAnyError()) {
        _wellDoneTimer?.cancel();
        _wellDoneTimer = null;
        _showWellDone = false;
      }
    }
    _checkComplete();
    _checkTutorialAdvance(row, col);
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

  bool _hasAnyError() {
    for (final row in grid) {
      for (final cell in row) {
        if (cell.hasError) return true;
      }
    }
    return false;
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
