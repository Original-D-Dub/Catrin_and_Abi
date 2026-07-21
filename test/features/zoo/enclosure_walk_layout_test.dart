import 'dart:ui';

import 'package:catrin_abi_bsl/features/zoo/game/enclosure_walk_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const phone = Size(390, 844);
  const tablet = Size(810, 1080);

  group('EnclosureWalkLayout', () {
    test('window is 70% of screen width on mobile, 50% on tablet', () {
      final phoneLayout = EnclosureWalkLayout.forCanvas(phone, 5);
      final tabletLayout = EnclosureWalkLayout.forCanvas(tablet, 5);

      expect(phoneLayout.isTablet, isFalse);
      expect(phoneLayout.windowWidth, closeTo(phone.width * 0.7, 0.01));
      expect(tabletLayout.isTablet, isTrue);
      expect(tabletLayout.windowWidth, closeTo(tablet.width * 0.5, 0.01));
    });

    test('edge of the next enclosure is visible when centred on a window',
        () {
      for (final canvas in [phone, tablet]) {
        final layout = EnclosureWalkLayout.forCanvas(canvas, 5);
        // Camera centred on window 0: the screen shows half a width
        // either side. Window 1's near edge must fall inside that.
        final viewRight = layout.windowCenters[0] + canvas.width / 2;
        final nextLeftEdge =
            layout.windowCenters[1] - layout.windowWidth / 2;
        expect(nextLeftEdge, lessThan(viewRight),
            reason: 'next window edge should peek in on $canvas');
      }
    });

    test('player is 320px tall on mobile and taller on tablet', () {
      expect(EnclosureWalkLayout.forCanvas(phone, 5).playerHeight, 320);
      expect(EnclosureWalkLayout.forCanvas(tablet, 5).playerHeight,
          greaterThan(320));
    });

    test('floor strip sits below the windows', () {
      final layout = EnclosureWalkLayout.forCanvas(phone, 5);
      expect(layout.windowTop + layout.windowHeight,
          lessThan(layout.floorTop));
      expect(layout.playerBaselineY, greaterThan(layout.floorTop));
      expect(layout.playerBaselineY, lessThan(phone.height));
    });

    test('exit door sits after the last window and peeks into view', () {
      for (final canvas in [phone, tablet]) {
        final layout = EnclosureWalkLayout.forCanvas(canvas, 5);
        final lastRightEdge =
            layout.windowCenters.last + layout.windowWidth / 2;
        final doorLeftEdge = layout.doorCenterX - layout.doorWidth / 2;
        expect(doorLeftEdge, greaterThan(lastRightEdge));
        // Visible from the last window, like the next window would be.
        final viewRight = layout.windowCenters.last + canvas.width / 2;
        expect(doorLeftEdge, lessThan(viewRight));
        // And the camera can centre on it.
        expect(layout.worldWidth,
            greaterThanOrEqualTo(layout.doorCenterX + canvas.width / 2));

        expect(layout.doorHeight, greaterThan(layout.playerHeight));
        expect(layout.isAtDoor(layout.doorCenterX), isTrue);
        expect(layout.isAtDoor(layout.windowCenters.last), isFalse);
      }
    });

    test('windowIndexAt detects stopping zones around each centre', () {
      final layout = EnclosureWalkLayout.forCanvas(phone, 3);
      expect(layout.windowIndexAt(layout.windowCenters[1]), 1);
      expect(
          layout.windowIndexAt(
              layout.windowCenters[1] + layout.triggerHalfWidth + 1),
          isNull);
      expect(layout.windowIndexAt(0), isNull);
    });
  });
}
