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
/// instead of their number of attempts. The dot grid is a plain 3x2 grid
/// for levels 1-[levelsPerSection]; from there on dots are arranged like a
/// die face in a 3x3 grid, shown as a single grid (dots 1-6) for the next
/// section and as two grids side by side, domino-style (dots 1-10), for
/// the last.
class NumberRaceProvider extends ChangeNotifier {
  NumberRaceProvider({this.locale = 'en'});

  /// UI locale ('en' or 'cy').
  final String locale;

  /// Number of correct answers needed to win the race.
  static const int raceLength = 5;

  /// Number of levels in each of the first two sections.
  static const int levelsPerSection = 4;

  /// Total number of playable levels across all three sections.
  /// Section 1 (levels 1-4): plain 3×2 grid, dots 1-6.
  /// Section 2 (levels 5-8): single 3×3 die-face grid, dots 1-6.
  /// Section 3 (levels 9-12): two 3×3 die-face grids side by side
  /// (domino-style), dots 1-10.
  static const int totalLevels = 12;

  /// Row-major dot positions within a 3×3 grid for each die/domino face
  /// value 0-6 — the standard six-sided-die pip layout (1 in the centre, 2
  /// on the diagonal, and so on up to 6 as two columns of three).
  static const Map<int, List<int>> _diePipPositions = {
    0: [],
    1: [4],
    2: [2, 6],
    3: [2, 4, 6],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  };

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

  /// The number of dots shown in the current round (0..[maxQuestionValue]).
  int currentDotCount = -1;

  /// Which cells of each board currently show a dot — one board normally,
  /// two side by side (domino-style) for levels 9-12. Resized by
  /// [_nextRound] to [boardCount] boards of [gridColumns] * [gridRows]
  /// cells each for the current level.
  List<List<bool>> dotCells = [List.filled(6, false)];

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

  /// Number of columns in each dot board — always 3.
  int get gridColumns => 3;

  /// Number of rows in each dot board: 2 for the plain grid of levels 1-4,
  /// 3 (a die face) from level 5 onward.
  int get gridRows => level <= 4 ? 2 : 3;

  /// Number of separate dot boards shown for [level] — a single board,
  /// except levels 9-12 which show two side by side, domino-style.
  int get boardCount => level > 8 ? 2 : 1;

  /// Highest number a question can ask for at [level].
  int get maxQuestionValue => level > 8 ? 10 : 6;

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
    dotCells = _emptyBoards();
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

  /// A fresh, all-empty set of [boardCount] boards for the current level.
  List<List<bool>> _emptyBoards() =>
      List.generate(boardCount, (_) => List.filled(gridColumns * gridRows, false));

  void _nextRound() {
    int next;
    do {
      next = _random.nextInt(maxQuestionValue) + 1;
    } while (next == currentDotCount);
    currentDotCount = next;

    dotCells = _emptyBoards();

    if (level <= 4) {
      // Dots fill the grid column by column (top to bottom within each
      // column, then moving to the next column) rather than row by row.
      for (int i = 0; i < currentDotCount; i++) {
        final column = i ~/ gridRows;
        final row = i % gridRows;
        dotCells[0][row * gridColumns + column] = true;
      }
    } else if (boardCount == 1) {
      // Single die-face board (levels 5-8).
      for (final index in _diePipPositions[currentDotCount]!) {
        dotCells[0][index] = true;
      }
    } else {
      // Two die-face boards side by side, domino-style (levels 9-12).
      final (left, right) = _splitDominoValue(currentDotCount);
      for (final index in _diePipPositions[left]!) {
        dotCells[0][index] = true;
      }
      for (final index in _diePipPositions[right]!) {
        dotCells[1][index] = true;
      }
    }

    _buildOptions();
  }

  /// Splits a domino total into two random halves, each 0-6, matching how a
  /// real double-six domino set represents that total (e.g. 6 could be
  /// shown as 0-6, 1-5, 2-4 or 3-3).
  (int, int) _splitDominoValue(int total) {
    final minLeft = max(0, total - 6);
    final maxLeft = min(6, total);
    final left = minLeft + _random.nextInt(maxLeft - minLeft + 1);
    return (left, total - left);
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
