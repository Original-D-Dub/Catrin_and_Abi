import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sport_card.dart';

/// Persists sports cards to the `sports_collection` Supabase table (see
/// `supabase/migrations/20261019000000_sports_collection.sql`). Each row is
/// one card and the chest ([source]) it came from; both are unique per
/// player.
class SportsCollectionService {
  SupabaseClient get _client => Supabase.instance.client;

  /// The player's cards, keyed by the chest each came from.
  Future<Map<String, SportCard>> fetchCollection({
    required String playerId,
  }) async {
    final rows = await _client
        .from('sports_collection')
        .select('sport_id, source')
        .eq('player_id', playerId) as List<dynamic>;
    return {
      for (final row in rows)
        row['source'] as String: ?SportCard.fromId(row['sport_id'] as String),
    };
  }

  Future<void> addToCollection({
    required String playerId,
    required SportCard card,
    required String source,
  }) async {
    await _client.from('sports_collection').insert({
      'player_id': playerId,
      'sport_id': card.id,
      'source': source,
    });
  }
}
