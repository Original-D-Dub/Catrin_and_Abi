import 'dart:math';

import 'number_builder_level.dart';

export 'number_builder_level.dart' show TagStyle;

/// Rules for BSL Number Builder: each item on the belt has a price, and the
/// player rings it up on the till.
///
/// A digit tag pairs with BSL-sign till keys; a BSL-sign tag
/// ([tagShowsSign]) switches the till keys to numerals. [tagStyle] picks
/// which, or a mix.
class NumberBuilderGame {
  /// Chance that an item's tag shows a BSL sign instead of a digit.
  static const double signTagChance = 0.35;

  /// Possible prices; these match the till's keys.
  final List<int> prices;

  final TagStyle tagStyle;

  /// Correct items needed to finish; null plays forever.
  final int? itemCount;

  /// Relative chance of each price coming up; unlisted prices weigh 1.
  final Map<int, double> priceWeights;

  final Random _random;

  NumberBuilderGame({
    required this.prices,
    this.tagStyle = TagStyle.mixed,
    this.itemCount,
    this.priceWeights = const {},
    Random? random,
  }) : assert(prices.length > 1, 'Need two prices to avoid repeats'),
       _random = random ?? Random();

  /// Items rung up correctly so far.
  int itemsDone = 0;

  /// Whether [itemCount] items have been rung up.
  bool get isComplete => itemCount != null && itemsDone >= itemCount!;

  /// Running coin total. Reset to zero by a wrong answer.
  int coins = 0;

  /// Price of the current item. Null before the first [nextItem].
  int? price;

  /// Whether the current item's tag shows a BSL sign (and the till shows
  /// numerals). In a mix, always false for the first item, so the player
  /// starts on the familiar layout.
  bool tagShowsSign = false;

  int _itemsShown = 0;

  /// Picks the next item's price (weighted by [priceWeights], never the same
  /// twice in a row) and tag style.
  void nextItem() {
    final choices = [
      for (final p in prices)
        if (p != price) p,
    ];
    final total = choices.fold(0.0, (sum, p) => sum + _weight(p));
    var pick = _random.nextDouble() * total;
    price = choices.last;
    for (final p in choices) {
      pick -= _weight(p);
      if (pick < 0) {
        price = p;
        break;
      }
    }
    tagShowsSign = switch (tagStyle) {
      TagStyle.digit => false,
      TagStyle.sign => true,
      TagStyle.mixed => _itemsShown > 0 && _random.nextDouble() < signTagChance,
    };
    _itemsShown++;
  }

  double _weight(int p) => priceWeights[p] ?? 1;

  /// Rings up [value]. Correct adds the price to [coins]; wrong resets
  /// [coins] to zero. Returns whether it was correct.
  bool submit(int value) {
    if (value == price) {
      coins += value;
      itemsDone++;
      return true;
    }
    coins = 0;
    return false;
  }
}
