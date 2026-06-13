import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/game_filters.dart';

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

  String _language = 'en';
  GameCategory _gameCategory = GameCategory.all;
  AgeGroup _ageGroup = AgeGroup.all;
  SignSystem _signSystem = SignSystem.bsl;

  /// Active language code — 'en' (English) or 'cy' (Welsh/Cymraeg).
  String get language => _language;

  /// Active game-type filter.
  GameCategory get gameCategory => _gameCategory;

  /// Active age-group filter.
  AgeGroup get ageGroup => _ageGroup;

  /// Active sign system used for letter signs (BSL or IAC).
  SignSystem get signSystem => _signSystem;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

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

        // Mirror to local prefs for offline access.
        await prefs.setString(_langKey, _language);
        await prefs.setString(_categoryKey, _gameCategory.toPrefsString());
        await prefs.setString(_ageGroupKey, _ageGroup.toPrefsString());
        await prefs.setString(_signSystemKey, _signSystem.toPrefsString());

        notifyListeners();
        return;
      }
    }

    // Anonymous / no metadata: fall back to local prefs.
    _language = prefs.getString(_langKey) ?? 'en';
    _gameCategory = GameCategory.fromPrefsString(prefs.getString(_categoryKey));
    _ageGroup = AgeGroup.fromPrefsString(prefs.getString(_ageGroupKey));
    _signSystem = SignSystem.fromPrefsString(prefs.getString(_signSystemKey));
    notifyListeners();
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

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, _language);
    await prefs.setString(_categoryKey, _gameCategory.toPrefsString());
    await prefs.setString(_ageGroupKey, _ageGroup.toPrefsString());
    await prefs.setString(_signSystemKey, _signSystem.toPrefsString());

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {
            _langKey: _language,
            _categoryKey: _gameCategory.toPrefsString(),
            _ageGroupKey: _ageGroup.toPrefsString(),
            _signSystemKey: _signSystem.toPrefsString(),
          }),
        );
      } catch (_) {
        // Non-critical — local preference already saved.
      }
    }
  }
}
