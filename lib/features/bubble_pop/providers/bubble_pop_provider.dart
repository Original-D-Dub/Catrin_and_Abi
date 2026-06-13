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

  /// Level 3: Letters a to j
  static const GameLevel bslLevel3 = GameLevel(
    number: 3,
    name: 'bubble_pop.bsl.level3.name',
    letters: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'],
  );

  /// Level 4: Letters i to r
  static const GameLevel bslLevel4 = GameLevel(
    number: 4,
    name: 'bubble_pop.bsl.level4.name',
    letters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o'
    ],
  );

  /// Level 5: Letters q to z
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

  BubblePopProvider({SignSystem signSystem = SignSystem.bsl})
      : _signSystem = signSystem,
        _currentLevel = GameLevels.forSignSystem(signSystem).first;

  /// The sign system (BSL or IAC) this game instance uses.
  final SignSystem _signSystem;
  SignSystem get signSystem => _signSystem;

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

  /// Track tapped letters for easter egg detection
  String _tappedSequence = '';

  /// Easter egg triggered (cat or dog)
  String? _easterEggTriggered;
  String? get easterEggTriggered => _easterEggTriggered;

  /// Bubble that was just popped (for animation)
  String? _lastPoppedBubbleId;
  String? get lastPoppedBubbleId => _lastPoppedBubbleId;

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
    notifyListeners();
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

    _selectNewTarget();
    _spawnInitialBubbles();
    _startCountdown();
    _startGameLoop();

    notifyListeners();
  }

  /// Stops the game.
  void stopGame() {
    _isPlaying = false;
    _gameOver = true;
    _lastResult = null;
    _countdownTimer?.cancel();
    _gameLoopTimer?.cancel();
    notifyListeners();

    final gameId =
        _signSystem == SignSystem.iac ? GameIds.welshBubblePop : GameIds.bubblePop;
    _statsService.recordGameResult(gameId, _score, level: _currentLevel.number).then((result) {
      _lastResult = result;
      notifyListeners();
    }).catchError((e) {
      debugPrint('recordGameResult error ($gameId): $e');
    });
  }

  /// Selects a new random target letter from the current level's letters.
  ///
  /// Audio call-outs are only available for BSL (English alphabet) letters;
  /// IAC letter call-outs are not yet wired up.
  void _selectNewTarget() {
    final letters = _currentLevel.letters;
    _targetLetter = letters[_random.nextInt(letters.length)];
    if (_isPlaying && _signSystem == SignSystem.bsl) {
      AudioService.playLetterMp3(_targetLetter).ignore();
    }
  }

  /// Spawns initial bubbles at game start.
  void _spawnInitialBubbles() {
    for (int i = 0; i < 8; i++) {
      _spawnBubble();
    }
  }

  /// Spawns a new bubble with random properties.
  ///
  /// The target letter is weighted more likely to appear than other letters.
  /// Base weight is 1.5x, with higher levels getting additional boosts:
  /// - Levels 1-2: 1.5x (base)
  /// - Level 3: +75% (2.625x)
  /// - Level 4: +150% (3.75x)
  /// - Level 5: +225% (4.875x)
  /// - Level 6: +300% (6.0x)
  void _spawnBubble() {
    final letters = _currentLevel.letters;
    final color = bubbleColors[_random.nextInt(bubbleColors.length)];

    // Calculate level-specific target weight
    final double targetWeight;
    switch (_currentLevel.number) {
      case 3:
        targetWeight = 2.625; // Base 1.5x + 75%
      case 4:
        targetWeight = 3.75; // Base 1.5x + 150%
      case 5:
        targetWeight = 4.875; // Base 1.5x + 225%
      case 6:
        targetWeight = 6.0; // Base 1.5x + 300%
      default:
        targetWeight = 1.5; // Base weight for levels 1-2
    }

    // Total weight = (n-1)*1 + targetWeight = n - 1 + targetWeight
    final n = letters.length;
    final totalWeight = n - 1 + targetWeight;
    final randomValue = _random.nextDouble() * totalWeight;

    String letter;
    if (randomValue < targetWeight && _targetLetter.isNotEmpty) {
      // Select target letter with level-specific weight
      letter = _targetLetter;
    } else {
      // Select from non-target letters (or all letters if no target yet)
      final otherLetters =
          letters.where((l) => l != _targetLetter).toList();
      if (otherLetters.isEmpty) {
        letter = letters[_random.nextInt(letters.length)];
      } else {
        letter = otherLetters[_random.nextInt(otherLetters.length)];
      }
    }

    final bubble = Bubble(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}',
      letter: letter,
      x: _random.nextDouble() * 0.8 + 0.1, // 10% to 90% of width
      y: 1.0 + _random.nextDouble() * 0.3, // Start below screen
      speedX: (_random.nextDouble() - 0.5) * 0.007, // Slight horizontal drift
      speedY: -0.003 - _random.nextDouble() * 0.004, // Float upward
      color: color,
    );

    _bubbles.add(bubble);
  }

  /// Starts the countdown timer.
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;

      if (_timeRemaining <= 0) {
        stopGame();
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
        bubble.x += bubble.speedX;
        bubble.y += bubble.speedY;

        // Bounce off horizontal edges
        if (bubble.x < 0.05 || bubble.x > 0.95) {
          bubble.x = bubble.x.clamp(0.05, 0.95);
        }
      }
    }

    // Remove bubbles that floated off screen (top) or are popped
    _bubbles.removeWhere((b) => b.y < -0.2 || b.isPopped);

    // Spawn new bubbles to maintain count
    while (_bubbles.length < 8) {
      _spawnBubble();
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

    // Track for easter egg
    _tappedSequence += bubble.letter;
    _checkEasterEgg();

    // Check if correct
    final isCorrect = bubble.letter == _targetLetter;
    if (isCorrect) {
      _score++;
      _selectNewTarget();
    }

    notifyListeners();
    return isCorrect;
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
