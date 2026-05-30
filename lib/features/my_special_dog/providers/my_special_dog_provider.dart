import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_stats_service.dart';
import '../models/multi_vowel_puzzle.dart';
import '../models/vowel_target.dart';

enum MySpecialDogGameState { ready, playing, finished }

class MySpecialDogProvider extends ChangeNotifier {
  // ── Core ──────────────────────────────────────────────────────────────────

  final GameStatsService _statsService = GameStatsService();
  final Random _random = Random();

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  MySpecialDogGameState _gameState = MySpecialDogGameState.ready;
  MySpecialDogGameState get gameState => _gameState;

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  MySpecialDogLevel _selectedLevel = MySpecialDogLevel.vowelMatch;
  MySpecialDogLevel get selectedLevel => _selectedLevel;

  int _score = 0;
  int get score => _score;

  int _remainingSeconds = MySpecialDogConstants.gameDurationSeconds;
  int get remainingSeconds => _remainingSeconds;

  // ── Level 1: Vowel Match ───────────────────────────────────────────────────

  String _currentVowel = 'a';
  String get currentVowel => _currentVowel;

  bool _showScoreAnimation = false;
  bool get showScoreAnimation => _showScoreAnimation;

  // ── Level 2: Multi-vowel word game ─────────────────────────────────────────

  static const List<String> _multiVowelWords = [
    'Pero', 'Catrin', 'dog', 'Deaf', 'hearing', 'cochlear', 'implant',
    'Abi', 'sign', 'story', 'listen', 'understand', 'ear', 'ding dong', 'beep',
    'alarm', 'language', 'sister', 'sounds', 'special', 'amazing', 'doorbell', 
    'fire alarm', 'learn', 'communicate', 'play', 'fun', 'learnt', 'wake up',
    'family', 'help', 'phone', 'together', 'fire exit', 'safe', 'safety', 'hearing dog',
  ];

  static const int targetWords = 5;

  MultiVowelPuzzle? _currentMultiPuzzle;
  MultiVowelPuzzle? get currentMultiPuzzle => _currentMultiPuzzle;

  final List<String> _completedWords = [];
  List<String> get completedWords => List.unmodifiable(_completedWords);

  /// Set to true the first time the player makes a wrong guess on the current
  /// word. Used by Level 3 to withhold the point for that word.
  bool _hadMistakeOnCurrentWord = false;

  // ── Shared feedback state ──────────────────────────────────────────────────

  bool? _isGuessCorrect;
  bool? get isGuessCorrect => _isGuessCorrect;

  bool _isInputLocked = false;
  bool get isInputLocked => _isInputLocked;

  Function(bool isCorrect)? onAnswerResult;

  // ── Pointer/touch ──────────────────────────────────────────────────────────

  Offset? _pointerPosition;
  Offset? get pointerPosition => _pointerPosition;

  bool _isPointerVisible = false;
  bool get isPointerVisible => _isPointerVisible;

  bool _hasScored = false;

  // ── Timers ─────────────────────────────────────────────────────────────────

  Timer? _gameTimer;
  Timer? _pointerHideTimer;
  Timer? _scoreAnimationTimer;
  Timer? _wrongAnswerTimer;

  // ── Level selection ────────────────────────────────────────────────────────

  void showLevelSelection() {
    _cancelTimers();
    _showLevelSelect = true;
    _gameState = MySpecialDogGameState.ready;
    _isPointerVisible = false;
    _pointerPosition = null;
    _isInputLocked = false;
    _isGuessCorrect = null;
    notifyListeners();
  }

  // ── Game control ───────────────────────────────────────────────────────────

  void prepareForIntro({MySpecialDogLevel? level}) {
    _cancelTimers();
    if (level != null) _selectedLevel = level;

    _showLevelSelect = false;
    _gameState = MySpecialDogGameState.ready;
    _score = 0;
    _remainingSeconds = MySpecialDogConstants.gameDurationSeconds;
    _isPointerVisible = false;
    _pointerPosition = null;
    _hasScored = false;
    _showScoreAnimation = false;
    _isInputLocked = false;
    _isGuessCorrect = null;
    _lastResult = null;

    if (_selectedLevel == MySpecialDogLevel.vowelMatch) {
      _selectRandomVowel();
    } else {
      _completedWords.clear();
      _currentMultiPuzzle = null;
      _selectMultiVowelPuzzle();
    }

    notifyListeners();
  }

