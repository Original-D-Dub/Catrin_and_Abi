import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/mixins/elapsed_timer_mixin.dart';
import '../models/zoo_animal_zone.dart';

/// State for the zoo's level 1: the BSL video photo quiz, played as a
/// walk-around on the zoo map.
///
/// Each question is a BSL video naming one animal; the player must walk
/// to that animal's enclosure ([ZooAnimalZone]) and take a picture. A
/// correct picture reveals the animal's photo and moves on to the next
/// question; the quiz ends after [questionCount] correct answers.
///
/// The game reports which animal zone (if any) the player is standing in
/// via [setActiveZone]; the screen shows the Take a Picture button in
/// response and calls [takeQuizPicture] when it's pressed.
class ZooQuizProvider extends ChangeNotifier with ElapsedTimerMixin {
  /// UI language ('en' or 'cy'), passed to AppLocalizations by the screen.
  final String locale;

  /// Which sign alphabet the question videos use.
  final SignSystem signSystem;

  /// The character chosen on the pick-a-player screen, drawn by the game.
  final String characterId;

  /// This level's number, shown in the header bar.
  final int levelNumber;

  /// The animal zones this level plays over ([ZooAnimalZone.all] for the
  /// zoo level, [ZooAnimalZone.farm] for the farm level) — questions are
  /// drawn from these and the game only reacts to these.
  final List<ZooAnimalZone> zones;

  /// How many video questions make up one playthrough.
  final int questionCount;

  final Random _random;

  late List<ZooAnimalZone> _questions;
  int _currentIndex = 0;
  ZooAnimalZone? _activeZone;
  ZooAnimalZone? _lastCaptured;

  ZooQuizProvider({
    this.locale = 'en',
    this.signSystem = SignSystem.bsl,
    this.characterId = 'abi',
    this.levelNumber = 1,
    this.zones = ZooAnimalZone.all,
    int questionCount = 3,
    Random? random,
  })  : questionCount = min(questionCount, _uniqueAnimalIds(zones).length),
        _random = random ?? Random() {
    _questions = _drawQuestions();
    startTimer();
  }

  /// [questionCount] distinct animals drawn from [zones], in the order
  /// they will be asked.
  List<ZooAnimalZone> get questions => List.unmodifiable(_questions);

  /// The [zones] entries whose [ZooAnimalZone.id] hasn't been seen yet, in
  /// list order — some animals (e.g. hippo) have more than one trigger
  /// zone sharing the same id for different photo spots, but should still
  /// only ever be asked about once per playthrough.
  static List<ZooAnimalZone> _uniqueAnimalIds(List<ZooAnimalZone> zones) {
    final seenIds = <String>{};
    return [
      for (final zone in zones)
        if (seenIds.add(zone.id)) zone,
    ];
  }

  /// The animal the current BSL video asks for, or null once the quiz is
  /// complete.
  ZooAnimalZone? get currentQuestion =>
      isComplete ? null : _questions[_currentIndex];

  /// How many questions have been answered correctly so far.
  int get answeredCount => _currentIndex;

  /// Whether all [questionCount] questions have been answered.
  bool get isComplete => _currentIndex >= _questions.length;

  /// The animal captured by the most recent correct picture — what the
  /// photo reveal shows.
  ZooAnimalZone? get lastCaptured => _lastCaptured;

  /// The animal zone the player is currently standing in, or null while
  /// they are on open walkway.
  ZooAnimalZone? get activeZone => _activeZone;

  /// Called by the game whenever the player enters or leaves an animal
  /// zone.
  void setActiveZone(ZooAnimalZone? zone) {
    if (_activeZone?.id == zone?.id) return;
    _activeZone = zone;
    notifyListeners();
  }

  /// Takes a picture of the animal zone the player is standing in.
  ///
  /// Returns true when it is the current question's animal (the question
  /// advances), false for the wrong animal, and null when the player is
  /// not in a zone or the quiz is already complete.
  bool? takeQuizPicture() {
    final zone = _activeZone;
    final question = currentQuestion;
    if (zone == null || question == null) return null;

    if (zone.id != question.id) return false;

    _lastCaptured = zone;
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
    startTimer();
    notifyListeners();
  }

  List<ZooAnimalZone> _drawQuestions() =>
      (_uniqueAnimalIds(zones)..shuffle(_random)).sublist(0, questionCount);
}
