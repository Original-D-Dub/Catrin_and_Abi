import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/services/audio_service.dart';
import '../models/clothes_line_models.dart';

class ClothesLineProvider extends ChangeNotifier {
  static const int totalItems = 10;

  final Random _rng = Random();

  /// UI locale ('en' or 'cy') used for all displayed text.
  final String locale;

  ClothesLineProvider({this.locale = 'en'});

  int level = 1;
  bool showLevelSelect = true;

  ClothesLineState state = ClothesLineState.playing;
  List<ClothesLineQuestion> questions = [];
  int currentIndex = 0;
  int score = 0;
  String? selectedAnswer;

  ClothesLineQuestion get currentQuestion => questions[currentIndex];
  ClothingItem get currentItem => currentQuestion.item;
  List<String> get answerChoices => currentQuestion.choices;

  // Convenience getter for widgets that iterate the full item list.
  List<ClothingItem> get items => questions.map((q) => q.item).toList();

  void selectLevel(int lvl) {
    level = lvl;
    showLevelSelect = false;
    startGame();
  }

  void goToLevelSelect() {
    showLevelSelect = true;
    if (state == ClothesLineState.finished) {
      state = ClothesLineState.playing;
    }
    notifyListeners();
  }

  void startGame() {
    score = 0;
    currentIndex = 0;
    selectedAnswer = null;
    questions = _generateQuestions();
    state = ClothesLineState.playing;
    notifyListeners();
  }

  /// Returns true when the chosen colour is correct.
  bool selectAnswer(String colour) {
    if (state != ClothesLineState.playing) return false;
    selectedAnswer = colour;
    final correct = colour == currentItem.colour;
    state = correct ? ClothesLineState.correct : ClothesLineState.wrong;
    if (correct) {
      score += 10;
      AudioService.playCorrect('clothes_line');
    } else {
      AudioService.playWrong('clothes_line');
    }
    notifyListeners();
    return correct;
  }

  /// Advances to the next pre-generated question.
  void nextItem() {
    selectedAnswer = null;
    if (currentIndex >= questions.length - 1) {
      state = ClothesLineState.finished;
      notifyListeners();
      return;
    }
    currentIndex++;
    state = ClothesLineState.playing;
    notifyListeners();
  }

  /// Clears feedback state so the player can try again after a wrong answer.
  void resumePlaying() {
    selectedAnswer = null;
    state = ClothesLineState.playing;
    notifyListeners();
  }

  void resetGame() => startGame();

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static const List<String> starterColours = ['red', 'blue', 'green'];

  /// Generates the full question array at game start so that every item's
  /// clothing type, colour, and answer choices are fixed before play begins.
  /// Level 1 restricts choices to [starterColours]; levels 2 and 3 use all colours.
  List<ClothesLineQuestion> _generateQuestions() {
    final colours = level == 1 ? starterColours : clothingColours;
    final defs = [...clothingDefinitions]..shuffle(_rng);
    return List.generate(totalItems, (i) {
      final def = defs[i % defs.length];
      final colour = colours[_rng.nextInt(colours.length)];
      final item = ClothingItem(definition: def, colour: colour);
      return ClothesLineQuestion(item: item, choices: _choicesFor(colour, colours));
    });
  }

  List<String> _choicesFor(String correct, List<String> pool) {
    final others = [...pool]..remove(correct)..shuffle(_rng);
    return ([correct, others[0], others[1]]..shuffle(_rng));
  }
}
