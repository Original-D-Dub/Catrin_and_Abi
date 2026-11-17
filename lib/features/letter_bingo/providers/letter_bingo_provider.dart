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

  /// Multiplayer: the caller's screen — shows each called letter's sign and
  /// a scrolling list of letters already called.
  caller,

  /// Multiplayer: a player's bingo card (tap squares to mark them).
  player,

  /// Multiplayer: a player completed a row on their card.
  playerBingo,
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
  }) : _signSystem = signSystem,
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

  /// Blank squares this game (levels with [LetterBingoLevel.blanksPerRow]),
  /// keyed by grid position (`row * cols + col`) with the value a random
  /// palette index for [tileColorForIndex]. Chosen once per game so the
  /// colours don't change on rebuild.
  Map<int, int> _blankColours = {};
  Map<int, int> get blankColours => Map.unmodifiable(_blankColours);

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

  // ── Multiplayer ────────────────────────────────────────────────────────────

  /// Whether the level select is showing the multiplayer (Caller / Player)
  /// choice instead of the one-player level grid.
  bool _isMultiplayer = false;
  bool get isMultiplayer => _isMultiplayer;

  void setMultiplayer(bool value) {
    if (_isMultiplayer == value) return;
    _isMultiplayer = value;
    notifyListeners();
  }

  /// Every letter (for IAC, every Welsh letter incl. digraphs) multiplayer
  /// draws from — the last level's pool, which is the whole alphabet.
  List<String> get _wholeAlphabet => levels.last.availableLetters;

  /// Multiplayer games won this session — counted when the Winner button
  /// is tapped on a checked card, at most once per card. Kept in memory
  /// only (never saved), for logged-in and anonymous players alike; it
  /// resets when the player leaves Letter Bingo, since this provider is
  /// created afresh for each visit.
  int _gamesWon = 0;
  int get gamesWon => _gamesWon;

  /// Whether the current card's win has already been counted.
  bool _cardWinCounted = false;

  /// Winner tapped on the checking view: counts the win (once per card).
  void recordWin() {
    if (_cardWinCounted) return;
    _cardWinCounted = true;
    _gamesWon++;
    notifyListeners();
  }

  /// How many letters the caller calls in all (26 for BSL, 29 for IAC).
  int get alphabetSize => _wholeAlphabet.length;

  /// Whether the player card is in the checking view — entered with Check
  /// on the BINGO overlay, left with Keep Playing (or a new card).
  bool _checking = false;

  /// Tiles (indices into [tiles]) in the checked row currently showing
  /// their BSL/IAC sign instead of the letter. Checking view only.
  final Set<int> _signsShown = {};

  bool isSignShown(int index) => _signsShown.contains(index);

  /// The completed row being checked, highlighted on the card while in the
  /// checking view. Null otherwise.
  int? get checkingRow =>
      _phase == LetterBingoPhase.player && _checking ? _completedRow : null;

  /// Caller: letters still to call, in shuffled order.
  List<String> _callerQueue = [];

  /// Caller: the letter currently being shown (null once every letter in
  /// the alphabet has been called).
  String? _callerLetter;
  String? get callerLetter => _callerLetter;

  /// Caller: letters already called, oldest first. The current
  /// [callerLetter] joins this list when the caller taps Next.
  final List<String> _calledHistory = [];
  List<String> get calledHistory => List.unmodifiable(_calledHistory);

  /// Opens the caller screen with a freshly shuffled alphabet.
  void startCaller() {
    _callerQueue = List<String>.from(_wholeAlphabet)..shuffle(_rng);
    _calledHistory.clear();
    _callerLetter = _callerQueue.removeAt(0);
    _phase = LetterBingoPhase.caller;
    notifyListeners();
  }

  /// Caller tapped Next: the current letter moves into [calledHistory] and
  /// the next letter is shown (or none, once the alphabet runs out).
  void callerNext() {
    if (_phase != LetterBingoPhase.caller || _callerLetter == null) return;
    _calledHistory.add(_callerLetter!);
    _callerLetter = _callerQueue.isEmpty ? null : _callerQueue.removeAt(0);
    notifyListeners();
  }

  /// Opens a new player card: Level 8's layout (3 rows of 6, two random
  /// blanks per row) with 12 letters from the whole alphabet. Blanks are
  /// placed by [_pickBlankColumns], as on the one-player levels.
  void startPlayerCard() {
    final last = levels.last;
    _currentLevel = LetterBingoLevel(
      number: last.number,
      name: last.name,
      rows: 3,
      cols: 6,
      blanksPerRow: 2,
      availableLetters: _wholeAlphabet,
      winByCompletingAllTiles: false,
    );
    _tileCountOverride = null;
    _completedRow = null;
    _tappedLetters.clear();
    _rewardAnimal = null;
    _calledLetter = null;
    _callQueue = [];
    _cardWinCounted = false;
    _checking = false;
    _signsShown.clear();
    _generateTiles();
    _phase = LetterBingoPhase.player;
    notifyListeners();
  }

  /// Player tapped Check on the BINGO overlay: closes it and opens the
  /// checking view, so the winning row's letters can be checked against
  /// the caller's list. See [togglePlayerTile] for taps while checking.
  void checkPlayerCard() {
    if (_phase != LetterBingoPhase.playerBingo) return;
    _phase = LetterBingoPhase.player;
    _checking = true;
    _signsShown.clear();
    notifyListeners();
  }

  /// Player tapped Keep Playing in the checking view: back to the normal
  /// card, where tapping a marked square removes its dab — so mistakes can
  /// be corrected and play carries on.
  void keepPlaying() {
    if (!_checking) return;
    _checking = false;
    _signsShown.clear();
    notifyListeners();
  }

  /// Player tapped a square on their card: marks it, or unmarks it if it
  /// was already marked (so a mis-tap can be undone). Completing a row
  /// moves to [LetterBingoPhase.playerBingo]. Nothing is checked against
  /// the caller — they're on another device; the caller checks a BINGO
  /// against their called-letters list.
  ///
  /// In the checking view, tapping a square in the winning row flips it
  /// between its letter and its BSL/IAC sign; any other square does nothing.
  void togglePlayerTile({required int index}) {
    if (_phase != LetterBingoPhase.player) return;
    if (index < 0 || index >= _tiles.length) return;
    final tile = _tiles[index];
    if (_checking) {
      if (tile.row != _completedRow) return;
      if (!_signsShown.remove(index)) _signsShown.add(index);
      notifyListeners();
      return;
    }
    tile.isRevealed = !tile.isRevealed;
    if (tile.isRevealed) onCorrect?.call();
    // Re-found by _checkWin if a row is still complete.
    _completedRow = null;
    if (_checkWin()) _phase = LetterBingoPhase.playerBingo;
    notifyListeners();
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
    _blankColours = {};
    _calledLetter = null;
    _callQueue = [];
    _completedRow = null;
    _tileCountOverride = null;
    _tappedLetters.clear();
    _rewardAnimal = null;
    _callerQueue = [];
    _callerLetter = null;
    _calledHistory.clear();
    _checking = false;
    _signsShown.clear();
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

    // Skipped if the player has already moved on with Next meanwhile.
    final callAtTap = _callCount;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_phase == LetterBingoPhase.playing && _callCount == callAtTap) {
        callNextLetter();
      }
    });
  }

  /// Bumped on every call, so a delayed auto-call after a correct tap can
  /// tell the player has already moved on with [nextLetter].
  int _callCount = 0;

  /// The player tapped Next: move on to another letter without tapping the
  /// current one. An on-board letter skipped this way comes round again.
  void nextLetter() => callNextLetter();

  /// Calls the next letter from the shuffled queue.
  void callNextLetter() {
    if (_phase != LetterBingoPhase.playing) return;

    // Drop anything revealed since it was queued.
    final revealed = {
      for (final t in _tiles)
        if (t.isRevealed) t.letter,
    };
    _callQueue.removeWhere(revealed.contains);

    if (_callQueue.isEmpty) _callQueue = _freshCallQueue();

    // Avoid calling the same letter twice in a row (the display only
    // speaks a letter when it changes).
    if (_callQueue.length > 1 && _callQueue.first == _calledLetter) {
      _callQueue.add(_callQueue.removeAt(0));
    }

    if (_callQueue.isNotEmpty) {
      _callCount++;
      _calledLetter = _callQueue.removeAt(0);
      notifyListeners();
    }
  }

  /// Every letter still to find on the board — plus, on levels with
  /// [LetterBingoLevel.callsOffGridLetters], the level's letters that
  /// aren't on the board — shuffled.
  List<String> _freshCallQueue() {
    final onBoard = _tiles.map((t) => t.letter).toSet();
    return [
      for (final t in _tiles)
        if (!t.isRevealed) t.letter,
      if (_currentLevel?.callsOffGridLetters ?? false)
        for (final letter in _currentLevel!.availableLetters)
          if (!onBoard.contains(letter)) letter,
    ]..shuffle(_rng);
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
  /// - L6–L8: every tapped letter (1×) — the level's pool already limits
  ///   them (a–m, n–z, full alphabet)
  Animal? _selectRewardAnimal() {
    final allAnimals = _bingoCollection.rewardsFor(_signSystem);
    if (allAnimals.isEmpty || _currentLevel == null || _tappedLetters.isEmpty) {
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
      case 6: // only this level's letters can have been tapped, so every
      case 7: // tapped letter is equally likely
      case 8:
        return 1;
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

    // Pick each row's blank squares at random, then fill the rest of the
    // grid, in reading order, with the selected letters.
    _blankColours = {};
    if (level.blanksPerRow > 0) {
      final blankCols = _pickBlankColumns(level);
      final colours = List.generate(bingoTilePalette.length, (i) => i)
        ..shuffle(_rng);
      for (int row = 0; row < level.rows; row++) {
        for (final col in blankCols[row]) {
          _blankColours[row * level.cols + col] =
              colours[_blankColours.length % colours.length];
        }
      }
    }

    var position = 0;
    for (final letter in selectedLetters) {
      while (_blankColours.containsKey(position)) {
        position++;
      }
      _tiles.add(
        BingoTile(
          letter: letter,
          row: position ~/ level.cols,
          col: position % level.cols,
        ),
      );
      position++;
    }
  }

  /// Random blank columns for each row of [level] — [blanksPerRow] per row —
  /// re-picked if every row's blanks would line up in the same column(s),
  /// or if any single column would be blank in every row.
  List<Set<int>> _pickBlankColumns(LetterBingoLevel level) {
    while (true) {
      final picks = List.generate(level.rows, (_) {
        final cols = List.generate(level.cols, (c) => c)..shuffle(_rng);
        return cols.take(level.blanksPerRow).toSet();
      });
      final allLinedUp = picks.every(
        (p) => p.length == picks.first.length && p.containsAll(picks.first),
      );
      final hasBlankColumn = List.generate(
        level.cols,
        (c) => c,
      ).any((c) => picks.every((p) => p.contains(c)));
      // A single row, or blanks filling whole rows, can't avoid lining up.
      if ((!allLinedUp && !hasBlankColumn) ||
          level.rows < 2 ||
          level.blanksPerRow >= level.cols) {
        return picks;
      }
    }
  }

  void _buildCallQueue() {
    _callQueue = _freshCallQueue();
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
