import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../core/constants/game_filters.dart';
import '../models/zoo_map_data.dart';

/// State for the zoo exploration game.
///
/// The Flame game reports which building trigger zone (if any) the player
/// is standing in; the screen shows/hides the floating Enter button in
/// response.
///
/// [locale] and [signSystem] are independent axes (see
/// bilingual-sign-game-structure): the map screen itself only uses
/// [locale], but [signSystem] is carried through to the building
/// interiors, whose activities will show BSL or IAC sign content.
class ZooProvider extends ChangeNotifier {
  /// UI language ('en' or 'cy'), passed to [AppLocalizations] by the screen.
  final String locale;

  /// Which sign alphabet the building activities should use.
  final SignSystem signSystem;

  /// The character chosen on the pick-a-player screen ([ZooCharacter.id]).
  final String characterId;

  /// The building the player must find and enter for this level (a zoo
  /// map trigger zone id, e.g. `reptile-house`), or null for free roam.
  ///
  /// When set, [ZooScreen] only offers the Enter button while the player
  /// stands in this building's zone — other buildings on the map are
  /// scenery for this level.
  final String? targetBuilding;

  /// This level's number, carried through to the building interior's
  /// header bar once the player finds and enters [targetBuilding].
  final int levelNumber;

  ZooProvider({
    this.locale = 'en',
    this.signSystem = SignSystem.bsl,
    this.characterId = 'abi',
    this.targetBuilding,
    this.levelNumber = 1,
  });

  ZooTriggerZone? _activeZone;
  Offset? _activeZoneAnchor;

  /// The trigger zone the player is currently inside, or null.
  ZooTriggerZone? get activeZone => _activeZone;

  /// Screen-space point (from the game's camera transform) just above the
  /// active zone's building, or null when no zone is active. [ZooScreen]
  /// anchors the Enter button here so it appears over the right building.
  Offset? get activeZoneAnchor => _activeZoneAnchor;

  /// Called by the game every frame with the current zone (or null) and,
  /// when a zone is active, the screen point just above its building.
  void setActiveZone(ZooTriggerZone? zone, [Offset? screenAnchor]) {
    if (_activeZone?.building == zone?.building &&
        _activeZoneAnchor == screenAnchor) {
      return;
    }
    _activeZone = zone;
    _activeZoneAnchor = screenAnchor;
    notifyListeners();
  }
}
