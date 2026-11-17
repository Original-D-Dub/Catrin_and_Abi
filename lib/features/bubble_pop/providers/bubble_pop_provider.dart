import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_filters.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_stats_service.dart';

/// Represents a bubble floating on screen.
class Bubble {
  /// Unique identifier for this bubble
  final String id;

  /// The letter (or digraph) displayed inside this bubble
  final String letter;

  /// Current position (0.0 to 1.0 representing screen width percentage)
  double x;

  /// Current position (0.0 to 1.0, where 1.0 is bottom of play area)
  double y;

  /// Horizontal speed (-1 to 1)
  final double speedX;

  /// Vertical speed (negative = moving up)
  final double speedY;

  /// Bubble color
  final Color color;

  /// Whether this bubble has been popped
  bool isPopped;

  Bubble({
    required this.id,
    required this.letter,
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.color,
    this.isPopped = false,
  });
}

/// Champion Mode "x2 multiplier" text that replaces the bubble whose pop
/// reached a new multiplier tier. It keeps floating along that bubble's
/// path, can't be tapped, and fades out after [BubblePopProvider
/// .multiplierLabelHoldMs].
class MultiplierLabel {
  final String id;
  final int multiplier;
  double x;
  double y;
  final double speedX;
  final double speedY;

  /// Milliseconds since the label appeared, advanced by the game loop.
  double ageMs = 0;

  MultiplierLabel({
    required this.id,
    required this.multiplier,
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
  });

  /// 1.0 until the hold delay ends, then fades linearly to 0.
  double get opacity {
    final fadeT = (ageMs - BubblePopProvider.multiplierLabelHoldMs) /
        BubblePopProvider.multiplierLabelFadeMs;
    return (1 - fadeT).clamp(0.0, 1.0);
  }

  bool get isFinished =>
      ageMs >=
      BubblePopProvider.multiplierLabelHoldMs +
          BubblePopProvider.multiplierLabelFadeMs;
}

/// Game level configuration with progressive letter sets.
class GameLevel {
  /// Level number (1-6)
  final int number;

  /// Translation key for the level's display name
  final String name;

  /// Letters (and, for IAC, digraphs) available in this level
  final List<String> letters;

  const GameLevel({
    required this.number,
    required this.name,
    required this.letters,
  });
}

/// All available game levels, for both sign systems.
///
/// BSL levels use the English alphabet (a-z); IAC levels use the Welsh
/// alphabet, which includes eight digraphs (ch, dd, ff, ng, ll, ph, rh, th)
/// introduced gradually alongside the single letters.
class GameLevels {
  GameLevels._();

  // ─────────────────────────────────────────
  // BSL levels (English alphabet)
  // ─────────────────────────────────────────

  /// Level 1: Vowels only
  static const GameLevel bslLevel1 = GameLevel(
    number: 1,
    name: 'bubble_pop.bsl.level1.name',
    letters: ['a', 'e', 'i', 'o', 'u'],
  );

  /// Level 2: Letters a to e
  static const GameLevel bslLevel2 = GameLevel(
    number: 2,
    name: 'bubble_pop.bsl.level2.name',
    letters: ['a', 'b', 'c', 'd', 'e'],
  );

  /// Level 3: Letters a to i
  static const GameLevel bslLevel3 = GameLevel(
    number: 3,
    name: 'bubble_pop.bsl.level3.name',
    letters: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'],
  );

