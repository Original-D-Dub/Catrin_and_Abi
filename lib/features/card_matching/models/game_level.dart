import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_constants.dart';

/// Configuration for a game level.
///
/// Defines which letters are included, their colors,
/// and display information for the level.
///
/// Example:
/// ```dart
/// final level1 = GameLevel.level1();
/// print(level1.letters); // ['a', 'e', 'i', 'o', 'u']
/// ```
class GameLevel {
  /// Display name of the level (English)
  final String name;

  /// Display name of the level (Welsh)
  final String nameCy;

  /// Level number (1, 2, 3, etc.)
  final int levelNumber;

  /// Letters included in this level
  final List<String> letters;

  /// Color assignments for each letter pair
  final Map<String, Color> pairColors;

  /// Creates a game level configuration.
  const GameLevel({
    required this.name,
    required this.nameCy,
    required this.levelNumber,
    required this.letters,
    required this.pairColors,
  });

  /// Level 1: Vowels (a, e, i, o, u)
  ///
  /// The simplest level with only 5 pairs (10 cards total).
  /// Color-coded for easy matching.
  factory GameLevel.level1() {
    return GameLevel(
      name: GameConstants.level1Name,
      nameCy: GameConstants.level1NameCy,
      levelNumber: 1,
      letters: GameConstants.level1Letters,
      pairColors: AppColors.vowelPairColors,
    );
  }

  /// Level 2: A to E (a, b, c, d, e)
  ///
  /// 5 pairs (10 cards total) with first 5 letters.
  factory GameLevel.level2() {
    return GameLevel(
      name: GameConstants.level2Name,
      nameCy: GameConstants.level2NameCy,
      levelNumber: 2,
      letters: GameConstants.level2Letters,
      pairColors: AppColors.letterPairColors,
    );
  }

  /// Level 3: A to I (a, b, c, d, e, f, g, h, i)
  ///
  /// 9 pairs (18 cards total) with letters a through i.
  factory GameLevel.level3() {
    return GameLevel(
      name: GameConstants.level3Name,
      nameCy: GameConstants.level3NameCy,
      levelNumber: 3,
      letters: GameConstants.level3Letters,
      pairColors: AppColors.letterPairColors,
    );
  }

  /// Level 4: I to O (i, j, k, l, m, n, o)
  ///
  /// 7 pairs (14 cards total) with letters i through o.
  factory GameLevel.level4() {
    return GameLevel(
      name: GameConstants.level4Name,
      nameCy: GameConstants.level4NameCy,
      levelNumber: 4,
      letters: GameConstants.level4Letters,
      pairColors: AppColors.letterPairColors,
    );
  }

  /// Level 5: P to Z (p, q, r, s, t, u, v, w, x, y, z)
  ///
  /// 11 pairs (22 cards total) with letters p through z.
  factory GameLevel.level5() {
    return GameLevel(
      name: GameConstants.level5Name,
      nameCy: GameConstants.level5NameCy,
      levelNumber: 5,
      letters: GameConstants.level5Letters,
      pairColors: AppColors.letterPairColors,
    );
  }

  /// Returns all available game levels.
  static List<GameLevel> allLevels() {
    return [
      GameLevel.level1(),
      GameLevel.level2(),
      GameLevel.level3(),
      GameLevel.level4(),
      GameLevel.level5(),
    ];
  }

  /// Total number of card pairs in this level
  int get totalPairs => letters.length;

  /// Total number of cards in this level (pairs * 2)
  int get totalCards => letters.length * 2;

  /// Gets the color for a specific letter.
  ///
  /// Returns grey if the letter is not found (shouldn't happen).
  Color getColorForLetter(String letter) {
    return pairColors[letter.toLowerCase()] ?? Colors.grey;
  }
}
