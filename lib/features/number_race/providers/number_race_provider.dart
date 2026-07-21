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
/// or both opponents also creep forward by one space, adding time pressure.
///
/// After picking a racer, the player chooses a level (1-[totalLevels]) from
/// a map screen. Levels are grouped into sections of [levelsPerSection]:
/// within each section [opponentTickInterval] shortens (7s, 5s, 3s, 3s)
/// and the last level times the player, recording how long the race took
/// instead of their number of attempts. The dot grid is 3x2 for levels
/// 1-[levelsPerSection] and 4x2 for the next section.
class NumberRaceProvider extends ChangeNotifier {
  NumberRaceProvider({this.locale = 'en'});

  /// UI locale ('en' or 'cy').
  final String locale;

  /// Number of correct answers needed to win the race.
  static const int raceLength = 5;

  /// Number of levels in each of the first two sections.
  static const int levelsPerSection = 4;

  /// Total number of playable levels across all three sections.
  /// Section 1 (levels 1-4): 3×2 grid, dots 1-6.
  /// Section 2 (levels 5-8): 4×2 grid, dots 1-8.
  /// Section 3 (levels 9-12): 5×2 grid, dots 1-10.
  static const int totalLevels = 12;

  /// Returns true when [lvl] is the last (timed) level of its section.
  static bool isSectionEnd(int lvl) => lvl == 4 || lvl == 8 || lvl == 12;

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

  /// Which grid cells currently show a dot — resized by [_nextRound] to
  /// [dotGridSize] for the current level.
  List<bool> dotCells = List.filled(8, false);

  /// The 3 BSL number options shown to the player this round.
  List<int> answerOptions = const [];

  /// Result of [GameStatsService.recordGameResult] once the race is won.
  GameResult? lastResult;

  /// Order in which racers have reached [raceLength], for the podium.
  final List<RaceCharacter> _finishOrder = [];

  bool get isWon => score >= raceLength;

  /// Position of [level] within its section (1-indexed).
  int get _sectionLevel {
    if (level <= 4) return level;
    if (level <= 8) return level - 4;
    return level - 8; // section 3: levels 9-12 → 1-4
  }

  /// Number of columns in the dot grid for [level].
  int get gridColumns {
    if (level <= 4) return 3;
    if (level <= 8) return 4;
    return 5;
  }

  /// Number of cells in the dot grid for [level] (2 rows of [gridColumns]).
  int get dotGridSize => gridColumns * 2;

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
        return const Duration(seconds: 7);
      case 2:
        return const Duration(seconds: 5);
      case 3:
        return const Duration(seconds: 3);
      default:
        return const Duration(seconds: 3);
    }
  }

  /// Racers other than the player's chosen character.
  List<RaceCharacter> get opponents =>
      RaceCharacter.values.where((c) => c != _playerCharacter).toList();

  /// Final 1st/2nd/3rd standings, in the order racers reached the finish
  /// line — racers still short of the finish line are ranked after by
  /// remaining progress.
  List<RaceCharacter> get standings {
    final remaining = RaceCharacter.values
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
    dotCells = List.filled(dotGridSize, false);
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
    _startOpponentTimer();
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
      progress[_playerCharacter!] =
          (progress[_playerCharacter!]! + 1).clamp(0, raceLength);
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
    } else {
      _nextRound();
    }
    notifyListeners();
  }

  /// Starts the periodic timer that creeps the opponents forward on their
  /// own, independent of the player's answers.
  void _startOpponentTimer() {
    _opponentTimer?.cancel();
    _opponentTimer = Timer.periodic(opponentTickInterval, (_) => _advanceOpponents());
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
    if (progress[character] == raceLength && !_finishOrder.contains(character)) {
      _finishOrder.add(character);
    }
  }

  /// Ticks once a second so a timed level's timer display stays current.
  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
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
      next = _random.nextInt(dotGridSize) + 1;
    } while (next == currentDotCount);
    currentDotCount = next;

    // Dots fill the grid column by column (top to bottom within each
    // column, then moving to the next column) rather than row by row.
    dotCells = List.filled(dotGridSize, false);
    const rows = 2;
    for (int i = 0; i < currentDotCount; i++) {
      final column = i ~/ rows;
      final row = i % rows;
      dotCells[row * gridColumns + column] = true;
    }

    _buildOptions();
  }

  void _buildOptions() {
    final options = <int>{currentDotCount};
    int attemptsToBuild = 0;
    while (options.length < 3 && attemptsToBuild < 100) {
      attemptsToBuild++;
      options.add(_random.nextInt(dotGridSize) + 1);
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
