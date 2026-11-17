import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_stats_service.dart';
import '../models/school_layouts.dart';
import '../models/school_scene.dart';

/// Explore = tap anything to learn its name; find = "Can you find the...?".
enum SchoolExplorerMode { explore, find }

/// Result of the last tap in find mode, for the scene's flash/shake.
enum FindFeedback { none, correct, wrong }

/// State for School Explorer: which area is showing, what's selected, and
/// the "Can you find...?" rounds.
///
/// [locale] sets the UI text and speech language.
class SchoolExplorerProvider extends ChangeNotifier {
  final String locale;

  SchoolExplorerProvider({this.locale = 'en', math.Random? random})
    : _random = random ?? math.Random();

  final math.Random _random;
  final GameStatsService _statsService = GameStatsService();

  /// Rounds per "find it" game (capped by the area's distinct objects).
  static const int roundsPerGame = 5;

  static const String audioGameId = 'school_explorer';

  // ── Area & selection ──────────────────────────────────────────────────────

  SchoolArea _area = SchoolArea.classroom;
  SchoolArea get area => _area;
  SchoolScene get scene => SchoolLayouts.forArea(_area);

  SchoolObject? _selected;
  SchoolObject? get selected => _selected;

  /// Object name keys the child has tapped, per area, for the
  /// "things discovered" counter.
  final Map<SchoolArea, Set<String>> _discovered = {
    for (final a in SchoolArea.values) a: <String>{},
  };

  int discoveredCount(SchoolArea a) => _discovered[a]!.length;

  int totalToDiscover(SchoolArea a) =>
      SchoolLayouts.forArea(a).objects.map((o) => o.nameKey).toSet().length;

  // ── Mode & find game ──────────────────────────────────────────────────────

  SchoolExplorerMode _mode = SchoolExplorerMode.explore;
  SchoolExplorerMode get mode => _mode;

  List<String> _targets = [];
  int _round = 0;
  int _wrongThisRound = 0;

  int _score = 0;
  int get score => _score;

  int get roundNumber => _round + 1;
  int get totalRounds => _targets.length;

  /// Name key of the object to find, or null outside find mode / when done.
  String? get targetNameKey =>
      _mode == SchoolExplorerMode.find && _round < _targets.length
      ? _targets[_round]
      : null;

  bool get isFindComplete =>
      _mode == SchoolExplorerMode.find &&
      _targets.isNotEmpty &&
      _round >= _targets.length;

  FindFeedback _feedback = FindFeedback.none;
  FindFeedback get feedback => _feedback;

  /// Bumped on every find-mode tap so the scene can replay its animation
  /// even when two taps in a row give the same feedback.
  int _feedbackSerial = 0;
  int get feedbackSerial => _feedbackSerial;

  /// The object tapped last in find mode (flashed green or shaken).
  String? _feedbackObjectId;
  String? get feedbackObjectId => _feedbackObjectId;

  GameResult? _lastResult;
  GameResult? get lastResult => _lastResult;

  // ── Actions ───────────────────────────────────────────────────────────────

  void goTo(SchoolArea area) {
    if (area == _area) return;
    AudioService.stopAll();
    _area = area;
    _selected = null;
    _feedback = FindFeedback.none;
    _feedbackObjectId = null;
    if (_mode == SchoolExplorerMode.find) {
      _startFindGame();
    } else {
      AudioService.playInstructionClip(
        audioGameId,
        'area_${area.name}',
        locale: locale,
      );
    }
    notifyListeners();
  }

  void setMode(SchoolExplorerMode mode) {
    if (mode == _mode) return;
    AudioService.stopAll();
    _mode = mode;
    _selected = null;
    _feedback = FindFeedback.none;
    _feedbackObjectId = null;
    if (mode == SchoolExplorerMode.find) _startFindGame();
    notifyListeners();
  }

  void clearSelection() {
    if (_selected == null) return;
    _selected = null;
    notifyListeners();
  }

  void tapObject(SchoolObject object) {
    _discovered[_area]!.add(object.nameKey);
    if (_mode == SchoolExplorerMode.explore) {
      _selected = object;
      AudioService.stopAll();
      AudioService.playInstructionClip(
        audioGameId,
        _clipName(object.nameKey),
        locale: locale,
      );
      notifyListeners();
      return;
    }
    _checkFind(object);
  }

  /// Restarts the find game in the current area.
  void playAgain() {
    _startFindGame();
    notifyListeners();
  }

  /// Repeats the current "Can you find...?" prompt.
  Future<void> repeatPrompt() => _speakPrompt();

  // ── Internals ─────────────────────────────────────────────────────────────

  /// `school_explorer.object.whiteboard` → `whiteboard`, giving the clip
  /// `school_explorer_whiteboard.mp3`.
  static String _clipName(String nameKey) => nameKey.split('.').last;

  void _startFindGame() {
    final keys = scene.findableObjects.map((o) => o.nameKey).toSet().toList()
      ..shuffle(_random);
    _targets = keys.take(roundsPerGame).toList();
    _round = 0;
    _wrongThisRound = 0;
    _score = 0;
    _lastResult = null;
    _feedback = FindFeedback.none;
    _feedbackObjectId = null;
    _speakPrompt();
  }

  Future<void> _speakPrompt() async {
    final target = targetNameKey;
    if (target == null) return;
    await AudioService.stopAll();
    await AudioService.playInstructionClipAndWait(
      audioGameId,
      'find',
      locale: locale,
      isCancelled: () => targetNameKey != target,
    );
    if (targetNameKey != target) return;
    AudioService.playInstructionClip(
      audioGameId,
      _clipName(target),
      locale: locale,
    );
  }

  void _checkFind(SchoolObject object) {
    final target = targetNameKey;
    if (target == null) return;
    _feedbackSerial++;
    _feedbackObjectId = object.id;
    if (object.nameKey == target) {
      _feedback = FindFeedback.correct;
      if (_wrongThisRound == 0) _score++;
      AudioService.playCorrect(audioGameId);
      _round++;
      _wrongThisRound = 0;
      if (isFindComplete) {
        _recordResult();
      } else {
        // Give the chime a moment before asking for the next thing.
        final nextTarget = targetNameKey;
        Future.delayed(const Duration(milliseconds: 900), () {
          if (targetNameKey == nextTarget) _speakPrompt();
        });
      }
    } else {
      _feedback = FindFeedback.wrong;
      _wrongThisRound++;
      AudioService.playWrong(audioGameId);
      // Say what they tapped, so a wrong guess still teaches a word.
      Future.delayed(const Duration(milliseconds: 500), () {
        AudioService.playInstructionClip(
          audioGameId,
          _clipName(object.nameKey),
          locale: locale,
        );
      });
    }
    notifyListeners();
  }

  Future<void> _recordResult() async {
    try {
      _lastResult = await _statsService.recordGameResult(
        GameIds.schoolExplorer,
        _score,
        level: _area.index + 1,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('SchoolExplorer: failed to record result: $e');
    }
  }
}
