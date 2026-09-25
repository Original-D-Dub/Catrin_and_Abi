import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks whether a player has already seen a timed game's instruction
/// screen, so [GameIntroCountdown] only shows it on the first play.
///
/// Mirrors [TrailProgressService]'s guest-play handling: anonymous/signed-out
/// players get an in-memory flag that lasts only for the current app
/// session (reset on next launch), while signed-in players get it persisted
/// to Supabase so it follows them across devices/logins.
class GameInstructionsService {
  final _db = Supabase.instance.client;

  static final Set<String> _guestSeenGameIds = {};

  bool get _isSignedIn {
    final user = _db.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  String? get _userId => _db.auth.currentUser?.id;

  /// Returns true if the current player has already seen [gameId]'s
  /// instruction screen.
  Future<bool> hasSeenInstructions(String gameId) async {
    if (!_isSignedIn) return _guestSeenGameIds.contains(gameId);

    final row = await _db
        .from('game_instructions_seen')
        .select('game_id')
        .eq('player_id', _userId!)
        .eq('game_id', gameId)
        .maybeSingle();
    return row != null;
  }

  /// Records that the current player has seen [gameId]'s instruction
  /// screen, so it won't be shown again.
  Future<void> markInstructionsSeen(String gameId) async {
    if (!_isSignedIn) {
      _guestSeenGameIds.add(gameId);
      return;
    }

    await _db.from('game_instructions_seen').upsert(
      {'player_id': _userId, 'game_id': gameId},
      onConflict: 'player_id,game_id',
    );
  }
}
