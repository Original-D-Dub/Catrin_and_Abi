import 'package:shared_preferences/shared_preferences.dart';

/// Characters that can mark the player's place on the Bubble Shooter level
/// map. Thumbnails come from the same folder as the card match game's
/// character select.
enum MapCharacter {
  abi('abi', 'Abi'),
  harley('harley', 'Harley');

  const MapCharacter(this.id, this.name);

  final String id;
  final String name;

  String get thumbAsset => 'assets/images/characters/${id}_thumb.png';

  static MapCharacter fromId(String? id) =>
      values.firstWhere((c) => c.id == id, orElse: () => abi);
}

/// On-device settings for the Bubble Shooter level map: the chosen
/// [MapCharacter] and the highest level completed (where the character
/// stands).
class BubbleShooterMapPrefs {
  static const _characterKey = 'bubble_shooter_map_character';
  static const _highestKey = 'bubble_shooter_highest_completed';

  Future<MapCharacter> character() async =>
      MapCharacter.fromId((await SharedPreferences.getInstance())
          .getString(_characterKey));

  Future<void> setCharacter(MapCharacter character) async =>
      (await SharedPreferences.getInstance())
          .setString(_characterKey, character.id);

  /// Highest level completed, or 0 if none.
  Future<int> highestCompleted() async =>
      (await SharedPreferences.getInstance()).getInt(_highestKey) ?? 0;

  /// Records [level] as completed (keeps the highest).
  Future<void> recordCompleted(int level) async {
    final prefs = await SharedPreferences.getInstance();
    if (level > (prefs.getInt(_highestKey) ?? 0)) {
      await prefs.setInt(_highestKey, level);
    }
  }
}