  void startGame({MySpecialDogLevel? level}) {
    if (_gameState == MySpecialDogGameState.playing) return;
    if (level != null) _selectedLevel = level;

    _showLevelSelect = false;
    _gameState = MySpecialDogGameState.playing;
    _score = 0;
    _remainingSeconds = MySpecialDogConstants.gameDurationSeconds;
    _hasScored = false;
    _lastResult = null;
    _isInputLocked = false;
    _isGuessCorrect = null;

    if (_selectedLevel == MySpecialDogLevel.vowelMatch) {
      _selectRandomVowel();
      _gameTimer?.cancel();
      _gameTimer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
    } else {
      _completedWords.clear();
      _currentMultiPuzzle = null;
      _selectMultiVowelPuzzle();
      // Level 2 is word-count-based — no countdown timer
    }

    notifyListeners();
  }

  void _onTimerTick(Timer _) {
    _remainingSeconds--;
    if (_remainingSeconds <= 0) {
      _endGame();
    } else {
      notifyListeners();
    }
  }

  void _endGame() {
    _cancelTimers();
    _gameState = MySpecialDogGameState.finished;
    _isPointerVisible = false;
    _pointerPosition = null;
    _isInputLocked = false;
    _lastResult = null;
    notifyListeners();
    _statsService
        .recordGameResult(GameIds.mySpecialDog, _score,
            level: _selectedLevel.number)
        .then((result) {
      _lastResult = result;
      notifyListeners();
    }).catchError((e) {
      debugPrint('recordGameResult error (mySpecialDog): $e');
    });
  }

  // ── Touch handling ─────────────────────────────────────────────────────────

  void onTouchUpdate(Offset position) {
    if (_gameState != MySpecialDogGameState.playing) return;
    _pointerHideTimer?.cancel();
    _pointerPosition = position;
    _isPointerVisible = true;
    notifyListeners();
  }

  void onTouchEnd({required Offset position, required Size handSize}) {
    if (_gameState != MySpecialDogGameState.playing) return;

    // Tapping while wrong-answer lock is active dismisses it early
    if (_isInputLocked && _isGuessCorrect == false) {
      _revertFeedback();
    }

    if (_selectedLevel == MySpecialDogLevel.vowelMatch) {
      _checkHitVowelMode(position: position, handSize: handSize);
    } else {
      _checkHitMultiVowelMode(position: position, handSize: handSize);
    }

    _pointerHideTimer?.cancel();
    _pointerHideTimer = Timer(
      const Duration(milliseconds: MySpecialDogConstants.pointerLingerDuration),
      () {
        _isPointerVisible = false;
        _pointerPosition = null;
        notifyListeners();
      },
    );

    _hasScored = false;
  }

  // ── Level 1: Vowel Match hit detection ────────────────────────────────────

  void _checkHitVowelMode({required Offset position, required Size handSize}) {
    if (_hasScored) return;

    final target =
        MySpecialDogConstants.targets.firstWhere((t) => t.vowel == _currentVowel);
    final targetPosition = Offset(
      target.normalizedPosition.dx * handSize.width,
      target.normalizedPosition.dy * handSize.height,
    );

    if ((position - targetPosition).distance <= target.hitRadius) {
      AudioService.playCorrect('my_special_dog');
      _score++;
      _hasScored = true;
      _showScoreAnimation = true;
      _selectRandomVowel();
      notifyListeners();

      _scoreAnimationTimer?.cancel();
      _scoreAnimationTimer = Timer(const Duration(milliseconds: 300), () {
        _showScoreAnimation = false;
        notifyListeners();
      });
    }
  }

  // ── Level 2: Multi-vowel hit detection ────────────────────────────────────

