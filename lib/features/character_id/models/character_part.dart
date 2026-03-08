/// Represents a single body part (head, torso, legs, or feet).
///
/// Each part has an image path and a map of attributes.
/// Attributes can be simple values (e.g., "eye_colour": "hazel")
/// or nested objects (e.g., "hat": {"item": "beanie", "color": "charcoal"}).
class CharacterPart {
  /// Path to the image asset for this part
  final String imagePath;

  /// All attributes for this part (excluding image_path)
  /// Keys are attribute names (e.g., "hat", "hair", "shirt")
  /// Values can be strings, numbers, or nested Maps
  final Map<String, dynamic> attributes;

  const CharacterPart({
    required this.imagePath,
    required this.attributes,
  });

  /// Base path for character part images
  static const String _imageBasePath = 'assets/images/character_parts/';

  /// Creates a CharacterPart from JSON data.
  ///
  /// Extracts `image_path` and stores all other keys as attributes.
  /// Prepends the image base path to the filename from JSON.
  factory CharacterPart.fromJson(Map<String, dynamic> json) {
    final filename = json['image_path'] as String? ?? '';
    final imagePath = filename.isNotEmpty ? '$_imageBasePath$filename' : '';

    // Copy all attributes except image_path
    final attributes = Map<String, dynamic>.from(json)..remove('image_path');

    return CharacterPart(
      imagePath: imagePath,
      attributes: attributes,
    );
  }

  /// Gets a specific attribute value.
  ///
  /// Returns null if the attribute doesn't exist.
  dynamic getAttribute(String key) => attributes[key];

  /// Gets a nested attribute value using dot notation.
  ///
  /// Example: `getNestedAttribute('hat', 'color')` returns the hat's color.
  dynamic getNestedAttribute(String key, String nestedKey) {
    final value = attributes[key];
    if (value is Map<String, dynamic>) {
      return value[nestedKey];
    }
    return null;
  }

  /// Gets the primary clothing item description for this part.
  ///
  /// Looks for common clothing keys and returns a formatted description.
  String? getPrimaryClothingDescription() {
    // Check for common clothing attributes
    final clothingKeys = ['hat', 'shirt', 'tie', 'trousers', 'shoes', 'belt'];

    for (final key in clothingKeys) {
      final clothing = attributes[key];
      if (clothing is Map<String, dynamic>) {
        final item = clothing['item'] as String?;
        final color = clothing['color'] as String?;
        if (item != null) {
          return color != null ? '$color $item' : item;
        } else if (color != null) {
          return '$color $key';
        }
      }
    }

    return null;
  }

  /// Converts to JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'image_path': imagePath,
      ...attributes,
    };
  }
}
