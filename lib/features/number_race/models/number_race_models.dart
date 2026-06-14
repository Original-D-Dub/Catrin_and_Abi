import '../../../core/constants/asset_paths.dart';

/// The three racers a player can choose between.
enum RaceCharacter {
  gary,
  pero,
  jamjam;

  /// Portrait/sprite used on the character-select card and the race track.
  String get assetPath {
    switch (this) {
      case RaceCharacter.gary:
        return 'assets/games/letter_quest/Gary.png';
      case RaceCharacter.pero:
        return AssetPaths.peroDefault;
      case RaceCharacter.jamjam:
        return 'assets/characters/space-jamjam.png';
    }
  }

  /// Translation key for this character's display name.
  String get nameKey => 'number_race.character.$name';
}
