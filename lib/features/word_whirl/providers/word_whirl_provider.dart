import 'package:flutter/material.dart';

import '../../../shared/services/audio_service.dart';
import '../models/word_whirl_models.dart';

class WordWhirlProvider extends ChangeNotifier {
  /// UI locale ('en' or 'cy') — determines which word lists are used.
  final String locale;

  late WordWhirlLevel _level;
  bool showLevelSelect = true;

  WordWhirlProvider({this.locale = 'en'}) {
    _level = WordWhirlLevel.forLocale(locale).first;
    AudioService.playTitle('word_search', locale: locale);
    AudioService.playIntro('word_whirl', locale: locale);
  }

  // ── State ──────────────────────────────────────────────────────────────────

  int _wordIndex = 0;
  int score = 0;
  WordWhirlState state = WordWhirlState.playing;

  /// Pool indices selected by the player in the current drag, in order.
  List<int> selectedIndices = [];

  /// True for ~350 ms after a wrong attempt — drives the red-flash animation.
  bool flashWrong = false;

  // ── Derived ────────────────────────────────────────────────────────────────

  WordWhirlLevel get level => _level;
  int get wordIndex => _wordIndex;
  int get wordCount => _level.words.length;
  WordWhirlWord get currentWord => _level.words[_wordIndex];

  /// The next level for [locale], or null if on the last level.
  WordWhirlLevel? get nextLevel {
    final all = WordWhirlLevel.forLocale(locale);
    final idx = all.indexWhere((l) => l.number == _level.number);
    if (idx == -1 || idx == all.length - 1) return null;
    return all[idx + 1];
  }

  String get currentAttempt =>
      selectedIndices.map((i) => level.letterPool[i]).join();

  // ── Drag API ───────────────────────────────────────────────────────────────

  /// Called each time the drag enters a new letter's hit area.
  /// Repeated entry into the same letter (finger staying still) is ignored;
  /// revisiting a letter after leaving it adds it again (enabling "where": w-h-e-r-e).
  void onLetterEntered(int index) {
    if (state != WordWhirlState.playing) return;
    if (selectedIndices.isNotEmpty && selectedIndices.last == index) return;
    selectedIndices = List.from(selectedIndices)..add(index);
    notifyListeners();
  }

  /// Called when the player lifts their finger. Evaluates the current attempt.
  void onDragEnd() {
    if (state != WordWhirlState.playing) return;
    if (selectedIndices.isEmpty) return;

    if (currentAttempt.toLowerCase() == currentWord.word.toLowerCase()) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _handleCorrect() {
    score += 10;
    state = WordWhirlState.correct;
    AudioService.playCorrect('word_whirl');
    AudioService.hapticSuccess();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1800), () {
      selectedIndices = [];
      if (_wordIndex < level.words.length - 1) {
        _wordIndex++;
        state = WordWhirlState.playing;
      } else {
        state = WordWhirlState.complete;
      }
      notifyListeners();
    });
  }

  void _handleWrong() {
    flashWrong = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 400), () {
      flashWrong = false;
      selectedIndices = [];
      notifyListeners();
    });
  }

  // ── Public ─────────────────────────────────────────────────────────────────

  void setLevel(WordWhirlLevel level) {
    _level = level;
    _wordIndex = 0;
    score = 0;
    state = WordWhirlState.playing;
    selectedIndices = [];
    flashWrong = false;
    showLevelSelect = false;
    notifyListeners();
  }

  void showLevelSelection() {
    showLevelSelect = true;
    AudioService.playIntro('word_whirl', locale: locale);
    notifyListeners();
  }

  void restart() {
    _wordIndex = 0;
    score = 0;
    state = WordWhirlState.playing;
    selectedIndices = [];
    flashWrong = false;
    notifyListeners();
  }

  /// Clears the current attempt so the player can start spelling again.
  void clearAttempt() {
    if (state != WordWhirlState.playing) return;
    if (selectedIndices.isEmpty) return;
    selectedIndices = [];
    notifyListeners();
  }
}
