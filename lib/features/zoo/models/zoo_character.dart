/// A selectable player character for the zoo game.
///
/// [thumbAsset] is the square thumbnail shown on the pick-a-player grid and
/// (until full character art lands) on the player detail screen. Placeholder
/// slots (Player 5/6) have no artwork yet, so [thumbAsset] is null and the
/// screens fall back to a person icon.
class ZooCharacter {
  /// Stable identifier passed through route arguments and into [ZooProvider].
  final String id;

  /// Translation key for the character's display name.
  final String nameKey;

  /// Square thumbnail asset, or null for placeholder slots.
  final String? thumbAsset;

  /// Multiplier on this character's rendered height on the zoo map,
  /// relative to the other characters' shared body size. 1.0 (default)
  /// keeps the standard size.
  final double heightScale;

  const ZooCharacter({
    required this.id,
    required this.nameKey,
    this.thumbAsset,
    this.heightScale = 1.0,
  });

  /// Full-size portrait shown on the player screen, named `<id>.png` by
  /// convention (e.g. abi.png). Not every character's art exists yet —
  /// the player screen falls back to [thumbAsset] via errorBuilder, so
  /// dropping a new lowercase `<id>.png` into the characters directory is
  /// all that's needed.
  String get fullAsset => 'lib/features/zoo/characters/$id.png';

  /// All characters in pick-a-player grid order (2 x 3).
  static const List<ZooCharacter> all = [
    ZooCharacter(
      id: 'abi',
      nameKey: 'zoo.character.abi',
      thumbAsset: 'lib/features/zoo/characters/Abi_thumb.jpg',
    ),
    ZooCharacter(
      id: 'catrin',
      nameKey: 'zoo.character.catrin',
      thumbAsset: 'lib/features/zoo/characters/catrin_thumb.jpg',
      heightScale: 1.2,
    ),
    ZooCharacter(
      id: 'ruby',
      nameKey: 'zoo.character.ruby',
      thumbAsset: 'lib/features/zoo/characters/Ruby_thumb.jpg',
    ),
    ZooCharacter(
      id: 'osian',
      nameKey: 'zoo.character.osian',
      thumbAsset: 'lib/features/zoo/characters/osian_thumb.jpg',
    ),
    ZooCharacter(id: 'player5', nameKey: 'zoo.character.player5'),
    ZooCharacter(id: 'player6', nameKey: 'zoo.character.player6'),
  ];

  /// Looks up a character by [id], defaulting to the first (Abi).
  static ZooCharacter byId(String? id) => all.firstWhere(
        (c) => c.id == id,
        orElse: () => all.first,
      );
}
