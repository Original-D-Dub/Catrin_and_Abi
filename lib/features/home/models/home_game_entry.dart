import 'package:flutter/material.dart';

import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
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
///
/// Every titleKey follows the `'<gameId>.title'` convention, so [gameId]
/// (the stable identifier used for hidden-game matching — see
/// [visibleGames]) is derived from it and should never need to be set
/// explicitly. The field exists as an escape hatch in case a future tile
/// ever has to deviate from the convention.
typedef HomeGameEntry = ({
  String route,
  String titleKey,
  String? imagePath,
  IconData? icon,
  GameCategory category,
  Set<AgeGroup> ageGroups,
  String? arguments,
  String? gameId,
});

/// Builds a [HomeGameEntry], defaulting [imagePath], [icon], [arguments]
/// and [gameId] to null.
HomeGameEntry homeGameEntry({
  required String route,
  required String titleKey,
  required GameCategory category,
  required Set<AgeGroup> ageGroups,
  String? imagePath,
  IconData? icon,
  String? arguments,
  String? gameId,
}) =>
    (
      route: route,
      titleKey: titleKey,
      imagePath: imagePath,
      icon: icon,
      category: category,
      ageGroups: ageGroups,
      arguments: arguments,
      gameId: gameId,
    );

/// The stable id used to match a tile against the hidden-games list:
/// [HomeGameEntry.gameId] if set, otherwise the `<gameId>` prefix of
/// [HomeGameEntry.titleKey].
String gameIdOf(HomeGameEntry g) => g.gameId ?? g.titleKey.split('.').first;

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

/// Filters [allGames] down to the entries that should currently be shown.
///
/// Entries must pass the category and age-group filters. On top of those,
/// when [hideListedGames] is true every entry whose [gameIdOf] id appears
/// in [hiddenGameIds] is removed *before* any other filter is applied —
/// the master hide-list (the "hide selected games" settings toggle backed
/// by `assets/data/hidden_games.json`) overrides the other settings.
List<HomeGameEntry> visibleGames(
  List<HomeGameEntry> allGames, {
  required GameCategory category,
  required AgeGroup ageGroup,
  required bool hideListedGames,
  required Set<String> hiddenGameIds,
}) {
  return allGames.where((g) {
    if (hideListedGames && hiddenGameIds.contains(gameIdOf(g))) {
      return false;
    }
    final catOk = category == GameCategory.all || g.category == category;
    final ageOk = ageGroup == AgeGroup.all || g.ageGroups.contains(ageGroup);
    return catOk && ageOk;
  }).toList();
}

/// Filters [allGames] by the player's current category/age-group settings
/// (plus the hide-selected-games master toggle — see [visibleGames]) and
/// renders the remainder as [GameTile]s wired up to navigate via
/// [Navigator.pushNamed].
List<Widget> buildGameTiles(
  BuildContext context,
  List<HomeGameEntry> allGames,
  SettingsProvider settings,
  AppLocalizations localizer,
) {
  return visibleGames(
    allGames,
    category: settings.gameCategory,
    ageGroup: settings.ageGroup,
    hideListedGames: settings.hideListedGames,
    hiddenGameIds: settings.hiddenGameIds,
  ).map<Widget>((g) => GameTile(
        title: localizer(g.titleKey),
        imagePath: g.imagePath,
        icon: g.icon,
        onTap: () {
          // titleKey is always '<gameId>.title' — strip the suffix to get
          // the id used by the recorded '<gameId>_title' speech clip.
          final gameId = g.titleKey.split('.').first;
          // Number Race plays its own title clip as the first step of its
          // character-select intro sequence (title -> pause -> choose
          // character), so skip the generic tap-triggered play here to
          // avoid overlapping playback of the same clip.
          if (gameId != 'number_race') {
            AudioService.playInstructionClip(gameId, 'title', locale: localizer.locale);
          }
          Navigator.pushNamed(context, g.route, arguments: g.arguments);
        },
      )).toList();
}
