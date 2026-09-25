import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists earned IAC bingo rewards to the `iac_bingo_player_inventory`
/// Supabase table — one row per reward a player has collected, linked via
/// `reward_id` to the specific `gwobrau_bingo_iac` row.
class IacBingoInventoryService {
  final _client = Supabase.instance.client;

  Future<void> addToInventory({
    required String userId,
    required String rewardId,
  }) async {
    await _client.from('iac_bingo_player_inventory').insert({
      'user_id': userId,
      'reward_id': rewardId,
    });
  }

  /// Returns the set of reward IDs the player has already collected.
  Future<Set<String>> fetchInventory({required String userId}) async {
    final rows = await _client
        .from('iac_bingo_player_inventory')
        .select('reward_id')
        .eq('user_id', userId) as List<dynamic>;
    return rows.map((r) => r['reward_id'] as String).toSet();
  }
}
