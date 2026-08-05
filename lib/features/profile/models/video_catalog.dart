import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// One BSL video tile shown in the profile screen's "My BSL Video" section.
///
/// Placeholder data — no `videos` table exists in Supabase yet. Shaped so a
/// future `getVideos()`/`getWatchedVideoIds()` call can populate the same
/// fields ([backgroundImagePath], [watched]) without changing the tile
/// widget. [watched] defaults to false for every video rather than faking
/// progress, since there's no per-user watch-history table
/// (`bsl_bingo_found_letters` is the closest existing precedent for what
/// that table would look like) to back a "true" value yet.
class BslVideoTile {
  final String id;
  final String titleKey;
  final Duration duration;
  final bool watched;

  /// Custom thumbnail/background image for this video. Null until real
  /// artwork exists — the tile falls back to [placeholderColor].
  final String? backgroundImagePath;

  /// Stand-in tile background, used while [backgroundImagePath] is null.
  final Color placeholderColor;

  const BslVideoTile({
    required this.id,
    required this.titleKey,
    required this.duration,
    required this.placeholderColor,
    this.watched = false,
    this.backgroundImagePath,
  });
}

/// Initial set of BSL videos, in display order.
const List<BslVideoTile> bslVideoCatalog = [
  BslVideoTile(
    id: 'deaf_awareness',
    titleKey: 'profile.video.deaf_awareness',
    duration: Duration(minutes: 4, seconds: 12),
    placeholderColor: AppColors.accentNavyBlue,
  ),
  BslVideoTile(
    id: 'iac_alphabet',
    titleKey: 'profile.video.iac_alphabet',
    duration: Duration(minutes: 5, seconds: 20),
    placeholderColor: AppColors.schoolGreen,
  ),
  BslVideoTile(
    id: 'bsl_alphabet',
    titleKey: 'profile.video.bsl_alphabet',
    duration: Duration(minutes: 5, seconds: 3),
    placeholderColor: AppColors.accentPurple,
  ),
  BslVideoTile(
    id: 'bsl_numbers',
    titleKey: 'profile.video.bsl_numbers',
    duration: Duration(minutes: 3, seconds: 48),
    placeholderColor: AppColors.peroJacket,
  ),
  BslVideoTile(
    id: 'colours',
    titleKey: 'profile.video.colours',
    duration: Duration(minutes: 2, seconds: 58),
    placeholderColor: AppColors.accentRed,
  ),
  BslVideoTile(
    id: 'weather',
    titleKey: 'profile.video.weather',
    duration: Duration(minutes: 4, seconds: 5),
    placeholderColor: AppColors.bslBlue,
  ),
  BslVideoTile(
    id: 'time',
    titleKey: 'profile.video.time',
    duration: Duration(minutes: 2, seconds: 40),
    placeholderColor: AppColors.catrinHair,
  ),
  BslVideoTile(
    id: 'questions',
    titleKey: 'profile.video.questions',
    duration: Duration(minutes: 3, seconds: 33),
    placeholderColor: AppColors.accentOrange,
  ),
];
