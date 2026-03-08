import 'package:flutter/foundation.dart';

import '../models/letter_bingo_level.dart';

/// Game phases for Letter Bingo.
enum LetterBingoPhase {
  /// Showing level selection screen
  levelSelect,

  /// Actively playing a level
  playing,

  /// Player has achieved BINGO
  bingo,
}

/// State management for the Letter Bingo game.
///
/// Manages the full game lifecycle:
/// 1. Level selection
/// 2. Board generation (tiles with BSL letters)
/// 3. Random letter calling
/// 4. Tile matching and reveal
/// 5. Win detection (all cleared for L1, row complete for L2)
///
/// Uses [ChangeNotifier] for reactive UI updates via Provider.
class LetterBingoProvider extends ChangeNotifier {
  /// Current game phase
  LetterBingoPhase _phase = LetterBingoPhase.levelSelect;
  LetterBingoPhase get phase => _phase;

  /// The current level configuration (null during level select)
  LetterBingoLevel? _currentLevel;
  LetterBingoLevel? get currentLevel => _currentLevel;

  /// The tiles on the board
  List<BingoTile> _tiles = [];
  List<BingoTile> get tiles => List.unmodifiable(_tiles);

  /// The letter currently being called (null before first call)
  String? _calledLetter;
  String? get calledLetter => _calledLetter;

  /// Queue of letters still to be called (shuffled order)
  List<String> _callQueue = [];

  /// The row index that completed BINGO (Level 2 only, null for Level 1)
  int? _completedRow;
  int? get completedRow => _completedRow;

  /// Sets the level and starts the game.
  ///
  /// Generates the tile board and shuffles the call queue,
  /// then automatically calls the first letter.
  ///
  /// Parameters:
  /// - [levelNumber]: 1–5
  void startLevel({required int levelNumber}) {
    _currentLevel = LetterBingoLevel.allLevels
        .firstWhere((l) => l.number == levelNumber);
    _completedRow = null;

    _generateTiles();
    _buildCallQueue();
    _phase = LetterBingoPhase.playing;

    // Auto-call the first letter
    callNextLetter();

    notifyListeners();
  }

  /// Returns to the level selection screen.
  ///
  /// Resets all game state and sets phase to [LetterBingoPhase.levelSelect].
  void showLevelSelection() {
    _phase = LetterBingoPhase.levelSelect;
    _currentLevel = null;
    _tiles = [];
    _calledLetter = null;
    _callQueue = [];
    _completedRow = null;
    notifyListeners();
  }

  /// Resets the current level and starts a new game.
  ///
  /// Keeps the same level but regenerates tiles and call queue.
  void resetGame() {
    if (_currentLevel == null) return;
    startLevel(levelNumber: _currentLevel!.number);
  }

  /// Handles a player tap on a tile.
  ///
  /// If the tapped tile's letter matches the [calledLetter]:
  /// 1. Reveals the tile (shows placeholder object)
  /// 2. Checks for win condition
  /// 3. If not won, calls the next letter
  ///
  /// If the tile doesn't match or is already revealed, does nothing.
  ///
  /// Parameters:
  /// - [index]: The index of the tapped tile in the [tiles] list
  void tapTile({required int index}) {
    if (_phase != LetterBingoPhase.playing) return;
    if (index < 0 || index >= _tiles.length) return;

    final tile = _tiles[index];

    // Ignore taps on already-revealed tiles
    if (tile.isRevealed) return;

    // Only accept taps matching the called letter
    if (tile.letter != _calledLetter) return;

    // Reveal the tile
    tile.isRevealed = true;
    notifyListeners();

    // Check for win condition
    if (_checkWin()) {
      _phase = LetterBingoPhase.bingo;
      notifyListeners();
      return;
    }

    // Call the next letter after a short delay for the reveal animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_phase == LetterBingoPhase.playing) {
        callNextLetter();
      }
    });
  }

  /// Calls the next letter from the shuffled queue.
  ///
  /// Pops the first letter from [_callQueue] and sets it as
  /// the [calledLetter]. If the queue is empty, reshuffles
  /// unrevealed tile letters.
  void callNextLetter() {
    if (_phase != LetterBingoPhase.playing) return;

    // If queue is empty, rebuild from unrevealed tiles
    if (_callQueue.isEmpty) {
      _callQueue = _tiles
          .where((t) => !t.isRevealed)
          .map((t) => t.letter)
          .toList()
        ..shuffle();
    }

    if (_callQueue.isNotEmpty) {
      _calledLetter = _callQueue.removeAt(0);
      notifyListeners();
    }
  }

  /// Generates tiles for the current level.
  ///
  /// - **Level 1**: Uses all 5 letters (a–e) in a single row.
  /// - **Level 2**: Randomly selects 6 letters from a–i,
  ///   arranged in a 2×3 grid.
  void _generateTiles() {
    final level = _currentLevel!;
    _tiles = [];

    List<String> selectedLetters;

    if (level.winByCompletingAllTiles) {
      // Level 1: use all available letters, shuffled
      selectedLetters = List<String>.from(level.availableLetters)..shuffle();
    } else {
      // Level 2: randomly select tileCount letters from available
      final pool = List<String>.from(level.availableLetters)..shuffle();
      selectedLetters = pool.take(level.tileCount).toList()..shuffle();
    }

    // Create tiles with row/col positions
    for (int i = 0; i < selectedLetters.length; i++) {
      final row = i ~/ level.cols;
      final col = i % level.cols;
      _tiles.add(BingoTile(
        letter: selectedLetters[i],
        row: row,
        col: col,
      ));
    }
  }

  /// Builds the call queue by shuffling the tile letters.
  ///
  /// For Level 1, all 5 letters are queued.
  /// For Level 2, all 6 placed letters are queued.
  void _buildCallQueue() {
    _callQueue = _tiles.map((t) => t.letter).toList()..shuffle();
  }

  /// Checks if the current board state satisfies the win condition.
  ///
  /// - **Level 1**: All tiles must be revealed.
  /// - **Level 2**: Any complete row (all 3 tiles in a row revealed).
  ///
  /// Returns true if the player has won.
  bool _checkWin() {
    final level = _currentLevel!;

    if (level.winByCompletingAllTiles) {
      // Level 1: all tiles must be revealed
      return _tiles.every((t) => t.isRevealed);
    } else {
      // Level 2: check each row for completion
      for (int row = 0; row < level.rows; row++) {
        final rowTiles = _tiles.where((t) => t.row == row).toList();
        if (rowTiles.isNotEmpty && rowTiles.every((t) => t.isRevealed)) {
          _completedRow = row;
          return true;
        }
      }
      return false;
    }
  }
}
