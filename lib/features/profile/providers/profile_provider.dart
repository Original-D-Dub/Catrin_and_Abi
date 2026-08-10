import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/game_stats_service.dart';

/// Loads and edits the current player's `profiles` row (screen name +
/// chosen avatar) and their `player_stats` rows (used to work out which
/// badges have been earned).
///
/// `screen_name` is the freely-editable display name shown and edited in
/// the app. It's separate from `username`, the unique name set once at
/// signup and never shown or edited here.
///
/// The `profiles` row for the signed-in user is created automatically by a
/// database trigger on `auth.users` insert, so this provider only ever
/// reads/updates it — it never needs to insert one itself.
///
/// Provided app-wide (alongside AuthProvider) so any screen — including
/// ones reached via their own route, like the delete-account page — shares
/// one instance and one up-to-date view of the profile, without each needing
/// to remember to call [refresh] after an auth change. It re-loads itself
/// automatically on every Supabase auth state change (sign in, sign out,
/// account deletion).
class ProfileProvider extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  final GameStatsService _statsService = GameStatsService();
  late final StreamSubscription<AuthState> _authSubscription;

  String? _screenName;
  String? get screenName => _screenName;

  String? _avatarId;
  String? get avatarId => _avatarId;

  List<Map<String, dynamic>> _stats = const [];
  List<Map<String, dynamic>> get stats => _stats;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  ProfileProvider() {
    _load();
    _authSubscription = _db.auth.onAuthStateChange.listen((_) => _load());
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final row = await _db
          .from('profiles')
          .select('screen_name, avatar')
          .eq('id', userId)
          .maybeSingle();
      _screenName = row?['screen_name'] as String?;
      _avatarId = row?['avatar'] as String?;
      _stats = await _statsService.getPlayerStats(userId);
    } catch (e) {
      debugPrint('ProfileProvider: failed to load profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetches the profile and stats. Normally unnecessary — the provider
  /// already reloads on every Supabase auth state change — but kept for
  /// screens that want to force a refresh outside of that (e.g. right after
  /// saving stats elsewhere).
  Future<void> refresh() => _load();

  /// Updates the screen name and/or avatar. Pass only the fields that
  /// changed; omitted fields are left untouched.
  ///
  /// Returns true on success, false if the save failed (e.g. no connection).
  Future<bool> updateProfile({String? screenName, String? avatarId}) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return false;

    final trimmedScreenName = screenName?.trim();
    final updates = <String, dynamic>{
      if (trimmedScreenName != null && trimmedScreenName.isNotEmpty)
        'screen_name': trimmedScreenName,
      'avatar': ?avatarId,
    };
    if (updates.isEmpty) return true;

    _isSaving = true;
    notifyListeners();

    try {
      await _db.from('profiles').update(updates).eq('id', userId);
      if (updates.containsKey('screen_name')) {
        _screenName = updates['screen_name'] as String;
      }
      if (updates.containsKey('avatar')) {
        _avatarId = updates['avatar'] as String;
      }
      return true;
    } catch (e) {
      debugPrint('ProfileProvider: failed to save profile: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
