import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/game_constants.dart';
import '../models/story_step.dart';

/// Manages state for the welcome/introduction screen.
///
/// Responsibilities:
/// - Track current story step
/// - Check if user has seen the intro before
/// - Persist first-launch status
/// - Provide story step data
///
/// Usage:
/// ```dart
/// final provider = WelcomeProvider();
/// await provider.initialize();
/// provider.nextStep(); // Move to next story step
/// ```
class WelcomeProvider extends ChangeNotifier {
  /// Whether the welcome intro is still loading
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Whether the user has seen the intro before
  bool _hasSeenIntro = false;
  bool get hasSeenIntro => _hasSeenIntro;

  /// Current step index in the story sequence
  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  /// The story steps for first-time users.
  ///
  /// Sequence:
  /// 1. Catrin introduces Abi
  /// 2. Catrin explains Abi is Deaf and they use BSL
  /// 3. Abi introduces Pero (hearing dog)
  final List<StoryStep> _storySteps = [
    const StoryStep(
      speakerName: 'Catrin',
      characterImagePath: AssetPaths.catrinDefault,
      dialogueKey: 'welcome.catrin_intro',
    ),
    const StoryStep(
      speakerName: 'Catrin',
      characterImagePath: AssetPaths.catrinDefault,
      dialogueKey: 'welcome.abi_is_deaf',
    ),
    const StoryStep(
      speakerName: 'Catrin',
      characterImagePath: AssetPaths.catrinDefault,
      dialogueKey: 'welcome.bsl_explanation',
    ),
    const StoryStep(
      speakerName: 'Abi',
      characterImagePath: AssetPaths.abiDefault,
      dialogueKey: 'welcome.pero_intro',
    ),
    const StoryStep(
      speakerName: 'Abi',
      characterImagePath: AssetPaths.abiDefault,
      dialogueKey: 'welcome.hearing_dog_explain',
    ),
    const StoryStep(
      speakerName: 'Pero',
      characterImagePath: AssetPaths.peroProfile,
      dialogueKey: 'welcome.pero_woof',
    ),
  ];

  /// Returns the list of story steps
  List<StoryStep> get storySteps => _storySteps;

  /// Returns the current story step, or null if complete
  StoryStep? get currentStep {
    if (_currentStepIndex >= _storySteps.length) {
      return null;
    }
    return _storySteps[_currentStepIndex];
  }

  /// Returns true if the story is complete
  bool get isStoryComplete => _currentStepIndex >= _storySteps.length;

  /// Total number of story steps
  int get totalSteps => _storySteps.length;

  /// Initializes the provider by checking SharedPreferences.
  ///
  /// Must be called before using the provider.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenIntro = prefs.getBool(GameConstants.firstLaunchKey) ?? false;
    } catch (e) {
      debugPrint('Error reading preferences: $e');
      _hasSeenIntro = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Advances to the next story step.
  ///
  /// If already at the last step, marks the intro as complete.
  void nextStep() {
    if (_currentStepIndex < _storySteps.length) {
      _currentStepIndex++;
      notifyListeners();
    }
  }

  /// Marks the introduction as seen and persists to storage.
  ///
  /// Should be called when user completes the intro or skips it.
  Future<void> markIntroAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(GameConstants.firstLaunchKey, true);
      _hasSeenIntro = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  /// Resets the intro state (for testing purposes).
  ///
  /// Clears the first-launch flag from SharedPreferences.
  Future<void> resetIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(GameConstants.firstLaunchKey);
      _hasSeenIntro = false;
      _currentStepIndex = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting preferences: $e');
    }
  }
}
