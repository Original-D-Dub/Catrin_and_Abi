import 'package:shared_preferences/shared_preferences.dart';

import '../../bubble_shooter/services/bubble_shooter_map_prefs.dart';

/// On-device progress for the More or Less level map: the chosen
/// [MapCharacter], the highest level completed (where the character
/// stands) and which treasure chests have been opened. Mirrors Bubble
/// Shooter's map prefs.
class MoreOrLessMapPrefs {
  static const _characterKey = 'more_or_less_map_character';
  static const _highestKey = 'more_or_less_highest_completed';
  static const _openedChestsKey = 'more_or_less_opened_chests';

  Future<MapCharacter> character() async => MapCharacter.fromId(
    (await SharedPreferences.getInstance()).getString(_characterKey),
  );

  Future<void> setCharacter(MapCharacter character) async =>
      (await SharedPreferences.getInstance()).setString(
        _characterKey,
        character.id,
      );

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

  /// Chest levels whose chest has been opened.
  Future<Set<int>> openedChests() async {
    final saved =
        (await SharedPreferences.getInstance()).getStringList(
          _openedChestsKey,
        ) ??
        const [];
    return saved.map(int.tryParse).whereType<int>().toSet();
  }

  /// Records the chest at [level] as opened.
  Future<void> recordChestOpened(int level) async {
    final opened = await openedChests();
    await (await SharedPreferences.getInstance()).setStringList(
      _openedChestsKey,
      [
        for (final l in {...opened, level}) '$l',
      ],
    );
  }
}
