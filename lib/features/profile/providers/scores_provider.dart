import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/game_filters.dart';
import '../../../shared/services/game_stats_service.dart';
import '../../letter_bingo/services/animal_collection_service.dart';

/// One level's score within a [GameScoreEntry]. [level] is null for games
/// with no per-level tracking (e.g. bsl_sprint, letter_quest) — those rows
/// are stored under the plain game id, with no numeric suffix.
///
/// [isChampion] is true when [score] came from the game's Champion Mode
/// (see [_championGameIds]) rather than normal play.
///
/// [hints] is how many hints the run that set [score] used (card matching's
/// Champion Mode hints, stored as `best_hints`); 0 when none or the game
/// has no hints.
class LevelScore {
  final int? level;
  final int score;
  final bool isChampion;
  final int hints;

  const LevelScore({
    required this.level,
    required this.score,
    this.isChampion = false,
    this.hints = 0,
  });
}

/// One row on the scores screen: a game's personal-best score(s), one per
/// level, swipeable in the UI. [levels] is sorted ascending by level and is
/// never empty (rows with no non-zero score are dropped by [ScoresProvider]).
///
/// [pillLabelKey] and [pillIcon] let a game's row read as something other
/// than a generic "Best" (e.g. Letter Bingo shows an animal count, not a
/// score). A null [pillIcon] hides the icon and reads as
/// "`<number> <label>`" instead of the usual "`<label>: <number>`".
/// [suffixKey], when set, is a localization key for a unit appended
/// straight after the number (e.g. card_matching's " moves").
///
/// [showPillLabel] hides both [pillLabelKey] and [pillIcon] from the row's
/// collapsed summary, leaving a bare "`<number> <suffix>`" — used for card
/// matching, where "Best: 88 moves" plus a trophy icon is too wide to sit
/// next to the title.
class GameScoreEntry {
  final String gameId;
  final String titleKey;
  final List<LevelScore> levels;
  final String pillLabelKey;
  final IconData? pillIcon;
  final String? suffixKey;
  final bool showPillLabel;

  const GameScoreEntry({
    required this.gameId,
    required this.titleKey,
    required this.levels,
    this.pillLabelKey = 'profile.scores_best_label',
    this.pillIcon = Icons.emoji_events,
    this.suffixKey,
    this.showPillLabel = true,
  });
}

/// Maps each scored [GameIds] value to the localization key for its display
/// title. Games that share a title — the BSL/Welsh sign-system variants of
/// the same game, e.g. [GameIds.bubblePop]/[GameIds.welshBubblePop] — share
/// one row on the scores screen, but that row's numbers only ever reflect
/// whichever sign system is currently selected (see [_gameSignSystem] and
/// [ScoresProvider.entries]) — the two are recorded, and shown, separately.
///
/// Games with no numeric score concept (colouring, word_whirl, zoo) are left
/// out — they never call [GameStatsService.recordGameResult], so no
/// `player_stats` rows for them can exist. [GameIds.letterBingo] is handled
/// separately (see [ScoresProvider._buildLetterBingoEntry]) since its row
/// shows the player's animal collection count, not a `player_stats` value.
const Map<String, String> _gameTitleKeys = {
  GameIds.vowelHand: 'vowel_hand.title',
  GameIds.welshVowels: 'iac_vowels.title',
  GameIds.cardMatching: 'card_matching.title',
  GameIds.welshCardMatching: 'card_matching.title',
  GameIds.bubblePop: 'bubble_pop.title',
  GameIds.welshBubblePop: 'bubble_pop.title',
  GameIds.numberRace: 'number_race.title',
  GameIds.bubbleShooter: 'bubble_shooter.title',
  GameIds.countingGame: 'counting_game.title',
  GameIds.countingBackGame: 'counting_back.title',
  GameIds.numberLineGame: 'number_line.title',
  GameIds.moreLessGame: 'more_or_less.title',
  GameIds.bslMaths: 'bsl_maths.title',
  GameIds.bslSprint: 'bsl_sprint.title',
  GameIds.letterQuest: 'letter_quest.title',
  GameIds.welshLetterQuest: 'letter_quest.title',
  GameIds.letterBingo: 'letter_bingo.title',
  GameIds.characterId: 'character_id.title',
};

