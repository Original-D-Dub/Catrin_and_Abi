import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/tts_helper.dart';
import '../models/hand_landmark_data.dart';
import '../services/hand_tracking_service.dart';

/// Level definition for the Camera Vowels game.
class CameraVowelsLevel {
  final int number;
  final String name;
  final String description;

  const CameraVowelsLevel({
    required this.number,
    required this.name,
    required this.description,
  });

  static const List<CameraVowelsLevel> all = [
    CameraVowelsLevel(
      number: 1,
      name: 'Practice',
      description: 'Touch each fingertip to hear its vowel sound',
    ),
    CameraVowelsLevel(
      number: 2,
      name: 'Challenge',
      description: 'Touch the correct fingertip for the vowel shown',
    ),
  ];
}

/// Game states for the Camera Vowels game.
enum CameraVowelsGameState { idle, playing, permissionDenied }

/// State manager for the BSL Camera Vowels game.
///
/// Coordinates between [HandTrackingService] landmark stream, proximity
/// detection logic, TTS output, and UI state.
///
/// **Level 1 – Practice**: all five fingertips are active; touching any
/// one speaks its vowel (a/e/i/o/u).
///
/// **Level 2 – Challenge**: a target vowel is shown; only the matching
/// fingertip triggers a correct response and scores a point. Touching a
/// wrong fingertip shows a brief red flash without scoring.
class CameraVowelsProvider extends ChangeNotifier {
  CameraVowelsProvider() {
    _initTts();
  }

  // ── Services ──────────────────────────────────────────────────────────────

  late final HandTrackingService _trackingService =
  HandTrackingService.create();
  final FlutterTts _tts = FlutterTts();
  StreamSubscription<List<HandLandmarkData>>? _landmarkSub;

  // ── Level / screen state ──────────────────────────────────────────────────

  bool _showLevelSelect = true;
  bool get showLevelSelect => _showLevelSelect;

  CameraVowelsLevel _currentLevel = CameraVowelsLevel.all[0];
  CameraVowelsLevel get currentLevel => _currentLevel;

  CameraVowelsGameState _gameState = CameraVowelsGameState.idle;
  CameraVowelsGameState get gameState => _gameState;

  // ── Score ─────────────────────────────────────────────────────────────────

  int _score = 0;
  int get score => _score;

  // ── Tracking state ────────────────────────────────────────────────────────

  /// Normalised (0–1) screen position of the right-hand index fingertip.
  /// Null when no right hand is detected.
  Offset? _cursorPosition;
  Offset? get cursorPosition => _cursorPosition;

  /// Index into [kFingertipIndices] that is currently "lit up" (just touched),
  /// or null when no fingertip is active.
  int? _activeFingertipIndex;
  int? get activeFingertipIndex => _activeFingertipIndex;

  /// Fingertip index that was last touched incorrectly (Level 2 only).
  int? _wrongFingertipIndex;
  int? get wrongFingertipIndex => _wrongFingertipIndex;

  /// Level 2: the vowel the player must currently find.
  String? _targetVowel;
  String? get targetVowel => _targetVowel;

  /// Per-fingertip cooldown — prevents re-triggering the same fingertip
  /// within 1.5 s of a successful touch.
  final Set<int> _cooledDown = {};
  final Map<int, Timer> _cooldownTimers = {};

  // ── Normalised proximity threshold ────────────────────────────────────────

  /// Right index tip must be within this normalised distance of a left
  /// fingertip to register a touch (≈ 6 % of frame width/height).
  static const double _touchThreshold = 0.06;

  /// Duration a fingertip stays "lit up" after a successful touch.
  static const Duration _highlightDuration = Duration(milliseconds: 600);

  /// Cooldown between touches on the same fingertip.
  static const Duration _cooldownDuration = Duration(milliseconds: 1500);

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    await TtsHelper.configure(_tts);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void showLevelSelection() {
    _stopTracking();
    _showLevelSelect = true;
    _gameState = CameraVowelsGameState.idle;
    _resetRoundState();
    notifyListeners();
  }

