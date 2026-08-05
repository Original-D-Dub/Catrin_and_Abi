import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches words from the Supabase `words`/`Geiriau` tables filtered by
/// `word_pattern`.
class WordsService {
  final _client = Supabase.instance.client;

  /// Returns all English words matching [pattern] (e.g. 'CCVC', 'CVCC').
  ///
  /// Queries the [words_filterable] view rather than the [words] table
  /// directly, because [word_pattern] is a GENERATED ALWAYS AS column
  /// which PostgREST cannot filter on via the REST API.
  ///
  /// Returns an empty list on error so callers can handle gracefully.
  Future<List<String>> fetchWordsByPattern(String pattern) =>
      _fetchWords(table: 'words_filterable', patterns: [pattern]);

  /// Returns all Welsh words matching any of [patterns] (e.g. ['CVC', 'VCC',
  /// 'CCV']) from the `Geiriau` table, used by the IAC sign-system levels.
  ///
  /// Unlike `words`, `Geiriau.word_pattern` is a plain (non-generated)
  /// column, so it can be filtered directly without a view.
  ///
  /// Returns an empty list on error so callers can handle gracefully.
  Future<List<String>> fetchWelshWordsByPatterns(List<String> patterns) =>
      _fetchWords(table: 'Geiriau', patterns: patterns);

  /// Returns all Welsh words from `Geiriau` whose pattern is NOT in
  /// [excludedPatterns] — used so a later level can draw from the words a
  /// prior level didn't use, without hardcoding the complement pattern list.
  ///
  /// Returns an empty list on error so callers can handle gracefully.
  Future<List<String>> fetchWelshWordsExcludingPatterns(
    List<String> excludedPatterns,
  ) async {
    try {
      final rows = await _client
          .from('Geiriau')
          .select('word')
          .not('word_pattern', 'in', excludedPatterns) as List<dynamic>;
      return rows
          .map((r) => (r['word'] as String).toLowerCase())
          .toList();
    } catch (e) {
      debugPrint(
          'WordsService: failed to fetch words excluding $excludedPatterns from Geiriau: $e');
      return [];
    }
  }

  Future<List<String>> _fetchWords({
    required String table,
    required List<String> patterns,
  }) async {
    try {
      final rows = await _client
          .from(table)
          .select('word')
          .inFilter('word_pattern', patterns) as List<dynamic>;
      return rows
          .map((r) => (r['word'] as String).toLowerCase())
          .toList();
    } catch (e) {
      debugPrint('WordsService: failed to fetch $patterns words from $table: $e');
      return [];
    }
  }
}