  /// Level 4: Letters a to o
  static const GameLevel bslLevel4 = GameLevel(
    number: 4,
    name: 'bubble_pop.bsl.level4.name',
    letters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o'
    ],
  );

  /// Level 5: Letters a to u
  static const GameLevel bslLevel5 = GameLevel(
    number: 5,
    name: 'bubble_pop.bsl.level5.name',
    letters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
      'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u'
    ],
  );

  /// Level 6: Full alphabet a to z
  static const GameLevel bslLevel6 = GameLevel(
    number: 6,
    name: 'bubble_pop.bsl.level6.name',
    letters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
      'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    ],
  );

  /// All BSL levels
  static const List<GameLevel> bslLevels = [
    bslLevel1,
    bslLevel2,
    bslLevel3,
    bslLevel4,
    bslLevel5,
    bslLevel6,
  ];

  // ─────────────────────────────────────────
  // IAC levels (Welsh alphabet, incl. digraphs)
  // ─────────────────────────────────────────

  /// Level 1: Welsh vowels
  static const GameLevel iacLevel1 = GameLevel(
    number: 1,
    name: 'bubble_pop.iac.level1.name',
    letters: ['a', 'e', 'i', 'o', 'u', 'w', 'y'],
  );

  /// Level 2: Letters a to f
  static const GameLevel iacLevel2 = GameLevel(
    number: 2,
    name: 'bubble_pop.iac.level2.name',
    letters: ['a', 'b', 'c', 'd', 'e', 'f'],
  );

  /// Level 3: Letters a to i, plus the digraphs ch, dd, ff
  static const GameLevel iacLevel3 = GameLevel(
    number: 3,
    name: 'bubble_pop.iac.level3.name',
    letters: ['a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'h', 'i'],
  );

  /// Level 4: Letters a to o, plus ng, ll
  static const GameLevel iacLevel4 = GameLevel(
    number: 4,
    name: 'bubble_pop.iac.level4.name',
    letters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o',
    ],
  );

  /// Level 5: Letters a to u, plus ph, rh, th
  static const GameLevel iacLevel5 = GameLevel(
    number: 5,
    name: 'bubble_pop.iac.level5.name',
    letters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o', 'p', 'ph', 'r', 'rh', 's',
      't', 'th', 'u',
    ],
  );

  /// Level 6: Full Welsh alphabet, including w and y
  static const GameLevel iacLevel6 = GameLevel(
    number: 6,
    name: 'bubble_pop.iac.level6.name',
    letters: [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g', 'ng', 'h',
      'i', 'j', 'l', 'll', 'm', 'n', 'o', 'p', 'ph', 'r', 'rh', 's',
      't', 'th', 'u', 'w', 'y',
    ],
  );

  /// All IAC levels
  static const List<GameLevel> iacLevels = [
    iacLevel1,
    iacLevel2,
    iacLevel3,
    iacLevel4,
    iacLevel5,
    iacLevel6,
  ];

  /// Returns the level list for the given sign system.
  static List<GameLevel> forSignSystem(SignSystem signSystem) =>
      signSystem == SignSystem.iac ? iacLevels : bslLevels;

  /// Gets a level by number (1-6) for the given sign system.
  /// Returns level 1 if [number] is invalid.
  static GameLevel getLevel(int number, SignSystem signSystem) {
    final levels = forSignSystem(signSystem);
    if (number < 1 || number > levels.length) return levels[0];
    return levels[number - 1];
  }
}

/// Game state for the Bubble Pop game.
///
/// Manages:
/// - Timer countdown (60 seconds)
/// - Current letter sign to match (BSL or IAC, per [signSystem])
/// - Floating bubbles with letters/digraphs
/// - Score tracking
/// - Level progression
/// - Easter egg detection (cat/dog for BSL, cath/ci for IAC)
class BubblePopProvider extends ChangeNotifier {
  /// Game duration in seconds
  static const int gameDurationSeconds = 60;

  /// Bubble colors for variety - using Catrin & Abi brand palette
  static const List<Color> bubbleColors = [
    AppColors.accentRed,       // Red
    AppColors.accentNavyBlue,  // Navy Blue
    AppColors.accentLimeGreen, // Lime Green
    AppColors.accentOrange,    // Orange
    AppColors.accentPurple,    // Purple
    AppColors.abiPink,         // Rose Pink (Abi's color)
    AppColors.catrinBlue,      // Sky Blue (Catrin's color)
    AppColors.connectorGold,   // Mustard Gold
  ];

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  /// [initialLevelNumber], when set, skips level-select and prepares that
  /// level directly (bubbles spawned, timer not yet running) — used when
  /// launched from the "Learn BSL trail", so the screen can still show the
  /// intro countdown before [startGame] actually starts the clock.
  BubblePopProvider({
    SignSystem signSystem = SignSystem.bsl,
    AgeGroup ageGroup = AgeGroup.all,
    int? initialLevelNumber,
  })  : _signSystem = signSystem,
        _speedScale = switch (ageGroup) {
          AgeGroup.years1to3 => 0.5,
          AgeGroup.years3to5 => 0.75,
          _ => 1.0,
        },
        _currentLevel = initialLevelNumber != null
            ? GameLevels.getLevel(initialLevelNumber, signSystem)
            : GameLevels.forSignSystem(signSystem).first {
    if (initialLevelNumber != null) prepareForIntro();
  }

