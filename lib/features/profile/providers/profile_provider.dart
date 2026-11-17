import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/game_stats_service.dart';
import '../models/profile_catalog.dart';

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

  /// Prefix for the local "badges already seen on the profile screen"
  /// store — completed with the player id, so a device shared between
  /// players keeps separate seen-sets.
  static const _seenBadgesKeyPrefix = 'profile_seen_badges';

  /// Badge ids that are earned but haven't been seen on the profile screen
  /// yet — the cue for the red dot on the home screen's profile icon.
  Set<String> _unseenBadgeIds = const {};
  Set<String> get unseenBadgeIds => _unseenBadgeIds;

  /// Whether at least one earned badge hasn't been seen yet.
  bool get hasUnseenBadges => _unseenBadgeIds.isNotEmpty;

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
      _unseenBadgeIds = const {};
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
      _unseenBadgeIds = await _computeUnseenBadges(userId);
    } catch (e) {
      debugPrint('ProfileProvider: failed to load profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Earned badge ids the player hasn't seen on the profile screen yet:
  /// everything earned minus everything previously marked seen (persisted
  /// locally per player).
  Future<Set<String>> _computeUnseenBadges(String userId) async {
    final earned = profileBadges
        .where((b) => b.isEarned(_stats))
        .map((b) => b.id)
        .toSet();
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getString('$_seenBadgesKeyPrefix.$userId') ?? '')
        .split(',')
        .where((id) => id.isNotEmpty)
        .toSet();
    return earned.difference(seen);
  }

  /// Records every currently earned badge as seen — the profile screen
  /// calls this once it has shown them, clearing the home screen's red
  /// dot. Callers that want to animate the just-earned badges should
  /// capture [unseenBadgeIds] before calling this.
  Future<void> markBadgesSeen() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null || _unseenBadgeIds.isEmpty) return;
    _unseenBadgeIds = const {};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getString('$_seenBadgesKeyPrefix.$userId') ?? '')
        .split(',')
        .where((id) => id.isNotEmpty)
        .toSet();
    seen.addAll(profileBadges
        .where((b) => b.isEarned(_stats))
        .map((b) => b.id));
    await prefs.setString(
        '$_seenBadgesKeyPrefix.$userId', seen.join(','));
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
