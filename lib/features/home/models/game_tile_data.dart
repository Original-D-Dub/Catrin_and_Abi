/// Model representing data for a game tile on the home screen.
///
/// Each game has a tile with an image, title, description,
/// and navigation route.
class GameTileData {
  /// Unique identifier for the game
  final String id;

  /// Display title for the game
  final String titleKey;

  /// Short description translation key
  final String descriptionKey;

  /// Asset path for the tile image/icon
  final String? imagePath;

  /// Route to navigate to when tile is tapped
  final String route;

  /// Whether this game is active and playable
  final bool isActive;

  /// Creates a game tile data object.
  ///
  /// [id] uniquely identifies the game.
  /// [titleKey] is the localization key for the title.
  /// [descriptionKey] is the localization key for the description.
  /// [route] is the navigation route for the game.
  /// [isActive] determines if the tile is clickable.
  const GameTileData({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.route,
    this.imagePath,
    this.isActive = true,
  });
}