  /// The sign system (BSL or IAC) this game instance uses.
  final SignSystem _signSystem;
  SignSystem get signSystem => _signSystem;

  /// Multiplier on every bubble's movement: ages 1–3 play at half speed,
  /// ages 3–5 at three-quarter speed.
  final double _speedScale;

  /// Levels available for the current sign system.
  List<GameLevel> get levels => GameLevels.forSignSystem(_signSystem);

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  /// Current game level
  GameLevel _currentLevel;
  GameLevel get currentLevel => _currentLevel;

  /// Whether to show level selection screen
  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  /// Remaining time in seconds
  int _timeRemaining = gameDurationSeconds;
  int get timeRemaining => _timeRemaining;

  /// Current score
  int _score = 0;
  int get score => _score;

  /// Current letter (or digraph) the player needs to find
  String _targetLetter = '';
  String get targetLetter => _targetLetter;

  /// List of active bubbles on screen
  List<Bubble> _bubbles = [];
  List<Bubble> get bubbles => List.unmodifiable(_bubbles);

  /// Whether the game is currently running
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Whether the game has ended
  bool _gameOver = false;
  bool get gameOver => _gameOver;

  /// Timer for countdown
  Timer? _countdownTimer;

  /// Timer for game loop (bubble movement)
  Timer? _gameLoopTimer;

  /// Number of bubbles kept on screen at once.
  static const int _targetBubbleCount = 10;

  /// Min/max delay (ms) between individual bubble spawns once the game is
  /// running, so replacements trickle in steadily instead of arriving in a
  /// synchronized batch ("waves").
  static const double _minSpawnIntervalMs = 300;
  static const double _maxSpawnIntervalMs = 900;

  /// Countdown (ms) until the next single bubble may spawn.
  double _spawnCooldownMs = 0;

  /// Track tapped letters for easter egg detection
  String _tappedSequence = '';

  /// Easter egg triggered (cat or dog)
  String? _easterEggTriggered;
  String? get easterEggTriggered => _easterEggTriggered;

  /// Bubble that was just popped (for animation)
  String? _lastPoppedBubbleId;
  String? get lastPoppedBubbleId => _lastPoppedBubbleId;

  // ─────────────────────────────────────────
  // Champion Mode
  // ─────────────────────────────────────────

  /// The level that must be completed (played until the timer runs out) to
  /// unlock Champion Mode.
  static const int championModeUnlockLevel = 6;

  /// Champion Mode points for a correct pop, before the streak multiplier.
  static const int championCorrectPoints = 10;

  /// Champion Mode points lost for a wrong pop (never multiplied).
  static const int championWrongPenalty = 5;

  /// Streak length → multiplier, highest threshold first. A streak below
  /// every threshold scores ×1.
  static const List<(int streak, int multiplier)> championMultipliers = [
    (20, 10),
    (10, 5),
    (5, 2),
  ];

  /// Whether Champion Mode scoring is enabled for the next game.
  bool _championMode = false;
  bool get championMode => _championMode;

  /// Whether the player has unlocked Champion Mode by completing level
  /// [championModeUnlockLevel].
  bool _isChampionModeUnlocked = false;
  bool get isChampionModeUnlocked => _isChampionModeUnlocked;

  /// True for one session only: the player just completed level
  /// [championModeUnlockLevel] for the first time. The screen shows a
  /// celebratory banner while this is true, then calls
  /// [dismissChampionModeUnlockedBanner] to clear it.
  bool _justUnlockedChampionMode = false;
  bool get justUnlockedChampionMode => _justUnlockedChampionMode;

  /// Consecutive correct pops in the current Champion Mode game. Reset to
  /// zero by a wrong pop.
  int _streak = 0;
  int get streak => _streak;

  /// Current Champion Mode score multiplier, derived from [streak].
  int get multiplier {
    for (final (threshold, value) in championMultipliers) {
      if (_streak >= threshold) return value;
    }
    return 1;
  }

