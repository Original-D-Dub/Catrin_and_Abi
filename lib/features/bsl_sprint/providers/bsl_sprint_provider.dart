import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_stats_service.dart';
import '../models/sprint_models.dart';

// ── Word pool ─────────────────────────────────────────────────────────────────

/// Simple 3-letter CVC words used across all difficulty levels.
/// Each is fully representable by the 26-letter BSL alphabet PNGs.
const List<String> _wordPool = [
  'cat', 'dog', 'hat', 'sun', 'bus', 'pen', 'cup', 'run', 'hop',
  'map', 'fan', 'net', 'leg', 'arm', 'jam', 'zip', 'box', 'fox',
  'mop', 'jet', 'big', 'hit', 'log', 'nod', 'pot', 'tub', 'yak',
];

const List<String> _wordPool2 = [
  'race', 'ready', 'Deaf', 'sign', 'language', 'sports', 'win', 'football', 'goals', 'win', 'play', 'fun', 'team', 'score', 'kick', 'throw', 'catch', 'jump', 'run',
  'hear', 'whistle', 'referee', 'playing', 'swim', 'buzzer', 'netball', 'shoot', 'coach', 'running', 'athletics', 'ball',
  'lose', 'try', 'rugby', 'hockey', 'tennis'
];

// Welsh word banks — placeholders mirroring the English pools above until
// real Welsh CVC/topic words are provided.
const List<String> _wordPoolCy = _wordPool;
const List<String> _wordPool2Cy = _wordPool2;

// ── Provider ──────────────────────────────────────────────────────────────────

class BslSprintProvider extends ChangeNotifier {
  /// UI locale ('en' or 'cy') — selects which word bank is used.
  final String locale;

  BslSprintProvider({this.locale = 'en'});

  // ── Tuning constants ──────────────────────────────────────────────────────

  /// Starting number of lives (Training level only).
  static const int maxLives = 3;

  /// Starting number of lives for the current level. Training gets the full
  /// [maxLives]; every other level is single-life.
  int get currentMaxLives => _currentLevel.number == 0 ? maxLives : 1;

  /// The character sits at this normalised Y position in the game area.
  /// 0.0 = top, 1.0 = bottom.
  static const double characterBaseY = 0.80;

  /// Half-height of the collision detection window (normalised).
  static const double _collisionRadius = 0.05;

  /// Minimum normalised Y an item must reach before it can trigger a letter
  /// collision. Prevents collecting letters that are still far in the z-plane.
  static const double _minCollectY = 0.60;

  /// Initial upward velocity for a jump (normalised units / second).
  static const double _jumpInitialVelocity = 2.2;

  /// Downward acceleration applied while airborne (normalised units / second²).
  static const double _gravity = 5.0;

  // ── Services & RNG ────────────────────────────────────────────────────────

  final Random _rng = Random();
  final GameStatsService _statsService = GameStatsService();

  // ── Game state ────────────────────────────────────────────────────────────

  SprintState state = SprintState.idle;
  int score = 0;
  int lives = maxLives;
  int wordsCompleted = 0;

  // ── Word tracking ─────────────────────────────────────────────────────────

  String currentWord = '';
  int _letterIndex = 0;
  int get letterIndex => _letterIndex;

  /// The next letter the player must collect, or empty when idle/word complete.
  String get nextLetter =>
      currentWord.isNotEmpty && _letterIndex < currentWord.length
          ? currentWord[_letterIndex]
          : '';

  // ── Character position & jump physics ────────────────────────────────────

  int characterLane = 1; // 0 = left, 1 = middle, 2 = right

  double _jumpVelocity = 0.0;

  /// How far above [characterBaseY] the character currently is (normalised).
  /// 0.0 means the character is grounded.
  double jumpOffset = 0.0;

  bool isJumping = false;

  /// Effective normalised Y position of the character including jump arc.
  double get characterY => characterBaseY - jumpOffset;

  // ── Scrolling items ───────────────────────────────────────────────────────

  final List<SprintItem> items = [];

  // ── Level ─────────────────────────────────────────────────────────────────

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  SprintLevel _currentLevel = SprintLevel.all[0];
  SprintLevel get currentLevel => _currentLevel;

