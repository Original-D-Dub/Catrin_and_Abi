import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/features/bsl_number_builder/screens/bsl_number_builder_screen.dart';
import 'package:catrin_abi_bsl/features/bsl_number_builder/widgets/belt_item.dart';
import 'package:catrin_abi_bsl/features/bsl_number_builder/widgets/coin_burst.dart';
import 'package:catrin_abi_bsl/features/bsl_number_builder/widgets/coin_counter.dart';
import 'package:catrin_abi_bsl/features/bsl_number_builder/widgets/conveyor_belt.dart';
import 'package:catrin_abi_bsl/shared/widgets/back_arrow_icon.dart';
import 'package:catrin_abi_bsl/shared/widgets/bsl_till.dart';
import 'package:catrin_abi_bsl/shared/widgets/game_header_bar.dart';
import 'package:catrin_abi_bsl/shared/widgets/level_select_screen.dart';
import 'package:catrin_abi_bsl/shared/widgets/rotate_device_overlay.dart';

void main() {
  const landscape = Size(900, 420);
  const arrive = Duration(milliseconds: 1500);
  // Tick (900ms) + leave (800ms) + next arrival (1400ms), with slack.
  const nextRound = Duration(milliseconds: 3300);

  Future<void> pumpAtSize(
    WidgetTester tester,
    Size size, {
    int seed = 7,
    int? level = 7,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BslNumberBuilderScreen(
          random: Random(seed),
          startLevel: level,
        ),
      ),
    );
  }

  // Advance in frames so chained animations and timers all get to run.
  Future<void> advance(WidgetTester tester, Duration total) async {
    const frame = Duration(milliseconds: 50);
    for (var t = Duration.zero; t < total; t += frame) {
      await tester.pump(frame);
    }
  }

  BslTill till(WidgetTester tester) =>
      tester.widget<BslTill>(find.byType(BslTill));
  GameHeaderBar header(WidgetTester tester) =>
      tester.widget<GameHeaderBar>(find.byType(GameHeaderBar));
  PriceTag tag(WidgetTester tester) =>
      tester.widget<PriceTag>(find.byType(PriceTag));
  int coins(WidgetTester tester) =>
      tester.widget<CoinCounter>(find.byType(CoinCounter)).coins;

  Future<void> press(WidgetTester tester, int value) async {
    await tester.tap(find.bySemanticsLabel('BSL $value'));
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('portrait shows the rotate-device overlay only', (tester) async {
    await pumpAtSize(tester, const Size(400, 800));
    expect(find.byType(RotateDeviceOverlay), findsOneWidget);
    expect(
      find.text('Turn your device to landscape mode to play'),
      findsOneWidget,
    );
    expect(find.byType(BslTill), findsNothing);
  });

  testWidgets('landscape shows the till, belt and header bar', (
    tester,
  ) async {
    await pumpAtSize(tester, landscape);
    expect(find.byType(BslTill), findsOneWidget);
    expect(find.byType(ConveyorBelt), findsOneWidget);
    expect(coins(tester), 0);

    final tillRect = tester.getRect(find.byType(BslTill));
    final belt = tester.getRect(find.byType(ConveyorBelt));
    expect(belt.left, 0);
    expect(belt.right, greaterThan(tillRect.left));

    // Header bar spans the screen, showing the level on the right.
    final bar = tester.getRect(find.byType(GameHeaderBar));
    expect(bar.left, 0);
    expect(bar.right, landscape.width);
    expect(header(tester).levelNumber, 7);
    // Coin pill sits inside the bar.
    final counter = tester.getRect(find.byType(CoinCounter));
    expect(bar.contains(counter.center), isTrue);
  });

  testWidgets('on a phone the screen bottom cuts the till keyhole in half', (
    tester,
  ) async {
    await pumpAtSize(tester, landscape);
    final tillRect = tester.getRect(find.byType(BslTill));
    expect(
      tillRect.top +
          tillRect.height *
              BslTillLayout.standard.keyholeY /
              BslTillLayout.standard.canvas.height,
      closeTo(landscape.height, 1),
    );
  });

  testWidgets('on a tablet the whole till is shown', (tester) async {
    const tablet = Size(1024, 768);
    await pumpAtSize(tester, tablet);
    final tillRect = tester.getRect(find.byType(BslTill));
    expect(tillRect.bottom, lessThanOrEqualTo(tablet.height));
  });

  testWidgets('item slides in from the left edge to the visible belt centre', (
    tester,
  ) async {
    await pumpAtSize(tester, landscape);
    expect(tester.getRect(find.byType(BeltItem)).right, lessThanOrEqualTo(1));
    expect(till(tester).enabled, isFalse);

    await advance(tester, arrive);
    final item = tester.getRect(find.byType(BeltItem));
    final tillLeft = tester.getRect(find.byType(BslTill)).left;
    final visibleRight =
        tillLeft + tester.getSize(find.byType(BslTill)).width * 47 / 2108;
    expect(item.center.dx, closeTo(visibleRight / 2, 1));
    expect(till(tester).enabled, isTrue);
    expect(tag(tester).showSign, isFalse);
  });

  testWidgets('correct price shows the tick and adds to the coins', (
    tester,
  ) async {
    await pumpAtSize(tester, landscape);
    await advance(tester, arrive);
    final price = tag(tester).price;

    await press(tester, price);
    expect(till(tester).display, '$price');
    expect(till(tester).showTick, isTrue);
    // Coins are still flying up to the counter.
    expect(find.byType(CoinBurst), findsOneWidget);
    expect(coins(tester), 0);

    await advance(tester, const Duration(milliseconds: 1500));
    expect(find.byType(CoinBurst), findsNothing);
    expect(coins(tester), price);

    await advance(tester, nextRound);
    expect(till(tester).showTick, isFalse);
    expect(till(tester).display, isNull);
    expect(tag(tester).price, isNot(price));
  });

  testWidgets('a mistake resets the coins to zero and keeps the item', (
    tester,
  ) async {
    await pumpAtSize(tester, landscape);
    await advance(tester, arrive);
    final first = tag(tester).price;
    await press(tester, first);
    await advance(tester, nextRound);
    expect(coins(tester), first);

    final price = tag(tester).price;
    final wrong = price == 1 ? 2 : 1;
    await press(tester, wrong);
    expect(coins(tester), 0);
    expect(till(tester).showTick, isFalse);
    expect(tag(tester).price, price);
    expect(till(tester).enabled, isTrue);
  });

  testWidgets('a sign tag switches the till keys to numbers', (tester) async {
    await pumpAtSize(tester, landscape);
    await advance(tester, arrive);
    // Level 7 has 10 items; stop before the last so the level doesn't end.
    for (var i = 0; i < 9 && !tag(tester).showSign; i++) {
      expect(till(tester).showNumbers, isFalse);
      await press(tester, tag(tester).price);
      await advance(tester, nextRound);
    }
    expect(tag(tester).showSign, isTrue);
    expect(till(tester).showNumbers, isTrue);
  });

  testWidgets('till plays only 1 to 12', (tester) async {
    await pumpAtSize(tester, landscape);
    final tillRect = tester.getRect(find.byType(BslTill));
    expect(tillRect.width / tillRect.height, closeTo(2108 / 1908, 0.01));

    await advance(tester, arrive);
    // Level 7 has 10 items; stop before the last so the level doesn't end.
    for (var i = 0; i < 9; i++) {
      final price = tag(tester).price;
      expect(price, inInclusiveRange(1, 12));
      await press(tester, price);
      await advance(tester, nextRound);
    }
  });

  testWidgets('opens on a level select with 8 levels', (tester) async {
    await pumpAtSize(tester, landscape, level: null);
    expect(find.byType(LevelSelectScreen), findsOneWidget);
    expect(find.byType(BslTill), findsNothing);
    final select = tester.widget<LevelSelectScreen>(
      find.byType(LevelSelectScreen),
    );
    expect(select.levels, hasLength(8));

    await tester.tap(find.text('Numbers 1–5'));
    await tester.pump();
    expect(find.byType(LevelSelectScreen), findsNothing);
    expect(find.byType(BslTill), findsOneWidget);
  });

  testWidgets('level 1: digit tags up to 5, signed till keys', (tester) async {
    await pumpAtSize(tester, landscape, level: 1);
    await advance(tester, arrive);
    // Stop before the 5th item so the level doesn't end.
    for (var i = 0; i < 4; i++) {
      expect(tag(tester).showSign, isFalse);
      expect(till(tester).showNumbers, isFalse);
      expect(tag(tester).price, inInclusiveRange(1, 5));
      await press(tester, tag(tester).price);
      await advance(tester, nextRound);
    }
    expect(find.text('4 / 5'), findsOneWidget);
  });

  testWidgets('level 2: sign tags up to 5, numeral till keys', (tester) async {
    await pumpAtSize(tester, landscape, level: 2);
    await advance(tester, arrive);
    for (var i = 0; i < 4; i++) {
      expect(tag(tester).showSign, isTrue);
      expect(till(tester).showNumbers, isTrue);
      expect(tag(tester).price, inInclusiveRange(1, 5));
      await press(tester, tag(tester).price);
      await advance(tester, nextRound);
    }
  });

  testWidgets('back from a level returns to the level select', (tester) async {
    await pumpAtSize(tester, landscape, level: 1);
    await advance(tester, arrive);
    await tester.tap(find.byType(BackArrowIcon));
    await tester.pump();
    expect(find.byType(LevelSelectScreen), findsOneWidget);
  });

  testWidgets('level 8 counts down a minute once the first item arrives', (
    tester,
  ) async {
    await pumpAtSize(tester, landscape, level: 8);
    expect(find.text('1:00'), findsOneWidget);
    await advance(tester, arrive);
    await advance(tester, const Duration(seconds: 3));
    expect(find.text('0:57'), findsOneWidget);
    expect(till(tester).enabled, isTrue);
  });
}