  /// How long a [MultiplierLabel] stays fully visible, then how long it
  /// takes to fade out.
  static const double multiplierLabelHoldMs = 2000;
  static const double multiplierLabelFadeMs = 500;

  /// Active "x2 multiplier" labels floating in the play area.
  final List<MultiplierLabel> _multiplierLabels = [];
  List<MultiplierLabel> get multiplierLabels =>
      List.unmodifiable(_multiplierLabels);

  /// Points awarded (positive) or lost (negative) by the most recent pop
  /// in Champion Mode, for the floating "+20" / "-5" feedback. Null when
  /// there's nothing to show.
  int? _lastPointsDelta;
  int? get lastPointsDelta => _lastPointsDelta;

  /// Incremented on every Champion Mode pop so the screen can restart the
  /// points feedback animation even when [lastPointsDelta] is unchanged.
  int _pointsDeltaSerial = 0;
  int get pointsDeltaSerial => _pointsDeltaSerial;

  /// Unlocks Champion Mode from the player's stats for level
  /// [championModeUnlockLevel], if it isn't already unlocked.
  ///
  /// Only ever raises [isChampionModeUnlocked], never lowers it: guest play
  /// isn't persisted by [GameStatsService], so this lookup always comes back
  /// empty for guests — if it could clear the flag, a guest who just
  /// unlocked Champion Mode this session would see it re-locked on returning
  /// to level select.
  Future<void> _refreshChampionModeUnlock() async {
    if (_isChampionModeUnlocked) return;
    final best = await _statsService
        .getPersonalBest('${_statsGameId}_$championModeUnlockLevel');
    if (best != null && !_isChampionModeUnlocked) {
      _isChampionModeUnlocked = true;
      _championMode = !_championModeOffThisSession;
      notifyListeners();
    }
  }

  /// Set when the player long-presses the Champion rosette to switch
  /// Champion Mode off. Static so it lasts for the rest of the app session
  /// (every new provider starts with Champion Mode off), then resets — once
  /// unlocked, Champion Mode is on by default.
  static bool _championModeOffThisSession = false;

  /// Enables or disables Champion Mode for the rest of this app session
  /// (see [_championModeOffThisSession]). No-ops if not yet unlocked.
  void setChampionMode(bool value) {
    if (!_isChampionModeUnlocked) return;
    _championMode = value;
    _championModeOffThisSession = !value;
    notifyListeners();
  }

  /// Clears [justUnlockedChampionMode] once the unlock banner has been
  /// shown and dismissed.
  void dismissChampionModeUnlockedBanner() {
    _justUnlockedChampionMode = false;
    notifyListeners();
  }

  /// Stats id for this sign system's Bubble Pop.
  String get _statsGameId =>
      _signSystem == SignSystem.iac ? GameIds.welshBubblePop : GameIds.bubblePop;

  /// Stats id for this sign system's Bubble Pop Champion Mode.
  String get _championStatsGameId => _signSystem == SignSystem.iac
      ? GameIds.welshBubblePopChampion
      : GameIds.bubblePopChampion;

  /// Called once, with the final [_score], the moment the level ends. Set
  /// by the screen when launched from the "Learn BSL trail" so it can
  /// decide (score-gated, since this game has no other win condition)
  /// whether to mark the trail node completed.
  Function(int score)? onLevelComplete;

  /// Sets the game level and shows level selection.
  ///
  /// [levelNumber] must be between 1 and 6.
  void setLevel(int levelNumber) {
    _currentLevel = GameLevels.getLevel(levelNumber, _signSystem);
    notifyListeners();
  }

  /// Shows the level selection screen.
  void showLevelSelection() {
    _showLevelSelect = true;
    _isPlaying = false;
    _gameOver = false;
    _refreshChampionModeUnlock();
    notifyListeners();
  }

  /// Resets per-game Champion Mode state (streak and points feedback).
  void _resetChampionState() {
    _streak = 0;
    _lastPointsDelta = null;
    _justUnlockedChampionMode = false;
    _multiplierLabels.clear();
  }

