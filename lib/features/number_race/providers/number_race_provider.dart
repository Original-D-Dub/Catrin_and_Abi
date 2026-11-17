import 'dart:async';
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
///
/// Independently of the player's answers, every [opponentTickInterval] one
/// or both opponents also creep forward by one space, adding time pressure
/// — except on level 1, a gentle warm-up where opponents only move when the
/// player answers wrongly.
///
/// After picking a racer, the player chooses a level (1-[totalLevels]) from
/// a map screen. After the level 1 warm-up, levels are grouped into
/// sections of [levelsPerSection]: within each section
/// [opponentTickInterval] shortens (7s, 5s, 3s, 3s) and the last level
/// times the player, recording how long the race took instead of their
/// number of attempts. Dots are shown in the counting
/// game's near-equal "five" patterns: a die face for 1-5, and two rows
/// split by a dividing line for 6-10 (3 over 3, 3 over 4, ... 5 over 5).
/// Levels 1-2 ask about 1-5 dots, level 3 about 1-6, levels 4-5 about 1-8
/// and levels 6-13 about 1-10.
class NumberRaceProvider extends ChangeNotifier {
  NumberRaceProvider({this.locale = 'en'});

  /// UI locale ('en' or 'cy').
  final String locale;

  /// Number of correct answers needed to win the race at [level].
  int get raceLength => level == 5 ? 10 : 5;

  /// Number of levels in each of the first two sections.
  static const int levelsPerSection = 4;

  /// Total number of playable levels: the level 1 warm-up plus three
  /// sections.
  /// Dot ranges are set per level in [maxQuestionValue].
  static const int totalLevels = 13;

  /// Returns true when [lvl] is the last (timed) level of its section.
  static bool isSectionEnd(int lvl) => lvl == 5 || lvl == 9 || lvl == 13;

  final Random _random = Random();
  final GameStatsService _statsService = GameStatsService();
  Timer? _opponentTimer;
  Timer? _displayTimer;
  final Stopwatch _stopwatch = Stopwatch();

  bool _showCharacterSelect = true;
  bool get showCharacterSelect => _showCharacterSelect;

  bool _showLevelMap = false;
  bool get showLevelMap => _showLevelMap;

  /// Selected level (1-[totalLevels]), chosen on the level map.
  int level = 1;

  /// Called with the level number when the player's race finishes — the
  /// screen uses it to move the player on along the level map.
  ValueChanged<int>? onRaceFinished;

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

  /// The number of dots shown in the current round (1..[maxQuestionValue]),
  /// or -1 before the first round.
  int currentDotCount = -1;

  /// The 3 BSL number options shown to the player this round.
  List<int> answerOptions = const [];

  /// Result of [GameStatsService.recordGameResult] once the race is won.
  GameResult? lastResult;

  /// Order in which racers have reached [raceLength], for the podium.
  final List<RaceCharacter> _finishOrder = [];

  bool get isWon => score >= raceLength;

  /// 1-based number of the question being asked, for the header's
  /// "Question N of [raceLength]". Only correct answers move it on, and it
  /// stays at [raceLength] once the race is won.
  int get questionNumber => (score + 1).clamp(1, raceLength);

  /// Position of [level] within its section (1-indexed).
  int get _sectionLevel {
    if (level <= 1) return 1; // level 1 warm-up
    if (level <= 5) return level - 1; // section 1: levels 2-5 → 1-4
    if (level <= 9) return level - 5; // section 2: levels 6-9 → 1-4
    return level - 9; // section 3: levels 10-13 → 1-4
  }

  /// Highest number a question can ask for at [level].
  int get maxQuestionValue => switch (level) {
    1 || 2 => 5,
    3 => 6,
    4 || 5 => 8,
    _ => 10,
  };

  /// Whether the answer buttons show the digit under each BSL sign. Levels
  /// 10-13 hide it, so the player has to read the sign alone.
  bool get showAnswerDigits => level < 10;

  /// Whether opponents creep forward on their own every
  /// [opponentTickInterval]. Off on the level 1 warm-up, where they only
  /// move when the player answers wrongly.
  bool get opponentsMoveOnTimer => level != 1;

  /// Whether the current level times the player and records that time
  /// instead of their number of attempts.
  bool get isTimedLevel => isSectionEnd(level);

  /// Time elapsed since [startGame] for a timed level — frozen once won.
  Duration get elapsedTime => _stopwatch.elapsed;

  /// How often the opponents creep forward on their own — shortens through
  /// each section.
  Duration get opponentTickInterval {
    switch (_sectionLevel) {
      case 1:
        return const Duration(seconds: 15);
      case 2:
        return const Duration(seconds: 10);
      case 3:
        return const Duration(seconds: 7);
      case 4:
        return const Duration(seconds: 5);
      case 5:
        return const Duration(seconds: 3);
      default:
        return const Duration(seconds: 7);
    }
  }

  /// Racers other than the player's chosen character.
  List<RaceCharacter> get opponents =>
      RaceCharacter.values.where((c) => c != _playerCharacter).toList();

  /// Final 1st/2nd/3rd standings, in the order racers reached the finish
  /// line — racers still short of the finish line are ranked after by
  /// remaining progress.
  List<RaceCharacter> get standings {
    final remaining =
        RaceCharacter.values
            .where((character) => !_finishOrder.contains(character))
            .toList()
          ..sort((a, b) => progress[b]!.compareTo(progress[a]!));
    return [..._finishOrder, ...remaining];
  }

