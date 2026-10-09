import 'dart:math';

const _root = 'assets/games/bsl_number_builder';

const _shared = [
  'all/bananas-number-builder-game.png',
  'all/bread-number-builder-game.png',
  'all/brocoli-number-builder-game.png',
  'all/carrots.png',
  'all/chocolates-number-builder-game.png',
  'all/cookies-number-builder-game.png',
  'all/eggs-number-builder-game.png',
  'all/garlic-number-builder-game.png',
  'all/green-apples-number-builder-game.png',
  'all/mushrooms-number-builder-game.png',
  'all/peppers-number-builder-game.png',
  'all/potatoes-number-builder-game.png',
  'all/red-apples-number-builder-game.png',
  'all/red-grapes-number-builder-game.png',
  'all/red-onions-number-builder-game.png',
  'all/strawberries-number-builder-game.png',
  'all/white-grapes-number-builder-game.png',
  'all/white-onions-number-builder-game.png',
];

const _englishOnly = [
  'all/milk-eu-number-builder-game.png',
  'all/pizza-eu-number-builder-game.png',
  'english/apricot-jam-eu.png',
  'english/baked-bean-eu.png',
  'english/butter-eu.png',
  'english/carton-orange-juice-eu.png',
  'english/crisps-eu.png',
  'english/dog-food-eu.png',
  'english/honey.eu.png',
  'english/lour-eu.png',
  'english/marmalade-jam-eu.png',
  'english/shampoo-eu.png',
  'english/strawberry-jam-eu.png',
  'english/sugar-eu.png',
  'english/tin-salmon-eu.png',
  'english/tin-sweetcorn-eu.png',
  'english/tin-tuna-eu.png',
  'english/toilet-cleaner-eu.png',
  'english/toothpaste-eu.png',
  'english/washing-detergent-eu.png',
  'english/washing-up-liquid-eu.png',
];

const _welshOnly = [
  'all/milk-cy-number-builder-game.png',
  'all/pizza-cy-number-builder-game.png',
  'cymraeg/apricot-jam-cy.png',
  'cymraeg/baked-beans-cy.png',
  'cymraeg/butter-cy.png',
  'cymraeg/carton-orange-juice-cy.png',
  'cymraeg/crisps-cy.png',
  'cymraeg/dog-food-cy.png',
  'cymraeg/flour-cy.png',
  'cymraeg/honey-cy.png',
  'cymraeg/maramalade-jam-cy.png',
  'cymraeg/shampoo-cy.png',
  'cymraeg/strawberry-jam-cy.png',
  'cymraeg/sugar-cy.png',
  'cymraeg/tin-salmon-cy.png',
  'cymraeg/tin-sweetcorn-cy.png',
  'cymraeg/tin-tuna-cy.png',
  'cymraeg/toilet-cleaner-cy.png',
  'cymraeg/toothpaste-cy.png',
  'cymraeg/washing-detergent-cy.png',
  'cymraeg/washing-up-liquid-cy.png',
  'cymraeg/yoghurt-cy.png',
];

/// Asset paths of the grocery images for [locale]: the shared ones plus
/// those labelled in that language.
List<String> beltItemImages(String locale) => [
  for (final p in [..._shared, ...(locale == 'cy' ? _welshOnly : _englishOnly)])
    '$_root/$p',
];

/// A random image from [images], never [previous] twice in a row.
String pickBeltItemImage(
  List<String> images,
  Random random, {
  String? previous,
}) {
  final choices = [
    for (final i in images)
      if (i != previous) i,
  ];
  return choices[random.nextInt(choices.length)];
}