  /// Transitions to game view and initialises bubbles without starting the timer.
  ///
  /// Call this when the player selects a level so the game content is visible
  /// under the intro overlay. Follow with [startGame] once the intro ends.
  void prepareForIntro() {
    _showLevelSelect = false;
    _timeRemaining = gameDurationSeconds;
    _score = 0;
    _bubbles = [];
    _isPlaying = false;
    _gameOver = false;
    _lastResult = null;
    _tappedSequence = '';
    _easterEggTriggered = null;
    _lastPoppedBubbleId = null;
    _resetChampionState();
    _resetTargetQueue();
    _selectNewTarget();
    _spawnInitialBubbles();
    notifyListeners();
  }

  /// Starts a new game with the current level.
  void startGame() {
    _showLevelSelect = false;
    _timeRemaining = gameDurationSeconds;
    _score = 0;
    _bubbles = [];
    _isPlaying = true;
    _gameOver = false;
    _lastResult = null;
    _tappedSequence = '';
    _easterEggTriggered = null;
    _lastPoppedBubbleId = null;
    _resetChampionState();
    _resetTargetQueue();
    _selectNewTarget();
    _spawnInitialBubbles();
    _startCountdown();
    _startGameLoop();

    notifyListeners();
  }

  /// Stops the game.
  ///
  /// [completed] is true when the timer ran out (the level was played to
  /// the end), as opposed to the player leaving early.
  void stopGame({bool completed = false}) {
    _isPlaying = false;
    _gameOver = true;
    _lastResult = null;
    _countdownTimer?.cancel();
    _gameLoopTimer?.cancel();
    notifyListeners();

    onLevelComplete?.call(_score);

    // Only games played until the timer runs out count towards stats —
    // leaving early (or backing out of level select) would otherwise record
    // a partial or zero score and inflate the play count.
    if (!completed) return;

    // Champion Mode scores are on a different scale, so they're recorded
    // under their own id (e.g. 'bubble_pop_champion_3') rather than mixed
    // into the normal per-level personal bests.
    final gameId = _championMode ? _championStatsGameId : _statsGameId;
    final unlocksChampionMode = completed &&
        !_championMode &&
        !_isChampionModeUnlocked &&
        _currentLevel.number == championModeUnlockLevel;
    _statsService.recordGameResult(gameId, _score, level: _currentLevel.number).then((result) {
      _lastResult = result;
      if (unlocksChampionMode && !_isChampionModeUnlocked) {
        _isChampionModeUnlocked = true;
        _championMode = !_championModeOffThisSession;
        _justUnlockedChampionMode = true;
      }
      notifyListeners();
    }).catchError((e) {
      debugPrint('recordGameResult error ($gameId): $e');
    });
  }

  /// Most consecutive times the same target letter may be called.
  static const int _maxSameTargetRun = 2;

  /// Number of upcoming target letters calculated in advance.
  static const int _upcomingTargetCount = 4;

  /// Target letters queued to be shown after [_targetLetter], in order.
  /// When a target is matched, the first entry becomes the new target, the
  /// rest shift up one, and a new random letter is appended to the end.
  final List<String> _upcomingTargets = [];
  List<String> get upcomingTargets => List.unmodifiable(_upcomingTargets);

  /// Picks a random letter to follow [sequence] (the current target plus
  /// queued targets), never allowing the same letter three times in a row.
  String _randomNextTarget(List<String> sequence) {
    var letters = _currentLevel.letters;
    if (sequence.length >= _maxSameTargetRun) {
      final last = sequence.last;
      final tail = sequence.sublist(sequence.length - _maxSameTargetRun);
      if (tail.every((l) => l == last)) {
        final others = letters.where((l) => l != last).toList();
        if (others.isNotEmpty) letters = others;
      }
    }
    return letters[_random.nextInt(letters.length)];
  }

  /// Clears the target queue and refills it with [_upcomingTargetCount]
  /// random letters for the current level.
  void _resetTargetQueue() {
    _targetLetter = '';
    _upcomingTargets.clear();
    for (int i = 0; i < _upcomingTargetCount; i++) {
      _upcomingTargets.add(_randomNextTarget(_upcomingTargets));
    }
  }

