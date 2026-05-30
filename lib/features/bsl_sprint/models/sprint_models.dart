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

  const SprintLevel({
    required this.number,
    required this.name,
    required this.scrollMultiplier,
    required this.initialScrollSpeed,
    required this.initialSpawnInterval,
  });

  static const List<SprintLevel> all = [
    SprintLevel(
      number: 0,
      name: 'Training',
      scrollMultiplier: 3.0,
      initialScrollSpeed: 0.1,
      initialSpawnInterval: 1.2,
    ),
    SprintLevel(
      number: 1,
      name: 'Beginner',
      scrollMultiplier: 5.0,
      initialScrollSpeed: 0.17,
      initialSpawnInterval: 2.0,
    ),
    SprintLevel(
      number: 2,
      name: 'Sprint',
      scrollMultiplier: 8.0,
      initialScrollSpeed: 0.19,
      initialSpawnInterval: 2.0,
    ),
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
