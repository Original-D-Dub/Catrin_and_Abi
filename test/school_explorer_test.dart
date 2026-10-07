import 'dart:ui';

import 'package:catrin_abi_bsl/core/constants/game_filters.dart';
import 'package:catrin_abi_bsl/core/localization/translations_cy.dart';
import 'package:catrin_abi_bsl/core/localization/translations_en.dart';
import 'package:catrin_abi_bsl/features/school_explorer/game/iso_painter.dart';
import 'package:catrin_abi_bsl/features/school_explorer/game/object_details.dart';
import 'package:catrin_abi_bsl/features/school_explorer/models/school_layouts.dart';
import 'package:catrin_abi_bsl/features/school_explorer/models/school_scene.dart';
import 'package:catrin_abi_bsl/features/school_explorer/widgets/fingerspelled_word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IsoPainter draw order', () {
    const colour = Color(0xFF000000);

    test('a part resting on top of another is drawn after it', () {
      const base = IsoPart(0, 0, 0, 4, 2, 0.8, colour);
      const onTop = IsoPart(0, 0, 0.8, 1, 0.25, 2, colour);
      final sorted = IsoPainter.sortForDrawing(
          [onTop, base], IsoPainter.boxOfPart);
      expect(sorted, [base, onTop]);
    });

    test('a part further back (lower x/y) is drawn first', () {
      const back = IsoPart(0, 0, 0, 1, 1, 2, colour);
      const front = IsoPart(2, 0, 0, 1, 1, 0.5, colour);
      expect(
          IsoPainter.sortForDrawing([front, back], IsoPainter.boxOfPart),
          [back, front]);
    });

    test('a flat rug under an object is drawn first', () {
      const rug = IsoPart(0, 0, 0, 3, 3, 0, colour);
      const chair = IsoPart(1, 1, 0, 0.5, 0.5, 0.8, colour);
      expect(IsoPainter.sortForDrawing([chair, rug], IsoPainter.boxOfPart),
          [rug, chair]);
    });
  });

  group('SchoolLayouts', () {
    for (final area in SchoolArea.values) {
      final scene = SchoolLayouts.forArea(area);

      test('${area.name}: ids are unique and every key is translated', () {
        final ids = scene.objects.map((o) => o.id).toList();
        expect(ids.toSet().length, ids.length);
        for (final o in scene.objects) {
          for (final key in [o.nameKey, '${o.nameKey}.info',
              '${o.nameKey}.find', o.spellKey]) {
            expect(translationsEn.containsKey(key), isTrue, reason: key);
            expect(translationsCy.containsKey(key), isTrue, reason: key);
          }
        }
        for (final key in [area.titleKey, 'school_explorer.go_to.${area.name}']) {
          expect(translationsEn.containsKey(key), isTrue, reason: key);
          expect(translationsCy.containsKey(key), isTrue, reason: key);
        }
      });

      test('${area.name}: has enough distinct things to find', () {
        final names = scene.findableObjects.map((o) => o.nameKey).toSet();
        expect(names.length, greaterThanOrEqualTo(5));
      });
    }

    test('every door leads somewhere else, and every area is reachable', () {
      final reachable = <SchoolArea>{SchoolArea.classroom};
      var changed = true;
      while (changed) {
        changed = false;
        for (final area in reachable.toList()) {
          for (final o in SchoolLayouts.forArea(area).objects) {
            final to = o.leadsTo;
            if (to == null) continue;
            expect(to, isNot(area));
            if (reachable.add(to)) changed = true;
          }
        }
      }
      expect(reachable, SchoolArea.values.toSet());
    });
  });

  group('Rendering', () {
    test('every object paints (with close-up detail) without throwing', () {
      var detailed = 0;
      for (final area in SchoolArea.values) {
        for (final o in SchoolLayouts.forArea(area).objects) {
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          for (final p in o.parts) {
            IsoPainter.paintShadow(canvas, p);
            IsoPainter.paintPart(canvas, p);
          }
          final art = ObjectDetails.artPainterFor(o);
          if (art != null) {
            art(canvas, o, 0.0, 0.5);
            art(canvas, o, 1.0, 0.5);
            detailed++;
          }
          final detail = ObjectDetails.painterFor(o);
          if (detail != null) {
            detail(canvas, o, 1.0, 1.25);
            detailed++;
          }
          recorder.endRecording().dispose();
        }
      }
      expect(detailed, greaterThan(0));
    });

    test('roundedPolygon copes with zero-length edges', () {
      const pts = [Offset.zero, Offset.zero, Offset(10, 0), Offset(10, 10)];
      expect(() => IsoPainter.roundedPolygon(pts, 7), returnsNormally);
    });
  });

  group('FingerspelledWord.lettersFor', () {
    test('BSL spells letters and marks word breaks', () {
      expect(FingerspelledWord.lettersFor("Teacher's desk", SignSystem.bsl),
          ['t', 'e', 'a', 'c', 'h', 'e', 'r', 's', ' ', 'd', 'e', 's', 'k']);
    });

    test('IAC keeps Welsh digraphs together and strips circumflexes', () {
      expect(FingerspelledWord.lettersFor('Ffrâm ddringo', SignSystem.iac),
          ['ff', 'r', 'a', 'm', ' ', 'dd', 'r', 'i', 'ng', 'o']);
    });
  });
}