  /// Advances to the next target letter: takes the first queued letter as
  /// the new target, shifts the queue up one and appends a new random
  /// letter to the end.
  ///
  /// Audio call-out is chosen by [_signSystem]: BSL levels use the English
  /// alphabet, IAC levels use the Welsh vowel set (consonants stay silent
  /// since there's no recording for them yet). Champion Mode has no
  /// call-out — the player reads the sign alone.
  void _selectNewTarget() {
    _targetLetter = _upcomingTargets.removeAt(0);
    _upcomingTargets
        .add(_randomNextTarget([_targetLetter, ..._upcomingTargets]));
    if (_isPlaying && !_championMode) {
      AudioService.playLetterMp3(_targetLetter, signSystem: _signSystem).ignore();
    }
  }

  /// Spawns initial bubbles at game start, spread across the full play area
  /// so they don't all enter together as a single visible wave.
  void _spawnInitialBubbles() {
    _lastSpawnedLetter = '';
    _sameLetterSpawnRun = 0;
    for (int i = 0; i < _targetBubbleCount; i++) {
      _spawnBubble(spreadAcrossScreen: true);
    }
    _spawnCooldownMs = 0;
  }

  /// Maximum number of on-screen (unpopped) bubbles allowed to share the
  /// same letter before that letter is excluded from spawning.
  static const int _maxDuplicateLetters = 3;

  /// Most consecutive spawns allowed to share the same letter.
  static const int _maxSameLetterSpawnRun = 2;

  /// Letter of the most recent spawn, and how many spawns in a row used it.
  String _lastSpawnedLetter = '';
  int _sameLetterSpawnRun = 0;

  /// Spawns a new bubble with random properties.
  ///
  /// The letter is chosen by [_pickWeightedLetter], which favours the
  /// current target and the queued [_upcomingTargets].
  ///
  /// Letters already at [_maxDuplicateLetters] copies on screen are excluded
  /// from selection so the same letter doesn't keep piling up, and a letter
  /// that was used for the last [_maxSameLetterSpawnRun] spawns is skipped
  /// so no letter appears three times in a row.
  ///
  /// [spreadAcrossScreen] distributes the bubble's starting height across the
  /// whole play area (used for initial fill); otherwise it enters from just
  /// below the bottom edge, as new bubbles do mid-game.
  void _spawnBubble({bool spreadAcrossScreen = false}) {
    final letters = _currentLevel.letters;
    final color = bubbleColors[_random.nextInt(bubbleColors.length)];

    // Count on-screen copies of each letter so we can avoid over-spawning
    // a letter that's already saturated the screen.
    final letterCounts = <String, int>{};
    for (final b in _bubbles) {
      if (!b.isPopped) {
        letterCounts[b.letter] = (letterCounts[b.letter] ?? 0) + 1;
      }
    }
    var eligibleLetters = letters
        .where((l) => (letterCounts[l] ?? 0) < _maxDuplicateLetters)
        .toList();
    if (eligibleLetters.isEmpty) {
      // Every letter is saturated (shouldn't normally happen) — fall back
      // to the full set rather than failing to spawn.
      eligibleLetters = letters;
    }

    // Never spawn the same letter three times in a row.
    if (_sameLetterSpawnRun >= _maxSameLetterSpawnRun) {
      final withoutRepeat =
          eligibleLetters.where((l) => l != _lastSpawnedLetter).toList();
      if (withoutRepeat.isNotEmpty) eligibleLetters = withoutRepeat;
    }

    final letter = _pickWeightedLetter(eligibleLetters);

    if (letter == _lastSpawnedLetter) {
      _sameLetterSpawnRun++;
    } else {
      _lastSpawnedLetter = letter;
      _sameLetterSpawnRun = 1;
    }

    final bubble = Bubble(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}',
      letter: letter,
      x: _random.nextDouble() * 0.8 + 0.1, // 10% to 90% of width
      y: spreadAcrossScreen
          ? _random.nextDouble() * 1.3 // spread across the full play area
          : 1.0 + _random.nextDouble() * 0.3, // Start below screen
      speedX: (_random.nextDouble() - 0.5) * 0.007, // Slight horizontal drift
      speedY: -0.003 - _random.nextDouble() * 0.004, // Float upward
      color: color,
    );

