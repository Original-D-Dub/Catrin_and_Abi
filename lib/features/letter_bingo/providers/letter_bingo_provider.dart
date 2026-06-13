import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/services/game_stats_service.dart';
import '../models/animal_model.dart';
import '../models/letter_bingo_level.dart';

/// Game phases for Letter Bingo.
enum LetterBingoPhase {
  /// Showing level selection screen
  levelSelect,

  /// Actively playing a level
  playing,

  /// Player has achieved BINGO (shows BingoCelebration)
  bingo,
}

/// State management for the Letter Bingo game.
///
/// Manages the full game lifecycle:
/// 1. Level selection
/// 2. Board generation (tiles with BSL letters)
/// 3. Random letter calling
/// 4. Tile matching and reveal
/// 5. Win detection (all cleared for L1, row complete for L2+)
/// 6. Animal reward selection (logged-in users only)
///
/// Uses [ChangeNotifier] for reactive UI updates via Provider.
class LetterBingoProvider extends ChangeNotifier {
  final GameStatsService _statsService = GameStatsService();

  LetterBingoProvider({SignSystem signSystem = SignSystem.bsl})
      : _signSystem = signSystem {
    _loadAnimals();
  }

  /// The sign system (BSL or IAC) this game instance uses.
  final SignSystem _signSystem;
  SignSystem get signSystem => _signSystem;

  /// Levels available for the current sign system.
  List<LetterBingoLevel> get levels =>
      LetterBingoLevel.forSignSystem(_signSystem);

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

  /// The row index that completed BINGO (Level 2+ only, null for Level 1)
  int? _completedRow;
  int? get completedRow => _completedRow;

  /// Called when the player successfully reveals a tile.
  VoidCallback? onCorrect;

  /// Called when the player taps a tile that doesn't match the called letter.
  VoidCallback? onWrongTap;

  /// Overrides how many tiles are generated for Level 1 (null = use all).
  int? _tileCountOverride;

  // ── Animal reward ──────────────────────────────────────────────────────────

  /// Lowercase letters the player has correctly tapped this round.
  final Set<String> _tappedLetters = {};
  Set<String> get tappedLetters => Set.unmodifiable(_tappedLetters);

  /// The animal selected as the round reward (null if none available).
  Animal? _rewardAnimal;
  Animal? get rewardAnimal => _rewardAnimal;

  /// All animals loaded from assets/data/animals.json.
  List<Animal> _allAnimals = [];

  final _rng = Random();

