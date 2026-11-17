import '../../../core/config/routes.dart';
import '../../../shared/services/game_stats_service.dart';

/// One step on the "Learn BSL trail" — a specific level of an existing game.
///
/// The trail is a small DAG, not a strict line: most nodes have exactly one
/// successor, but [nextNodeIds] can hold two (a fork) or zero (the final
/// node). A node is unlocked once any node listing it in [nextNodeIds] is
/// completed — see `TrailProvider.isNodeUnlocked`, which also makes that the
/// OR-merge point after a fork.
class TrailNode {
  /// Stable id, also the value stored in Supabase (`bsl_trail_progress.node_id`).
  final String id;

  /// Route to launch for this node — one of [AppRoutes]'s game routes.
  final String route;

  /// Matches [GameIds] — passed through so completion can be cross-checked
  /// against the right game if ever needed.
  final String gameId;

  /// 1-based level number within that game.
  final int level;

  /// Existing `<game>.title` translation key, reused for the node's title.
  final String titleKey;

  /// `trail.level<N>.name` translation key for the tile's name pill, where
  /// `<N>` is this node's 1-based position in [bslTrail]. Null for
  /// positions that don't have copy yet — the UI falls back to a
  /// placeholder in that case.
  final String? nameKey;

  /// Reuses each game's existing home-tile artwork — no trail-specific art
  /// exists yet.
  final String thumbnailAsset;

  /// Ids of the node(s) this one unlocks. Empty for the final node; two
  /// entries at the fork after letter_bingo level 1.
  final List<String> nextNodeIds;

  /// Minimum score required to count this node as completed. Null means the
  /// game's own structural win condition (all matched / row filled) is
  /// enough — only vowel_hand and bubble_pop, which otherwise just end on a
  /// timer regardless of score, need this gate.
  final int? minScore;

  const TrailNode({
    required this.id,
    required this.route,
    required this.gameId,
    required this.level,
    required this.titleKey,
    this.nameKey,
    required this.thumbnailAsset,
    required this.nextNodeIds,
    this.minScore,
  });
}

const _vowelHandThumb = 'assets/images/home_screen/bsl-vowels.jpg';
const _cardMatchingThumb = 'assets/images/home_screen/card-match.jpg';
const _bubblePopThumb = 'assets/images/home_screen/bubble-pop.jpg';
const _letterBingoThumb = 'assets/images/home_screen/letter-bingo.jpg';
const _countingGameThumb = 'assets/images/home_screen/counting-game.jpg';

