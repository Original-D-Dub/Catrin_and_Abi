import 'package:flutter/material.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/level_path_map.dart';
import '../widgets/zoo_screen_chrome.dart';

/// Choose-a-level screen for the zoo game: the shared winding-path level
/// map ([LevelPathMap], as used by Number Race) drawn over the zoo photo
/// background. Tapping an unlocked level opens that level's route from
/// [levels]; nodes past the last defined level are locked.
class ZooLevelSelectScreen extends StatefulWidget {
  /// UI language ('en' or 'cy').
  final String locale;

  /// Sign system passed through to the level screens.
  final SignSystem signSystem;

  /// The character chosen on the pick-a-player screen, passed through to
  /// levels that draw the player on the zoo map (the quiz).
  final String characterId;

  const ZooLevelSelectScreen({
    super.key,
    this.locale = 'en',
    this.signSystem = SignSystem.bsl,
    this.characterId = 'abi',
  });

  /// The zoo's levels in order — level 1 is the first entry. Each level is
  /// a route plus the building it plays in ('' for map-wide levels like
  /// the quizzes) and, for quiz levels, which animal-zone set they play
  /// over ('zoo' or 'farm'). Add an entry to unlock the next level node.
  ///
  /// The building-walk levels (2 and 4) open [AppRoutes.zooMap] rather than
  /// [AppRoutes.zooBuilding] directly: the player always starts at the zoo
  /// gate and must find that level's building on the map and tap Enter
  /// before the building's own walk level opens.
  static const List<({String route, String building, String zones})> levels = [
    (route: AppRoutes.zooQuiz, building: '', zones: 'zoo'),
    (route: AppRoutes.zooMap, building: 'aquarium', zones: ''),
    (route: AppRoutes.zooQuiz, building: '', zones: 'farm'),
    (route: AppRoutes.zooMap, building: 'reptile-house', zones: ''),
  ];

  @override
  State<ZooLevelSelectScreen> createState() => _ZooLevelSelectScreenState();
}

class _ZooLevelSelectScreenState extends State<ZooLevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.playTitle('zoo', locale: widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    final signSystem = widget.signSystem;
    final characterId = widget.characterId;
    final levels = ZooLevelSelectScreen.levels;
    final localizer = AppLocalizations(locale: locale);

    return ZooBackgroundScaffold(
      child: Stack(
        children: [
          LevelPathMap(
            locale: locale,
            unlockedLevels: levels.length,
            onLevelSelected: (level) => Navigator.pushNamed(
              context,
              levels[level - 1].route,
              arguments: {
                'building': levels[level - 1].building,
                'zones': levels[level - 1].zones,
                'level': '$level',
                'locale': locale,
                'signSystem': signSystem.toPrefsString(),
                'character': characterId,
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.white.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const BackArrowIcon(),
                tooltip: localizer('general.back'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
