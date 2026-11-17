import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/game_filters.dart';
import 'audio_service.dart';

/// Manages user-configurable app settings.
///
/// Persists locally via shared_preferences for all users.
/// For signed-in (non-anonymous) users also syncs to Supabase user
/// metadata so settings follow the user across devices.
class SettingsProvider extends ChangeNotifier {
  static const _langKey = 'app_language';
  static const _categoryKey = 'game_category';
  static const _ageGroupKey = 'age_group';
  static const _signSystemKey = 'sign_system';
  static const _zooCharacterKey = 'zoo_last_character';
  static const _soundEffectsEnabledKey = 'sound_effects_enabled';
  static const _instructionsEnabledKey = 'instructions_enabled';
  static const _hideListedGamesKey = 'hide_listed_games';

  /// Asset listing the game tiles hidden by the "hide selected games"
  /// master toggle (see [hiddenGameIds]).
  static const _hiddenGamesAssetPath = 'assets/data/hidden_games.json';

  String _language = 'en';
  GameCategory _gameCategory = GameCategory.all;
  AgeGroup _ageGroup = AgeGroup.all;
  SignSystem _signSystem = SignSystem.bsl;
  String? _lastZooCharacter;
  bool _soundEffectsEnabled = true;
  bool _instructionsEnabled = true;
  bool _hideListedGames = false;
  Set<String> _hiddenGameIds = {};

  /// Active language code — 'en' (English) or 'cy' (Welsh/Cymraeg).
  String get language => _language;

  /// Active game-type filter.
  GameCategory get gameCategory => _gameCategory;

  /// Active age-group filter.
  AgeGroup get ageGroup => _ageGroup;

  /// Active sign system used for letter signs (BSL or IAC).
  SignSystem get signSystem => _signSystem;

  /// The zoo character last chosen by a signed-in (non-anonymous) user, or
  /// null if none is remembered yet (or the user isn't signed in).
  String? get lastZooCharacter => _lastZooCharacter;

  /// Whether short sound effects (correct/wrong/success chimes) play.
  bool get soundEffectsEnabled => _soundEffectsEnabled;

  /// Whether spoken/audio game instructions play.
  bool get instructionsEnabled => _instructionsEnabled;

  /// Whether the "hide selected games" master toggle is on. When true, the
  /// tiles whose ids appear in [hiddenGameIds] are removed from the home
  /// screens no matter what the game-type/age-group filters would show.
  bool get hideListedGames => _hideListedGames;

  /// Game ids listed in [assets/data/hidden_games.json] — the tiles hidden
  /// when [hideListedGames] is on. Loaded from the asset so the list can be
  /// updated without touching code.
  Set<String> get hiddenGameIds => _hiddenGameIds;

  late final StreamSubscription<AuthState> _authSubscription;

  SettingsProvider() {
    _load();
    // Reload whenever the signed-in account changes (sign in, sign out,
    // switch to/from a guest session) so settings reflect the *current*
    // account instead of whatever was last loaded in memory.
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((_) => _load());
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // The hidden-games list lives in an asset (not user data), so it is
    // loaded the same way regardless of who is signed in. rootBundle caches
    // asset reads, making this cheap across reloads.
    await _loadHiddenGameIds();

    // For logged-in non-anonymous users Supabase metadata is the source of truth.
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      final meta = user.userMetadata;
      if (meta != null) {
        final lang = meta[_langKey] as String?;
        final cat = meta[_categoryKey] as String?;
        final age = meta[_ageGroupKey] as String?;
        final signSystem = meta[_signSystemKey] as String?;

        if (lang != null) _language = lang;
        _gameCategory = GameCategory.fromPrefsString(cat);
        _ageGroup = AgeGroup.fromPrefsString(age);
        _signSystem = SignSystem.fromPrefsString(signSystem);
        _lastZooCharacter = meta[_zooCharacterKey] as String?;
        _soundEffectsEnabled = meta[_soundEffectsEnabledKey] as bool? ?? true;
        _instructionsEnabled = meta[_instructionsEnabledKey] as bool? ?? true;
        _hideListedGames = meta[_hideListedGamesKey] as bool? ?? false;

        // Mirror to local prefs for offline access.
        await prefs.setString(_langKey, _language);
        await prefs.setString(_categoryKey, _gameCategory.toPrefsString());
        await prefs.setString(_ageGroupKey, _ageGroup.toPrefsString());
        await prefs.setString(_signSystemKey, _signSystem.toPrefsString());
        if (_lastZooCharacter != null) {
          await prefs.setString(_zooCharacterKey, _lastZooCharacter!);
        }
        await prefs.setBool(_soundEffectsEnabledKey, _soundEffectsEnabled);
        await prefs.setBool(_instructionsEnabledKey, _instructionsEnabled);
        await prefs.setBool(_hideListedGamesKey, _hideListedGames);

        _applyToAudioService();
        notifyListeners();
        return;
      }
    }