/// The "Learn BSL trail", in order. Linear except for one fork/merge after
/// letter_bingo level 1:
///
/// ```
/// 1 vowel_hand L1 → 2 card_matching L1 → 3 vowel_hand L2 → 4 card_matching L2
/// → 5 bubble_pop L2 → 6 letter_bingo L1 → ┬→ 7 bubble_pop L3 ──────┐
///                                         └→ 8 card_matching L3 ───┴→ 9 letter_bingo L3
///                                                                     → 10 bubble_pop L4
///                                                                     → 11 counting L1
///                                                                     → 12 counting L3
///                                                                     → 13 counting L6
///                                                                     → 14 counting L10
///                                                                     → 15 counting L8
///                                                                     → 16 letter_bingo L2
///                                                                     → 17 letter_bingo L3
/// ```
///
/// Section 2 ("BSL Numbers", trail.section2.*) starts at node 11, gated on
/// node 10; section 3 ("Finger Spelling" again, trail.section3.*) starts
/// at node 16, gated on node 15 — see [LearnBslTrailScreen] for the
/// reveal-on-completing-a-gate-node mechanic. Node 17 reuses letter_bingo
/// level 3 (already node 9's level) under a different trail id
/// ('letter_bingo_3b') since a node's id must be unique in this list even
/// when it points at the same underlying game level.
const List<TrailNode> bslTrail = [
  TrailNode(
    id: 'vowel_hand_1',
    route: AppRoutes.vowelHand,
    gameId: GameIds.vowelHand,
    level: 1,
    titleKey: 'bsl_vowels.title',
    nameKey: 'trail.level1.name',
    thumbnailAsset: _vowelHandThumb,
    nextNodeIds: ['card_matching_1'],
    minScore: 3,
  ),
  TrailNode(
    id: 'card_matching_1',
    route: AppRoutes.cardMatching,
    gameId: GameIds.cardMatching,
    level: 1,
    titleKey: 'card_matching.title',
    nameKey: 'trail.level2.name',
    thumbnailAsset: _cardMatchingThumb,
    nextNodeIds: ['vowel_hand_2'],
  ),
  TrailNode(
    id: 'vowel_hand_2',
    route: AppRoutes.vowelHand,
    gameId: GameIds.vowelHand,
    level: 2,
    titleKey: 'bsl_vowels.title',
    nameKey: 'trail.level3.name',
    thumbnailAsset: _vowelHandThumb,
    nextNodeIds: ['card_matching_2'],
    minScore: 3,
  ),
  TrailNode(
    id: 'card_matching_2',
    route: AppRoutes.cardMatching,
    gameId: GameIds.cardMatching,
    level: 2,
    titleKey: 'card_matching.title',
    nameKey: 'trail.level4.name',
    thumbnailAsset: _cardMatchingThumb,
    nextNodeIds: ['bubble_pop_2'],
  ),
  TrailNode(
    id: 'bubble_pop_2',
    route: AppRoutes.bubblePop,
    gameId: GameIds.bubblePop,
    level: 2,
    titleKey: 'bubble_pop.title',
    nameKey: 'trail.level5.name',
    thumbnailAsset: _bubblePopThumb,
    nextNodeIds: ['letter_bingo_1'],
    minScore: 3,
  ),
  TrailNode(
    id: 'letter_bingo_1',
    route: AppRoutes.letterBingo,
    gameId: GameIds.letterBingo,
    level: 1,
    titleKey: 'letter_bingo.title',
    nameKey: 'trail.level6.name',
    thumbnailAsset: _letterBingoThumb,
    nextNodeIds: ['bubble_pop_3', 'card_matching_3'],
  ),
  TrailNode(
    id: 'bubble_pop_3',
    route: AppRoutes.bubblePop,
    gameId: GameIds.bubblePop,
    level: 3,
    titleKey: 'bubble_pop.title',
    nameKey: 'trail.level7.name',
    thumbnailAsset: _bubblePopThumb,
    nextNodeIds: ['letter_bingo_3'],
    minScore: 3,
  ),
  TrailNode(
    id: 'card_matching_3',
    route: AppRoutes.cardMatching,
    gameId: GameIds.cardMatching,
    level: 3,
    titleKey: 'card_matching.title',
    nameKey: 'trail.level8.name',
    thumbnailAsset: _cardMatchingThumb,
    nextNodeIds: ['letter_bingo_3'],
  ),
  TrailNode(
    id: 'letter_bingo_3',
    route: AppRoutes.letterBingo,
    gameId: GameIds.letterBingo,
    level: 3,
    titleKey: 'letter_bingo.title',
    nameKey: 'trail.level9.name',
    thumbnailAsset: _letterBingoThumb,
    nextNodeIds: ['bubble_pop_4'],
  ),
  TrailNode(
    id: 'bubble_pop_4',
    route: AppRoutes.bubblePop,
    gameId: GameIds.bubblePop,
    level: 4,
    titleKey: 'bubble_pop.title',
    nameKey: 'trail.level10.name',
    thumbnailAsset: _bubblePopThumb,
    nextNodeIds: ['counting_game_1'],
    minScore: 3,
  ),
  // Section 2 ("BSL Numbers") — see trail.section2.title/description.
  TrailNode(
    id: 'counting_game_1',
    route: AppRoutes.countingGame,
    gameId: GameIds.countingGame,
    level: 1,
    titleKey: 'counting_game.title',
    thumbnailAsset: _countingGameThumb,
    nextNodeIds: ['counting_game_3'],
  ),
  TrailNode(
    id: 'counting_game_3',
    route: AppRoutes.countingGame,
    gameId: GameIds.countingGame,
    level: 3,
    titleKey: 'counting_game.title',
    thumbnailAsset: _countingGameThumb,
    nextNodeIds: ['counting_game_6'],
  ),
  // Node ids stay fixed (they key persisted trail progress); the `level`
  // values below were shifted +4 when no-numeral levels 5-8 were inserted
  // into countingColourPairs, to keep pointing at the same level content
  // (yellow single-colour, green timed, blue/red two-colour).
  TrailNode(
    id: 'counting_game_6',
    route: AppRoutes.countingGame,
    gameId: GameIds.countingGame,
    level: 10,
    titleKey: 'counting_game.title',
    thumbnailAsset: _countingGameThumb,
    nextNodeIds: ['counting_game_10'],
  ),
  TrailNode(
    id: 'counting_game_10',
    route: AppRoutes.countingGame,
    gameId: GameIds.countingGame,
    level: 14,
    titleKey: 'counting_game.title',
    thumbnailAsset: _countingGameThumb,
    nextNodeIds: ['counting_game_8'],
  ),
  // Level 12 is a 60-second timed duplicate of level 11 (see
  // countingColourPairs) — like bubble_pop/vowel_hand's timed levels, it
  // needs a minScore gate since it otherwise just ends on the clock.
  TrailNode(
    id: 'counting_game_8',
    route: AppRoutes.countingGame,
    gameId: GameIds.countingGame,
    level: 12,
    titleKey: 'counting_game.title',
    thumbnailAsset: _countingGameThumb,
    nextNodeIds: ['letter_bingo_2'],
    minScore: 3,
  ),
  // Section 3 ("Finger Spelling", trail.section3.*) — see
  // trail.section3.title/description.
  TrailNode(
    id: 'letter_bingo_2',
    route: AppRoutes.letterBingo,
    gameId: GameIds.letterBingo,
    level: 2,
    titleKey: 'letter_bingo.title',
    nameKey: 'trail.level16.name',
    thumbnailAsset: _letterBingoThumb,
    nextNodeIds: ['letter_bingo_3b'],
  ),
  TrailNode(
    id: 'letter_bingo_3b',
    route: AppRoutes.letterBingo,
    gameId: GameIds.letterBingo,
    level: 3,
    titleKey: 'letter_bingo.title',
    nameKey: 'trail.level17.name',
    thumbnailAsset: _letterBingoThumb,
    nextNodeIds: [],
  ),
];
