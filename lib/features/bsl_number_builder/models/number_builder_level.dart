/// What an item's price tag shows, and so what the till keys show.
enum TagStyle {
  /// Tag shows the digit; till keys show BSL signs.
  digit,

  /// Tag shows the BSL sign; till keys show numerals.
  sign,

  /// A mix of both, starting with a digit tag.
  mixed,
}

/// One level of BSL Number Builder.
///
/// A level ends after [itemCount] correct items or, for a timed level, when
/// [timeLimit] runs out.
class NumberBuilderLevel {
  final int number;
  final String nameKey;

  /// Highest price used.
  final int maxPrice;

  final TagStyle tagStyle;

  /// Items to ring up correctly to finish the level; null for a timed level.
  final int? itemCount;

  /// How long a timed level lasts; null when the level is [itemCount] items.
  final Duration? timeLimit;

  /// Relative chance of these prices being picked for an item, e.g.
  /// `{11: 2}`. Prices not listed have a weight of 1.
  final Map<int, double> priceWeights;

  const NumberBuilderLevel({
    required this.number,
    required this.nameKey,
    required this.maxPrice,
    required this.tagStyle,
    this.itemCount,
    this.timeLimit,
    this.priceWeights = const {},
  }) : assert(
         (itemCount == null) != (timeLimit == null),
         'A level is either a number of items or timed',
       );

  /// The till's [keyValues] this level's prices are drawn from.
  List<int> pricesFrom(List<int> keyValues) => [
    for (final v in keyValues)
      if (v <= maxPrice) v,
  ];
}

/// Makes 11 and 12 come up three times as often as each other number in
/// 1–12. Prices never repeat back-to-back, which holds a favourite back more
/// than the rest, so the weight is a bit over 3: with ten other prices at
/// weight 1, w = √31 − 2 (from w² + 4w = 27) nets out at exactly 3×.
const Map<int, double> _favour11And12 = {11: 3.568, 12: 3.568};

const List<NumberBuilderLevel> numberBuilderLevels = [
  NumberBuilderLevel(
    number: 1,
    nameKey: 'bsl_number_builder.level1.name',
    maxPrice: 5,
    tagStyle: TagStyle.digit,
    itemCount: 5,
  ),
  NumberBuilderLevel(
    number: 2,
    nameKey: 'bsl_number_builder.level2.name',
    maxPrice: 5,
    tagStyle: TagStyle.sign,
    itemCount: 5,
  ),
  NumberBuilderLevel(
    number: 3,
    nameKey: 'bsl_number_builder.level3.name',
    maxPrice: 10,
    tagStyle: TagStyle.digit,
    itemCount: 7,
  ),
  NumberBuilderLevel(
    number: 4,
    nameKey: 'bsl_number_builder.level4.name',
    maxPrice: 10,
    tagStyle: TagStyle.sign,
    itemCount: 7,
  ),
  NumberBuilderLevel(
    number: 5,
    nameKey: 'bsl_number_builder.level5.name',
    maxPrice: 12,
    tagStyle: TagStyle.digit,
    itemCount: 10,
    priceWeights: _favour11And12,
  ),
  NumberBuilderLevel(
    number: 6,
    nameKey: 'bsl_number_builder.level6.name',
    maxPrice: 12,
    tagStyle: TagStyle.sign,
    itemCount: 10,
    priceWeights: _favour11And12,
  ),
  NumberBuilderLevel(
    number: 7,
    nameKey: 'bsl_number_builder.level7.name',
    maxPrice: 12,
    tagStyle: TagStyle.mixed,
    itemCount: 10,
  ),
  NumberBuilderLevel(
    number: 8,
    nameKey: 'bsl_number_builder.level8.name',
    maxPrice: 12,
    tagStyle: TagStyle.mixed,
    timeLimit: Duration(minutes: 1),
  ),
];