    _bubbles.add(bubble);
  }

  /// First level that uses the queue-based spawn chances below; earlier
  /// levels use [_levelTargetWeight] instead.
  static const int _queueWeightingFromLevel = 4;

  /// Whether the queue-based spawn chances below apply to the current level.
  bool get _usesQueueWeighting =>
      _currentLevel.number >= _queueWeightingFromLevel;

  /// On levels without queue weighting, how many times as likely the target
  /// letter is to spawn as each other letter.
  double get _levelTargetWeight {
    switch (_currentLevel.number) {
      case 3:
        return 2.625; // Base 1.5x + 75%
      default:
        return 1.5; // Base weight for levels 1-2
    }
  }

  /// Spawn chance (%) for the current target letter, then for each queued
  /// target in [_upcomingTargets] order. Applies only when
  /// [_usesQueueWeighting] is true.
  static const double _targetSpawnChance = 15;
  static const List<double> _upcomingSpawnChances = [10, 7, 5, 3];

  /// Picks a letter from [eligibleLetters] for a new bubble.
  ///
  /// Without queue weighting, every letter has weight 1 except the current
  /// target, which has [_levelTargetWeight].
  ///
  /// From level [_queueWeightingFromLevel] onward, the current target gets [_targetSpawnChance]% and each queued target
  /// gets its [_upcomingSpawnChances] slot (a letter in several slots gets
  /// the sum). The remaining chance is split evenly across the other
  /// letters. Ineligible letters are dropped and the remaining weights
  /// renormalised, so the chances are exact only when every letter is
  /// eligible and at least one non-queued letter exists.
  String _pickWeightedLetter(List<String> eligibleLetters) {
    final weights = <String, double>{};
    void addWeight(String letter, double chance) {
      if (letter.isEmpty) return;
      weights[letter] = (weights[letter] ?? 0) + chance;
    }

    if (!_usesQueueWeighting) {
      for (final l in _currentLevel.letters) {
        weights[l] = 1;
      }
      if (_targetLetter.isNotEmpty) {
        weights[_targetLetter] = _levelTargetWeight;
      }
    } else {
      addWeight(_targetLetter, _targetSpawnChance);
      for (int i = 0;
          i < _upcomingTargets.length && i < _upcomingSpawnChances.length;
          i++) {
        addWeight(_upcomingTargets[i], _upcomingSpawnChances[i]);
      }

      final reserved = weights.values.fold<double>(0, (sum, w) => sum + w);
      final otherLetters =
          _currentLevel.letters.where((l) => !weights.containsKey(l)).toList();
      if (otherLetters.isNotEmpty) {
        final share = (100 - reserved) / otherLetters.length;
        for (final l in otherLetters) {
          weights[l] = share;
        }
      }
    }

    final candidates =
        eligibleLetters.where((l) => (weights[l] ?? 0) > 0).toList();
    if (candidates.isEmpty) {
      return eligibleLetters[_random.nextInt(eligibleLetters.length)];
    }

    final total = candidates.fold<double>(0, (sum, l) => sum + weights[l]!);
    var roll = _random.nextDouble() * total;
    for (final l in candidates) {
      roll -= weights[l]!;
      if (roll < 0) return l;
    }
    return candidates.last;
  }

  /// Starts the countdown timer.
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;

      if (_timeRemaining <= 0) {
        stopGame(completed: true);
      } else {
        notifyListeners();
      }
    });
  }

  /// Starts the game loop for bubble movement.
  void _startGameLoop() {
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) return;

      _updateBubbles();
      notifyListeners();
    });
  }

  /// Updates bubble positions and removes off-screen bubbles.
  void _updateBubbles() {
    // Update positions
    for (final bubble in _bubbles) {
      if (!bubble.isPopped) {
        bubble.x += bubble.speedX * _speedScale;
        bubble.y += bubble.speedY * _speedScale;

        // Bounce off horizontal edges
        if (bubble.x < 0.05 || bubble.x > 0.95) {
          bubble.x = bubble.x.clamp(0.05, 0.95);
        }
      }
    }

    // Remove bubbles that floated off screen (top) or are popped
    _bubbles.removeWhere((b) => b.y < -0.2 || b.isPopped);

    for (final label in _multiplierLabels) {
      label.x = (label.x + label.speedX * _speedScale).clamp(0.05, 0.95);
      label.y += label.speedY * _speedScale;
      label.ageMs += 16;
    }
    _multiplierLabels.removeWhere((l) => l.isFinished || l.y < -0.2);

    // Spawn replacement bubbles one at a time on a randomized cooldown so
    // they trickle in steadily instead of arriving together in a batch
    // whenever several bubbles happen to leave the screen at once.
    _spawnCooldownMs -= 16;
    if (_bubbles.length < _targetBubbleCount && _spawnCooldownMs <= 0) {
      _spawnBubble();
      _spawnCooldownMs = _minSpawnIntervalMs +
          _random.nextDouble() * (_maxSpawnIntervalMs - _minSpawnIntervalMs);
    }
  }

  /// Called when a bubble is tapped.
  ///
  /// Returns true if the bubble matched the target letter.
  bool tapBubble(String bubbleId) {
    final bubbleIndex = _bubbles.indexWhere((b) => b.id == bubbleId);
    if (bubbleIndex == -1) return false;

    final bubble = _bubbles[bubbleIndex];
    if (bubble.isPopped) return false;

    // Mark as popped for animation
    bubble.isPopped = true;
    _lastPoppedBubbleId = bubbleId;

    // Immediately spawn a replacement so the screen doesn't feel emptied
    // out while this one fades away; the passive cooldown-based spawn in
    // _updateBubbles still handles bubbles that float off the top.
    _spawnBubble();

    // Track for easter egg
    _tappedSequence += bubble.letter;
    _checkEasterEgg();

    // Check if correct
    final isCorrect = bubble.letter == _targetLetter;
    if (_championMode) {
      _applyChampionScoring(isCorrect, bubble);
    } else if (isCorrect) {
      _score++;
    }
    if (isCorrect) _selectNewTarget();

    notifyListeners();
    return isCorrect;
  }

  /// Champion Mode scoring: a correct pop extends the streak and scores
  /// [championCorrectPoints] × [multiplier] (the multiplier includes this
  /// pop, so the 5th in a row already scores ×2); a wrong pop costs
  /// [championWrongPenalty] and resets the streak. The score never drops
  /// below zero.
  ///
  /// When a correct pop reaches a new multiplier tier, [bubble] is replaced
  /// by a [MultiplierLabel] that carries on along its path.
  void _applyChampionScoring(bool isCorrect, Bubble bubble) {
    final int delta;
    if (isCorrect) {
      final previousMultiplier = multiplier;
      _streak++;
      delta = championCorrectPoints * multiplier;
      if (multiplier > previousMultiplier) {
        _multiplierLabels.add(MultiplierLabel(
          id: 'multiplier_${bubble.id}',
          multiplier: multiplier,
          x: bubble.x,
          y: bubble.y,
          speedX: bubble.speedX,
          speedY: bubble.speedY,
        ));
      }
    } else {
      _streak = 0;
      delta = -min(championWrongPenalty, _score);
    }
    _score += delta;
    _lastPointsDelta = isCorrect ? delta : -championWrongPenalty;
    _pointsDeltaSerial++;
  }

  /// Checks if the tapped sequence contains easter egg words.
  ///
  /// BSL uses the English words "cat"/"dog"; IAC uses the Welsh words
  /// "cath"/"ci".
  void _checkEasterEgg() {
    // Keep only the characters needed for the longest easter egg word
    if (_tappedSequence.length > 5) {
      _tappedSequence = _tappedSequence.substring(_tappedSequence.length - 5);
    }

    if (_signSystem == SignSystem.iac) {
      if (_tappedSequence.endsWith('cath')) {
        _triggerEasterEgg('cat');
      } else if (_tappedSequence.endsWith('ci')) {
        _triggerEasterEgg('dog');
      }
    } else {
      if (_tappedSequence.endsWith('cat')) {
        _triggerEasterEgg('cat');
      } else if (_tappedSequence.endsWith('dog')) {
        _triggerEasterEgg('dog');
      }
    }
  }

  void _triggerEasterEgg(String animal) {
    _easterEggTriggered = animal;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), () {
      _easterEggTriggered = null;
      notifyListeners();
    });
  }

  /// Clears the last popped bubble ID after animation completes.
  void clearLastPoppedBubble() {
    _lastPoppedBubbleId = null;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameLoopTimer?.cancel();
    super.dispose();
  }
}
