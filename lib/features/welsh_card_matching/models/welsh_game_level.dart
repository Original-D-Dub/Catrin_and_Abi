import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Configuration for a Welsh card matching game level.
///
/// Uses the Welsh alphabet (Wyddor Gymraeg / Wyddor IAC) which includes
/// digraphs: ch, dd, ff, ng, ll, ph, rh, th.
class WelshGameLevel {
  final String name;
  final String nameCy;
  final int levelNumber;
  final List<String> letters;
  final Map<String, Color> pairColors;

  const WelshGameLevel({
    required this.name,
    required this.nameCy,
    required this.levelNumber,
    required this.letters,
    required this.pairColors,
  });

  /// Level 1: Welsh vowels — a, e, i, o, u, w, y (7 pairs)
  factory WelshGameLevel.level1() {
    return const WelshGameLevel(
      name: 'Welsh Vowels',
      nameCy: 'Llafariaid Cymraeg',
      levelNumber: 1,
      letters: ['a', 'e', 'i', 'o', 'u', 'w', 'y'],
      pairColors: AppColors.welshVowelPairColors,
    );
  }

  /// Level 2: Welsh digraphs — ch, dd, ff, ng, ll, ph, rh, th (8 pairs)
  factory WelshGameLevel.level2() {
    return const WelshGameLevel(
      name: 'Digraphs',
      nameCy: 'Deugraffiaid',
      levelNumber: 2,
      letters: ['ch', 'dd', 'ff', 'ng', 'll', 'ph', 'rh', 'th'],
      pairColors: AppColors.welshDigraphPairColors,
    );
  }

  /// Level 3: Welsh consonants a–n (b, c, d, f, g, h, j, l, m, n — 10 pairs)
  factory WelshGameLevel.level3() {
    return WelshGameLevel(
      name: 'b to n',
      nameCy: 'b i n',
      levelNumber: 3,
      letters: const ['b', 'c', 'd', 'f', 'g', 'h', 'j', 'l', 'm', 'n'],
      pairColors: Map.fromEntries(
        const ['b', 'c', 'd', 'f', 'g', 'h', 'j', 'l', 'm', 'n']
            .map((l) => MapEntry(l, AppColors.letterPairColors[l]!)),
      ),
    );
  }

  /// Level 4: Welsh consonants p–t (p, r, s, t — 4 pairs) + digraphs (4 pairs)
  factory WelshGameLevel.level4() {
    const letters = ['p', 'r', 's', 't', 'ch', 'dd', 'll', 'th'];
    final colors = <String, Color>{};
    for (final l in ['p', 'r', 's', 't']) {
      colors[l] = AppColors.letterPairColors[l]!;
    }
    colors['ch'] = AppColors.welshDigraphPairColors['ch']!;
    colors['dd'] = AppColors.welshDigraphPairColors['dd']!;
    colors['ll'] = AppColors.welshDigraphPairColors['ll']!;
    colors['th'] = AppColors.welshDigraphPairColors['th']!;
    return WelshGameLevel(
      name: 'Mixed',
      nameCy: 'Cymysg',
      levelNumber: 4,
      letters: letters,
      pairColors: colors,
    );
  }

  /// Level 5: Full Welsh alphabet — 10 random letters each game.
  factory WelshGameLevel.level5() {
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
    return WelshGameLevel(
      name: 'Wyddor Lawn',
      nameCy: 'Wyddor Lawn',
      levelNumber: 5,
      letters: chosen,
      pairColors: {for (final l in chosen) l: allColors[l] ?? Colors.grey},
    );
  }

  static List<WelshGameLevel> allLevels() => [
        WelshGameLevel.level1(),
        WelshGameLevel.level2(),
        WelshGameLevel.level3(),
        WelshGameLevel.level4(),
        WelshGameLevel.level5(),
      ];

  int get totalPairs => letters.length;
  int get totalCards => letters.length * 2;

  Color getColorForLetter(String letter) =>
      pairColors[letter.toLowerCase()] ?? Colors.grey;
}
