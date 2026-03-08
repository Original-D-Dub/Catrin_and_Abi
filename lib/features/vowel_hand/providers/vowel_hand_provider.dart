import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vowel_target.dart';
import '../models/word_puzzle.dart';

/// Game state enumeration for the vowel hand game.
enum VowelHandGameState {
  /// Initial state before game starts
  ready,

  /// Game is actively running
  playing,

  /// Game has ended (time up)
  finished,
}

/// Provider for managing the BSL vowel hand game state.
///
/// Handles:
/// - Level selection (Vowel Match or Vowel Words)
/// - Game timer (60 second countdown)
/// - Score tracking
/// - Current vowel selection (Level 1) or word puzzle (Level 2)
/// - Touch position and pointer visibility
/// - Hit detection for correct vowel taps
class VowelHandProvider extends ChangeNotifier {
  // -------------------------
  // Core Game State
  // -------------------------

  /// Current game state
  VowelHandGameState _gameState = VowelHandGameState.ready;
  VowelHandGameState get gameState => _gameState;

  /// Whether to show level selection screen
  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  /// Currently selected game level
  VowelHandLevel _selectedLevel = VowelHandLevel.vowelMatch;
  VowelHandLevel get selectedLevel => _selectedLevel;

  /// Current score (number of correct taps)
  int _score = 0;
  int get score => _score;

  /// Remaining time in seconds
  int _remainingSeconds = VowelHandConstants.gameDurationSeconds;
  int get remainingSeconds => _remainingSeconds;

  // -------------------------
  // Level 1: Vowel Match State
  // -------------------------

  /// The current vowel the player needs to tap (Level 1)
  String _currentVowel = 'a';
  String get currentVowel => _currentVowel;

  // -------------------------
  // Level 2: Vowel Words State
  // -------------------------

  /// Current word puzzle (Level 2)
  WordPuzzle? _currentPuzzle;
  WordPuzzle? get currentPuzzle => _currentPuzzle;

  /// The vowel the player guessed (null = show underscore)
  String? _guessedVowel;
  String? get guessedVowel => _guessedVowel;

  /// Whether the current guess is correct (null = no guess, true = correct, false = wrong)
  bool? _isGuessCorrect;
  bool? get isGuessCorrect => _isGuessCorrect;

  /// Whether input is locked during wrong answer display
  bool _isInputLocked = false;
  bool get isInputLocked => _isInputLocked;

  /// Recently used words to avoid repeats
  final List<String> _recentWords = [];

  /// Timer for reverting wrong answer display
  Timer? _wrongAnswerTimer;

  // -------------------------
  // Pointer/Touch State
  // -------------------------

  /// Current touch/pointer position (null when not touching)
  Offset? _pointerPosition;
  Offset? get pointerPosition => _pointerPosition;

  /// Whether the pointer should be visible (stays visible 400ms after release)
  bool _isPointerVisible = false;
  bool get isPointerVisible => _isPointerVisible;

  // -------------------------
  // Timers
  // -------------------------

  /// Timer for the game countdown
  Timer? _gameTimer;

  /// Timer for hiding the pointer after touch release
  Timer? _pointerHideTimer;

  /// Timer for score animation
  Timer? _scoreAnimationTimer;

  // -------------------------
  // Internal State
  // -------------------------

  /// Random number generator for selecting vowels/words
  final Random _random = Random();

  /// Tracks if we've already scored for the current touch
  /// Prevents multiple scores for dragging across the target
  bool _hasScored = false;

  /// Whether to show the score animation (brief flash on correct tap)
  bool _showScoreAnimation = false;
  bool get showScoreAnimation => _showScoreAnimation;

  /// Initializes the provider.
  ///
  /// The game starts on the level selection screen.
  VowelHandProvider() {
    // Level select shown first, no need to initialize vowel/puzzle yet
  }

  // -------------------------
  // Level Selection Methods
  // -------------------------

  /// Shows the level selection screen.
  ///
  /// Stops any running timers and resets game state.
  void showLevelSelection() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _pointerHideTimer?.cancel();
    _pointerHideTimer = null;
    _scoreAnimationTimer?.cancel();
    _scoreAnimationTimer = null;
    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = null;

    _showLevelSelect = true;
    _gameState = VowelHandGameState.ready;
    _isPointerVisible = false;
    _pointerPosition = null;
    _isInputLocked = false;
    _guessedVowel = null;
    _isGuessCorrect = null;