/// Which sign system each id in [_gameTitleKeys] was recorded under. Ids not
/// listed here (the BSL-only games with no Welsh/IAC variant — bsl_maths,
/// bsl_sprint, character_id, number_race, counting_game, number_line_game,
/// counting_back_game, more_or_less) default to [SignSystem.bsl] and so
/// only ever appear when the BSL toggle is selected.
const Map<String, SignSystem> _gameSignSystem = {
  GameIds.vowelHand: SignSystem.bsl,
  GameIds.welshVowels: SignSystem.iac,
  GameIds.cardMatching: SignSystem.bsl,
  GameIds.welshCardMatching: SignSystem.iac,
  GameIds.bubblePop: SignSystem.bsl,
  GameIds.welshBubblePop: SignSystem.iac,
  GameIds.letterQuest: SignSystem.bsl,
  GameIds.welshLetterQuest: SignSystem.iac,
};

/// Restricts which levels are shown for specific games, keyed by the game id
/// under which levels are actually stored (see the `level:` argument at each
/// game's `recordGameResult` call site). Games not listed here show every
/// level that has a non-zero score.
///
/// - Counting: only levels 4, 10 and 17 are the timed variants (see
///   `DotColourPair.isTimed` in counting_game_provider.dart) — the ones
///   worth comparing over time.
/// - BSL Maths: only level 5 is shown.
const Map<String, Set<int>> _levelFilters = {
  GameIds.countingGame: {4, 10, 17},
  GameIds.bslMaths: {5},
};

/// Games whose Champion Mode scores are stored under a separate id (e.g.
/// 'bubble_pop_champion_3'). They share the normal game's row: each level
/// shows whichever of the normal or Champion Mode best is higher, flagged
/// via [LevelScore.isChampion] when it's the Champion Mode one.
const Map<String, String> _championGameIds = {
  GameIds.bubblePop: GameIds.bubblePopChampion,
  GameIds.welshBubblePop: GameIds.welshBubblePopChampion,
};

/// Per-game unit appended right after the score number (e.g. "8 moves").
/// Card matching's `high_score` is a move count where *lower* is better —
/// recorded that way already via `recordGameResult(..., higherIsBetter:
/// false)` in card_game_provider.dart — so it needs a unit to read sensibly
/// as a "best", unlike every other game's plain point/count total.
const Map<String, String> _scoreSuffixKeys = {
  GameIds.cardMatching: 'card_matching.moves_suffix',
};

/// Row order for the scores list: the keys of [_gameTitleKeys], de-duplicated
/// by title so games sharing a title appear once, at the position of their
/// first occurrence.
List<String> _buildDisplayOrder() {
  final seenTitleKeys = <String>{};
  final order = <String>[];
  for (final entry in _gameTitleKeys.entries) {
    if (seenTitleKeys.add(entry.value)) order.add(entry.key);
  }
  return order;
}

final List<String> _displayOrder = _buildDisplayOrder();

/// Returns the id in [relatedIds] that [rowGameId] belongs to — either an
/// exact match (no per-level suffix) or `'<id>_<level>'` — or null if none.
String? _matchGameId(String rowGameId, Set<String> relatedIds) {
  for (final id in relatedIds) {
    if (rowGameId == id || rowGameId.startsWith('${id}_')) return id;
  }
  return null;
}

/// Loads the signed-in player's per-game high scores from Supabase.
///
/// Lazily fetched: nothing is downloaded until [loadIfNeeded] is called
/// (from the scores screen's `initState`). This is deliberately separate
/// from `ProfileProvider`, which eagerly loads the same `player_stats` table
/// for the profile page's badge row — that eager load stays as-is, this
/// provider exists so the scores screen's own fetch only happens when a
/// player actually opens it.
class ScoresProvider extends ChangeNotifier {
  final GameStatsService _statsService = GameStatsService();
  final AnimalCollectionService _animalService = AnimalCollectionService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasLoaded = false;

  /// True once a fetch has completed for a signed-in, non-anonymous user —
  /// used by the screen to tell "loading" apart from "guest, nothing to load".
  bool get hasLoaded => _hasLoaded;

  List<Map<String, dynamic>> _rawStats = const [];
  int _animalsCollected = 0;

  /// Which sign system's scores to display — toggled on the scores screen.
  /// Purely a local view filter, independent of [SettingsProvider]'s
  /// app-wide sign system (switching which stats you're *looking at*
  /// shouldn't change which games/content show elsewhere in the app).
  SignSystem _selectedSignSystem = SignSystem.bsl;
  SignSystem get selectedSignSystem => _selectedSignSystem;

