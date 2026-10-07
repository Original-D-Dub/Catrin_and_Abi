/// Zoo-specific tweaks for the characters on the choose-a-character grid
/// ([CharacterThumb], keyed by [CharacterThumb.id]). Characters not listed
/// here use the defaults.
class ZooCharacter {
  ZooCharacter._();

  /// Multipliers on a character's rendered height on the zoo map, relative
  /// to the other characters' shared body size.
  static const Map<String, double> _heightScales = {'catrin': 1.2};

  /// Height multiplier for the character with [id]; 1.0 keeps the standard
  /// size.
  static double heightScaleFor(String id) => _heightScales[id] ?? 1.0;
}
