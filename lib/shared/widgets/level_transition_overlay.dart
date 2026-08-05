import 'package:flutter/material.dart';

import '../../core/constants/game_filters.dart' show SignSystem;
import '../services/audio_service.dart';

/// Duration of each stage of the level-select → gameplay transition: the
/// delay before the fade starts, the fade to black, and the fade back in.
const Duration kLevelTransitionDuration = Duration(milliseconds: 600);

/// Full-screen black overlay for the level-select → gameplay transition.
///
/// Wrap in `Positioned.fill` as the last child of the screen's outer
/// [Stack] (above both the level-select and gameplay content) and drive
/// [opacity] from [LevelTransitionMixin.levelTransitionOpacity].
class LevelTransitionOverlay extends StatelessWidget {
  final double opacity;

  const LevelTransitionOverlay({super.key, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: opacity == 0,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: kLevelTransitionDuration,
        child: const ColoredBox(color: Colors.black),
      ),
    );
  }
}

/// Drives the black-fade transition played when a level tile is tapped on
/// the level-select screen.
///
/// Timeline: play the level-name audio → wait [kLevelTransitionDuration] →
/// fade to black over [kLevelTransitionDuration] → run [startLevel] to swap
/// in the gameplay content (hidden behind the now-opaque overlay) → fade
/// back to transparent over [kLevelTransitionDuration].
mixin LevelTransitionMixin<T extends StatefulWidget> on State<T> {
  double levelTransitionOpacity = 0.0;

  Future<void> startLevelWithTransition({
    required String gameId,
    required int levelNumber,
    String locale = 'en',
    SignSystem? signSystem,
    required VoidCallback startLevel,
  }) async {
    AudioService.playLevelName(
      gameId,
      levelNumber,
      locale: locale,
      signSystem: signSystem,
    );

    await Future.delayed(kLevelTransitionDuration);
    if (!mounted) return;
    setState(() => levelTransitionOpacity = 1.0);

    await Future.delayed(kLevelTransitionDuration);
    if (!mounted) return;
    startLevel();
    setState(() => levelTransitionOpacity = 0.0);
  }
}