  Future<void> selectLevel(int levelNumber) async {
    _currentLevel = CameraVowelsLevel.all.firstWhere(
      (l) => l.number == levelNumber,
      orElse: () => CameraVowelsLevel.all[0],
    );
    _showLevelSelect = false;
    _score = 0;
    _resetRoundState();

    if (_currentLevel.number == 2) {
      _pickNextTargetVowel();
    }

    final started = await _requestPermissionAndStart();
    if (!started) {
      _gameState = CameraVowelsGameState.permissionDenied;
    } else {
      _gameState = CameraVowelsGameState.playing;
    }
    notifyListeners();
  }

  // ── Camera permission + tracking ──────────────────────────────────────────

  Future<bool> _requestPermissionAndStart() async {
    if (kIsWeb) return false;
    final status = await Permission.camera.request();
    if (!status.isGranted) return false;
    await _trackingService.start();
    _landmarkSub = _trackingService.landmarkStream.listen(_onLandmarks);
    return true;
  }

  void _stopTracking() {
    _landmarkSub?.cancel();
    _landmarkSub = null;
    _trackingService.stop();
  }

  // ── Landmark processing ───────────────────────────────────────────────────

  void _onLandmarks(List<HandLandmarkData> hands) {
    if (_gameState != CameraVowelsGameState.playing) return;

    final leftHand = hands.where((h) => h.isLeftHand).firstOrNull;
    final rightHand = hands.where((h) => !h.isLeftHand).firstOrNull;

    // Update cursor position from right index fingertip.
    final newCursor = rightHand?.indexTip;
    if (newCursor != _cursorPosition) {
      _cursorPosition = newCursor;
      notifyListeners();
    }

    if (leftHand == null || rightHand == null) return;

    final rightTip = rightHand.landmark(kIndexTip);

    for (final fingertipIndex in kFingertipIndices) {
      if (_cooledDown.contains(fingertipIndex)) continue;

      final leftTip = leftHand.landmark(fingertipIndex);
      final distance = (rightTip - leftTip).distance;

      if (distance < _touchThreshold) {
        _onFingertipTouched(fingertipIndex);
        break; // only one touch per frame
      }
    }
  }

  void _onFingertipTouched(int fingertipIndex) {
    final vowel = kFingertipVowels[fingertipIndex]!;

    if (_currentLevel.number == 2 && vowel != _targetVowel) {
      // Wrong fingertip in Challenge mode — flash red, no score.
      _wrongFingertipIndex = fingertipIndex;
      notifyListeners();
      Timer(const Duration(milliseconds: 500), () {
        _wrongFingertipIndex = null;
        notifyListeners();
      });
      return;
    }

    // Correct touch — speak vowel, increment score, highlight fingertip.
    _tts.speak(vowel);
    _score++;
    _activeFingertipIndex = fingertipIndex;
    notifyListeners();

    // Clear highlight after a short delay.
    Timer(_highlightDuration, () {
      _activeFingertipIndex = null;
      notifyListeners();
    });

    // Start per-fingertip cooldown.
    _cooledDown.add(fingertipIndex);
    _cooldownTimers[fingertipIndex]?.cancel();
    _cooldownTimers[fingertipIndex] = Timer(_cooldownDuration, () {
      _cooledDown.remove(fingertipIndex);
    });

    // Advance to next target vowel in Challenge mode.
    if (_currentLevel.number == 2) {
      _pickNextTargetVowel();
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _pickNextTargetVowel() {
    final vowels = kFingertipVowels.values.toList();
    vowels.shuffle();
    _targetVowel = vowels.first;
  }

  void _resetRoundState() {
    _cursorPosition = null;
    _activeFingertipIndex = null;
    _wrongFingertipIndex = null;
    _targetVowel = null;
    _cooledDown.clear();
    for (final t in _cooldownTimers.values) {
      t.cancel();
    }
    _cooldownTimers.clear();
  }

  @override
  void dispose() {
    _stopTracking();
    _trackingService.dispose();
    _tts.stop();
    for (final t in _cooldownTimers.values) {
      t.cancel();
    }
    super.dispose();
  }
}
