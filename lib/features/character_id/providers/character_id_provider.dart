import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_character.dart';
import '../models/mixed_character.dart';

/// Game state for the Character Identification game.
enum CharacterIdGameState {
  /// Loading character data from JSON
  loading,

  /// Showing level selection screen
  levelSelect,

  /// Game is active - waiting for player to guess
  playing,

  /// Correct answer selected
  correct,

  /// Wrong answer selected
  wrong,

  /// Level 1 completed (10 correct answers)
  finished,
}

/// Question types for Level 1.
enum Level1QuestionType {
  /// Ask about trouser colour
  trousers,

  /// Ask about shoe colour
  shoes,

  /// Ask about a torso item colour (shirt, jumper, coat, etc.)
  torso,
}

/// Represents a level in the Character Identification game.
class CharacterIdLevel {
  final int number;
  final String name;
  final String description;

  const CharacterIdLevel({
    required this.number,
    required this.name,
    required this.description,
  });

  /// All available levels.
  static const List<CharacterIdLevel> all = [
    CharacterIdLevel(
      number: 1,
      name: 'Clothing Colours',
      description: 'Get 10 correct to win!',
    ),
    CharacterIdLevel(
      number: 2,
      name: 'Clothing Colours',
      description: 'Get 10 correct to win!',
    ),
    CharacterIdLevel(
      number: 3,
      name: 'Speed Round',
      description: 'How many can you get in 60 seconds?',
    ),
    CharacterIdLevel(
      number: 4,
      name: 'Compare Characters',
      description: 'Get 10 correct to win!',
    ),
  ];
}

/// A valid Level 4 question with the correct answer.
class _Level4Question {
  final String questionText;
  final String correctCharacterName;

  const _Level4Question(this.questionText, this.correctCharacterName);
}

/// Provider for managing the Character Identification game state.
///
/// Handles:
/// - Loading character data from JSON asset
/// - Level selection and management
/// - Level 1: "What colour trousers?" with mixed-up character
/// - Level 2: Mixed-up character identification by head
/// - Tracking player guesses and score
/// - Managing game state (correct/wrong feedback)
class CharacterIdProvider extends ChangeNotifier {
  // -------------------------
  // Constants
  // -------------------------

  /// Path to the character data JSON file
  static const String _jsonAssetPath = 'assets/data/catrin_and_abi.json';

  /// Duration to show correct feedback before generating next character
  static const int correctFeedbackDurationMs = 1500;

  /// Duration to show wrong feedback before allowing retry
  static const int wrongFeedbackDurationMs = 1000;

  /// Number of correct answers needed to complete Level 1
  static const int level1WinningScore = 10;

  /// Time limit for Level 3 in seconds
  static const int level3TimeLimitSeconds = 60;

  // -------------------------
  // State
  // -------------------------

  final Random _random = Random();

  /// Current game state
  CharacterIdGameState _gameState = CharacterIdGameState.loading;
  CharacterIdGameState get gameState => _gameState;

  /// Current level
  CharacterIdLevel _currentLevel = CharacterIdLevel.all[0];
  CharacterIdLevel get currentLevel => _currentLevel;

  /// Whether to show level selection
  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  /// All loaded characters from JSON
  List<GameCharacter> _characters = [];
  List<GameCharacter> get characters => _characters;

  /// The current mixed-up character being displayed (all levels)
  MixedCharacter? _currentMixedCharacter;
  MixedCharacter? get currentMixedCharacter => _currentMixedCharacter;

  /// The second mixed-up character for Level 3 comparison
  MixedCharacter? _secondMixedCharacter;
  MixedCharacter? get secondMixedCharacter => _secondMixedCharacter;

  /// The question text for Level 3 comparison
  String _level4Question = '';
  String get level4Question => _level4Question;

  /// The correct character name for Level 3
  String? _level4CorrectName;

  /// The answer choices for Level 1 (clothing colors)
  List<String> _answerChoices = [];
  List<String> get answerChoices => _answerChoices;

  /// The correct answer for Level 1
  String? _correctAnswer;
  String? get correctAnswer => _correctAnswer;

  /// Current question type for Level 1 (cycles through trousers, shoes, torso)
  Level1QuestionType _currentQuestionType = Level1QuestionType.trousers;
  Level1QuestionType get currentQuestionType => _currentQuestionType;

  /// The torso attribute being asked about (e.g., "shirt", "jumper", "coat")
  String? _currentTorsoAttribute;
  String? get currentTorsoAttribute => _currentTorsoAttribute;

