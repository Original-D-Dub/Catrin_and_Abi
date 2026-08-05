import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/services/game_stats_service.dart';

// ── Avatars ──────────────────────────────────────────────────────────────────

/// One selectable avatar. [id] is what's stored in `profiles.avatar_url`.
///
/// Placeholder art: emoji-in-a-circle until real illustrated avatars exist.
/// Swap [emoji] for an asset path (and adjust the rendering in the profile
/// screen) without touching [id] or callers, so saved choices keep working.
class AvatarOption {
  final String id;
  final String emoji;
  final Color color;

  const AvatarOption({required this.id, required this.emoji, required this.color});
}

const List<Color> _avatarColors = [
  AppColors.accentRed,
  AppColors.accentOrange,
  AppColors.accentYellow,
  AppColors.accentLimeGreen,
  AppColors.accentNavyBlue,
  AppColors.accentPurple,
  AppColors.abiPink,
  AppColors.catrinBlue,
];

/// Twenty selectable avatars, laid out 5x4 in the edit sheet.
///
/// Today every avatar is unlocked from the start. The "collect more as
/// rewards" concept needs a rewards table (mirroring
/// `bsl_bingo_player_inventory`) before any of these can be gated — that's
/// future work, not wired up here.
final List<AvatarOption> avatarCatalog = List.generate(_avatarEmoji.length, (i) {
  return AvatarOption(
    id: _avatarEmoji[i].$1,
    emoji: _avatarEmoji[i].$2,
    color: _avatarColors[i % _avatarColors.length],
  );
});

const List<(String, String)> _avatarEmoji = [
  ('dog', '🐶'),
  ('cat', '🐱'),
  ('unicorn', '🦄'),
  ('panda', '🐼'),
  ('lion', '🦁'),
  ('fox', '🦊'),
  ('bear', '🐻'),
  ('tiger', '🐯'),
  ('rabbit', '🐰'),
  ('pig', '🐷'),
  ('frog', '🐸'),
  ('koala', '🐨'),
  ('chick', '🐤'),
  ('penguin', '🐧'),
  ('owl', '🦉'),
  ('hedgehog', '🦔'),
  ('elephant', '🐘'),
  ('whale', '🐳'),
  ('octopus', '🐙'),
  ('dragon', '🐉'),
];

/// Looks up an avatar by [id], falling back to the first avatar when [id]
/// is null or unrecognised (e.g. a player who hasn't picked one yet).
AvatarOption avatarById(String? id) {
  return avatarCatalog.firstWhere(
    (a) => a.id == id,
    orElse: () => avatarCatalog.first,
  );
}

// ── Badges ───────────────────────────────────────────────────────────────────

/// Every game ID declared in [GameIds] (kept in sync by hand — [GameIds] is
/// a plain class of `static const` strings, not an enum, so there's no
/// `.values` to enumerate automatically).
const Set<String> _allGameIds = {
  GameIds.cardMatching,
  GameIds.bubblePop,
  GameIds.welshBubblePop,
  GameIds.colouring,
  GameIds.vowelHand,
  GameIds.welshVowels,
  GameIds.bslMaths,
  GameIds.letterQuest,
  GameIds.letterBingo,
  GameIds.characterId,
  GameIds.countingGame,
  GameIds.numberLineGame,
  GameIds.countingBackGame,
  GameIds.bslSprint,
  GameIds.moreLessGame,
  GameIds.wordSearch,
  GameIds.numberRace,
  GameIds.zoo,
};

/// Game IDs that use IAC (Welsh) signs; everything else in [GameIds] is BSL.
const Set<String> _iacGameIds = {
  GameIds.welshVowels,
  GameIds.welshBubblePop,
};

final Set<String> _bslGameIds =
    _allGameIds.difference(_iacGameIds);

bool _playedAnyOf(List<Map<String, dynamic>> stats, Set<String> gameIds) {
  return stats.any((row) {
    final id = row['game_id'] as String? ?? '';
    final highScore = row['high_score'] as int? ?? 0;
    if (highScore <= 0) return false;
    // player_stats rows are keyed 'gameId' or 'gameId_level' for per-level
    // tracking (see GameStatsService.recordGameResult).
    return gameIds.any((g) => id == g || id.startsWith('${g}_'));
  });
}

/// A single earnable badge shown on the profile screen.
class ProfileBadge {
  final String id;
  final String emoji;
  final String labelKey;
  final Color color;

  /// Whether this badge has been earned, given the player's `player_stats` rows.
  final bool Function(List<Map<String, dynamic>> stats) isEarned;

  const ProfileBadge({
    required this.id,
    required this.emoji,
    required this.labelKey,
    required this.color,
    required this.isEarned,
  });
}

/// Badges shown in the profile screen's badge row.
///
/// Thresholds are a starting point, not tuned against real play data —
/// adjust freely as the reward system matures.
final List<ProfileBadge> profileBadges = [
  ProfileBadge(
    id: 'bsl_cup',
    emoji: '🏆',
    labelKey: 'profile.badge.bsl_cup',
    color: AppColors.accentNavyBlue,
    isEarned: (stats) => _playedAnyOf(stats, _bslGameIds),
  ),
  ProfileBadge(
    id: 'iac_cup',
    emoji: '🏆',
    labelKey: 'profile.badge.iac_cup',
    color: AppColors.schoolGreen,
    isEarned: (stats) => _playedAnyOf(stats, _iacGameIds),
  ),
  ProfileBadge(
    id: 'running_fast',
    emoji: '🏃',
    labelKey: 'profile.badge.running_fast',
    color: AppColors.accentOrange,
    isEarned: (stats) => stats.any((row) =>
        ((row['current_streak'] as int? ?? 0) >= 3) ||
        ((row['longest_streak'] as int? ?? 0) >= 3)),
  ),
  ProfileBadge(
    id: 'monkey_face',
    emoji: '🐵',
    labelKey: 'profile.badge.monkey_face',
    color: AppColors.abiPink,
    isEarned: (stats) => stats.fold<int>(
          0,
          (sum, row) => sum + (row['total_plays'] as int? ?? 0),
        ) >=
        20,
  ),
];
