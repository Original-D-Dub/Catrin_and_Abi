import 'dart:io';

import 'package:catrin_abi_bsl/features/counting_game/providers/counting_game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('counting game Patterns/Random group split', () {
    test('17 levels; Patterns lists 1-6, Random lists 7-13', () {
      expect(countingColourPairs.length, 17);
      expect(CountingGameProvider.patternTabLevels, [1, 2, 3, 4, 5, 6]);
      expect(CountingGameProvider.randomTabLevels, [7, 8, 9, 10, 11, 12, 13]);
      for (var i = 0; i < countingColourPairs.length; i++) {
        expect(countingColourPairs[i].name, 'counting_game.level${i + 1}.name');
      }
    });

    test('Patterns group numbers pass through unchanged (canonical 1-6)', () {
      for (var canonical = 1; canonical <= 6; canonical++) {
        expect(
          CountingGameProvider.displayLevelNumber(canonical),
          canonical,
          reason: 'canonical level $canonical',
        );
      }
    });

    test('Random group renumbers canonical 7-13 to on-screen 1-7', () {
      for (var i = 1; i <= 7; i++) {
        expect(
          CountingGameProvider.displayLevelNumber(6 + i),
          i,
          reason: 'canonical level ${6 + i}',
        );
      }
    });

    test('next level flows through Patterns then Random, ending after 13', () {
      for (var canonical = 1; canonical < 13; canonical++) {
        expect(CountingGameProvider.nextLevelNumber(canonical), canonical + 1);
      }
      expect(CountingGameProvider.nextLevelNumber(13), isNull);
      // Canonical 14-17 aren't listed in any group — continue as level 4.
      expect(CountingGameProvider.nextLevelNumber(17), 5);
    });
  });

  group('counting game Champion Mode', () {
    test('unlocks on a score of 10+ in either level 4 game', () {
      expect(CountingGameProvider.championModeUnlockScore, 10);
      // Patterns level 4 and Random level 4 (canonical 10) — both
      // 60-second timed levels.
      expect(CountingGameProvider.championModeUnlockLevels, [4, 10]);
      for (final level in CountingGameProvider.championModeUnlockLevels) {
        expect(
          countingColourPairs[level - 1].isTimed,
          isTrue,
          reason: 'canonical level $level should be timed',
        );
      }
    });
  });

  test('group tile placeholder images ship with the app', () {
    // flutter test runs from the package root; the folder is bundled via
    // pubspec's assets list.
    expect(
      File('assets/images/counting_game/patterns_tile.png').existsSync(),
      isTrue,
    );
    expect(
      File('assets/images/counting_game/random_tile.png').existsSync(),
      isTrue,
    );
  });
}
