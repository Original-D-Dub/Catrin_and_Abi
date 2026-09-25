import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles reading and writing "Learn BSL trail" progress to Supabase.
///
/// Mirrors [GameStatsService]'s guest-play handling: anonymous/signed-out
/// players simply don't get anything persisted, so the trail still works for
/// them within a single session (progress just resets next launch).
class TrailProgressService {
  final _db = Supabase.instance.client;

  bool get _isSignedIn {
    final user = _db.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  String? get _userId => _db.auth.currentUser?.id;

  /// Returns the set of trail node ids the current player has completed.
  Future<Set<String>> fetchCompletedNodeIds() async {
    if (!_isSignedIn) return {};

    final rows = await _db
        .from('bsl_trail_progress')
        .select('node_id')
        .eq('player_id', _userId!);
    return {for (final row in rows) row['node_id'] as String};
  }

  /// Records [nodeId] as completed for the current player. No-ops for guests.
  Future<void> markNodeCompleted(String nodeId) async {
    if (!_isSignedIn) return;

    await _db.from('bsl_trail_progress').upsert(
      {'player_id': _userId, 'node_id': nodeId},
      onConflict: 'player_id,node_id',
    );
  }
}
