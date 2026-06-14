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
