import 'package:supabase_flutter/supabase_flutter.dart';

/// Game ID constants — must match the values used in the database.
class GameIds {
  GameIds._();

  static const String cardMatching = 'card_matching';
  static const String bubblePop = 'bubble_pop';
  static const String welshBubblePop = 'welsh_bubble_pop';
  static const String colouring = 'colouring';
  static const String vowelHand = 'vowel_hand';
  static const String welshVowels = 'iac_vowels';
  static const String mySpecialDog = 'my_special_dog';
  static const String bslMaths = 'bsl_maths';
  static const String letterQuest = 'letter_quest';
  static const String letterBingo = 'letter_bingo';
  static const String characterId = 'character_id';
  static const String countingGame = 'counting_game';
  static const String numberLineGame = 'number_line_game';
  static const String countingBackGame = 'counting_back_game';
static const String bslSprint = 'bsl_sprint';
  static const String moreLessGame = 'higher_or_lower';
  static const String wordSearch = 'word_search';
}

/// The result returned by [GameStatsService.recordGameResult].
///
/// Use [isNewPersonalBest] to show a "New PB!" celebration in the game's
/// end screen, and [personalBest] to display the all-time best score.
class GameResult {
  /// The score submitted this session.
  final int score;

  /// The all-time personal best for this game (equals [score] when it's a new PB).
  final int personalBest;

  /// Whether this session set a new personal best.
  final bool isNewPersonalBest;

  const GameResult({
    required this.score,
    required this.personalBest,
    required this.isNewPersonalBest,
  });
}

/// Handles reading and writing player game statistics to Supabase.
///
/// Call [recordGameResult] at the end of each game session.
/// If the player is not logged in the call returns a [GameResult] with
/// [isNewPersonalBest] false, so guest play works without changes to game providers.
class GameStatsService {
  final _db = Supabase.instance.client;

  String? get _userId => _db.auth.currentUser?.id;

  /// Ensures a profile row exists for the current user.
  ///
  /// Guards against the trigger failing silently for anonymous sign-ins,
  /// which would cause a foreign key violation when writing game_stats.
  Future<void> _ensureProfile() async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    final username = user.userMetadata?['username'] as String? ??
        (user.email != null ? user.email!.split('@').first : 'player_${user.id.substring(0, 8)}');

    await _db.from('profiles').upsert(
      {'id': user.id, 'user_id': user.id, 'username': username},
      onConflict: 'id',
    );
  }

  /// Records a completed game session.
  ///
  /// - Updates [high_score] if [score] beats the previous personal best.
  /// - Increments [total_plays].
  /// - Recalculates the daily streak based on [last_played_at].
  ///
  /// Returns a [GameResult] so callers can show a "New Personal Best!" message.
  /// [level] is appended to [gameId] when provided, giving per-level tracking
  /// (e.g. gameId='bubble_pop', level=2 → stored as 'bubble_pop_2').
  /// [higherIsBetter] controls how the personal best is compared.
  /// Pass `false` for games where a lower score is better (e.g. fewest moves).
  Future<GameResult> recordGameResult(
    String gameId,
    int score, {
    int? level,
    bool higherIsBetter = true,
  }) async {
    final effectiveGameId = level != null ? '${gameId}_$level' : gameId;
    final user = _db.auth.currentUser;
    if (user == null || user.isAnonymous) {
      return GameResult(score: score, personalBest: score, isNewPersonalBest: false);
    }
    final userId = user.id;

    await _ensureProfile();

    final today = _todayString();

    final existing = await _db
        .from('game_stats')
        .select()
        .eq('player_id', userId)
        .eq('game_id', effectiveGameId)
        .maybeSingle();

    if (existing == null) {
      // First time playing this game — no previous score to beat so don't notify.
      await _db.from('game_stats').insert({
        'player_id': userId,
        'game_id': effectiveGameId,
        'high_score': score,
        'total_plays': 1,
        'last_played_at': today,
        'current_streak': 1,
        'longest_streak': 1,
      });
      return GameResult(score: score, personalBest: score, isNewPersonalBest: false);
    } else {
      final prevHigh = existing['high_score'] as int;
      final prevPlays = existing['total_plays'] as int;
      final lastPlayed = existing['last_played_at'] as String?;
      final currentStreak = existing['current_streak'] as int;
      final longestStreak = existing['longest_streak'] as int;

      final isNewPB = higherIsBetter ? score > prevHigh : score < prevHigh;
      final newHigh = isNewPB ? score : prevHigh;

      final newStreak = _calculateStreak(
        lastPlayed: lastPlayed,
        today: today,
        currentStreak: currentStreak,
      );

      await _db.from('game_stats').update({
        'high_score': newHigh,
        'total_plays': prevPlays + 1,
        'last_played_at': today,
        'current_streak': newStreak,
        'longest_streak': newStreak > longestStreak ? newStreak : longestStreak,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('player_id', userId).eq('game_id', effectiveGameId);

      return GameResult(score: score, personalBest: newHigh, isNewPersonalBest: isNewPB);
    }
  }

  /// Returns the personal best score for the current player for a given game,
  /// or null if they have never played it.
  Future<int?> getPersonalBest(String gameId) async {
    final userId = _userId;
    if (userId == null) return null;

    final row = await _db
        .from('game_stats')
        .select('high_score')
        .eq('player_id', userId)
        .eq('game_id', gameId)
        .maybeSingle();

    return row?['high_score'] as int?;
  }

  /// Returns all game stats rows for the given player.
  Future<List<Map<String, dynamic>>> getPlayerStats(String userId) async {
    final rows = await _db
        .from('game_stats')
        .select()
        .eq('player_id', userId)
        .order('game_id');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Returns the stat row for a specific player + game, or null if not played.
  Future<Map<String, dynamic>?> getGameStat(
      String userId, String gameId) async {
    return await _db
        .from('game_stats')
        .select()
        .eq('player_id', userId)
        .eq('game_id', gameId)
        .maybeSingle();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _todayString() => DateTime.now().toIso8601String().substring(0, 10);

  int _calculateStreak({
    required String? lastPlayed,
    required String today,
    required int currentStreak,
  }) {
    if (lastPlayed == null) return 1;

    final last = DateTime.parse(lastPlayed);
    final todayDate = DateTime.parse(today);
    final diff = todayDate.difference(last).inDays;

    if (diff == 0) return currentStreak; // played again today, no change
    if (diff == 1) return currentStreak + 1; // consecutive day
    return 1; // streak broken
  }
}
