/// Game state for the Clothes Line game.
enum ClothesLineState { playing, correct, wrong, finished }

/// A pre-generated question: the clothing item to show and the colour choices to present.
class ClothesLineQuestion {
  final ClothingItem item;
  final List<String> choices;

  const ClothesLineQuestion({required this.item, required this.choices});
}

/// Definition of a clothing type — its name and whether it is grammatically plural.
class ClothingDefinition {
  final String name;
  final bool plural;

  const ClothingDefinition(this.name, {required this.plural});
}

/// A single clothing item on the line, with a specific colour assigned.
class ClothingItem {
  final ClothingDefinition definition;
  final String colour;

  const ClothingItem({required this.definition, required this.colour});

  String get assetPath => 'assets/images/clothes-svg/${definition.name}.svg';
}

/// All clothing types used in the game.
const List<ClothingDefinition> clothingDefinitions = [
  ClothingDefinition('socks',    plural: true),
  ClothingDefinition('shirt',    plural: false),
  ClothingDefinition('trousers', plural: true),
  ClothingDefinition('skirt',    plural: false),
  ClothingDefinition('t-shirt',  plural: false),
  ClothingDefinition('shorts',   plural: true),
  ClothingDefinition('coat',     plural: false),
];

/// Colour options used in the game.
const List<String> clothingColours = [
  'red', 'blue', 'green', 'yellow', 'orange',
  'purple', 'pink', 'brown', 'black', 'white',
];