  Future<void> _loadAnimals() async {
    try {
      final json = await rootBundle.loadString('assets/data/animals.json');
      final list = jsonDecode(json) as List<dynamic>;
      _allAnimals =
          list.map((e) => Animal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('LetterBingoProvider: failed to load animals.json — $e');
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Sets the level and starts the game.
  void startLevel({required int levelNumber, int? tileCountOverride}) {
    _currentLevel = levels.firstWhere((l) => l.number == levelNumber);
    _tileCountOverride = tileCountOverride;
    _completedRow = null;
    _tappedLetters.clear();
    _rewardAnimal = null;

    _generateTiles();
    _buildCallQueue();
    _phase = LetterBingoPhase.playing;

    callNextLetter();
    notifyListeners();
  }

  /// Returns to the level selection screen and resets all state.
  void showLevelSelection() {
    _phase = LetterBingoPhase.levelSelect;
    _currentLevel = null;
    _tiles = [];
    _calledLetter = null;
    _callQueue = [];
    _completedRow = null;
    _tileCountOverride = null;
    _tappedLetters.clear();
    _rewardAnimal = null;
    notifyListeners();
  }

  /// Resets the current level and starts a new game.
  void resetGame() {
    if (_currentLevel == null) return;
    startLevel(
      levelNumber: _currentLevel!.number,
      tileCountOverride: _tileCountOverride,
    );
  }

  /// Handles a player tap on a tile.
  ///
  /// Accepts only taps matching [calledLetter]. On a correct tap the tile is
  /// revealed, the letter recorded, and win condition checked. On win,
  /// transitions to [LetterBingoPhase.reward] if an animal reward can be
  /// selected, otherwise directly to [LetterBingoPhase.bingo].
  void tapTile({required int index}) {
    if (_phase != LetterBingoPhase.playing) return;
    if (index < 0 || index >= _tiles.length) return;

    final tile = _tiles[index];
    if (tile.isRevealed) return;
    if (tile.letter != _calledLetter) {
      onWrongTap?.call();
      return;
    }

    tile.isRevealed = true;
    _tappedLetters.add(tile.letter);
    onCorrect?.call();
    notifyListeners();

    if (_checkWin()) {
      _statsService.recordGameResult(
        GameIds.letterBingo,
        _tiles.where((t) => t.isRevealed).length,
        level: _currentLevel!.number,
      );
      _rewardAnimal = _selectRewardAnimal();
      _phase = LetterBingoPhase.bingo;
      notifyListeners();
      return;
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_phase == LetterBingoPhase.playing) callNextLetter();
    });
  }

  /// Calls the next letter from the shuffled queue.
  void callNextLetter() {
    if (_phase != LetterBingoPhase.playing) return;

    if (_callQueue.isEmpty) {
      _callQueue = _tiles
          .where((t) => !t.isRevealed)
          .map((t) => t.letter)
          .toList()
        ..shuffle(_rng);
    }

    if (_callQueue.isNotEmpty) {
      _calledLetter = _callQueue.removeAt(0);
      notifyListeners();
    }
  }

  // ── Animal reward selection ────────────────────────────────────────────────

  /// Picks a weighted-random animal whose letter the player tapped this round.
  ///
  /// Level weighting (letters listed as uppercase in JSON but compared
  /// case-insensitively):
  /// - L1: a–e (1×)
  /// - L2: a–e (1×), f–i (2×)
  /// - L3: a–i (1×), j–o (2×)
  /// - L4: a–o (1×), p–u (2×)
  /// - L5: a–u (1×), v–z (2×)
  Animal? _selectRewardAnimal() {
    if (_allAnimals.isEmpty ||
        _currentLevel == null ||
        _tappedLetters.isEmpty) {
      return null;
    }

    final level = _currentLevel!.number;
    final pool = <Animal>[];

    for (final animal in _allAnimals) {
      final letter = animal.letter.toLowerCase();
      if (!_tappedLetters.contains(letter)) continue;
      final weight = _weightForLetter(letter, level);
      for (int i = 0; i < weight; i++) {
        pool.add(animal);
      }
    }

    if (pool.isEmpty) return null;
    return pool[_rng.nextInt(pool.length)];
  }

  /// Returns the selection weight (0 = excluded) for [letter] at [level].
  int _weightForLetter(String letter, int level) {
    final code = letter.codeUnitAt(0) - 'a'.codeUnitAt(0); // 0=a … 25=z
    switch (level) {
      case 1: // a–e only
        return code <= 4 ? 1 : 0;
      case 2: // a–e (1×), f–i (2×)
        if (code <= 4) return 1;
        if (code <= 8) return 2;
        return 0;
      case 3: // a–i (1×), j–o (2×)
        if (code <= 8) return 1;
        if (code <= 14) return 2;
        return 0;
      case 4: // a–o (1×), p–u (2×)
        if (code <= 14) return 1;
        if (code <= 20) return 2;
        return 0;
      case 5: // a–u (1×), v–z (2×)
        if (code <= 20) return 1;
        return 2;
      default:
        return 0;
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  void _generateTiles() {
    final level = _currentLevel!;
    _tiles = [];

    List<String> selectedLetters;

    if (level.winByCompletingAllTiles) {
      final pool = List<String>.from(level.availableLetters)..shuffle(_rng);
      final count = _tileCountOverride ?? pool.length;
      selectedLetters = pool.take(count).toList();
    } else {
      final pool = List<String>.from(level.availableLetters)..shuffle(_rng);
      selectedLetters = pool.take(level.tileCount).toList()..shuffle(_rng);
    }

    for (int i = 0; i < selectedLetters.length; i++) {
      _tiles.add(BingoTile(
        letter: selectedLetters[i],
        row: i ~/ level.cols,
        col: i % level.cols,
      ));
    }
  }

  void _buildCallQueue() {
    _callQueue = _tiles.map((t) => t.letter).toList()..shuffle(_rng);
  }

  bool _checkWin() {
    final level = _currentLevel!;

    if (level.winByCompletingAllTiles) {
      return _tiles.every((t) => t.isRevealed);
    }

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
