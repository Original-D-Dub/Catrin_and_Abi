import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../game/zoo_quest_game.dart';
import '../providers/zoo_provider.dart';

/// Main screen for the zoo exploration game.
///
/// Hosts the Flame [GameWidget] for [ZooQuestGame] under the same
/// [GameHeaderBar] chrome as the level 1 quiz map, so a building-hunt level
/// (2, 4) starts exactly like level 1 — same map, same walking character,
/// same header — differing only in the objective: instead of a BSL video
/// and Take a Picture button, a banner names the building to find, and a
/// floating Enter button appears once the player reaches it, opening that
/// building's screen ([AppRoutes.zooBuilding]) to continue the existing
/// take-a-picture gameplay inside.
///
/// When [ZooProvider.targetBuilding] is set (a level from the choose-a-level
/// screen rather than free roam) the Enter button only appears for that
/// building — the others are scenery for this level.
///
/// The [ZooProvider] is provided by the route in routes.dart.
class ZooScreen extends StatefulWidget {
  const ZooScreen({super.key});

  @override
  State<ZooScreen> createState() => _ZooScreenState();
}

class _ZooScreenState extends State<ZooScreen> {
  late final ZooQuestGame _game;

  @override
  void initState() {
    super.initState();
    _game = ZooQuestGame(provider: context.read<ZooProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ZooProvider>();
    final locale = provider.locale;
    final targetBuilding = provider.targetBuilding;
    final localizer = AppLocalizations(locale: locale);

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          // Same header chrome as the level 1 quiz map (back arrow, level
          // badge) — no score circle, since this stage has no photo count.
          SafeArea(
            child: GameHeaderBar(
              onBack: () => Navigator.of(context).pop(),
              showScore: false,
              levelNumber: provider.levelNumber,
            ),
          ),
          // Objective banner, naming the building to find — only shown
          // when playing a level (as opposed to free roam).
          if (targetBuilding != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Material(
                    color: const Color(0xFF3B6231),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        localizer('zoo.find_building.'
                            '${targetBuilding.replaceAll('-', '_')}'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Floating Enter button — visible while the player is inside the
          // target building's trigger zone (or any zone, in free roam),
          // positioned just above that building via the game's anchor.
          Consumer<ZooProvider>(
            builder: (context, provider, _) {
              final zone = provider.activeZone;
              final anchor = provider.activeZoneAnchor;
              if (zone == null || anchor == null) return const SizedBox.shrink();
              if (targetBuilding != null && zone.building != targetBuilding) {
                return const SizedBox.shrink();
              }

              const buttonWidth = 260.0;
              const buttonHeight = 56.0;
              const margin = 16.0;
              final screenSize = MediaQuery.of(context).size;
              final topInset = MediaQuery.of(context).padding.top;
              // Keep clear of the header bar (88px + safe-area inset).
              final minTop = topInset + 88 + margin;

              final left = (anchor.dx - buttonWidth / 2)
                  .clamp(margin, screenSize.width - buttonWidth - margin);
              final top = (anchor.dy - buttonHeight - margin)
                  .clamp(minTop, screenSize.height - buttonHeight - margin);

              return Positioned(
                left: left,
                top: top,
                child: FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF3B6231),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.meeting_room),
                  label: Text(
                    '${localizer('zoo.enter')} — '
                    '${localizer(zone.titleKey)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.zooBuilding,
                    arguments: {
                      'building': zone.building,
                      'locale': locale,
                      'signSystem': provider.signSystem.toPrefsString(),
                      'level': '${provider.levelNumber}',
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
