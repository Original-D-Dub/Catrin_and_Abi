import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/constants/game_filters.dart';

/// Configuration for a card matching game level.
///
/// [name] is a translation key (e.g. `'card_matching.bsl.level1.name'`),
/// resolved via [AppLocalizations] when displayed.
class GameLevel {
  final int levelNumber;
  final String name;
  final List<String> letters;
  final Map<String, Color> pairColors;

  const GameLevel({
    required this.levelNumber,
    required this.name,
    required this.letters,
    required this.pairColors,
  });

  int get totalPairs => letters.length;
  int get totalCards => letters.length * 2;

  Color getColorForLetter(String letter) {
    return pairColors[letter.toLowerCase()] ?? Colors.grey;
  }

  // ─────────────────────────────────────────
  // BSL levels (English alphabet)
  // ─────────────────────────────────────────

  static const GameLevel bslLevel1 = GameLevel(
    levelNumber: 1,
    name: 'card_matching.bsl.level1.name',
    letters: GameConstants.level1Letters,
    pairColors: AppColors.vowelPairColors,
  );

  static const GameLevel bslLevel2 = GameLevel(
    levelNumber: 2,
    name: 'card_matching.bsl.level2.name',
    letters: GameConstants.level2Letters,
    pairColors: AppColors.letterPairColors,
  );

  static const GameLevel bslLevel3 = GameLevel(
    levelNumber: 3,
    name: 'card_matching.bsl.level3.name',
    letters: GameConstants.level3Letters,
    pairColors: AppColors.letterPairColors,
  );

  static const GameLevel bslLevel4 = GameLevel(
    levelNumber: 4,
    name: 'card_matching.bsl.level4.name',
    letters: GameConstants.level4Letters,
    pairColors: AppColors.letterPairColors,
  );

  static const GameLevel bslLevel5 = GameLevel(
    levelNumber: 5,
    name: 'card_matching.bsl.level5.name',
    letters: GameConstants.level5Letters,
    pairColors: AppColors.letterPairColors,
  );

  /// Level 6: Full Alphabet — 10 letters drawn at random each game.
  static GameLevel bslLevel6() {
    const fullAlphabet = [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
      'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    ];
    final letters = [...fullAlphabet]..shuffle(Random());
    return GameLevel(
      levelNumber: 6,
      name: 'card_matching.bsl.level6.name',
      letters: letters.take(10).toList(),
      pairColors: AppColors.letterPairColors,
    );
  }

  static List<GameLevel> get bslLevels =>
      [bslLevel1, bslLevel2, bslLevel3, bslLevel4, bslLevel5, bslLevel6()];

  // ─────────────────────────────────────────
  // IAC levels (Welsh alphabet, incl. digraphs)
  // ─────────────────────────────────────────

  /// Level 1: Welsh vowels — a, e, i, o, u, w, y (7 pairs)
  static const GameLevel iacLevel1 = GameLevel(
    levelNumber: 1,
    name: 'card_matching.iac.level1.name',
    letters: ['a', 'e', 'i', 'o', 'u', 'w', 'y'],
    pairColors: AppColors.welshVowelPairColors,
  );

  /// Level 2: a to e (a, b, c, ch, d, dd, e — 7 pairs)
  static const GameLevel iacLevel2 = GameLevel(
    levelNumber: 2,
    name: 'card_matching.iac.level2.name',
    letters: ['a', 'b', 'c', 'ch', 'd', 'dd', 'e'],
    pairColors: {
      ...AppColors.letterPairColors,
      ...AppColors.welshDigraphPairColors,
    },
  );

  /// Level 3: e to i (e, f, ff, g, ng, h, i — 7 pairs)
  static const GameLevel iacLevel3 = GameLevel(
    levelNumber: 3,
    name: 'card_matching.iac.level3.name',
    letters: ['e', 'f', 'ff', 'g', 'ng', 'h', 'i'],
    pairColors: {
      ...AppColors.letterPairColors,
      ...AppColors.welshDigraphPairColors,
    },
  );

  /// Level 4: j to s (j, l, ll, m, n, o, p, r, rh, s — 10 pairs)
  static const GameLevel iacLevel4 = GameLevel(
    levelNumber: 4,
    name: 'card_matching.iac.level4.name',
    letters: ['j', 'l', 'll', 'm', 'n', 'o', 'p', 'r', 'rh', 's'],
    pairColors: {
      ...AppColors.letterPairColors,
      ...AppColors.welshDigraphPairColors,
    },
  );

  /// Level 5: o to y (o, p, r, rh, s, t, th, u, w, y — 10 pairs)
  static const GameLevel iacLevel5 = GameLevel(
    levelNumber: 5,
    name: 'card_matching.iac.level5.name',
    letters: ['o', 'p', 'r', 'rh', 's', 't', 'th', 'u', 'w', 'y'],
    pairColors: {
      ...AppColors.letterPairColors,
      ...AppColors.welshDigraphPairColors,
    },
  );

  /// Level 6: Full Welsh alphabet — 10 random letters each game.
  static GameLevel iacLevel6() {
    const fullWelsh = [
      'a', 'b', 'c', 'ch', 'd', 'dd', 'e', 'f', 'ff', 'g',
      'h', 'i', 'j', 'l', 'll', 'm', 'n', 'ng', 'o', 'p',
      'ph', 'r', 'rh', 's', 't', 'th', 'u', 'w', 'y',
    ];
    final allColors = <String, Color>{
      ...AppColors.welshVowelPairColors,
      ...AppColors.welshDigraphPairColors,
      ...AppColors.letterPairColors,
    };
    final letters = [...fullWelsh]..shuffle(Random());
    final chosen = letters.take(10).toList();
    return GameLevel(
      levelNumber: 6,
      name: 'card_matching.iac.level6.name',
      letters: chosen,
      pairColors: {for (final l in chosen) l: allColors[l] ?? Colors.grey},
    );
  }

  static List<GameLevel> get iacLevels =>
      [iacLevel1, iacLevel2, iacLevel3, iacLevel4, iacLevel5, iacLevel6()];

  /// Returns the level list for the given sign system.
  static List<GameLevel> forSignSystem(SignSystem signSystem) =>
      signSystem == SignSystem.iac ? iacLevels : bslLevels;
}