    // Anonymous / no metadata: fall back to local prefs.
    _language = prefs.getString(_langKey) ?? 'en';
    _gameCategory = GameCategory.fromPrefsString(prefs.getString(_categoryKey));
    _ageGroup = AgeGroup.fromPrefsString(prefs.getString(_ageGroupKey));
    _signSystem = SignSystem.fromPrefsString(prefs.getString(_signSystemKey));
    _soundEffectsEnabled = prefs.getBool(_soundEffectsEnabledKey) ?? true;
    _instructionsEnabled = prefs.getBool(_instructionsEnabledKey) ?? true;
    _hideListedGames = prefs.getBool(_hideListedGamesKey) ?? false;
    _applyToAudioService();
    notifyListeners();
  }

  /// Parses the raw contents of [assets/data/hidden_games.json] into the
  /// set of hideable game ids. Accepts either an object with a
  /// `hidden_games` array (the shipped format) or a bare JSON array.
  /// Malformed contents yield an empty set — a broken file must never stop
  /// the app from showing games.
  static Set<String> parseHiddenGamesJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      final list =
          decoded is List ? decoded : decoded is Map ? decoded['hidden_games'] : null;
      return list is List ? list.whereType<String>().toSet() : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> _loadHiddenGameIds() async {
    try {
      final raw = await rootBundle.loadString(_hiddenGamesAssetPath);
      _hiddenGameIds = parseHiddenGamesJson(raw);
    } catch (_) {
      // Missing or malformed asset — keep whatever was loaded before
      // (initially nothing hidden) rather than crashing.
    }
  }

  void _applyToAudioService() {
    AudioService.sfxEnabled = _soundEffectsEnabled;
    AudioService.instructionsEnabled = _instructionsEnabled;
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    await _persist();
  }

  Future<void> setGameCategory(GameCategory cat) async {
    if (_gameCategory == cat) return;
    _gameCategory = cat;
    notifyListeners();
    await _persist();
  }

  Future<void> setAgeGroup(AgeGroup age) async {
    if (_ageGroup == age) return;
    _ageGroup = age;
    notifyListeners();
    await _persist();
  }

  Future<void> setSignSystem(SignSystem signSystem) async {
    if (_signSystem == signSystem) return;
    _signSystem = signSystem;
    notifyListeners();
    await _persist();
  }

  Future<void> setSoundEffectsEnabled(bool value) async {
    if (_soundEffectsEnabled == value) return;
    _soundEffectsEnabled = value;
    _applyToAudioService();
    notifyListeners();
    await _persist();
  }

  Future<void> setInstructionsEnabled(bool value) async {
    if (_instructionsEnabled == value) return;
    _instructionsEnabled = value;
    _applyToAudioService();
    notifyListeners();
    await _persist();
  }

  Future<void> setHideListedGames(bool value) async {
    if (_hideListedGames == value) return;
    _hideListedGames = value;
    notifyListeners();
    await _persist();
  }

  /// Remembers [characterId] as the last zoo character picked, for
  /// signed-in (non-anonymous) users only. Anonymous users get no default
  /// next time — the pick-a-player grid is shown as normal.
  Future<void> setLastZooCharacter(String characterId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) return;
    if (_lastZooCharacter == characterId) return;

    _lastZooCharacter = characterId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zooCharacterKey, characterId);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {_zooCharacterKey: characterId}),
      );
    } catch (_) {
      // Non-critical — local preference already saved.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, _language);
    await prefs.setString(_categoryKey, _gameCategory.toPrefsString());
    await prefs.setString(_ageGroupKey, _ageGroup.toPrefsString());
    await prefs.setString(_signSystemKey, _signSystem.toPrefsString());
    await prefs.setBool(_soundEffectsEnabledKey, _soundEffectsEnabled);
    await prefs.setBool(_instructionsEnabledKey, _instructionsEnabled);
    await prefs.setBool(_hideListedGamesKey, _hideListedGames);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              _langKey: _language,
              _categoryKey: _gameCategory.toPrefsString(),
              _ageGroupKey: _ageGroup.toPrefsString(),
              _signSystemKey: _signSystem.toPrefsString(),
              _soundEffectsEnabledKey: _soundEffectsEnabled,
              _instructionsEnabledKey: _instructionsEnabled,
              _hideListedGamesKey: _hideListedGames,
            },
          ),
        );
      } catch (_) {
        // Non-critical — local preference already saved.
      }
    }
  }
}
