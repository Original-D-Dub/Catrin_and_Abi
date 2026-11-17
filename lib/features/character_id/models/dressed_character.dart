import 'package:flutter/painting.dart';

/// Colours garments can be dyed; each has a BSL sign in
/// `assets/images/colours_BSL/` and a palette entry in
/// `AppColors.bslFabricFor`.
const List<String> clothingColours = [
  'black', 'blue', 'brown', 'green', 'orange',
  'pink', 'purple', 'red', 'white', 'yellow',
];

/// Where a clothing item is worn. Bottoms are drawn first so tops overlap
/// the waistband.
enum ClothingSlot { bottom, top }

/// A character body image (underwear, shoes and head included).
///
/// All bodies share one figure template drawn on a 600x790 canvas; a body
/// whose canvas is larger has the template shifted by [templateOffset].
class CharacterBody {
  final String name;
  final String assetPath;
  final Size canvasSize;
  final Offset templateOffset;

  const CharacterBody({
    required this.name,
    required this.assetPath,
    this.canvasSize = const Size(600, 790),
    this.templateOffset = Offset.zero,
  });

  static const String _dir = 'assets/games/character_id/bodies';

  static const List<CharacterBody> all = [
    CharacterBody(name: 'Abi', assetPath: '$_dir/body-abi.png'),
    CharacterBody(name: 'Ruby', assetPath: '$_dir/body-ruby.png'),
    CharacterBody(
      name: 'Esmay',
      assetPath: '$_dir/body-esmay.png',
      canvasSize: Size(618, 813),
      templateOffset: Offset(9, 0),
    ),
  ];
}

/// A clothing item that can be layered onto any [CharacterBody].
///
/// SVG items are recoloured at runtime to any of [clothingColours]; bitmap
/// items can't be, so they always show their [fixedColour].
class ClothingItem {
  /// Garment name used in questions, e.g. "t-shirt", "trousers".
  final String type;

  /// The colour of a bitmap item that can't be recoloured.
  final String? fixedColour;

  final ClothingSlot slot;
  final String assetPath;

  /// Position and size in the 600x790 template coordinate space.
  final Rect bounds;

  const ClothingItem({
    required this.type,
    this.fixedColour,
    required this.slot,
    required this.assetPath,
    required this.bounds,
  });

  bool get isSvg => assetPath.endsWith('.svg');

  /// Colours this item can be shown in.
  List<String> get availableColours =>
      fixedColour != null ? [fixedColour!] : clothingColours;

  /// Whether the garment name is plural ("trousers", "shorts").
  bool get isPlural => type.endsWith('s');

  /// BSL video signing the "what colour is the ...?" question for this
  /// garment (shared with the Clothes Line game).
  String get videoAssetPath =>
      'assets/images/clothes_line_video/$type-colour-12fps.m4v';

  static const String _dir = 'assets/games/character_id/clothes';

  static const List<ClothingItem> all = [
    // Tops
    ClothingItem(
      type: 't-shirt',
      slot: ClothingSlot.top,
      assetPath: '$_dir/t-shirt_purple.svg',
      bounds: Rect.fromLTWH(180.5, 246.5, 239, 209),
    ),
    ClothingItem(
      type: 'shirt',
      slot: ClothingSlot.top,
      assetPath: '$_dir/shirt_yellow.svg',
      bounds: Rect.fromLTWH(136, 240.5, 332, 226),
    ),
    ClothingItem(
      type: 'coat',
      fixedColour: 'orange',
      slot: ClothingSlot.top,
      assetPath: '$_dir/coat.png',
      bounds: Rect.fromLTWH(137.5, 233, 329, 241),
    ),
    // Bottoms
    ClothingItem(
      type: 'shorts',
      slot: ClothingSlot.bottom,
      assetPath: '$_dir/shorts_orange.svg',
      bounds: Rect.fromLTWH(210, 440.5, 177, 117),
    ),
    ClothingItem(
      type: 'skirt',
      slot: ClothingSlot.bottom,
      assetPath: '$_dir/skirt_pink.svg',
      // Top edge raised from 451 (hem unchanged) so it tucks under the
      // shorter t-shirt without the body's vest showing.
      bounds: Rect.fromLTWH(197.5, 438, 201, 144),
    ),
    ClothingItem(
      type: 'trousers',
      slot: ClothingSlot.bottom,
      assetPath: '$_dir/trounsers_blue.svg',
      // 10px wider than the SVG so the hips cover the body's white pants.
      bounds: Rect.fromLTWH(201.5, 444.5, 199, 260),
    ),
  ];

  static List<ClothingItem> inSlot(ClothingSlot slot) =>
      all.where((c) => c.slot == slot).toList();
}

/// A [ClothingItem] being worn in a particular colour.
class WornItem {
  final ClothingItem item;
  final String colour;

  const WornItem(this.item, this.colour);

  @override
  bool operator ==(Object other) =>
      other is WornItem && other.item == item && other.colour == colour;

  @override
  int get hashCode => Object.hash(item, colour);
}

/// A body wearing one top and one bottom.
class DressedCharacter {
  final CharacterBody body;
  final WornItem top;
  final WornItem bottom;

  const DressedCharacter({
    required this.body,
    required this.top,
    required this.bottom,
  });

  WornItem wornIn(ClothingSlot slot) =>
      slot == ClothingSlot.top ? top : bottom;

  /// Clothing in draw order (bottom layer first).
  List<WornItem> get layers => [bottom, top];

  bool sameOutfitAs(DressedCharacter? other) =>
      other != null &&
      other.body == body &&
      other.top == top &&
      other.bottom == bottom;
}
