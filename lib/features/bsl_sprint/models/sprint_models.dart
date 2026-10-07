import 'package:flutter/material.dart';

/// Level configuration for BSL Sprint.
class SprintLevel {
  final int number;
  final String name;

  /// Multiplier applied to scrollSpeed when advancing the road-marking offset.
  final double scrollMultiplier;

  /// Starting scroll speed (world units / second) for this level.
  final double initialScrollSpeed;

  /// Starting seconds between spawn waves for this level.
  final double initialSpawnInterval;

  /// Shortest the gap between spawn waves can get as the level speeds up.
  final double minSpawnInterval;

  const SprintLevel({
    required this.number,
    required this.name,
    required this.scrollMultiplier,
    required this.initialScrollSpeed,
    required this.initialSpawnInterval,
    required this.minSpawnInterval,
  });

  static const List<SprintLevel> all = [
    SprintLevel(
      number: 0,
      name: 'Training',
      scrollMultiplier: 3.0,
      initialScrollSpeed: 0.07,
      initialSpawnInterval: 1.2,
      minSpawnInterval: 1.25,
    ),
    SprintLevel(
      number: 1,
      name: 'Beginner',
      scrollMultiplier: 5.0,
      initialScrollSpeed: 0.119,
      initialSpawnInterval: 2.0,
      minSpawnInterval: 1.0,
    ),
    SprintLevel(
      number: 2,
      name: 'Sprint',
      scrollMultiplier: 8.0,
      initialScrollSpeed: 0.133,
      initialSpawnInterval: 2.0,
      minSpawnInterval: 1.0,
    ),
  ];
}

/// A character the player can race as.
///
/// Each racer's art lives in `assets/games/bsl_sprint/<folder>/` and is named
/// `<prefix>.png` (thumbnail), `<prefix>-run-1..4.png`, `<prefix>-jump.png` and
/// `<prefix>-landing.png`.
/// Every frame is 317 × 450 px.
class SprintRacer {
  /// Stable identifier, also used as the file-name prefix (e.g. "jam-jam").
  final String id;

  /// Name shown under the thumbnail.
  final String name;

  /// Folder under `assets/games/bsl_sprint/` holding this racer's art.
  final String folder;

  const SprintRacer({
    required this.id,
    required this.name,
    required this.folder,
  });

  String get _base => 'assets/games/bsl_sprint/$folder/$id';

  /// Thumbnail shown on the racer-select grid.
  String get thumbnail => '$_base.png';

  /// Run-cycle frames, played in order and looped.
  List<String> get runFrames => [for (var i = 1; i <= 4; i++) '$_base-run-$i.png'];

  /// Pose shown while airborne.
  String get jumpFrame => '$_base-jump.png';

  /// Pose shown briefly as the racer touches down after a jump.
  String get landingFrame => '$_base-landing.png';

  static const List<SprintRacer> all = [
    SprintRacer(id: 'abi', name: 'Abi', folder: 'Abi'),
    SprintRacer(id: 'catrin', name: 'Catrin', folder: 'Catrin'),
    SprintRacer(id: 'harley', name: 'Harley', folder: 'Harley'),
    SprintRacer(id: 'jam-jam', name: 'JamJam', folder: 'JamJam'),
    SprintRacer(id: 'osian', name: 'Osian', folder: 'Osian'),
    SprintRacer(id: 'ruby', name: 'Ruby', folder: 'Ruby'),
    SprintRacer(id: 'ryan', name: 'Ryan', folder: 'Ryan'),
  ];
}

/// The lifecycle states for the BSL Sprint game.
enum SprintState {
  idle,     // start screen, waiting to begin
  playing,  // active game loop running
  gameOver, // lives ran out — show retry panel
  won,      // all target words spelled — show success overlay
}

/// A single item scrolling down one of the three lanes.
///
/// Items spawn above the visible area ([y] < 0) and scroll downward each tick.
/// Once [y] exceeds 1.2 (off the bottom) or [collected] is true the item is
/// considered inactive and is removed from the active list by the provider.
class SprintItem {
  /// The uppercase letter displayed on this item.  Empty string for obstacles.
  final String letter;

  /// Which lane this item occupies: 0 = left, 1 = middle, 2 = right.
  final int lane;

  /// Normalised vertical position: 0.0 = top of game area, 1.0 = bottom.
  double y;

  /// True once the player has collected or been hit by this item.
  bool collected;

  /// When true this item is a hazard the player must jump over.
  final bool isObstacle;

  /// When true this item is a wall the player cannot jump over — must change lane.
  final bool isBarrier;

  /// Background tint colour used when rendering this item.
  /// Mutable so it can be updated when a decoy becomes the new correct letter.
  Color displayColour;

  SprintItem({
    required this.letter,
    required this.lane,
    required this.y,
    this.collected = false,
    this.isObstacle = false,
    this.isBarrier = false,
    required this.displayColour,
  });

  /// Returns false once the item has scrolled off-screen or been collected.
  bool get isActive => !collected && y < 1.2;
}
