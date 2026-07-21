import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/mixins/elapsed_timer_mixin.dart';
import '../models/enclosure_level_config.dart';

/// State for a side-scrolling enclosure walk level (aquarium,
/// reptile house).
///
/// Plays the same BSL video quiz as the zoo's map levels: each question
/// is a video naming one enclosure's animal; the player must walk to that
/// enclosure and take a picture. A correct picture reveals the animal's
/// photo and moves on to the next question; the level ends after
/// [questionCount] correct answers.
///
/// The Flame game reports which enclosure (if any) the player has stopped
/// in front of; the screen shows the Take a Picture button in response and
/// calls [takeQuizPicture] when it's pressed.
///
/// [locale] and [signSystem] are independent axes (see
/// bilingual-sign-game-structure). The walk itself only uses [locale];
/// [signSystem] is carried so enclosure content can show BSL or IAC signs
/// once the placeholder windows get real media.
class EnclosureWalkProvider extends ChangeNotifier with ElapsedTimerMixin {
  /// Which building this walk is (enclosure list, colours).
  final EnclosureLevelConfig config;

  /// UI language ('en' or 'cy'), passed to AppLocalizations by the screen.
  final String locale;

  /// Which sign alphabet future enclosure content should use.
  final SignSystem signSystem;

  /// This level's number, shown in the header bar.
  final int levelNumber;

  /// How many video questions make up one playthrough.
  final int questionCount;

  final Random _random;

  late List<EnclosureSpec> _questions;
  int _currentIndex = 0;
  EnclosureSpec? _activeEnclosure;
  EnclosureSpec? _lastCaptured;
  final Set<String> _photographed = {};

  EnclosureWalkProvider({
    required this.config,
    this.locale = 'en',
    this.signSystem = SignSystem.bsl,
    this.levelNumber = 1,
    int questionCount = 3,
    Random? random,
  })  : questionCount = min(questionCount, config.enclosures.length),
        _random = random ?? Random() {
    _questions = _drawQuestions();
    startTimer();
  }

  /// [questionCount] distinct enclosures drawn from [config], in the
  /// order they will be asked.
  List<EnclosureSpec> get questions => List.unmodifiable(_questions);

  /// The enclosure the current BSL video asks for, or null once the
  /// level is complete.
  EnclosureSpec? get currentQuestion =>
      isComplete ? null : _questions[_currentIndex];

  /// How many questions have been answered correctly so far.
  int get answeredCount => _currentIndex;

  /// Whether all [questionCount] questions have been answered.
  bool get isComplete => _currentIndex >= _questions.length;

  /// The enclosure captured by the most recent correct picture — what the
  /// photo reveal shows.
  EnclosureSpec? get lastCaptured => _lastCaptured;

  /// The enclosure the player is currently stopped in front of, or null
  /// while they are walking / between enclosures.
  EnclosureSpec? get activeEnclosure => _activeEnclosure;

  /// Whether the enclosure with [id] has already been correctly
  /// photographed — drives the tick badge on its window.
  bool isPhotographed(String id) => _photographed.contains(id);

  /// Called by the game whenever the player stops in front of an
  /// enclosure or starts moving again.
  void setActiveEnclosure(EnclosureSpec? spec) {
    if (_activeEnclosure?.id == spec?.id) return;
    _activeEnclosure = spec;
    notifyListeners();
  }

  /// Takes a picture of the enclosure the player is standing in front of.
  ///
  /// Returns true when it is the current question's animal (the question
  /// advances), false for the wrong animal, and null when the player is
  /// not in front of an enclosure or the level is already complete.
  bool? takeQuizPicture() {
    final spec = _activeEnclosure;
    final question = currentQuestion;
    if (spec == null || question == null) return null;

    if (spec.id != question.id) return false;

    _photographed.add(spec.id);
    _lastCaptured = spec;
    _currentIndex++;
    if (isComplete) stopTimer();
    notifyListeners();
    return true;
  }

  /// Starts a fresh playthrough with newly drawn questions (Play Again).
  void reset() {
    _questions = _drawQuestions();
    _currentIndex = 0;
    _lastCaptured = null;
    _photographed.clear();
    startTimer();
    notifyListeners();
  }

  List<EnclosureSpec> _drawQuestions() =>
      (config.enclosures.toList()..shuffle(_random)).sublist(0, questionCount);
}
