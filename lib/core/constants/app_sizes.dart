/// Size constants to eliminate magic numbers throughout the app.
///
/// All spacing, sizing, and dimension values should be defined here.
/// This ensures consistency and makes global adjustments easy.
///
/// Usage:
/// ```dart
/// Padding(padding: EdgeInsets.all(AppSizes.paddingMedium))
/// SizedBox(height: AppSizes.spacingLarge)
/// ```
class AppSizes {
  // Private constructor to prevent instantiation
  AppSizes._();

  // -------------------------
  // Spacing (margins/padding)
  // -------------------------

  /// Extra small spacing: 4.0
  static const double spacingXSmall = 4.0;

  /// Small spacing: 8.0
  static const double spacingSmall = 8.0;

  /// Medium spacing: 16.0
  static const double spacingMedium = 16.0;

  /// Large spacing: 24.0
  static const double spacingLarge = 24.0;

  /// Extra large spacing: 32.0
  static const double spacingXLarge = 32.0;

  /// XXL spacing: 48.0
  static const double spacingXXLarge = 48.0;

  // -------------------------
  // Padding shortcuts
  // -------------------------

  static const double paddingSmall = spacingSmall;
  static const double paddingMedium = spacingMedium;
  static const double paddingLarge = spacingLarge;

  // -------------------------
  // Border radius
  // -------------------------

  /// Small border radius: 8.0
  static const double borderRadiusSmall = 8.0;

  /// Medium border radius: 12.0
  static const double borderRadiusMedium = 12.0;

  /// Large border radius: 16.0
  static const double borderRadiusLarge = 16.0;

  /// Extra large border radius: 24.0
  static const double borderRadiusXLarge = 24.0;

  // -------------------------
  // Button sizes
  // -------------------------

  /// Standard button height for child-friendly tapping
  static const double buttonHeight = 56.0;

  /// Large button height for primary actions
  static const double buttonHeightLarge = 64.0;

  /// Minimum tap target size (accessibility requirement)
  static const double minTapTarget = 48.0;

  // -------------------------
  // Icon sizes
  // -------------------------

  /// Small icon size: 20.0
  static const double iconSmall = 20.0;

  /// Medium icon size: 24.0
  static const double iconMedium = 24.0;

  /// Large icon size: 32.0
  static const double iconLarge = 32.0;

  /// Extra large icon size: 48.0
  static const double iconXLarge = 48.0;

  // -------------------------
  // Logo sizes
  // -------------------------

  /// Logo width on welcome screen
  static const double logoWidthWelcome = 200.0;

  /// Logo height on welcome screen
  static const double logoHeightWelcome = 100.0;

  /// Logo width in app bar
  static const double logoWidthAppBar = 120.0;

  // -------------------------
  // Character sizes
  // -------------------------

  /// Character image height on welcome screen
  static const double characterHeightWelcome = 250.0;

  /// Character image height in speech bubble section
  static const double characterHeightSpeaker = 180.0;

  /// Character group - Catrin height (tallest)
  static const double characterCatrinHeight = 200.0;

  /// Character group - Abi height (medium)
  static const double characterAbiHeight = 160.0;

  /// Character group - Pero height (knee height)
  static const double characterPeroHeight = 80.0;

  // -------------------------
  // Card game sizes
  // -------------------------

  /// Width of a game card
  static const double cardWidth = 80.0;

  /// Height of a game card
  static const double cardHeight = 100.0;

  /// Card border width for color coding
  static const double cardBorderWidth = 4.0;

  /// Card grid spacing
  static const double cardGridSpacing = 8.0;

  // -------------------------
  // Game tile sizes (home screen)
  // -------------------------

  /// Game tile width
  static const double gameTileWidth = 150.0;

  /// Game tile height
  static const double gameTileHeight = 180.0;

  // -------------------------
  // Speech bubble
  // -------------------------

  /// Speech bubble max width
  static const double speechBubbleMaxWidth = 300.0;

  /// Speech bubble padding
  static const double speechBubblePadding = 16.0;

  /// Speech bubble border radius
  static const double speechBubbleRadius = 20.0;

  // -------------------------
  // Font sizes
  // -------------------------

  /// Small text size - labels and captions
  static const double fontSizeSmall = 14.0;

  /// Body text size - readable for children
  static const double fontSizeBody = 18.0;

  /// Large body text
  static const double fontSizeLarge = 22.0;

  /// Heading text size
  static const double fontSizeHeading = 28.0;

  /// Title text size
  static const double fontSizeTitle = 32.0;

  /// Card letter text size
  static const double fontSizeCardLetter = 36.0;
}
