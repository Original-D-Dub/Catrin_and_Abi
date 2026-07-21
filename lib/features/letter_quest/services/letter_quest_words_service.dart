import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/letter_quest_word.dart';

/// Fetches target words for Letter Quest Level 5 from Supabase.
class LetterQuestWordsService {
  final _client = Supabase.instance.client;
  final _random = Random();

  /// Returns [count] random [LetterQuestWord]s from the `letter_quest_words`
  /// table, with [LetterQuestWord.category] populated.
  ///
  /// Fetches all available words, shuffles them client-side, and returns
  /// the first [count]. Falls back to an empty list on error so the game
  /// can use its local word list instead.
  Future<List<LetterQuestWord>> fetchRandomWords({int count = 5}) async {
    try {
      final rows = await _client
          .from('letter_quest_words')
          .select('word, category') as List<dynamic>;

      final words = rows
          .map((r) {
            final word = r['word'] as String?;
            if (word == null || word.isEmpty) return null;
            return LetterQuestWord(
              word: word.toLowerCase(),
              category: r['category'] as String?,
            );
          })
          .whereType<LetterQuestWord>()
          .toList()
        ..shuffle(_random);

      return words.take(count).toList();
    } catch (e) {
      debugPrint('LetterQuestWordsService: failed to fetch words: $e');
      return [];
    }
  }
}
