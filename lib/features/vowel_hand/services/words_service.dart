import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches words from the Supabase `words` table filtered by `word_pattern`.
class WordsService {
  final _client = Supabase.instance.client;

  /// Returns all words matching [pattern] (e.g. 'CCVC', 'CVCC').
  ///
  /// Returns an empty list on error so callers can handle gracefully.
  Future<List<String>> fetchWordsByPattern(String pattern) async {
    try {
      final rows = await _client
          .from('words')
          .select('word')
          .eq('word_pattern', pattern) as List<dynamic>;
      return rows
          .map((r) => (r['word'] as String).toLowerCase())
          .toList();
    } catch (e) {
      debugPrint('WordsService: failed to fetch $pattern words: $e');
      return [];
    }
  }
}