  // ── Speed & spawn timing ──────────────────────────────────────────────────

  double _scrollSpeed = SprintLevel.all[0].initialScrollSpeed;
  double get scrollSpeed => _scrollSpeed;

  double _spawnTimer = 0.0;
  double _spawnInterval = 2.0; // seconds between spawn waves
  double _speedUpTimer = 0.0;  // counts up to 10 s then applies 1% speed boost

  // ── End-of-game result ────────────────────────────────────────────────────

  GameResult? lastResult;
  bool get isWon => state == SprintState.won;

  // ── Word pool rotation ────────────────────────────────────────────────────

  late List<String> _remainingWords;

  /// The word pool for the current level and [locale].
  List<String> get _activeWordPool {
    final useSecondary = _currentLevel.number >= 2;
    if (locale == 'cy') {
      return useSecondary ? _wordPool2Cy : _wordPoolCy;
    }
    return useSecondary ? _wordPool2 : _wordPool;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Shows the level-selection screen.
  void showLevelSelection() {
    _showLevelSelect = true;
    notifyListeners();
  }

  /// Selects a level and hides the level-select screen.
  void setLevel(int levelNumber) {
    _currentLevel =
        SprintLevel.all.firstWhere((l) => l.number == levelNumber);
    items.clear();
    state = SprintState.idle;
    _showLevelSelect = false;
    notifyListeners();
  }

  /// Clears items and returns to idle so the screen can show a countdown
  /// before calling [startGame]. Does not reset score or lives.
  void resetForCountdown() {
    items.clear();
    state = SprintState.idle;
    notifyListeners();
  }

  /// Resets everything and starts a new game from the beginning.
  void startGame() {
    state = SprintState.playing;
    score = 0;
    lives = currentMaxLives;
    wordsCompleted = 0;
    items.clear();
    characterLane = 1;
    jumpOffset = 0.0;
    _jumpVelocity = 0.0;
    isJumping = false;
    _scrollSpeed = _currentLevel.initialScrollSpeed;
    _spawnTimer = 0.0;
    _spawnInterval = _currentLevel.initialSpawnInterval;
    _speedUpTimer = 0.0;
    lastResult = null;
    _remainingWords = List.from(_activeWordPool)..shuffle(_rng);
    _nextWord();
    if (_currentLevel.number == 0) {
      final word = currentWord;
      Future(() => AudioService.speak(word));
    }
    notifyListeners();
  }

  /// Called every frame from the screen's ticker.  Does NOT call
  /// [notifyListeners] — the screen drives repaints via setState().
  /// [notifyListeners] is called only for discrete state changes so that
  /// the success overlay and HUD update immediately.
  void tick(double dt) {
    if (state != SprintState.playing) return;
    _updateJump(dt);
    _updateItems(dt);
    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0.0;
      _spawnWave();
    }
    _speedUpTimer += dt;
    if (_speedUpTimer >= 10.0) {
      _speedUpTimer -= 10.0;
      _scrollSpeed = (_scrollSpeed * 1.01).clamp(_currentLevel.initialScrollSpeed, 0.85);
    }
    _checkCollisions();
    items.removeWhere((item) => !item.isActive);
  }

  /// Move the character one lane to the left (if not already in lane 0).
  void swipeLeft() {
    if (state != SprintState.playing) return;
    if (characterLane > 0) characterLane--;
  }

  /// Move the character one lane to the right (if not already in lane 2).
  void swipeRight() {
    if (state != SprintState.playing) return;
    if (characterLane < 2) characterLane++;
  }