  void setSelectedSignSystem(SignSystem signSystem) {
    if (_selectedSignSystem == signSystem) return;
    _selectedSignSystem = signSystem;
    notifyListeners();
  }

  /// One entry per distinct game with at least one non-zero level score, in
  /// a fixed display order. Rows are restricted to [_selectedSignSystem]:
  /// e.g. with IAC selected, a bubble_pop row only reflects
  /// welsh_bubble_pop's own stats, not bubble_pop's — the two sign-system
  /// variants are recorded (and shown) separately rather than merged.
  /// [_levelFilters] restricts which levels appear for games listed there.
  List<GameScoreEntry> get entries {
    final result = <GameScoreEntry>[];
    for (final gameId in _displayOrder) {
      if (gameId == GameIds.letterBingo) {
        final entry = _buildLetterBingoEntry();
        if (entry != null) result.add(entry);
        continue;
      }

      final titleKey = _gameTitleKeys[gameId]!;
      final relatedIds = _gameTitleKeys.entries
          .where((e) =>
              e.value == titleKey &&
              (_gameSignSystem[e.key] ?? SignSystem.bsl) ==
                  _selectedSignSystem)
          .map((e) => e.key)
          .toSet();
      if (relatedIds.isEmpty) continue;
      final allowedLevels = _levelFilters[gameId];

      final championIds = relatedIds
          .map((id) => _championGameIds[id])
          .whereType<String>()
          .toSet();

      final byLevel = <int?, LevelScore>{};
      for (final row in _rawStats) {
        final rowGameId = row['game_id'] as String? ?? '';
        final highScore = row['high_score'] as int? ?? 0;
        if (highScore <= 0) continue;

        // Champion ids are checked first: 'bubble_pop_champion_3' also
        // starts with 'bubble_pop_'.
        final championId = _matchGameId(rowGameId, championIds);
        final isChampion = championId != null;
        final matchedId = championId ?? _matchGameId(rowGameId, relatedIds);
        if (matchedId == null) continue;

        final int? level = rowGameId == matchedId
            ? null
            : int.tryParse(rowGameId.substring(matchedId.length + 1));
        // Skip rows with an unrecognised non-numeric suffix.
        if (rowGameId != matchedId && level == null) continue;
        if (allowedLevels != null &&
            (level == null || !allowedLevels.contains(level))) {
          continue;
        }

        final prevBest = byLevel[level]?.score ?? 0;
        if (highScore > prevBest) {
          byLevel[level] = LevelScore(
            level: level,
            score: highScore,
            isChampion: isChampion,
            hints: row['best_hints'] as int? ?? 0,
          );
        }
      }

      if (byLevel.isEmpty) continue;

      final levels = byLevel.values.toList()
        ..sort((a, b) => (a.level ?? -1).compareTo(b.level ?? -1));

      result.add(GameScoreEntry(
        gameId: gameId,
        titleKey: titleKey,
        levels: levels,
        suffixKey: _scoreSuffixKeys[gameId],
        showPillLabel: gameId != GameIds.cardMatching,
      ));
    }
    return result;
  }

  /// Letter Bingo's row shows the number of animals collected (from the
  /// separate `animal_collection` table — see [AnimalCollectionService]),
  /// not a `player_stats` value.
  GameScoreEntry? _buildLetterBingoEntry() {
    if (_animalsCollected <= 0) return null;
    return GameScoreEntry(
      gameId: GameIds.letterBingo,
      titleKey: _gameTitleKeys[GameIds.letterBingo]!,
      levels: [LevelScore(level: null, score: _animalsCollected)],
      pillLabelKey: 'profile.scores_animals_label',
      pillIcon: null,
    );
  }

  /// Fetches scores from Supabase the first time it's called. Safe to call
  /// repeatedly (e.g. every `initState`) — later calls are no-ops unless
  /// [forceRefresh] is set. Guest (anonymous) users have nothing synced to
  /// Supabase, so this resolves immediately with an empty list for them.
  Future<void> loadIfNeeded({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      _rawStats = const [];
      _animalsCollected = 0;
      _hasLoaded = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      // Both requests fire before either is awaited, so they run concurrently.
      final statsFuture = _statsService.getPlayerStats(user.id);
      final animalsFuture = _animalService.fetchCollection(playerId: user.id);
      _rawStats = await statsFuture;
      _animalsCollected = (await animalsFuture).length;
      _hasLoaded = true;
    } catch (e) {
      debugPrint('ScoresProvider: failed to load scores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
