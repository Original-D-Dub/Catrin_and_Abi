import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

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

/// The `player_stats` game ids that record the vowel hand badges: a row
/// appears under one of these (high score 1) when the player opens the
/// matching treasure chest on the ages 1–3 level map — the level 4 chest
/// awards the Vowels badge, the level 8 chest the Spelling badge.
const String vowelsBadgeGameId = 'vowel_hand_badge';
const String spellingBadgeGameId = 'vowel_hand_spelling_badge';

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
/// Badges are earned by playing, not tuned from aggregate stats — each one
/// documents below exactly what awards it.
final List<ProfileBadge> profileBadges = [
  ProfileBadge(
    id: 'vowels',
    emoji: '🖐️',
    labelKey: 'profile.badge.vowels',
    color: AppColors.catrinBlue,
    isEarned: (stats) => _hasStatsRow(stats, vowelsBadgeGameId),
  ),
  ProfileBadge(
    id: 'spelling',
    emoji: '📝',
    labelKey: 'profile.badge.spelling',
    color: AppColors.accentPurple,
    isEarned: (stats) => _hasStatsRow(stats, spellingBadgeGameId),
  ),
];

/// Whether a `player_stats` row recording [gameId] exists with a positive
/// high score — how chest-awarded badges mark themselves earned.
bool _hasStatsRow(List<Map<String, dynamic>> stats, String gameId) {
  return stats.any((row) =>
      row['game_id'] == gameId && ((row['high_score'] as int? ?? 0) > 0));
}

/// Looks up a badge by [id], falling back to the first badge when [id] is
/// unrecognised.
ProfileBadge badgeById(String id) => profileBadges.firstWhere(
      (b) => b.id == id,
      orElse: () => profileBadges.first,
    );

/// Whether the Vowels badge has been earned, given the player's stats.
bool vowelsBadgeEarned(List<Map<String, dynamic>> stats) =>
    _hasStatsRow(stats, vowelsBadgeGameId);

/// Whether the Spelling badge has been earned, given the player's stats.
bool spellingBadgeEarned(List<Map<String, dynamic>> stats) =>
    _hasStatsRow(stats, spellingBadgeGameId);

