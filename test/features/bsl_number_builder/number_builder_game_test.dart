import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:catrin_abi_bsl/features/bsl_number_builder/models/number_builder_game.dart';
import 'package:catrin_abi_bsl/features/bsl_number_builder/models/number_builder_level.dart';
import 'package:catrin_abi_bsl/shared/widgets/bsl_till.dart';

void main() {
  final prices = BslTillLayout.standard.values;

  test('prices come from the till keys and never repeat back-to-back', () {
    final game = NumberBuilderGame(prices: prices, random: Random(1));
    int? previous;
    for (var i = 0; i < 200; i++) {
      game.nextItem();
      expect(prices, contains(game.price));
      expect(game.price, isNot(previous));
      previous = game.price;
    }
  });

  test('first item always shows a digit tag; later items sometimes a sign', () {
    final game = NumberBuilderGame(prices: prices, random: Random(2))
      ..nextItem();
    expect(game.tagShowsSign, isFalse);

    var signs = 0;
    for (var i = 0; i < 200; i++) {
      game.nextItem();
      if (game.tagShowsSign) signs++;
    }
    expect(signs, greaterThan(40));
    expect(signs, lessThan(120));
  });

  test('correct answer adds the price; a mistake resets coins to zero', () {
    final game = NumberBuilderGame(prices: prices, random: Random(3))
      ..nextItem();
    final first = game.price!;
    expect(game.submit(first), isTrue);
    expect(game.coins, first);

    game.nextItem();
    final second = game.price!;
    expect(game.submit(second), isTrue);
    expect(game.coins, first + second);

    game.nextItem();
    final wrong = game.prices.firstWhere((p) => p != game.price);
    expect(game.submit(wrong), isFalse);
    expect(game.coins, 0);
  });

  test('till prices are 1 to 12', () {
    expect(prices, List.generate(12, (i) => i + 1));
  });

  test('levels 1 and 2 use prices 1 to 5 with fixed tag styles', () {
    final keys = BslTillLayout.standard.values;
    final l1 = numberBuilderLevels[0];
    final l2 = numberBuilderLevels[1];
    expect(l1.pricesFrom(keys), [1, 2, 3, 4, 5]);
    expect(l2.pricesFrom(keys), [1, 2, 3, 4, 5]);
    expect(l1.itemCount, 5);
    expect(numberBuilderLevels, hasLength(8));

    for (final (level, sign) in [(l1, false), (l2, true)]) {
      final game = NumberBuilderGame(
        prices: level.pricesFrom(keys),
        tagStyle: level.tagStyle,
        itemCount: level.itemCount,
        random: Random(5),
      );
      for (var i = 0; i < 20; i++) {
        game.nextItem();
        expect(game.tagShowsSign, sign);
      }
    }
  });

  test('a level is complete after its item count of correct answers', () {
    final game = NumberBuilderGame(
      prices: [1, 2, 3, 4, 5],
      itemCount: 5,
      random: Random(6),
    );
    for (var i = 0; i < 5; i++) {
      expect(game.isComplete, isFalse);
      game.nextItem();
      final wrong = game.price == 1 ? 2 : 1;
      game.submit(wrong); // mistakes don't count
      game.submit(game.price!);
    }
    expect(game.isComplete, isTrue);
  });

  test('levels 5 and 6 make 11 and 12 three times as likely', () {
    for (final level in [numberBuilderLevels[4], numberBuilderLevels[5]]) {
      final game = NumberBuilderGame(
        prices: level.pricesFrom(BslTillLayout.standard.values),
        priceWeights: level.priceWeights,
        random: Random(8),
      );
      expect(game.prices, List.generate(12, (i) => i + 1));
      final counts = <int, int>{};
      for (var i = 0; i < 30000; i++) {
        game.nextItem();
        counts.update(game.price!, (c) => c + 1, ifAbsent: () => 1);
      }
      final ordinary =
          counts.entries
              .where((e) => e.key <= 10)
              .fold(0, (sum, e) => sum + e.value) /
          10;
      expect(counts[11]! / ordinary, closeTo(3, 0.15));
      expect(counts[12]! / ordinary, closeTo(3, 0.15));
    }
  });

  test('levels 3-8 match the agreed set-up', () {
    final l = numberBuilderLevels;
    expect([for (final x in l) x.itemCount], [5, 5, 7, 7, 10, 10, 10, null]);
    expect([for (final x in l) x.maxPrice], [5, 5, 10, 10, 12, 12, 12, 12]);
    expect(l[7].timeLimit, const Duration(minutes: 1));
    expect(
      [for (final x in l) x.tagStyle],
      [
        TagStyle.digit,
        TagStyle.sign,
        TagStyle.digit,
        TagStyle.sign,
        TagStyle.digit,
        TagStyle.sign,
        TagStyle.mixed,
        TagStyle.mixed,
      ],
    );
  });
}
