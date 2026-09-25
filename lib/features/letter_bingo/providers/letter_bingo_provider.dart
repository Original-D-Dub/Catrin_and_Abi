import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/services/game_stats_service.dart';
import '../models/animal_model.dart';
import '../models/letter_bingo_level.dart';
import 'bingo_collection_provider.dart';

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

  /// [initialLevelNumber], when set, skips level-select and starts directly
  /// at that level — used when launched from the "Learn BSL trail".
  ///
  /// [bingoCollection] is the app-wide reward cache (see
  /// [BingoCollectionProvider]). Its `preload` is kicked off right here,
  /// the moment the game is entered — this constructor runs exactly once
  /// per game session (via `ChangeNotifierProvider.create` in routes.dart),
  /// unlike the route's `builder`, which can re-run mid-transition — so by
  /// the time a round is won [_selectRewardAnimal] can read the reward list
  /// straight from the cache without a fresh fetch.
  LetterBingoProvider({
    SignSystem signSystem = SignSystem.bsl,
    required BingoCollectionProvider bingoCollection,
    String? playerId,
    int? initialLevelNumber,
  })  : _signSystem = signSystem,
        _bingoCollection = bingoCollection {
    unawaited(
      _bingoCollection.preload(signSystem: _signSystem, playerId: playerId),
    );
    if (initialLevelNumber != null) {
      startLevel(levelNumber: initialLevelNumber);
    }
  }

  /// The sign system (BSL or IAC) this game instance uses.
  final SignSystem _signSystem;
  SignSystem get signSystem => _signSystem;

  /// Shared app-wide reward cache — see the constructor doc.
  final BingoCollectionProvider _bingoCollection;

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

  /// Called once, with the number of tiles revealed, the moment BINGO is
  /// achieved. Set by the screen when launched from the "Learn BSL trail"
  /// so it can mark the trail node completed without coupling the provider
  /// to trail state.
  Function(int score)? onLevelComplete;

  /// Overrides how many tiles are generated for Level 1 (null = use all).
  int? _tileCountOverride;

  // ── Animal reward ──────────────────────────────────────────────────────────

  /// Lowercase letters the player has correctly tapped this round.
  final Set<String> _tappedLetters = {};
  Set<String> get tappedLetters => Set.unmodifiable(_tappedLetters);

  /// The animal selected as the round reward (null if none available).
  Animal? _rewardAnimal;
  Animal? get rewardAnimal => _rewardAnimal;

  final _rng = Random();

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
      final revealedCount = _tiles.where((t) => t.isRevealed).length;
      final gameId = _signSystem == SignSystem.iac
          ? GameIds.welshLetterBingo
          : GameIds.letterBingo;
      _statsService.recordGameResult(
        gameId,
        revealedCount,
        level: _currentLevel!.number,
      );
      onLevelComplete?.call(revealedCount);
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
    final allAnimals = _bingoCollection.rewardsFor(_signSystem);
    if (allAnimals.isEmpty ||
        _currentLevel == null ||
        _tappedLetters.isEmpty) {
      return null;
    }

    final level = _currentLevel!.number;
    final pool = <Animal>[];

    for (final animal in allAnimals) {
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
