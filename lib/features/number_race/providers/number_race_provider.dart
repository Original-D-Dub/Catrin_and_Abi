import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../shared/services/game_stats_service.dart';
import '../models/number_race_models.dart';

/// Game logic for Number Race.
///
/// The player picks a racer (Gary, Pero or JamJam) and then answers a
/// series of "how many dots?" questions using BSL number signs. A correct
/// answer moves the player's racer forward; a wrong answer moves the other
/// two racers forward instead. The player wins as soon as they reach
/// [raceLength] correct answers — the race never ends in a loss, the other
/// racers simply catch up (and stop at the finish line).
class NumberRaceProvider extends ChangeNotifier {
  NumberRaceProvider({this.locale = 'en'});

  /// UI locale ('en' or 'cy').
  final String locale;

  /// Number of correct answers needed to win the race.
  static const int raceLength = 5;

  /// Number of cells in the dot grid (3 columns x 2 rows).
  static const int dotGridSize = 6;

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();

  bool _showCharacterSelect = true;
  bool get showCharacterSelect => _showCharacterSelect;

  RaceCharacter? _playerCharacter;
  RaceCharacter? get playerCharacter => _playerCharacter;

  /// Progress (0..[raceLength]) for every racer, keyed by character.
  final Map<RaceCharacter, int> progress = {
    for (final character in RaceCharacter.values) character: 0,
  };

  /// Number of correct answers the player has given so far.
  int score = 0;

  /// Total number of answers (correct + incorrect) given this game.
  int attempts = 0;

  /// The number of dots shown in the current round (0..[dotGridSize]).
  int currentDotCount = -1;

  /// Which of the 6 grid cells currently show a dot.
  List<bool> dotCells = List.filled(dotGridSize, false);

  /// The 3 BSL number options shown to the player this round.
  List<int> answerOptions = const [];

  /// Result of [GameStatsService.recordGameResult] once the race is won.
  GameResult? lastResult;

  bool get isWon => score >= raceLength;

  /// Racers other than the player's chosen character.
  List<RaceCharacter> get opponents =>
      RaceCharacter.values.where((c) => c != _playerCharacter).toList();

  void selectCharacter(RaceCharacter character) {
    _playerCharacter = character;
    _showCharacterSelect = false;
    notifyListeners();
  }

  void showCharacterSelection() {
    _showCharacterSelect = true;
    notifyListeners();
  }

  /// Resets the race and generates the first question.
  void startGame() {
    score = 0;
    attempts = 0;
    lastResult = null;
    for (final character in RaceCharacter.values) {
      progress[character] = 0;
    }
    _nextRound();
    notifyListeners();
  }

  /// Called when the player taps a BSL number answer.
  void selectAnswer(int answer) {
    if (isWon) return;

    attempts++;
    if (answer == currentDotCount) {
      score++;
      progress[_playerCharacter!] =
          (progress[_playerCharacter!]! + 1).clamp(0, raceLength);
    } else {
      for (final opponent in opponents) {
        progress[opponent] = (progress[opponent]! + 1).clamp(0, raceLength);
      }
    }

    if (isWon) {
      _recordResult();
    } else {
      _nextRound();
    }
    notifyListeners();
  }

  void _nextRound() {
    int next;
    do {
      next = _random.nextInt(dotGridSize + 1);
    } while (next == currentDotCount);
    currentDotCount = next;

    final cellOrder = List.generate(dotGridSize, (i) => i)..shuffle(_random);
    dotCells = List.filled(dotGridSize, false);
    for (int i = 0; i < currentDotCount; i++) {
      dotCells[cellOrder[i]] = true;
    }

    _buildOptions();
  }

  void _buildOptions() {
    final options = <int>{currentDotCount};
    int attemptsToBuild = 0;
    while (options.length < 3 && attemptsToBuild < 100) {
      attemptsToBuild++;
      options.add(_random.nextInt(dotGridSize + 1));
    }
    answerOptions = options.toList()..shuffle(_random);
  }

  Future<void> _recordResult() async {
    final result = await _statsService.recordGameResult(
      GameIds.numberRace,
      attempts,
      higherIsBetter: false,
    );
    lastResult = result;
    notifyListeners();
  }
}