  void _checkHitMultiVowelMode(
      {required Offset position, required Size handSize}) {
    if (_hasScored || _currentMultiPuzzle == null || _isInputLocked) return;

    String? tappedVowel;
    double closestDistance = double.infinity;

    for (final target in MySpecialDogConstants.targets) {
      final tp = Offset(
        target.normalizedPosition.dx * handSize.width,
        target.normalizedPosition.dy * handSize.height,
      );
      final d = (position - tp).distance;
      if (d <= target.hitRadius && d < closestDistance) {
        tappedVowel = target.vowel;
        closestDistance = d;
      }
    }

    if (tappedVowel == null) return;
    _hasScored = true;

    AudioService.playLetterMp3(tappedVowel);

    if (_currentMultiPuzzle!.hasUnguessedVowel(tappedVowel)) {
      _handleCorrectMultiVowelGuess(tappedVowel);
    } else {
      _handleWrongMultiVowelGuess();
    }
  }

  void _handleCorrectMultiVowelGuess(String vowel) {
    _currentMultiPuzzle = _currentMultiPuzzle!.withVowelGuessed(vowel);
    _isGuessCorrect = true;

    if (_currentMultiPuzzle!.isComplete) {
      final word = _currentMultiPuzzle!.word;
      // Level 3: only count if the player made no mistakes on this word
      final counts = _selectedLevel != MySpecialDogLevel.noMistakes ||
          !_hadMistakeOnCurrentWord;
      if (counts) {
        _completedWords.add(word);
        if (_selectedLevel == MySpecialDogLevel.noMistakes) {
          // Points = number of letters in the word (spaces don't count)
          _score += word.replaceAll(' ', '').length;
        } else {
          _score = _completedWords.length;
        }
      }
      _isInputLocked = true;
      notifyListeners();

      AudioService.playCorrect('my_special_dog');

      _scoreAnimationTimer?.cancel();
      _scoreAnimationTimer = Timer(const Duration(milliseconds: 900), () {
        _isGuessCorrect = null;
        _isInputLocked = false;
        if (_completedWords.length >= targetWords) {
          _endGame();
        } else {
          if (_selectedLevel == MySpecialDogLevel.vowelWords) {
            AudioService.playMp3(
                'my_special_dog/${word.replaceAll(' ', '_')}.mp3');
          } else {
            AudioService.speak(word);
          }
          _selectMultiVowelPuzzle();
          notifyListeners();
        }
      });
    } else {
      // More vowels still to find — brief green flash then continue
      notifyListeners();
      _scoreAnimationTimer?.cancel();
      _scoreAnimationTimer = Timer(const Duration(milliseconds: 500), () {
        _isGuessCorrect = null;
        notifyListeners();
      });
    }
  }

  void _handleWrongMultiVowelGuess() {
    _hadMistakeOnCurrentWord = true;
    _isGuessCorrect = false;
    _isInputLocked = true;
    notifyListeners();

    AudioService.playTryAgain();

    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = Timer(const Duration(milliseconds: 2500), () {
      _revertFeedback();
      notifyListeners();
    });
  }

  void _revertFeedback() {
    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = null;
    _isGuessCorrect = null;
    _isInputLocked = false;
    _hasScored = false;
  }

  // ── Selection helpers ──────────────────────────────────────────────────────

  void _selectRandomVowel() {
    final vowels = MySpecialDogConstants.vowels;
    String v;
    do {
      v = vowels[_random.nextInt(vowels.length)];
    } while (v == _currentVowel && vowels.length > 1);
    _currentVowel = v;

    if (_gameState == MySpecialDogGameState.playing) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_gameState == MySpecialDogGameState.playing && _currentVowel == v) {
          AudioService.playLetterMp3(v);
        }
      });
    }
  }

  void _selectMultiVowelPuzzle() {
    _hadMistakeOnCurrentWord = false;
    final available = _multiVowelWords
        .where((w) => !_completedWords.contains(w) &&
            w != _currentMultiPuzzle?.word)
        .toList();
    final candidates = available.isNotEmpty ? available : _multiVowelWords;
    _currentMultiPuzzle =
        MultiVowelPuzzle.fromWord(candidates[_random.nextInt(candidates.length)]);
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  String get displayLetter => _currentVowel;

  String get formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _cancelTimers() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _pointerHideTimer?.cancel();
    _pointerHideTimer = null;
    _scoreAnimationTimer?.cancel();
    _scoreAnimationTimer = null;
    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
