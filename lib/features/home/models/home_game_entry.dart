import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/settings_provider.dart';
import '../widgets/game_tile.dart';

/// Data describing one tile in a home screen's game grid.
///
/// The English and Welsh home screens each keep their own list of these —
/// the tiles shown on each screen are different (different locales,
/// artwork, and sometimes different games) — but both render their list the
/// same way via [buildGameTiles] and [GameTile].
///
/// When [imagePath] is null, or the asset fails to load, [GameTile] falls
/// back to [icon], or to [Icons.games] if [icon] is also null.
typedef HomeGameEntry = ({
  String route,
  String titleKey,
  String? imagePath,
  IconData? icon,
  GameCategory category,
  Set<AgeGroup> ageGroups,
  String? arguments,
});

/// Builds a [HomeGameEntry], defaulting [imagePath], [icon] and [arguments]
/// to null.
HomeGameEntry homeGameEntry({
  required String route,
  required String titleKey,
  required GameCategory category,
  required Set<AgeGroup> ageGroups,
  String? imagePath,
  IconData? icon,
  String? arguments,
}) =>
    (
      route: route,
      titleKey: titleKey,
      imagePath: imagePath,
      icon: icon,
      category: category,
      ageGroups: ageGroups,
      arguments: arguments,
    );

/// Spacing/shape constants for the home-screen game grid — kept alongside
/// [gameGridCrossAxisCount] so anything that needs to match a game tile's
/// size (e.g. the "Learn BSL/IAC" banner tile) uses the same numbers as the
/// GridView itself.
const double gameGridSpacing = 8.0;
const double gameGridChildAspectRatio = 0.85;

/// Cross-axis tile count for the home-screen game grid, based on device
/// width/orientation. Shared by both home screens (and by widgets like the
/// "Learn BSL/IAC" banner tile that need to match the grid's per-tile size)
/// so the breakpoints can't drift between call sites.
int gameGridCrossAxisCount(BuildContext context, double width) {
  final mq = MediaQuery.of(context);
  final isTabletLandscape =
      mq.size.width >= 768 && mq.orientation == Orientation.landscape;
  return isTabletLandscape
      ? 4
      : width < 400
          ? 2
          : 3;
}

/// Height a single game tile renders at in the grid, for a given
/// [availableWidth] — mirrors [SliverGridDelegateWithFixedCrossAxisCount]'s
/// own math so a non-grid widget (like the banner tile) can match it.
double gameGridTileHeight(BuildContext context, double availableWidth) {
  final crossAxisCount = gameGridCrossAxisCount(context, availableWidth);
  final tileWidth = (availableWidth - gameGridSpacing * (crossAxisCount - 1)) /
      crossAxisCount;
  return tileWidth / gameGridChildAspectRatio;
}

/// Filters [allGames] by the player's current category/age-group settings
/// and renders the remainder as [GameTile]s wired up to navigate via
/// [Navigator.pushNamed].
List<Widget> buildGameTiles(
  BuildContext context,
  List<HomeGameEntry> allGames,
  SettingsProvider settings,
  AppLocalizations localizer,
) {
  return allGames.where((g) {
    final catOk = settings.gameCategory == GameCategory.all ||
        g.category == settings.gameCategory;
    final ageOk = settings.ageGroup == AgeGroup.all ||
        g.ageGroups.contains(settings.ageGroup);
    return catOk && ageOk;
  }).map<Widget>((g) => GameTile(
        title: localizer(g.titleKey),
        imagePath: g.imagePath,
        icon: g.icon,
        onTap: () => Navigator.pushNamed(context, g.route, arguments: g.arguments),
      )).toList();
}
