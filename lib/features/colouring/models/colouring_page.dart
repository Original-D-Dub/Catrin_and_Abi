import '../../../core/constants/asset_paths.dart';

/// Represents a colouring page with its metadata.
///
/// Each colouring page has:
/// - A unique identifier
/// - Display name (English and Welsh)
/// - Path to the image asset
///
/// Example:
/// ```dart
/// final page = ColouringPage.abi();
/// print(page.name); // 'Abi'
/// ```
class ColouringPage {
  /// Unique identifier for this colouring page
  final String id;

  /// Display name in English
  final String name;

  /// Display name in Welsh
  final String nameCy;

  /// Path to the colouring sheet image asset
  final String imagePath;

  /// Creates a colouring page configuration.
  const ColouringPage({
    required this.id,
    required this.name,
    required this.nameCy,
    required this.imagePath,
  });

  /// Abi colouring page - the Deaf character
  factory ColouringPage.abi() {
    return const ColouringPage(
      id: 'abi',
      name: 'Abi',
      nameCy: 'Abi',
      imagePath: AssetPaths.colouringAbi,
    );
  }

  /// Catrin colouring page - Abi's older sister
  factory ColouringPage.catrin() {
    return const ColouringPage(
      id: 'catrin',
      name: 'Catrin',
      nameCy: 'Catrin',
      imagePath: AssetPaths.colouringCatrin,
    );
  }

  /// Pero colouring page - the hearing assistance dog
  factory ColouringPage.pero() {
    return const ColouringPage(
      id: 'pero',
      name: 'Pero',
      nameCy: 'Pero',
      imagePath: AssetPaths.colouringPero,
    );
  }

  /// Returns all available colouring pages.
  static List<ColouringPage> allPages() {
    return [
      ColouringPage.abi(),
      ColouringPage.catrin(),
      ColouringPage.pero(),
    ];
  }
}
