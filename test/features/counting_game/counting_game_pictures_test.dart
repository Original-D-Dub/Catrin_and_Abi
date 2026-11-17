import 'dart:io';

import 'package:catrin_abi_bsl/core/localization/translations_cy.dart';
import 'package:catrin_abi_bsl/core/localization/translations_en.dart';
import 'package:catrin_abi_bsl/features/counting_game/providers/counting_game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('counting game picture objects', () {
    test('Random levels 7-13 use pictures; the rest keep circles', () {
      for (var i = 0; i < countingColourPairs.length; i++) {
        expect(
          countingColourPairs[i].usePictures,
          i + 1 >= 7 && i + 1 <= 13,
          reason: 'level ${i + 1}',
        );
      }
    });

    test('every picture exists on disk', () {
      for (final object in CountingObject.values) {
        for (final file in object.images) {
          final path = 'assets/images/counting_game/${object.name}/$file';
          expect(File(path).existsSync(), isTrue, reason: path);
        }
        for (final file in object.byColour.values) {
          expect(object.images, contains(file));
        }
      }
    });

    test('two-colour picture levels have an object in both colours', () {
      for (final level in countingColourPairs) {
        if (!level.usePictures ||
            level.singleColour ||
            level.usesNumberColours) {
          continue;
        }
        expect(
          CountingObject.values.any(
            (o) =>
                o.byColour.containsKey(level.nameA) &&
                o.byColour.containsKey(level.nameB),
          ),
          isTrue,
          reason: level.name,
        );
      }
    });

    test('every object question is translated', () {
      final keys = ['counting_game.object.altogether'];
      for (final object in CountingObject.values) {
        final base = 'counting_game.object.${object.name}';
        keys.addAll(['$base.how_many', '$base.total', '$base.altogether']);
        keys.addAll(object.byColour.keys.map((c) => '$base.$c'));
      }
      for (final key in keys) {
        expect(translationsEn.containsKey(key), isTrue, reason: key);
        expect(translationsCy.containsKey(key), isTrue, reason: key);
      }
    });
  });
}