  /// The question text for the current Level 1 round
  String get currentQuestion {
    switch (_currentQuestionType) {
      case Level1QuestionType.trousers:
        return 'What colour trousers am I wearing?';
      case Level1QuestionType.shoes:
        return 'What colour shoes am I wearing?';
      case Level1QuestionType.torso:
        final attr = _currentTorsoAttribute ?? 'shirt';
        return 'What colour is the $attr?';
    }
  }

  /// The answer that was last selected (for highlighting)
  String? _selectedAnswer;
  String? get selectedAnswer => _selectedAnswer;

  /// The name of the button that was last selected (for Level 2 highlighting)
  String? _selectedName;
  String? get selectedName => _selectedName;

  /// Current score (number of correct answers)
  int _score = 0;
  int get score => _score;

  /// Total number of rounds played
  int _roundsPlayed = 0;
  int get roundsPlayed => _roundsPlayed;

  /// Error message if loading fails
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Timer for Level 2 speed round
  Timer? _timer;

  /// Remaining seconds for Level 2
  int _remainingSeconds = level3TimeLimitSeconds;
  int get remainingSeconds => _remainingSeconds;

  // -------------------------
  // Computed Properties
  // -------------------------

  /// All unique character names (for generating buttons in Level 2)
  List<String> get characterNames =>
      _characters.map((c) => c.characterName).toList();

  /// Whether the game data has been loaded
  bool get isLoaded => _characters.isNotEmpty;

  /// Whether currently on Level 1 (Clothing Colours with colour hints - 10 to win)
  bool get isLevel1 => _currentLevel.number == 1;

  /// Whether currently on Level 2 (Clothing Colours without colour hints - 10 to win)
  bool get isLevel2 => _currentLevel.number == 2;

  /// Whether currently on Level 3 (Speed Round - 60 seconds)
  bool get isLevel3 => _currentLevel.number == 3;

  /// Whether currently on Level 4 (Compare Characters - 10 to win)
  bool get isLevel4 => _currentLevel.number == 4;

  // -------------------------
  // Lifecycle
  // -------------------------

  /// Initialises the provider and loads character data.
  CharacterIdProvider() {
    loadCharacterData();
  }

  // -------------------------
  // Level Selection
  // -------------------------

  /// Shows the level selection screen.
  void showLevelSelection() {
    _showLevelSelect = true;
    _gameState = CharacterIdGameState.levelSelect;
    notifyListeners();
  }

  /// Selects a level and starts the game.
  void selectLevel(int levelNumber) {
    _currentLevel = CharacterIdLevel.all.firstWhere(
      (l) => l.number == levelNumber,
      orElse: () => CharacterIdLevel.all[0],
    );
    _showLevelSelect = false;
    _score = 0;
    _roundsPlayed = 0;
    _startLevel();
    notifyListeners();
  }

  /// Starts the current level.
  void _startLevel() {
    // Stop any existing timer
    _stopTimer();

    if (isLevel1 || isLevel2 || isLevel3) {
      // Levels 1, 2, and 3 use the same clothing colour questions
      _generateLevel1Round();

      // Start timer for Level 3 (Speed Round)
      if (isLevel3) {
        _remainingSeconds = level3TimeLimitSeconds;
        _startTimer();
      }
    } else {
      // Level 4: Compare Characters
      _generateLevel4Round();
    }
    _gameState = CharacterIdGameState.playing;
  }

  /// Starts the countdown timer for Level 3.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      notifyListeners();