  void selectCharacter(RaceCharacter character) {
    _playerCharacter = character;
    _showCharacterSelect = false;
    _showLevelMap = true;
    notifyListeners();
  }

  /// Called when the player taps a level on the level map.
  void selectLevel(int level) {
    this.level = level;
    _showLevelMap = false;
    resetForIntro();
  }

  /// Clears score, progress and the current question, without starting the
  /// opponent timer or stopwatch early — those only start once [startGame]
  /// runs at the end of the countdown. Called whenever a fresh race is
  /// about to begin (picking a level, Play Again, Next Level) so the race
  /// is already reset by the time the intro countdown appears, instead of
  /// showing stale state from the previous race through it.
  void resetForIntro() {
    score = 0;
    attempts = 0;
    lastResult = null;
    currentDotCount = -1;
    answerOptions = const [];
    _finishOrder.clear();
    for (final character in RaceCharacter.values) {
      progress[character] = 0;
    }
    _stopOpponentTimer();
    _stopDisplayTimer();
    _stopwatch
      ..stop()
      ..reset();
    notifyListeners();
  }

  /// Returns to the level map (e.g. from Next Level), with the race
  /// stopped.
  void showLevelMapScreen() {
    _showCharacterSelect = false;
    _showLevelMap = true;
    _stopOpponentTimer();
    _stopDisplayTimer();
    _stopwatch
      ..stop()
      ..reset();
    notifyListeners();
  }

  void showCharacterSelection() {
    _showCharacterSelect = true;
    _showLevelMap = false;
    _stopOpponentTimer();
    _stopDisplayTimer();
    _stopwatch
      ..stop()
      ..reset();
    notifyListeners();
  }

  /// Starts the race: generates the first question and starts timers.
  /// Score, progress and the current question are already cleared by
  /// [resetForIntro], called before the intro countdown begins.
  void startGame() {
    _nextRound();
    if (opponentsMoveOnTimer) _startOpponentTimer();
    if (isTimedLevel) {
      _stopwatch
        ..reset()
        ..start();
      _startDisplayTimer();
    }
    notifyListeners();
  }

  /// Called when the player taps a BSL number answer.
  void selectAnswer(int answer) {
    if (isWon) return;

    attempts++;
    if (answer == currentDotCount) {
      score++;
      progress[_playerCharacter!] = (progress[_playerCharacter!]! + 1).clamp(
        0,
        raceLength,
      );
      _checkFinish(_playerCharacter!);
    } else {
      for (final opponent in opponents) {
        progress[opponent] = (progress[opponent]! + 1).clamp(0, raceLength);
        _checkFinish(opponent);
      }
    }

    if (isWon) {
      _stopOpponentTimer();
      _stopwatch.stop();
      _stopDisplayTimer();
      _recordResult();
      onRaceFinished?.call(level);
    } else {
      _nextRound();
    }
    notifyListeners();
  }

  /// Starts the periodic timer that creeps the opponents forward on their
  /// own, independent of the player's answers.
  void _startOpponentTimer() {
    _opponentTimer?.cancel();
    _opponentTimer = Timer.periodic(
      opponentTickInterval,
      (_) => _advanceOpponents(),
    );
  }

  void _stopOpponentTimer() {
    _opponentTimer?.cancel();
    _opponentTimer = null;
  }

  /// Moves either one (randomly chosen) or both opponents forward one space.
  void _advanceOpponents() {
    if (isWon) {
      _stopOpponentTimer();
      return;
    }

    final movingOpponents = _random.nextBool()
        ? opponents
        : [opponents[_random.nextInt(opponents.length)]];
    for (final opponent in movingOpponents) {
      progress[opponent] = (progress[opponent]! + 1).clamp(0, raceLength);
      _checkFinish(opponent);
    }
    notifyListeners();
  }

  /// Records [character] as having reached the finish line, the first
  /// time its progress reaches [raceLength].
  void _checkFinish(RaceCharacter character) {
    if (progress[character] == raceLength &&
        !_finishOrder.contains(character)) {
      _finishOrder.add(character);
    }
  }

  /// Ticks once a second so a timed level's timer display stays current.
  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  void _stopDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = null;
  }

  @override
  void dispose() {
    _stopOpponentTimer();
    _stopDisplayTimer();
    super.dispose();
  }

  void _nextRound() {
    int next;
    do {
      next = _random.nextInt(maxQuestionValue) + 1;
    } while (next == currentDotCount);
    currentDotCount = next;

    _buildOptions();
  }

  void _buildOptions() {
    final options = <int>{currentDotCount};
    int attemptsToBuild = 0;
    while (options.length < 3 && attemptsToBuild < 100) {
      attemptsToBuild++;
      options.add(_random.nextInt(maxQuestionValue) + 1);
    }
    answerOptions = options.toList()..shuffle(_random);
  }

  Future<void> _recordResult() async {
    final value = isTimedLevel ? _stopwatch.elapsed.inSeconds : attempts;
    final result = await _statsService.recordGameResult(
      GameIds.numberRace,
      value,
      level: level,
      higherIsBetter: false,
    );
    lastResult = result;
    notifyListeners();
  }
}
