import 'package:shared_preferences/shared_preferences.dart';

/// On-device progress for the ages 1–3 level map: the highest level
/// completed (the coin the character stands on, and how far the chest
/// levels have been reached). Mirrors Bubble Shooter's map prefs.
class VowelHandMapPrefs {
  static const _highestKey = 'vowel_hand_map_highest_completed';

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