      if (_remainingSeconds <= 0) {
        _stopTimer();
        _gameState = CharacterIdGameState.finished;
        notifyListeners();
      }
    });
  }

  /// Stops the countdown timer.
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // -------------------------
  // Level 1 Logic
  // -------------------------

  /// Generates a new round for Level 1 (cycling clothing colour questions).
  ///
  /// Creates a mixed-up character and generates 3 colour choices
  /// (the correct answer + 2 wrong answers from other characters).
  /// Cycles through asking about trousers, shoes, and torso items.
  void _generateLevel1Round() {
    if (_characters.isEmpty) return;

    // Cycle through question types: trousers -> shoes -> torso -> trousers...
    switch (_currentQuestionType) {
      case Level1QuestionType.trousers:
        _currentQuestionType = Level1QuestionType.shoes;
        break;
      case Level1QuestionType.shoes:
        _currentQuestionType = Level1QuestionType.torso;
        break;
      case Level1QuestionType.torso:
        _currentQuestionType = Level1QuestionType.trousers;
        break;
    }

    // Generate a mixed character with randomised body parts
    _generateMixedCharacter();

    // Get the correct colour based on question type
    final allColours = <String>{};

    if (_currentQuestionType == Level1QuestionType.trousers) {
      // Get trouser colour from the mixed character's legs
      final trousersAttr =
          _currentMixedCharacter!.legs.getAttribute('trousers');
      if (trousersAttr is Map<String, dynamic>) {
        _correctAnswer = trousersAttr['color'] as String?;
      } else {
        _correctAnswer = null;
      }

      // Gather all unique trouser colours from all characters
      for (final char in _characters) {
        final trousers = char.legs.getAttribute('trousers');
        if (trousers is Map<String, dynamic>) {
          final color = trousers['color'] as String?;
          if (color != null) {
            allColours.add(color);
          }
        }
      }
    } else if (_currentQuestionType == Level1QuestionType.shoes) {
      // Get shoe colour from the mixed character's feet
      final shoesAttr = _currentMixedCharacter!.feet.getAttribute('shoes');
      if (shoesAttr is Map<String, dynamic>) {
        _correctAnswer = shoesAttr['color'] as String?;
      } else {
        _correctAnswer = null;
      }

      // Gather all unique shoe colours from all characters
      for (final char in _characters) {
        final shoes = char.feet.getAttribute('shoes');
        if (shoes is Map<String, dynamic>) {
          final color = shoes['color'] as String?;
          if (color != null) {
            allColours.add(color);
          }
        }
      }
    } else {
      // Torso question - pick a random attribute from the torso
      _generateTorsoQuestion(allColours);
    }

    // Build answer choices: correct + 2 wrong
    _answerChoices = [];
    if (_correctAnswer != null) {
      _answerChoices.add(_correctAnswer!);

      // Add wrong answers
      final wrongChoices = allColours
          .where((c) => c != _correctAnswer)
          .toList()
        ..shuffle(_random);

      for (int i = 0; i < 2 && i < wrongChoices.length; i++) {
        _answerChoices.add(wrongChoices[i]);
      }

      // Shuffle the final choices
      _answerChoices.shuffle(_random);
    }

    _selectedAnswer = null;
  }

  /// Torso attributes that can have a color (excludes image_path).
  static const List<String> _torsoAttributes = [
    'shirt',
    'jumper',
    'coat',
    'tie',
  ];

  /// Generates a torso colour question.
  ///
  /// Picks a random torso attribute from the displayed character and
  /// gathers all torso colours from all characters as potential answers.
  void _generateTorsoQuestion(Set<String> allColours) {
    // Find which torso attributes the current character has
    final availableAttrs = <String>[];
    for (final attr in _torsoAttributes) {
      final value = _currentMixedCharacter!.torso.getAttribute(attr);
      if (value is Map<String, dynamic> && value['color'] != null) {
        availableAttrs.add(attr);
      }
    }

    if (availableAttrs.isEmpty) {
      _correctAnswer = null;
      _currentTorsoAttribute = null;
      return;
    }

    // Pick a random attribute from available ones
    availableAttrs.shuffle(_random);
    _currentTorsoAttribute = availableAttrs.first;

    // Get the correct colour
    final attrData = _currentMixedCharacter!.torso
        .getAttribute(_currentTorsoAttribute!) as Map<String, dynamic>;
    _correctAnswer = attrData['color'] as String?;

    // Gather all torso colours from all characters (any attribute)
    for (final char in _characters) {
      for (final attr in _torsoAttributes) {
        final value = char.torso.getAttribute(attr);
        if (value is Map<String, dynamic>) {
          final color = value['color'] as String?;
          if (color != null) {
            allColours.add(color);
          }
        }
      }
    }
  }

  /// Called when the player selects an answer in Level 1.
  void selectLevel1Answer(String answer) {
    if (_gameState != CharacterIdGameState.playing) return;
    if (_correctAnswer == null) return;

    _selectedAnswer = answer;

    if (answer == _correctAnswer) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  // -------------------------
  // Data Loading
  // -------------------------

  /// Loads character data from the JSON asset file.
  ///
  /// Supports two JSON formats:
  /// 1. A JSON array of character objects: `[{...}, {...}]`
  /// 2. Comma-separated objects (will be wrapped in array): `{...}, {...}`
  Future<void> loadCharacterData() async {
    _gameState = CharacterIdGameState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      var jsonString = await rootBundle.loadString(_jsonAssetPath);

      // Trim whitespace
      jsonString = jsonString.trim();

      // If the JSON doesn't start with '[', wrap it in array brackets
      // This handles comma-separated objects without outer brackets
      if (!jsonString.startsWith('[')) {
        jsonString = '[$jsonString]';
      }

      final jsonData = json.decode(jsonString) as List<dynamic>;

      _characters = jsonData
          .map((c) => GameCharacter.fromJson(c as Map<String, dynamic>))
          .toList();

      if (_characters.isEmpty) {
        _errorMessage = 'No characters found in JSON file';
      } else {
        // Show level selection after loading
        _gameState = CharacterIdGameState.levelSelect;
      }
    } catch (e) {
      _errorMessage = 'Failed to load character data: $e';
      _gameState = CharacterIdGameState.levelSelect;
    }

    notifyListeners();
  }

  // -------------------------
  // Game Logic
  // -------------------------

  /// Generates a new mixed-up character from random parts.
  ///
  /// Preferably selects parts from different characters when possible.
  void _generateMixedCharacter() {
    if (_characters.isEmpty) return;

    // Shuffle the characters list for random selection
    final shuffled = List<GameCharacter>.from(_characters)..shuffle(_random);

    // Select parts from different characters when possible
    final headChar = shuffled[0];
    final torsoChar = shuffled.length > 1 ? shuffled[1] : shuffled[0];
    final legsChar = shuffled.length > 2 ? shuffled[2] : shuffled[0];
    final feetChar = shuffled.length > 3 ? shuffled[3] : shuffled[0];

    _currentMixedCharacter = MixedCharacter(
      identityName: headChar.characterName, // Identity from head
      head: headChar.head,
      torso: torsoChar.torso,
      legs: legsChar.legs,
      feet: feetChar.feet,
      headSource: headChar.characterName,
      torsoSource: torsoChar.characterName,
      legsSource: legsChar.characterName,
      feetSource: feetChar.characterName,
    );
  }

  // -------------------------
  // Level 3 Logic
  // -------------------------

  /// Generates a new round for Level 3 (comparison between two characters).
  ///
  /// Creates two mixed-up characters and generates a question asking
  /// which character has a specific coloured clothing item.
  /// Ensures the two characters have different colours for the asked attribute.
  void _generateLevel4Round() {
    if (_characters.length < 2) return;

    // Generate two different mixed characters
    _generateMixedCharacter();
    _generateSecondMixedCharacter();

    // Find a valid question where both characters have different colours
    final validQuestions = _findValidLevel4Questions();

    if (validQuestions.isEmpty) {
      // No valid questions - regenerate characters
      _generateLevel4Round();
      return;
    }

    // Pick a random valid question
    final question = validQuestions[_random.nextInt(validQuestions.length)];
    _level4Question = question.questionText;
    _level4CorrectName = question.correctCharacterName;
    _selectedName = null;
  }

  /// Finds all valid Level 3 questions where the two characters differ.
  ///
  /// Returns a list of valid questions (attribute + colour combinations
  /// where only one character has that colour).
  List<_Level4Question> _findValidLevel4Questions() {
    final questions = <_Level4Question>[];
    final char1 = _currentMixedCharacter!;
    final char2 = _secondMixedCharacter!;

    // Check trousers
    final trousers1 = _getColour(char1.legs, 'trousers');
    final trousers2 = _getColour(char2.legs, 'trousers');
    if (trousers1 != null && trousers2 != null && trousers1 != trousers2) {
      // Both have trousers but different colours - valid question
      if (_random.nextBool()) {
        questions.add(_Level4Question(
          'Which character has $trousers1 trousers?',
          char1.identityName,
        ));
      } else {
        questions.add(_Level4Question(
          'Which character has $trousers2 trousers?',
          char2.identityName,
        ));
      }
    }

    // Check shoes
    final shoes1 = _getColour(char1.feet, 'shoes');
    final shoes2 = _getColour(char2.feet, 'shoes');
    if (shoes1 != null && shoes2 != null && shoes1 != shoes2) {
      if (_random.nextBool()) {
        questions.add(_Level4Question(
          'Which character has $shoes1 shoes?',
          char1.identityName,
        ));
      } else {
        questions.add(_Level4Question(
          'Which character has $shoes2 shoes?',
          char2.identityName,
        ));
      }
    }

    // Check torso attributes
    for (final attr in _torsoAttributes) {
      final colour1 = _getColour(char1.torso, attr);
      final colour2 = _getColour(char2.torso, attr);

      // Only valid if exactly one character has this attribute with a colour
      // or both have it but with different colours
      if (colour1 != null && colour2 == null) {
        questions.add(_Level4Question(
          'Which character has the $colour1 $attr?',
          char1.identityName,
        ));
      } else if (colour2 != null && colour1 == null) {
        questions.add(_Level4Question(
          'Which character has the $colour2 $attr?',
          char2.identityName,
        ));
      } else if (colour1 != null && colour2 != null && colour1 != colour2) {
        if (_random.nextBool()) {
          questions.add(_Level4Question(
            'Which character has the $colour1 $attr?',
            char1.identityName,
          ));
        } else {
          questions.add(_Level4Question(
            'Which character has the $colour2 $attr?',
            char2.identityName,
          ));
        }
      }
    }

    return questions;
  }

  /// Helper to get a colour from a character part's attribute.
  String? _getColour(dynamic part, String attributeName) {
    final attr = part.getAttribute(attributeName);
    if (attr is Map<String, dynamic>) {
      return attr['color'] as String?;
    }
    return null;
  }

  /// Generates a second mixed-up character for Level 3.
  ///
  /// Ensures the second character has a different head (identity) from the first.
  void _generateSecondMixedCharacter() {
    if (_characters.isEmpty) return;

    // Shuffle and ensure we get a different head
    final shuffled = List<GameCharacter>.from(_characters)..shuffle(_random);

    // Find a character with a different head than the first
    GameCharacter headChar = shuffled[0];
    for (final char in shuffled) {
      if (char.characterName != _currentMixedCharacter?.identityName) {
        headChar = char;
        break;
      }
    }

    // Pick random parts for the rest
    final torsoChar = shuffled[_random.nextInt(shuffled.length)];
    final legsChar = shuffled[_random.nextInt(shuffled.length)];
    final feetChar = shuffled[_random.nextInt(shuffled.length)];

    _secondMixedCharacter = MixedCharacter(
      identityName: headChar.characterName,
      head: headChar.head,
      torso: torsoChar.torso,
      legs: legsChar.legs,
      feet: feetChar.feet,
      headSource: headChar.characterName,
      torsoSource: torsoChar.characterName,
      legsSource: legsChar.characterName,
      feetSource: feetChar.characterName,
    );
  }

  /// Called when the player selects a character name in Level 3.
  void selectLevel4Answer(String name) {
    if (_gameState != CharacterIdGameState.playing) return;
    if (_level4CorrectName == null) return;

    _selectedName = name;

    if (name == _level4CorrectName) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  /// Called when the player taps a character name button.
  void selectAnswer(String name) {
    if (_gameState != CharacterIdGameState.playing) return;
    if (_currentMixedCharacter == null) return;

    _selectedName = name;

    if (name == _currentMixedCharacter!.identityName) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  /// Handles a correct answer.
  void _handleCorrectAnswer() {
    _score++;
    _roundsPlayed++;
    _gameState = CharacterIdGameState.correct;
    notifyListeners();

    // Check if Level 1, 2, or 4 is complete (10 correct answers)
    // Level 3 has no win condition - plays until timer expires
    if ((isLevel1 || isLevel2 || isLevel4) && _score >= level1WinningScore) {
      Future.delayed(
        const Duration(milliseconds: correctFeedbackDurationMs),
        () {
          _gameState = CharacterIdGameState.finished;
          notifyListeners();
        },
      );
      return;
    }

    // Show feedback then generate next round
    Future.delayed(
      const Duration(milliseconds: correctFeedbackDurationMs),
      () {
        _selectedName = null;
        _selectedAnswer = null;
        if (isLevel1 || isLevel2 || isLevel3) {
          _generateLevel1Round();
        } else {
          _generateLevel4Round();
        }
        _gameState = CharacterIdGameState.playing;
        notifyListeners();
      },
    );
  }

  /// Handles a wrong answer.
  void _handleWrongAnswer() {
    _gameState = CharacterIdGameState.wrong;
    notifyListeners();

    // Show feedback then allow retry
    Future.delayed(
      const Duration(milliseconds: wrongFeedbackDurationMs),
      () {
        _selectedName = null;
        _selectedAnswer = null;
        _gameState = CharacterIdGameState.playing;
        notifyListeners();
      },
    );
  }

  /// Resets the game to start fresh.
  void resetGame() {
    _score = 0;
    _roundsPlayed = 0;
    _selectedName = null;
    _selectedAnswer = null;
    _startLevel();
    notifyListeners();
  }

  /// Skips to the next round without scoring.
  void skipRound() {
    if (_gameState != CharacterIdGameState.playing) return;

    _roundsPlayed++;
    _selectedName = null;
    _selectedAnswer = null;
    if (isLevel1 || isLevel2 || isLevel3) {
      _generateLevel1Round();
    } else {
      _generateLevel4Round();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
