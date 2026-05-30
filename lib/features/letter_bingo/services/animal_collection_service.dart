import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal_model.dart';

/// Persists earned animals to the `animal_collection` Supabase table.
///
/// Required SQL (run once in the Supabase dashboard):
/// ```sql
/// create table animal_collection (
///   id            uuid primary key default gen_random_uuid(),
///   player_id     uuid references auth.users not null,
///   animal_letter text not null,
///   animal_name   text not null,
///   level_number  int  not null,
///   earned_at     timestamptz not null default now()
/// );
/// alter table animal_collection enable row level security;
/// create policy "Users manage own collection"
///   on animal_collection for all using (auth.uid() = player_id);
/// ```
class AnimalCollectionService {
  final _client = Supabase.instance.client;

  Future<void> addToCollection({
    required String playerId,
    required Animal animal,
    required int levelNumber,
  }) async {
    await _client.from('animal_collection').insert({
      'player_id': playerId,
      'animal_letter': animal.letter,
      'animal_name': animal.name,
      'level_number': levelNumber,
      'earned_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns the set of lowercase letters the player has collected.
  Future<Set<String>> fetchCollection({required String playerId}) async {
    final rows = await _client
        .from('animal_collection')
        .select('animal_letter')
        .eq('player_id', playerId) as List<dynamic>;
    return rows
        .map((r) => (r['animal_letter'] as String).toLowerCase())
        .toSet();
  }
}