    notifyListeners();
  }

  // -------------------------
  // Game Control Methods
  // -------------------------

  /// Starts the game with the specified level.
  ///
  /// [level] is the game level to play. If null, uses the currently selected level.
  void startGame({VowelHandLevel? level}) {
    if (_gameState == VowelHandGameState.playing) return;

    // Update level if provided
    if (level != null) {
      _selectedLevel = level;
    }

    _showLevelSelect = false;
    _gameState = VowelHandGameState.playing;
    _score = 0;
    _remainingSeconds = VowelHandConstants.gameDurationSeconds;
    _hasScored = false;
    _isInputLocked = false;
    _guessedVowel = null;
    _isGuessCorrect = null;

    // Initialize based on level
    if (_selectedLevel == VowelHandLevel.vowelMatch) {
      _selectRandomVowel();
    } else {
      _selectRandomPuzzle();
    }

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);

    notifyListeners();
  }

  /// Handles the countdown timer tick.
  void _onTimerTick(Timer timer) {
    _remainingSeconds--;

    if (_remainingSeconds <= 0) {
      _endGame();
    } else {
      notifyListeners();
    }
  }

  /// Ends the game and stops the timer.
  void _endGame() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = null;
    _gameState = VowelHandGameState.finished;
    _isPointerVisible = false;
    _pointerPosition = null;
    _isInputLocked = false;
    notifyListeners();
  }

  /// Resets the game to the ready state (within current level).
  void resetGame() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _pointerHideTimer?.cancel();
    _pointerHideTimer = null;
    _scoreAnimationTimer?.cancel();
    _scoreAnimationTimer = null;
    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = null;

    _gameState = VowelHandGameState.ready;
    _score = 0;
    _remainingSeconds = VowelHandConstants.gameDurationSeconds;
    _isPointerVisible = false;
    _pointerPosition = null;
    _hasScored = false;
    _showScoreAnimation = false;
    _isInputLocked = false;
    _guessedVowel = null;
    _isGuessCorrect = null;

    if (_selectedLevel == VowelHandLevel.vowelMatch) {
      _selectRandomVowel();
    } else {
      _selectRandomPuzzle();
    }

    notifyListeners();
  }

  // -------------------------
  // Touch Handling Methods
  // -------------------------

  /// Called when the user touches/drags on the hand area.
  ///
  /// Updates the pointer position for visual feedback.
  /// [position] is the touch position in local coordinates.
  void onTouchUpdate(Offset position) {
    if (_gameState != VowelHandGameState.playing) return;

    _pointerHideTimer?.cancel();
    _pointerPosition = position;
    _isPointerVisible = true;

    notifyListeners();
  }

  /// Called when the user releases their touch.
  ///
  /// Checks if the release position is within a vowel target.
  /// [position] is the final touch position.
  /// [handSize] is the current rendered size of the hand widget.
  void onTouchEnd({
    required Offset position,
    required Size handSize,
  }) {
    debugPrint('onTouchEnd called - position: $position, handSize: $handSize');
    if (_gameState != VowelHandGameState.playing) {
      debugPrint('Game not playing, ignoring touch end');
      return;
    }

    // Handle input lock for word mode
    if (_selectedLevel == VowelHandLevel.vowelWords && _isInputLocked) {
      // Clear wrong answer immediately and process new tap
      _revertWrongAnswer();
    }

    // Check for hit based on current level
    if (_selectedLevel == VowelHandLevel.vowelMatch) {
      _checkHitVowelMode(position: position, handSize: handSize);
    } else {
      _checkHitWordMode(position: position, handSize: handSize);
    }

    // Start timer to hide pointer after 400ms
    _pointerHideTimer?.cancel();
    _pointerHideTimer = Timer(
      const Duration(milliseconds: VowelHandConstants.pointerLingerDuration),
      () {
        _isPointerVisible = false;
        _pointerPosition = null;
        notifyListeners();
      },
    );

    // Reset scoring flag for next touch
    _hasScored = false;
  }

  // -------------------------
  // Level 1: Vowel Match Hit Detection
  // -------------------------

  /// Checks if the touch position hits the correct vowel target (Level 1).
  void _checkHitVowelMode({
    required Offset position,
    required Size handSize,
  }) {
    if (_hasScored) return;

    // Find the target for the current vowel
    final target = VowelHandConstants.targets.firstWhere(
      (t) => t.vowel == _currentVowel,
    );

    // Calculate the target position in hand coordinates
    final targetPosition = Offset(
      target.normalizedPosition.dx * handSize.width,
      target.normalizedPosition.dy * handSize.height,
    );

    // Use fixed hit radius (no scaling)
    final hitRadius = target.hitRadius;

    // Check if touch is within the target
    final distance = (position - targetPosition).distance;

    // Debug logging
    debugPrint('=== HIT CHECK (VOWEL MODE) ===');
    debugPrint('Current vowel: $_currentVowel');
    debugPrint('Touch position: $position');
    debugPrint('Hand size: $handSize');
    debugPrint('Target position (normalized): ${target.normalizedPosition}');
    debugPrint('Target position: $targetPosition');
    debugPrint('Hit radius: $hitRadius');
    debugPrint('Distance: $distance');
    debugPrint('Hit: ${distance <= hitRadius}');

    if (distance <= hitRadius) {
      _score++;
      _hasScored = true;
      _showScoreAnimation = true;
      _selectRandomVowel();
      notifyListeners();

      // Hide score animation after 300ms
      _scoreAnimationTimer?.cancel();
      _scoreAnimationTimer = Timer(const Duration(milliseconds: 300), () {
        _showScoreAnimation = false;
        notifyListeners();
      });
    }
  }

  // -------------------------
  // Level 2: Word Mode Hit Detection
  // -------------------------

  /// Checks which vowel fingertip was tapped and evaluates correctness (Level 2).
  ///
  /// Unlike Level 1, this checks ALL 5 fingertips to determine which vowel
  /// was selected, then evaluates if it matches the word's missing vowel.
  void _checkHitWordMode({
    required Offset position,
    required Size handSize,
  }) {
    if (_hasScored || _currentPuzzle == null) return;

    // Check all fingertips to find which one was tapped
    String? tappedVowel;
    double closestDistance = double.infinity;

    for (final target in VowelHandConstants.targets) {
      final targetPosition = Offset(
        target.normalizedPosition.dx * handSize.width,
        target.normalizedPosition.dy * handSize.height,
      );

      final distance = (position - targetPosition).distance;

      // Check if within hit radius and closer than previous matches
      if (distance <= target.hitRadius && distance < closestDistance) {
        tappedVowel = target.vowel;
        closestDistance = distance;
      }
    }

    // Debug logging
    debugPrint('=== HIT CHECK (WORD MODE) ===');
    debugPrint('Current puzzle: ${_currentPuzzle!.word}');
    debugPrint('Correct vowel: ${_currentPuzzle!.vowel}');
    debugPrint('Touch position: $position');
    debugPrint('Tapped vowel: $tappedVowel');

    // If no fingertip was tapped, do nothing
    if (tappedVowel == null) {
      debugPrint('No fingertip tapped');
      return;
    }

    // Set the guessed vowel for display
    _guessedVowel = tappedVowel;
    _hasScored = true;

    // Check if correct
    if (tappedVowel == _currentPuzzle!.vowel) {
      _handleCorrectWordGuess();
    } else {
      _handleWrongWordGuess();
    }
  }

  /// Handles a correct word guess.
  ///
  /// Shows green feedback, increments score, and moves to next word.
  void _handleCorrectWordGuess() {
    _isGuessCorrect = true;
    _score++;
    _showScoreAnimation = true;
    notifyListeners();

    // After 300ms, clear feedback and show next word
    _scoreAnimationTimer?.cancel();
    _scoreAnimationTimer = Timer(const Duration(milliseconds: 300), () {
      _showScoreAnimation = false;
      _guessedVowel = null;
      _isGuessCorrect = null;
      _selectRandomPuzzle();
      notifyListeners();
    });
  }

  /// Handles a wrong word guess.
  ///
  /// Shows red feedback and locks input. Reverts after 3 seconds
  /// or when the player taps again.
  void _handleWrongWordGuess() {
    _isGuessCorrect = false;
    _isInputLocked = true;
    notifyListeners();

    // Start 3-second timer to revert
    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = Timer(
      const Duration(milliseconds: WordPuzzleConstants.wrongAnswerDisplayDurationMs),
      () {
        _revertWrongAnswer();
        notifyListeners();
      },
    );
  }

  /// Reverts the wrong answer display back to underscore.
  void _revertWrongAnswer() {
    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = null;
    _guessedVowel = null;
    _isGuessCorrect = null;
    _isInputLocked = false;
    _hasScored = false;
  }

  // -------------------------
  // Selection Methods
  // -------------------------

  /// Selects a new random vowel, ensuring it's different from the current one (Level 1).
  void _selectRandomVowel() {
    final vowels = VowelHandConstants.vowels;
    String newVowel;

    do {
      newVowel = vowels[_random.nextInt(vowels.length)];
    } while (newVowel == _currentVowel && vowels.length > 1);

    _currentVowel = newVowel;
  }

  /// Selects a new random word puzzle, avoiding recently used words (Level 2).
  void _selectRandomPuzzle() {
    _currentPuzzle = WordPuzzleConstants.getRandomPuzzle(
      random: _random,
      recentWords: _recentWords,
      vowels: VowelHandConstants.vowels,
    );

    // Track this word to avoid repeats
    _recentWords.add(_currentPuzzle!.word);
    if (_recentWords.length > WordPuzzleConstants.maxRecentWords) {
      _recentWords.removeAt(0);
    }
  }

  // -------------------------
  // Utility Methods
  // -------------------------

  /// Formats the remaining time as MM:SS string.
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _pointerHideTimer?.cancel();
    _scoreAnimationTimer?.cancel();
    _wrongAnswerTimer?.cancel();
    super.dispose();
  }
}
