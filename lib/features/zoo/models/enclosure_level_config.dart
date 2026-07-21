import 'dart:ui';

/// How the wall/floor surfaces of a walk level are textured.
enum WallTexture {
  /// Two-tone oval speckles — rocky (the aquarium).
  rock,

  /// Per-pixel noise grain — sandstone (the reptile house).
  sand,
}

/// One enclosure window in an [EnclosureLevelConfig].
///
/// [id] is an identifier (English, untranslated) used for translation keys
/// and, later, media asset paths — never displayed directly.
class EnclosureSpec {
  final String id;

  const EnclosureSpec(this.id);
}

/// Data for one side-scrolling "walk past the enclosures" building level.
///
/// The aquarium and the reptile house share the same game, screen and
/// provider ([EnclosureWalkGame] / EnclosureWalkScreen /
/// EnclosureWalkProvider); only this config differs. To open a new
/// building as a walk level, add a static config here and list it in
/// [forBuilding].
class EnclosureLevelConfig {
  /// Building identifier from the zoo map trigger zones
  /// (`aquarium`, `reptile-house`).
  final String building;

  /// Enclosures in walk order, left to right.
  final List<EnclosureSpec> enclosures;

  /// Base colour of the rocky wall the windows are set into.
  final Color wallColor;

  /// Floor the player walks on — slightly darker than [wallColor].
  final Color floorColor;

  /// Chunky rock frame around each window — darker again.
  final Color frameColor;

  /// Placeholder fill for the windows until pictures/video exist.
  final Color windowColor;

  /// Surface texture for the wall and floor.
  final WallTexture texture;

  const EnclosureLevelConfig({
    required this.building,
    required this.enclosures,
    required this.wallColor,
    required this.floorColor,
    required this.frameColor,
    required this.windowColor,
    this.texture = WallTexture.rock,
  });

  /// Translation key for the building name, e.g. `zoo.reptile_house`.
  String get titleKey => 'zoo.${building.replaceAll('-', '_')}';

  /// Translation key for an enclosure's plaque, e.g. `zoo.aquarium.sharks`.
  String enclosureNameKey(EnclosureSpec spec) =>
      'zoo.${building.replaceAll('-', '_')}.${spec.id}';

  /// The aquarium: cool blue-grey rock, deep-blue placeholder windows.
  static const aquarium = EnclosureLevelConfig(
    building: 'aquarium',
    enclosures: [
      EnclosureSpec('sharks'),
      EnclosureSpec('clownfish'),
      EnclosureSpec('seahorses'),
      EnclosureSpec('turtles'),
      EnclosureSpec('jellyfish'),
    ],
    wallColor: Color(0xFF57616B),
    floorColor: Color(0xFF454E57),
    frameColor: Color(0xFF3A424A),
    windowColor: Color(0xFF1565C0),
  );

  /// The reptile house: grainy sandstone walls, leafy-green terrarium
  /// placeholder windows.
  static const reptileHouse = EnclosureLevelConfig(
    building: 'reptile-house',
    enclosures: [
      EnclosureSpec('snakes'),
      EnclosureSpec('crocodiles'),
      EnclosureSpec('lizards'),
      EnclosureSpec('tortoises'),
      EnclosureSpec('geckos'),
    ],
    wallColor: Color(0xFFD3AC6C),
    floorColor: Color(0xFFBB934F),
    frameColor: Color(0xFF8E6B3A),
    windowColor: Color(0xFF3E7B2E),
    texture: WallTexture.sand,
  );

  /// The walk-level config for [building], or null if that building
  /// doesn't have one yet (it falls back to the coming-soon screen).
  static EnclosureLevelConfig? forBuilding(String building) =>
      switch (building) {
        'aquarium' => aquarium,
        'reptile-house' => reptileHouse,
        _ => null,
      };
}
