import 'dart:ui';

/// One animal enclosure area on the zoo map, used by the BSL video quiz.
///
/// The enclosures are artwork baked into `zoo_map.png`, so their zones are
/// defined here in map coordinates (2000×1400, matching the SVG viewBox)
/// rather than parsed from the SVG. Each rect covers the enclosure plus
/// the stretch of walkway beside it, so a player standing on the path in
/// front of the animal counts as "in front of" it.
class ZooAnimalZone {
  /// Animal identifier (English, untranslated) — used for translation
  /// keys and the BSL question video asset name, never displayed directly.
  final String id;

  /// Zone bounds in map coordinates.
  final Rect rect;

  /// Overrides which photo asset a picture taken in this zone reveals —
  /// defaults to [id] when null. Lets one animal have more than one
  /// trigger zone (e.g. a second, hidden spot along the path) that counts
  /// as the same animal for quiz matching but shows a different photo —
  /// see the hippo enclosure's two zones below.
  final String? photoVariant;

  const ZooAnimalZone(this.id, this.rect, {this.photoVariant});

  /// Asset id used to look up this zone's revealed photo — [photoVariant]
  /// when set, otherwise [id].
  String get photoId => photoVariant ?? id;

  /// Translation key for the animal's display name, e.g. `zoo.animal.lion`.
  String get nameKey => 'zoo.animal.$id';

  /// Every animal enclosure on the map, roughly clockwise from the
  /// top-left corner.
  static const List<ZooAnimalZone> all = [
    ZooAnimalZone('lion', Rect.fromLTWH(140, 50, 570, 450)),
    ZooAnimalZone('elephant', Rect.fromLTWH(650, 20, 700, 280)),
    ZooAnimalZone('tiger', Rect.fromLTWH(1340, 30, 630, 450)),
    ZooAnimalZone('rhino', Rect.fromLTWH(1600, 380, 370, 260)),
    ZooAnimalZone('crocodile', Rect.fromLTWH(1350, 480, 340, 330)),
    ZooAnimalZone('kangaroo', Rect.fromLTWH(1620, 770, 350, 300)),
    ZooAnimalZone('giraffe', Rect.fromLTWH(1230, 890, 390, 290)),
    ZooAnimalZone('gorilla', Rect.fromLTWH(820, 540, 490, 300)),
    ZooAnimalZone('monkey', Rect.fromLTWH(750, 260, 340, 190)),
    // Main hippo viewing spot, front-on from the busy top path — the
    // camera catches the hippo mid-yawn/splash, so the photo comes out
    // funny rather than flattering.
    ZooAnimalZone('hippo', Rect.fromLTWH(360, 390, 460, 280),
        photoVariant: 'hippo_funny'),
    // Second, hidden hippo photo spot: the quieter stretch of path that
    // curves down the west side of the pond toward the bear enclosure.
    // Sampled against the walkable path so it only covers the section of
    // that path actually bordering the hippo pond, not the whole
    // west-side walkway. Same `id` as the zone above (still "find the
    // hippo" for the quiz) but no `photoVariant`, so it reveals the
    // plain, clearer `hippo` photo.
    ZooAnimalZone('hippo', Rect.fromLTWH(305, 520, 55, 180)),
    ZooAnimalZone('bear', Rect.fromLTWH(50, 330, 340, 380)),
    ZooAnimalZone('penguin', Rect.fromLTWH(70, 710, 330, 340)),
    ZooAnimalZone('dolphin', Rect.fromLTWH(80, 1020, 550, 340)),
  ];

  /// The farm animals along the spur path at the bottom right of the map,
  /// in path order from the main ring: pig, horse, cow, sheep. Used by the
  /// farm level's quiz.
  ///
  /// The spur drops down at x≈1480-1560, runs right along y≈1180-1200 and
  /// hooks down at x≈1720-1780 to y≈1310; each zone covers the stretch of
  /// that path in front of its icon (the hook is split between the cow,
  /// on its upper right, and the sheep, by its lower end).
  static const List<ZooAnimalZone> farm = [
    ZooAnimalZone('pig', Rect.fromLTWH(1500, 1180, 120, 100)),
    ZooAnimalZone('horse', Rect.fromLTWH(1620, 1080, 160, 120)),
    ZooAnimalZone('cow', Rect.fromLTWH(1720, 1200, 250, 60)),
    ZooAnimalZone('sheep', Rect.fromLTWH(1600, 1260, 180, 130)),
  ];

  /// The zone from [zones] containing [point] (map coordinates), or null.
  static ZooAnimalZone? zoneAt(List<ZooAnimalZone> zones, Offset point) {
    for (final zone in zones) {
      if (zone.rect.contains(point)) return zone;
    }
    return null;
  }
}