  /// Trigger a jump if the character is currently grounded.
  void jump() {
    if (state != SprintState.playing) return;
    if (!isJumping) {
      isJumping = true;
      _jumpVelocity = _jumpInitialVelocity;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internals
  // ─────────────────────────────────────────────────────────────────────────

  void _nextWord() {
    if (_remainingWords.isEmpty) {
      _remainingWords = List.from(
        _currentLevel.number >= 2 ? _wordPool2 : _wordPool,
      )..shuffle(_rng);
    }
    currentWord = _remainingWords.removeLast();
    _letterIndex = 0;
    // Do not clear items — game is continuous, existing tiles keep scrolling.
    _spawnTimer = _spawnInterval;
  }

  void _updateJump(double dt) {
    if (!isJumping) return;
    jumpOffset += _jumpVelocity * dt;
    _jumpVelocity -= _gravity * dt;
    if (jumpOffset <= 0.0) {
      jumpOffset = 0.0;
      _jumpVelocity = 0.0;
      isJumping = false;
    }
  }

  // Perspective world-Z factor: derived so an item spawned at t=0.12 reaches
  // the player at t=characterBaseY in the same time as the old linear model.
  // = (1/spawnT − 1/playerT) / (playerT − spawnT) = 7.08 / 0.68
  static const double _perspWorldFactor = 10.41;

  void _updateItems(double dt) {
    final worldSpeed = _scrollSpeed * _perspWorldFactor;
    for (final item in items) {
      // Constant world-Z speed: z_new = z − worldSpeed·dt, t = 1/z
      // → t_new = t / (1 − t·worldSpeed·dt)
      final denom = 1.0 - item.y * worldSpeed * dt;
      item.y = denom > 0.01 ? item.y / denom : 1.5;
    }
  }

  void _spawnWave() {
    if (nextLetter.isEmpty) return;
    // Level 2: 20 % chance of an unjumpable barrier wave first.
    if (_currentLevel.number == 2 && _rng.nextDouble() < 0.20) {
      _spawnBarriers();
      return;
    }
    // ~35 % chance of a hurdle obstacle wave; otherwise a letter wave.
    if (_rng.nextDouble() < 0.35) {
      _spawnObstacles();
    } else {
      _spawnLetters();
    }
  }

  /// Spawns one BSL letter on each lane: the correct letter on a random lane,
  /// two unique decoy letters on the remaining lanes.
  void _spawnLetters() {
    // Skip if the correct letter disc is already scrolling — avoids duplicates.
    if (items.any((item) =>
        item.isActive &&
        !item.isObstacle &&
        !item.isBarrier &&
        item.letter == nextLetter)) {
      return;
    }

    final correctLane = _rng.nextInt(3);
    final decoys = _decoyLetters(nextLetter); // always 2 unique letters

    for (int lane = 0; lane < 3; lane++) {
      final String letter;
      final Color colour;
      if (lane == correctLane) {
        letter = nextLetter;
        colour = const Color(0xFF4CAF50); // green — the one to collect
      } else {
        // Map non-correct lanes to decoy indices 0 and 1.
        final decoyIndex = lane < correctLane ? lane : lane - 1;
        letter = decoys[decoyIndex];
        colour = const Color(0xFF5C6BC0); // indigo — wrong letter
      }
      items.add(SprintItem(
        letter: letter,
        lane: lane,
        y: 0.12,
        displayColour: colour,
      ));
    }
  }

  /// Spawns unjumpable barriers on 1 or 2 randomly chosen lanes (level 2 only).
  /// Never blocks all three lanes so there is always a safe lane to dodge into.
  void _spawnBarriers() {
    final count = 1 + _rng.nextInt(2);
    final lanes = ([0, 1, 2]..shuffle(_rng)).take(count).toList();
    for (final lane in lanes) {
      items.add(SprintItem(
        letter: '',
        lane: lane,
        y: 0.12,
        isBarrier: true,
        displayColour: const Color(0xFFC62828),
      ));
    }
  }

  /// Spawns rock obstacles on 1 or 2 randomly chosen lanes.
  /// Never blocks all three lanes so there is always a safe path.
  void _spawnObstacles() {
    final count = 1 + _rng.nextInt(2); // 1 or 2 obstacles
    final lanes = ([0, 1, 2]..shuffle(_rng)).take(count).toList();
    for (final lane in lanes) {
      items.add(SprintItem(
        letter: '',
        lane: lane,
        y: 0.12,
        isObstacle: true,
        displayColour: const Color(0xFF795548), // brown
      ));
    }
  }

  /// Returns 2 unique letters that differ from [exclude].
  List<String> _decoyLetters(String exclude) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final pool = alphabet.split('')
      ..remove(exclude)
      ..shuffle(_rng);
    return pool.take(2).toList();
  }

  void _checkCollisions() {
    final cy = characterY;

    for (final item in items) {
      if (item.collected) continue;
      if (item.lane != characterLane) continue;

      if (item.isBarrier) {
        // Barriers hit regardless of jump — compare against fixed ground Y.
        if ((item.y - characterBaseY).abs() > _collisionRadius) continue;
        item.collected = true;
        _hitObstacle();
        return;
      }

      if (item.isObstacle) {
        // Obstacles use the character's actual Y (including jump arc) so that
        // jumping over them works correctly.
        if ((item.y - cy).abs() > _collisionRadius) continue;
        if (jumpOffset < 0.05) {
          item.collected = true;
          _hitObstacle();
          return;
        }
        // Player is airborne — safely cleared.
      } else {
        // Letters use the actual character Y (jump arc included) so that
        // jumping over a letter avoids it. The depth guard prevents collecting
        // letters that are still far in the z-plane.
        if (item.y < _minCollectY) continue;
        if ((item.y - cy).abs() > _collisionRadius) continue;
        if (item.letter == nextLetter) {
          final collectedLetter = nextLetter;
          item.collected = true;
          // Silently collect any duplicate of this letter in the same row so
          // they don't later trigger a wrong-letter penalty.
          for (final sibling in items) {
            if (!sibling.collected &&
                !sibling.isObstacle &&
                !sibling.isBarrier &&
                sibling.letter == collectedLetter &&
                (sibling.y - item.y).abs() < 0.01) {
              sibling.collected = true;
            }
          }
          _collectLetter();
          return;
        } else {
          item.collected = true;
          //AudioService.playWrong('bsl_sprint');
          AudioService.speak('Oops');
          // All levels except Training penalise a wrong letter.
          if (_currentLevel.number != 0) {
            score -= 10;
            notifyListeners();
          }
        }
      }
    }
  }

  void _hitObstacle() {
    lives--;
    final wrongAudio = AudioService.playWrong('bsl_sprint');
    if (lives <= 0) {
      // Wait for the "wrong" SFX to finish before showing the success
      // overlay so the two sounds don't overlap.
      Future(() async {
        await wrongAudio;
        state = SprintState.gameOver;
        AudioService.hapticSuccess();
        _recordResult();
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _collectLetter() {
    final collectedLetter = currentWord[_letterIndex];
    _letterIndex++;
    //AudioService.playCorrect('bsl_sprint');
    final letterAudio = AudioService.playLetterMp3(collectedLetter);
    score += 10;

    // Re-colour any on-screen decoy that now matches the new correct letter.
    final newNext = nextLetter;
    if (newNext.isNotEmpty) {
      for (final item in items) {
        if (item.isActive &&
            !item.isObstacle &&
            !item.isBarrier &&
            item.letter == newNext) {
          item.displayColour = const Color(0xFF4CAF50);
        }
      }
    }

    if (_letterIndex >= currentWord.length) {
      // ── Word complete ──────────────────────────────────────────────
      score += 50; // word-completion bonus
      wordsCompleted++;

      // Training level ends after 3 words.
      if (_currentLevel.number == 0 && wordsCompleted >= 3) {
        // Wait for the final letter's audio to finish before showing the
        // success overlay so the two sounds don't overlap.
        Future(() async {
          await letterAudio;
          state = SprintState.gameOver;
          AudioService.hapticSuccess();
          _recordResult();
          notifyListeners();
        });
        notifyListeners();
        return;
      }

      // Ramp up difficulty each word.
      _scrollSpeed = (_scrollSpeed * 1.08).clamp(_currentLevel.initialScrollSpeed, 0.85);
      _spawnInterval = (_spawnInterval * 0.92).clamp(1.0, 2.0);

      _nextWord();

      // Say "Well Done!" then the new word to collect.
      final newWord = currentWord;
      Future(() async {
        await letterAudio;
        await AudioService.speakAndWait('Well Done!');
        await AudioService.speak(newWord);
      });
    } else {
      letterAudio.ignore();
    }
    notifyListeners();
  }

  void _recordResult() {
    _statsService
        .recordGameResult(GameIds.bslSprint, score)
        .then((result) {
      lastResult = result;
      notifyListeners();
    });
  }
}
