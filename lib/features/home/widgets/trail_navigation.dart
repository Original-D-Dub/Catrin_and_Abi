import 'package:flutter/material.dart';

import '../../../core/config/routes.dart';
import '../providers/trail_provider.dart';

/// Advances a "Learn BSL trail" session after a level is finished, called
/// from a game's "Next Level" button when [TrailProvider.activeNodeId] is
/// set (i.e. this game was launched from the trail, not played normally).
///
/// Always returns to the trail map rather than jumping straight into the
/// next game, so the player sees their progress and picks the next step
/// themselves — necessary at a fork (2 successors) or the trail's end (0
/// successors) anyway, and kept consistent for the common single-successor
/// case too.
void advanceTrail(BuildContext context, TrailProvider trail) {
  trail.exitTrail();
  Navigator.popUntil(context, ModalRoute.withName(AppRoutes.learnBslTrail));
}
