import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_stats_service.dart';
import '../models/multi_vowel_puzzle.dart';
import '../models/vowel_target.dart';
import '../models/word_puzzle.dart';
import '../services/words_service.dart';

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

  final GameStatsService _statsService = GameStatsService();
  final WordsService _wordsService = WordsService();

  /// The sign system (BSL or IAC) this game instance is playing with.
  ///
  /// Determines which vowels are cycled through, whether w/y badges are
  /// shown, which level(s) are available, and which language's words are
  /// used — independent of the UI [AppLocalizations] locale, since a
  /// Welsh-speaking pupil learning BSL still needs English words, and an
  /// English-speaking pupil learning IAC still needs Welsh words.
  final SignSystem _signSystem;
  SignSystem get signSystem => _signSystem;

  /// The player's age group from Settings, which decides which levels are
  /// offered on level select.
  final AgeGroup _ageGroup;
  AgeGroup get ageGroup => _ageGroup;

  /// Levels offered on level select for this sign system and age group.
  List<VowelHandLevel> get availableLevels =>
      VowelHandLevel.forAgeGroup(_signSystem, _ageGroup);

  /// The "Level N" number shown for [level]: its position in
  /// [availableLevels], so each age group's list counts 1, 2, 3… Falls back
  /// to [VowelHandLevel.number] for a level outside the list (e.g. one
  /// opened from the Learn BSL trail). Stats and level-name audio stay keyed
  /// on [VowelHandLevel.number].
  int displayNumberOf(VowelHandLevel level) {
    final i = availableLevels.indexOf(level);
    return i >= 0 ? i + 1 : level.number;
  }

  /// The level after [_selectedLevel] within [availableLevels], or null if
  /// it is the last one for this age group.
  VowelHandLevel? get nextLevel {
    final levels = availableLevels;
    final i = levels.indexOf(_selectedLevel);
    return (i >= 0 && i + 1 < levels.length) ? levels[i + 1] : null;
  }

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

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
  // Ages 1–3 (toddler) Level State
  // -------------------------

  /// Letters still to be called after [_currentVowel] in a toddler level.
  List<String> _vowelQueue = [];

  /// Total letters (Levels 1–4) or words (Levels 5–7) in the current
  /// toddler level, shown as progress in place of the timer.
  int _totalRounds = 0;
  int get totalRounds => _totalRounds;

  /// The letter whose fingertip/badge is flashing red as a hint, or null.
  String? _hintVowel;
  String? get hintVowel => _hintVowel;

  /// Bumped on every new hint flash so the screen restarts the animation
  /// even when the same letter flashes again.
  int _hintToken = 0;
  int get hintToken => _hintToken;

  /// Clears [_hintVowel] once the flash has run its course.
  Timer? _hintTimer;

  /// How long the hint flashes for. BSL Level 3 has no w/y to add, so it
  /// is made harder with a shorter flash instead.
  Duration get _hintDuration =>
      _selectedLevel == VowelHandLevel.toddlerChallenge &&
              _signSystem == SignSystem.bsl
          ? const Duration(milliseconds: 1000)
          : const Duration(milliseconds: 3000);

  /// Whether the IAC w/y badges are shown. Toddler Levels 1 & 2 never call
  /// w or y, so they leave the badges out.
  bool get showsWyBadges =>
      _signSystem == SignSystem.iac &&
      _selectedLevel != VowelHandLevel.toddlerAei &&
      (_selectedLevel != VowelHandLevel.toddlerVowels || isIacWarmUp);

  /// Whether this is the IAC warm-up Level 1 for ages 3+ — [toddlerVowels]
  /// played outside the ages 1–3 group — which also calls w and y, and so
  /// has its own name and intro text.
  bool get isIacWarmUp =>
      _signSystem == SignSystem.iac &&
      _selectedLevel == VowelHandLevel.toddlerVowels &&
      _ageGroup != AgeGroup.years1to3;

  /// Letters called in toddler Level 4.
  static const int _toddlerAllRounds = 15;

  /// Words completed in the random toddler word level before it ends.
  static const int _toddlerWordRounds = 10;

  /// The fixed word list for ages 1–3 Five Words — the same five words, in
  /// the same order, every game.
  static const List<String> _toddlerFiveWords = [
    'bed', 'dog', 'cat', 'sun', 'pin',
  ];

  /// The fixed word list for ages 1–3 Ten Words — the same ten words every
  /// game, shuffled into a new random order each game.
  static const List<String> _toddlerTenWords = [
    'bed', 'dog', 'cat', 'sun', 'pin', 'pot', 'hen', 'hat', 'run', 'bin',
  ];

  /// Every three-letter word with a picture in
  /// `assets/images/word_thumbnails/` — the word list for ages 1–3 Level 8
  /// (see [isPictureWordLevel]), in place of the CCVC words that level
  /// plays for older children.
  static const List<String> _pictureWords = [
    'bag', 'bat', 'can', 'cap', 'cat', 'fan', 'hat', 'jam', 'man', 'map',
    'mat', 'pan', 'tag', 'van', 'wag',
    'bed', 'den', 'hen', 'jet', 'men', 'net', 'pen', 'pet', 'red', 'ten',
    'wet',
    'bib', 'big', 'bin', 'dig', 'fin', 'fit', 'hit', 'pig', 'pin', 'sit',
    'tin', 'wig', 'win',
    'box', 'dog', 'dot', 'fog', 'fox', 'got', 'hog', 'hop', 'hot', 'jog',
    'log', 'lot', 'pot', 'top',
    'bug', 'bun', 'bus', 'cup', 'cut', 'dug', 'fun', 'gun', 'hug', 'jug',
    'mug', 'nut', 'run', 'sun',
  ];

  /// Whether this is ages 1–3 Level 8 — the [VowelHandLevel.ccvc] slot,
  /// which for this age group plays [_pictureWords] (shown with their
  /// pictures) rather than CCVC words. Like the fixed-word levels, these
  /// are English words for both sign systems.
  bool get isPictureWordLevel =>
      _selectedLevel == VowelHandLevel.ccvc &&
      _ageGroup == AgeGroup.years1to3;

  /// Words still to come in the current game of a fixed-word level
  /// ([VowelHandLevel.isFixedWords]).
  List<String> _fixedWordQueue = [];

  /// How many words the selected toddler word level plays before it ends.
  int get _toddlerWordRoundsForLevel => _selectedLevel.isFixedWords
      ? (_selectedLevel == VowelHandLevel.toddlerFiveWords
          ? _toddlerFiveWords.length
          : _toddlerTenWords.length)
      : _toddlerWordRounds;

  // -------------------------
  // Level 2: Vowel Words State
  // -------------------------

  /// Current word puzzle (Level 2)
  WordPuzzle? _currentPuzzle;
  WordPuzzle? get currentPuzzle => _currentPuzzle;

  // -------------------------
  // Levels 5 & 6: Multi-vowel Word State
  // -------------------------

  /// Word list shared with My Special Dog's multi-vowel word levels.
  static const List<String> _multiVowelWords = [
    'Pero', 'Catrin', 'dog', 'Deaf', 'hearing', 'cochlear', 'implant',
    'Abi', 'sign', 'story', 'listen', 'understand', 'ear', 'ding dong', 'beep',
    'alarm', 'language', 'sister', 'sounds', 'special', 'amazing', 'doorbell',
    'fire alarm', 'learn', 'communicate', 'play', 'fun', 'learnt', 'wake up',
    'family', 'help', 'phone', 'together', 'fire exit', 'safe', 'safety', 'hearing dog',
  ];

  /// Welsh translation of [_multiVowelWords], used for Levels 5 & 6 when
  /// [_useWelshMultiVowelWords] is true. Same order/length as the English
  /// list.
  ///
  /// Every entry must contain at least one of a/e/i/o/u — the model only
  /// recognises those as blank-able vowels (not w/y or accented vowels like
  /// â/ô), so a word without one can never be completed. Originally 'clyw',
  /// 'hwyl', 'ffôn' and 'ynghyd' had none and were swapped for 'clywed',
  /// 'difyr', 'galwad' and "gyda'i gilydd".
  static const List<String> _multiVowelWordsCY = [
    'Pero', 'Catrin', 'ci', 'Byddar', 'clywed', 'cochlear', 'mewnblaniad',
    'Abi', 'arwydd', 'stori', 'gwrando', 'deall', 'clust', 'ding dong', 'bib',
    'larwm', 'iaith', 'chwaer', 'synau', 'arbennig', 'anhygoel', 'cloch drws',
    'larwm tân', 'dysgu', 'cyfathrebu', 'chwarae', 'difyr', 'wedi dysgu', 'deffro',
    'teulu', 'helpu', 'galwad', "gyda'i gilydd", 'allanfa dân', 'diogel', 'diogelwch', 'ci clyw',
  ];

  /// Whether Levels 5 & 6 should draw from the Welsh word list — true for
  /// IAC, matching Levels 2 & 3. Keyed on sign system, not UI language: a
  /// Welsh-speaking pupil playing BSL still practises English words, and an
  /// English-speaking pupil playing IAC still practises Welsh words.
  bool get _useWelshMultiVowelWords => _signSystem == SignSystem.iac;

  /// The multi-vowel word list to draw from.
  List<String> get _multiVowelWordsForLocale =>
      _useWelshMultiVowelWords ? _multiVowelWordsCY : _multiVowelWords;

  /// Number of words to complete before Levels 5/6 end.
  static const int targetWords = 5;

  /// Current multi-vowel word puzzle (Levels 5 & 6).
  MultiVowelPuzzle? _currentMultiPuzzle;
  MultiVowelPuzzle? get currentMultiPuzzle => _currentMultiPuzzle;

  /// Words completed so far in the current Level 5/6 game.
  final List<String> _completedWords = [];
  List<String> get completedWords => List.unmodifiable(_completedWords);

  /// Set to true the first time the player makes a wrong guess on the current
  /// word. Used by Level 6 to withhold the point for that word.
  bool _hadMistakeOnCurrentWord = false;

  /// The vowel the player guessed (null = show underscore)
  String? _guessedVowel;
  String? get guessedVowel => _guessedVowel;

  /// Whether the current guess is correct (null = no guess, true = correct, false = wrong)
  bool? _isGuessCorrect;
  bool? get isGuessCorrect => _isGuessCorrect;

  /// Whether input is locked during wrong answer display
  bool _isInputLocked = false;
  bool get isInputLocked => _isInputLocked;

  /// Whether the just-completed word is still on show during the extra
  /// pause before the next word appears (ages 1–3 word levels, Levels 5–7).
  /// Blocks input so the pause can't be double-scored.
  bool _awaitingNextWord = false;

  /// Recently used words to avoid repeats
  final List<String> _recentWords = [];

  /// Words fetched from Supabase for levels 3 (CCVC) and 4 (CVCC)
  List<String> _remoteWords = [];

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

  /// Called when a player taps the wrong fingertip or badge on any level,
  /// so the screen can show "Try again" in the UI language.
  VoidCallback? onTryAgain;

  /// Called once, with the final [_score], the moment the level ends. Set
  /// by the screen when launched from the "Learn BSL trail" so it can
  /// decide (score-gated, since this game has no other win condition)
  /// whether to mark the trail node completed.
  Function(int score)? onLevelComplete;

  /// Random number generator for selecting vowels/words
  final Random _random = Random();

  /// Tracks if we've already scored for the current touch
  /// Prevents multiple scores for dragging across the target
  bool _hasScored = false;

  /// Whether to show the score animation (brief flash on correct tap)
  bool _showScoreAnimation = false;
  bool get showScoreAnimation => _showScoreAnimation;

  /// Initializes the provider.
  VowelHandProvider({
    SignSystem signSystem = SignSystem.bsl,
    AgeGroup ageGroup = AgeGroup.all,
  })  : _signSystem = signSystem,
        _ageGroup = ageGroup {
    if (_signSystem == SignSystem.iac) {
      _showLevelSelect = false;
    }
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
    _clearHint();

    _showLevelSelect = true;
    _gameState = VowelHandGameState.ready;
    _isPointerVisible = false;
    _pointerPosition = null;
    _isInputLocked = false;
    _awaitingNextWord = false;
    _guessedVowel = null;
    _isGuessCorrect = null;

    notifyListeners();
  }

  // -------------------------
  // Game Control Methods
  // -------------------------

  /// Transitions to game view and initialises content without starting the timer.
  ///
  /// Call when a level is selected so the game is visible under the intro overlay.
  /// Follow with [startGame] once the intro countdown ends.
  void prepareForIntro({VowelHandLevel? level}) {
    _gameTimer?.cancel();
    _wrongAnswerTimer?.cancel();
    _scoreAnimationTimer?.cancel();
    _pointerHideTimer?.cancel();
    _clearHint();

    if (level != null) {
      _selectedLevel = level;
    }

    _showLevelSelect = false;
    _gameState = VowelHandGameState.ready;
    _score = 0;
    _remainingSeconds = VowelHandConstants.gameDurationSeconds;
    _isPointerVisible = false;
    _pointerPosition = null;
    _hasScored = false;
    _showScoreAnimation = false;
    _isInputLocked = false;
    _awaitingNextWord = false;
    _guessedVowel = null;
    _isGuessCorrect = null;
    _lastResult = null;

    if (_selectedLevel.isVowelMatch) {
      _startVowels();
    } else if (_selectedLevel.isMultiVowel) {
      _completedWords.clear();
      _currentMultiPuzzle = null;
      _selectMultiVowelPuzzle();
    } else {
      _totalRounds = _toddlerWordRoundsForLevel;
      _remoteWords = [];
      // Each new game starts its fixed sequence (or shuffle) from scratch.
      _fixedWordQueue = [];
      if (isPictureWordLevel) {
        // Local list: nothing to fetch.
      } else if (_selectedLevel.isShortWords && _signSystem == SignSystem.iac) {
        _loadRemoteWelshWords();
      } else if (_selectedLevel == VowelHandLevel.ccvc && _signSystem == SignSystem.iac) {
        _loadRemoteWelshWordsLevel3();
      } else if (_selectedLevel == VowelHandLevel.ccvc) {
        _loadRemoteWords('CCVC');
      } else if (_selectedLevel == VowelHandLevel.cvcc) {
        _loadRemoteWords('CVCC');
      }
      _selectRandomPuzzle();
    }

    notifyListeners();
  }

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
    _lastResult = null;
    _isInputLocked = false;
    _awaitingNextWord = false;
    _guessedVowel = null;
    _isGuessCorrect = null;

    // Initialize based on level
    if (_selectedLevel.isVowelMatch) {
      _startVowels();
    } else if (_selectedLevel.isMultiVowel) {
      _completedWords.clear();
      _currentMultiPuzzle = null;
      _selectMultiVowelPuzzle();
    } else {
      _totalRounds = _toddlerWordRoundsForLevel;
      // A fixed-word level keeps the word chosen in prepareForIntro so its
      // sequence isn't advanced twice; only select when starting cold.
      if (_fixedWordQueue.isEmpty || !_selectedLevel.isFixedWords) {
        _selectRandomPuzzle();
      }
    }

    // Levels 5 & 6 are word-count-based and the toddler levels end after a
    // fixed set of letters — neither uses the countdown timer.
    if (_selectedLevel.isTimed) {
      _gameTimer?.cancel();
      _gameTimer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
    }

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
    _clearHint();
    _gameState = VowelHandGameState.finished;
    _isPointerVisible = false;
    _pointerPosition = null;
    _isInputLocked = false;
    _awaitingNextWord = false;
    _lastResult = null;
    notifyListeners();

    onLevelComplete?.call(_score);

    final gameId =
        _signSystem == SignSystem.iac ? GameIds.welshVowels : GameIds.vowelHand;
    // Toddler levels reuse level numbers 1–3, so keep their stats separate
    // from the timed levels' personal bests.
    final resultFuture = _selectedLevel.isToddler
        ? _statsService.recordGameResult('${gameId}_toddler', _score,
            level: _selectedLevel.number)
        : _signSystem == SignSystem.iac
            ? _statsService.recordGameResult(gameId, _score)
            : _statsService.recordGameResult(gameId, _score,
                level: _selectedLevel.number);

    resultFuture.then((result) {
      _lastResult = result;
      notifyListeners();
    }).catchError((e) {
      debugPrint('recordGameResult error (vowelHand): $e');
    });
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
    _clearHint();

    _gameState = VowelHandGameState.ready;
    _score = 0;
    _remainingSeconds = VowelHandConstants.gameDurationSeconds;
    _isPointerVisible = false;
    _pointerPosition = null;
    _hasScored = false;
    _showScoreAnimation = false;
    _isInputLocked = false;
    _awaitingNextWord = false;
    _guessedVowel = null;
    _isGuessCorrect = null;

    if (_selectedLevel.isVowelMatch) {
      _startVowels();
    } else {
      // A fixed-word level restarts its sequence from the first word.
      if (_selectedLevel.isFixedWords) _fixedWordQueue = [];
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
    // debugPrint('onTouchEnd called - position: $position, handSize: $handSize');
    if (_gameState != VowelHandGameState.playing) {
      debugPrint('Game not playing, ignoring touch end');
      return;
    }

    // Handle input lock for word mode
    if (!_selectedLevel.isVowelMatch && _isInputLocked) {
      _revertWrongAnswer();
    }

    // Check for hit based on current level
    if (_selectedLevel.isVowelMatch) {
      _checkHitVowelMode(position: position, handSize: handSize);
    } else if (_selectedLevel.isMultiVowel) {
      _checkHitMultiVowelMode(position: position, handSize: handSize);
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

    // IAC-only vowels (w, y) have no fingertip target — they're matched via
    // onTapAdditionalVowel instead, so a fingertip tap for them is a miss.
    final tappedVowel = VowelHandConstants.targetAt(position, handSize)?.vowel;
    if (tappedVowel == null) return;

    if (tappedVowel == _currentVowel) {
      _scoreCorrectVowel();
    } else {
      _handleWrongVowelTap();
    }
  }

  /// Handles a tap on the 'w' or 'y' vowel badges (IAC only).
  ///
  /// These vowels have no fingertip target on the hand SVG, so they're
  /// matched via direct badge taps instead of [onTouchEnd]. Works for both
  /// Vowel Match (Level 1) and the Vowel Words puzzle (Level 2), since
  /// Welsh CVC words fetched from `Geiriau` can have 'w' or 'y' as their
  /// vowel.
  void onTapAdditionalVowel(String vowel) {
    if (_gameState != VowelHandGameState.playing) return;

    if (_selectedLevel.isVowelMatch) {
      if (vowel == _currentVowel) {
        _scoreCorrectVowel();
        // This tap is a standalone gesture, not part of an onTouchEnd cycle,
        // so clear the flag immediately rather than leaving it to block the
        // next fingertip hit check.
        _hasScored = false;
      } else {
        _handleWrongVowelTap();
      }
      return;
    }

    if (_hasScored || _currentPuzzle == null || _isInputLocked) return;
    if (_awaitingNextWord) return;
    _guessedVowel = vowel;
    _hasScored = true;
    AudioService.playLetterMp3(vowel, signSystem: _signSystem);
    if (vowel == _currentPuzzle!.vowel) {
      _handleCorrectWordGuess();
    } else {
      _handleWrongWordGuess();
    }
    // Standalone gesture, not part of an onTouchEnd cycle — clear the flag
    // immediately rather than leaving it to block the next fingertip hit check.
    _hasScored = false;
  }

  /// Handles a wrong fingertip/badge in a vowel-match level: every level
  /// says "Try again", and the toddler match levels also re-flash their
  /// hint.
  void _handleWrongVowelTap() {
    onTryAgain?.call();
    if (_selectedLevel.hasHint) _flashHint();
  }

  /// Awards a point for a correct vowel match, advances to the next vowel,
  /// and briefly shows the score animation.
  void _scoreCorrectVowel() {
    AudioService.playCorrect('vowel_hand');
    _score++;
    _hasScored = true;
    _showScoreAnimation = true;
    _clearHint();
    if (_selectedLevel.isToddlerMatch) {
      if (_vowelQueue.isEmpty) {
        // Every letter has been called — the level is complete.
        _endGame();
      } else {
        _setCurrentVowel(_vowelQueue.removeAt(0));
      }
    } else {
      _selectRandomVowel();
    }
    notifyListeners();

    // Hide score animation after 300ms
    _scoreAnimationTimer?.cancel();
    _scoreAnimationTimer = Timer(const Duration(milliseconds: 300), () {
      _showScoreAnimation = false;
      notifyListeners();
    });
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
    if (_hasScored || _currentPuzzle == null || _awaitingNextWord) return;

    // Check all fingertips to find which one was tapped
    final tappedVowel = VowelHandConstants.targetAt(position, handSize)?.vowel;

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

    AudioService.playLetterMp3(tappedVowel, signSystem: _signSystem);

    // Check if correct
    if (tappedVowel == _currentPuzzle!.vowel) {
      _handleCorrectWordGuess();
    } else {
      _handleWrongWordGuess();
    }
  }

  /// Handles a correct word guess.
  ///
  /// Shows green feedback, increments score, and moves to next word. The
  /// ages 1–3 word levels (Levels 5–7) hold the completed word on show for
  /// an extra 1.5s — spoken aloud — before the next word appears.
  void _handleCorrectWordGuess() {
    final word = _currentPuzzle!.word;
    _isGuessCorrect = true;
    _score++;
    _showScoreAnimation = true;
    notifyListeners();

    // After 300ms, clear feedback, speak the completed word, and show next word
    _scoreAnimationTimer?.cancel();
    _scoreAnimationTimer = Timer(const Duration(milliseconds: 300), () {
      _showScoreAnimation = false;
      AudioService.speak(word);
      // The toddler word levels are untimed and end after a fixed number
      // of words (5 or 10), with a pause between words.
      if (_selectedLevel.isToddlerWordLevel) {
        if (_score >= _totalRounds) {
          _guessedVowel = null;
          _isGuessCorrect = null;
          _endGame();
          return;
        }
        // Extra 1.5s pause with the completed word still on show (in
        // green, spoken aloud) before the next word replaces it.
        _awaitingNextWord = true;
        _scoreAnimationTimer = Timer(const Duration(milliseconds: 1500), () {
          _awaitingNextWord = false;
          _guessedVowel = null;
          _isGuessCorrect = null;
          _selectRandomPuzzle();
          notifyListeners();
        });
        return;
      }
      _guessedVowel = null;
      _isGuessCorrect = null;
      _selectRandomPuzzle();
      notifyListeners();
    });
  }

  /// Handles a wrong word guess.
  ///
  /// Shows red feedback and locks input, and — on every level — says
  /// "Try again". Reverts after 3 seconds or when the player taps again.
  void _handleWrongWordGuess() {
    _isGuessCorrect = false;
    _isInputLocked = true;
    onTryAgain?.call();
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
  // Levels 5 & 6: Multi-vowel Word Hit Detection
  // -------------------------

  /// Checks which vowel fingertip was tapped and evaluates correctness
  /// against the current multi-vowel puzzle (Levels 5 & 6).
  void _checkHitMultiVowelMode({
    required Offset position,
    required Size handSize,
  }) {
    if (_hasScored || _currentMultiPuzzle == null || _isInputLocked) return;

    final tappedVowel = VowelHandConstants.targetAt(position, handSize)?.vowel;
    if (tappedVowel == null) return;
    _hasScored = true;

    AudioService.playLetterMp3(tappedVowel, signSystem: _signSystem);

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
      // Level 6: only count if the player made no mistakes on this word
      final counts = _selectedLevel != VowelHandLevel.noMistakes ||
          !_hadMistakeOnCurrentWord;
      if (counts) {
        _completedWords.add(word);
        if (_selectedLevel == VowelHandLevel.noMistakes) {
          // Points = number of letters in the word (spaces don't count)
          _score += word.replaceAll(' ', '').length;
        } else {
          _score = _completedWords.length;
        }
      }
      _isInputLocked = true;
      notifyListeners();

      AudioService.playCorrect('vowel_hand');

      _scoreAnimationTimer?.cancel();
      _scoreAnimationTimer = Timer(const Duration(milliseconds: 900), () {
        _isGuessCorrect = null;
        _isInputLocked = false;
        if (_completedWords.length >= targetWords) {
          _endGame();
        } else {
          if (!_useWelshMultiVowelWords) {
            AudioService.playMp3(
                'vowel_hand/${word.replaceAll(' ', '_')}.mp3');
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
    // The screen shows the "Try again" message, with its audio.
    onTryAgain?.call();
    notifyListeners();

    _wrongAnswerTimer?.cancel();
    _wrongAnswerTimer = Timer(const Duration(milliseconds: 2500), () {
      _revertWrongAnswer();
      notifyListeners();
    });
  }

  // -------------------------
  // Selection Methods
  // -------------------------

  /// Selects a new random vowel, ensuring it's different from the current one (Level 1).
  void _selectRandomVowel() {
    final vowels = VowelHandConstants.vowelsForSignSystem(_signSystem);
    String newVowel;

    do {
      newVowel = vowels[_random.nextInt(vowels.length)];
    } while (newVowel == _currentVowel && vowels.length > 1);

    _setCurrentVowel(newVowel);
  }

  /// Makes [vowel] the letter to tap and, once play is running, calls it
  /// out (and, in the toddler levels, flashes its fingertip/badge).
  void _setCurrentVowel(String vowel) {
    _currentVowel = vowel;
    if (_gameState == VowelHandGameState.playing) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_gameState == VowelHandGameState.playing && _currentVowel == vowel) {
          AudioService.playLetterMp3(vowel, signSystem: _signSystem);
          if (_selectedLevel.hasHint) _flashHint();
        }
      });
    }
  }

  /// Sets up the first letter for a vowel-match level: a fresh shuffled
  /// sequence for the toddler levels, otherwise a random vowel.
  void _startVowels() {
    if (!_selectedLevel.isToddlerMatch) {
      _selectRandomVowel();
      return;
    }
    _vowelQueue = _buildToddlerSequence();
    _totalRounds = _vowelQueue.length;
    _setCurrentVowel(_vowelQueue.removeAt(0));
  }

  /// The letters called in the current toddler level, in random order:
  /// - Level 1: a, e, i — twice each.
  /// - Level 2: a, e, i, o, u — twice each (BSL and IAC alike). As the
  ///   ages 3+ warm-up Level 1 in IAC, w and y are called twice each too.
  /// - Level 3: BSL — a, e, i, o, u three times each. IAC — as Level 2,
  ///   plus w and y four times each.
  /// - Level 4: [_toddlerAllRounds] picks from every vowel for the sign
  ///   system.
  List<String> _buildToddlerSequence() {
    if (_selectedLevel == VowelHandLevel.toddlerAll) {
      final vowels = VowelHandConstants.vowelsForSignSystem(_signSystem);
      final letters = <String>[];
      while (letters.length < _toddlerAllRounds) {
        final v = vowels[_random.nextInt(vowels.length)];
        if (letters.isEmpty || letters.last != v) letters.add(v);
      }
      return letters;
    }
    const fingertips = VowelHandConstants.vowels;
    final counts = <String, int>{
      if (_selectedLevel == VowelHandLevel.toddlerAei)
        for (final v in const ['a', 'e', 'i']) v: 2
      else
        for (final v in fingertips)
          v: _selectedLevel == VowelHandLevel.toddlerChallenge &&
                  _signSystem == SignSystem.bsl
              ? 3
              : 2,
      if (_selectedLevel == VowelHandLevel.toddlerChallenge &&
          _signSystem == SignSystem.iac) ...{'w': 4, 'y': 4},
      if (isIacWarmUp) ...{'w': 2, 'y': 2},
    };
    final letters = [
      for (final e in counts.entries)
        for (var i = 0; i < e.value; i++) e.key,
    ];
    // Reshuffle until no letter is called twice in a row, so each new call
    // is visibly a new letter.
    for (var attempt = 0; attempt < 100; attempt++) {
      letters.shuffle(_random);
      var ok = true;
      for (var i = 1; i < letters.length; i++) {
        if (letters[i] == letters[i - 1]) {
          ok = false;
          break;
        }
      }
      if (ok) break;
    }
    return letters;
  }

  /// Flashes the current letter's fingertip/badge red for [_hintDuration].
  void _flashHint() {
    _hintTimer?.cancel();
    _hintVowel = _currentVowel;
    _hintToken++;
    notifyListeners();
    _hintTimer = Timer(_hintDuration, () {
      _hintVowel = null;
      notifyListeners();
    });
  }

  /// Stops any hint flash. Callers notify listeners themselves.
  void _clearHint() {
    _hintTimer?.cancel();
    _hintTimer = null;
    _hintVowel = null;
  }

  /// Selects a new random word puzzle, avoiding recently used words.
  ///
  /// The fixed-word toddler levels (Five Words / Ten Words) take the next
  /// word from their fixed list instead.
  /// Level 2 uses the local English CVC word list for BSL, or Welsh CVC
  /// words fetched from Supabase (`Geiriau`) for IAC.
  /// Levels 3 and 4 use English words fetched from Supabase (`words`),
  /// except ages 1–3 Level 8, which uses the local [_pictureWords].
  void _selectRandomPuzzle() {
    if (_selectedLevel.isFixedWords) {
      _selectFixedWordPuzzle();
      return;
    }
    if (isPictureWordLevel) {
      final available =
          _pictureWords.where((w) => !_recentWords.contains(w)).toList();
      final candidates = available.isNotEmpty ? available : _pictureWords;
      // English words, so parsed with the English alphabet (w is never a
      // vowel) whatever the sign system.
      _currentPuzzle =
          WordPuzzle(word: candidates[_random.nextInt(candidates.length)]);
      _recentWords.add(_currentPuzzle!.word);
      if (_recentWords.length > WordPuzzleConstants.maxRecentWords) {
        _recentWords.removeAt(0);
      }
      return;
    }
    if (_selectedLevel == VowelHandLevel.ccvc ||
        _selectedLevel == VowelHandLevel.cvcc ||
        (_selectedLevel.isShortWords && _signSystem == SignSystem.iac)) {
      if (_remoteWords.isEmpty) {
        _currentPuzzle = null;
        return;
      }
      final available =
          _remoteWords.where((w) => !_recentWords.contains(w)).toList();
      final candidates = available.isNotEmpty ? available : _remoteWords;
      final word = candidates[_random.nextInt(candidates.length)];
      _currentPuzzle =
          WordPuzzle(word: word, useWelshAlphabet: _signSystem == SignSystem.iac);
    } else {
      _currentPuzzle = WordPuzzleConstants.getRandomPuzzle(
        random: _random,
        recentWords: _recentWords,
        vowels: VowelHandConstants.vowels,
      );
    }

    _recentWords.add(_currentPuzzle!.word);
    if (_recentWords.length > WordPuzzleConstants.maxRecentWords) {
      _recentWords.removeAt(0);
    }
  }

  /// Selects the next word for a fixed-word level (ages 1–3 Five Words /
  /// Ten Words): (re)building the queue when it is empty — in list order
  /// for Five Words, shuffled for Ten Words — then taking the first word
  /// left. The words are English CVC words, so they always parse with the
  /// English alphabet rules regardless of sign system.
  void _selectFixedWordPuzzle() {
    if (_fixedWordQueue.isEmpty) {
      if (_selectedLevel == VowelHandLevel.toddlerFiveWords) {
        _fixedWordQueue = List.of(_toddlerFiveWords);
      } else {
        _fixedWordQueue = List.of(_toddlerTenWords)..shuffle(_random);
      }
    }
    _currentPuzzle = WordPuzzle(word: _fixedWordQueue.removeAt(0));
  }

  /// Selects a new multi-vowel word puzzle (Levels 5 & 6), avoiding the
  /// words already completed this game and immediate repeats.
  void _selectMultiVowelPuzzle() {
    _hadMistakeOnCurrentWord = false;
    final words = _multiVowelWordsForLocale;
    final available = words
        .where((w) => !_completedWords.contains(w) &&
            w != _currentMultiPuzzle?.word)
        .toList();
    final candidates = available.isNotEmpty ? available : words;
    _currentMultiPuzzle =
        MultiVowelPuzzle.fromWord(candidates[_random.nextInt(candidates.length)]);
  }

  /// Fetches words for [pattern] from Supabase.
  ///
  /// Called during intro so words are ready before the game starts.
  /// If the fetch completes after [startGame] and no puzzle is loaded yet,
  /// immediately selects the first puzzle.
  Future<void> _loadRemoteWords(String pattern) async {
    _remoteWords = await _wordsService.fetchWordsByPattern(pattern);
    if (_currentPuzzle == null &&
        _gameState != VowelHandGameState.finished &&
        _remoteWords.isNotEmpty) {
      _selectRandomPuzzle();
      notifyListeners();
    }
  }

  /// Three-letter word patterns used for the IAC Vowel Words level (Level 2).
  static const List<String> _iacLevel2Patterns = ['CVC', 'VCC', 'CCV'];

  /// Fetches Welsh 3-letter words from the `Geiriau` table (IAC Level 2).
  ///
  /// Called during intro so words are ready before the game starts.
  /// If the fetch completes after [startGame] and no puzzle is loaded yet,
  /// immediately selects the first puzzle.
  Future<void> _loadRemoteWelshWords() async {
    _remoteWords =
        await _wordsService.fetchWelshWordsByPatterns(_iacLevel2Patterns);
    if (_currentPuzzle == null &&
        _gameState != VowelHandGameState.finished &&
        _remoteWords.isNotEmpty) {
      _selectRandomPuzzle();
      notifyListeners();
    }
  }

  /// Fetches Welsh words from `Geiriau` whose pattern wasn't already used
  /// by Level 2 (IAC Level 3) — i.e. everything other than
  /// [_iacLevel2Patterns].
  ///
  /// Called during intro so words are ready before the game starts.
  /// If the fetch completes after [startGame] and no puzzle is loaded yet,
  /// immediately selects the first puzzle.
  Future<void> _loadRemoteWelshWordsLevel3() async {
    _remoteWords = await _wordsService
        .fetchWelshWordsExcludingPatterns(_iacLevel2Patterns);
    if (_currentPuzzle == null &&
        _gameState != VowelHandGameState.finished &&
        _remoteWords.isNotEmpty) {
      _selectRandomPuzzle();
      notifyListeners();
    }
  }

  // -------------------------
  // Utility Methods
  // -------------------------

  /// The current vowel letter shown at the top of the screen (Level 1 only).
  String get displayLetter => _currentVowel;

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
    _hintTimer?.cancel();
    super.dispose();
  }
}
