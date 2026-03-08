import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Represents a bubble floating on screen.
class Bubble {
  /// Unique identifier for this bubble
  final String id;

  /// The letter displayed inside this bubble
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
///
/// Each level introduces more letters:
/// - Level 1: Vowels only (a, e, i, o, u)
/// - Level 2: Letters a-e
/// - Level 3: Letters a-i
/// - Level 4: Letters a-o
/// - Level 5: Letters a-u
/// - Level 6: Full alphabet (a-z)
class GameLevel {
  /// Level number (1-6)
  final int number;

  /// Display name for the level
  final String name;

  /// Letters available in this level
  final List<String> letters;

  const GameLevel({
    required this.number,
    required this.name,
    required this.letters,
  });
}

/// All available game levels with their letter configurations.
class GameLevels {
  GameLevels._();

  /// Level 1: Vowels only
  static const GameLevel level1 = GameLevel(
    number: 1,
    name: 'Vowels',
    letters: ['a', 'e', 'i', 'o', 'u'],
  );

  /// Level 2: Letters a to e
  static const GameLevel level2 = GameLevel(
    number: 2,
    name: 'Letters a-e',
    letters: ['a', 'b', 'c', 'd', 'e'],
  );

  /// Level 3: Letters a to i
  static const GameLevel level3 = GameLevel(
    number: 3,
    name: 'Letters a-i',
    letters: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'],
  );

  /// Level 4: Letters a to o
  static const GameLevel level4 = GameLevel(
    number: 4,
    name: 'Letters a-o',
    letters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o'
    ],
  );

  /// Level 5: Letters a to u
  static const GameLevel level5 = GameLevel(
    number: 5,
    name: 'Letters a-u',
    letters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
      'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u'
    ],
  );

  /// Level 6: Full alphabet a to z
  static const GameLevel level6 = GameLevel(
    number: 6,
    name: 'Full Alphabet',
    letters: [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
      'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    ],
  );

  /// List of all available levels
  static const List<GameLevel> all = [
    level1,
    level2,
    level3,
    level4,
    level5,
    level6,
  ];

  /// Gets a level by number (1-6). Returns level 1 if invalid.
  static GameLevel getLevel(int number) {
    if (number < 1 || number > all.length) return level1;
    return all[number - 1];
  }
}

/// Game state for the Bubble Pop game.
///
/// Manages:
/// - Timer countdown (60 seconds)
/// - Current BSL sign to match
/// - Floating bubbles with letters
/// - Score tracking
/// - Level progression
/// - Easter egg detection (cat/dog)
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

  /// Current game level
  GameLevel _currentLevel = GameLevels.level1;
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

  /// Current letter the player needs to find
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
    _currentLevel = GameLevels.getLevel(levelNumber);
    notifyListeners();
  }

  /// Shows the level selection screen.
  void showLevelSelection() {
    _showLevelSelect = true;
    _isPlaying = false;
    _gameOver = false;
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
    _countdownTimer?.cancel();
    _gameLoopTimer?.cancel();
    notifyListeners();
  }

  /// Selects a new random target letter from the current level's letters.
  void _selectNewTarget() {
    final letters = _currentLevel.letters;
    _targetLetter = letters[_random.nextInt(letters.length)];
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
  void _checkEasterEgg() {
    // Keep only last 5 characters
    if (_tappedSequence.length > 5) {
      _tappedSequence = _tappedSequence.substring(_tappedSequence.length - 5);
    }

    // Check for cat or dog
    if (_tappedSequence.endsWith('cat')) {
      _easterEggTriggered = 'cat';
      notifyListeners();
      // Reset after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _easterEggTriggered = null;
        notifyListeners();
      });
    } else if (_tappedSequence.endsWith('dog')) {
      _easterEggTriggered = 'dog';
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 500), () {
        _easterEggTriggered = null;
        notifyListeners();
      });
    }
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
