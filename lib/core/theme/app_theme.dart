import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// App theme configuration for the Catrin & Abi BSL app.
///
/// Defines a child-friendly, accessible theme with:
/// - Large, readable text
/// - High contrast colors
/// - Rounded, friendly shapes
/// - Warm background colors
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Base style for page/section titles — the largest heading level.
  ///
  /// Carries only [fontFamily] and [fontWeight]; call sites layer their own
  /// [TextStyle.copyWith] for size and color, the same way a CSS class
  /// combines with per-element overrides.
  static const TextStyle title = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w700,
  );

  /// Base style for headings — a level below [title].
  ///
  /// Carries only [fontFamily] and [fontWeight]; call sites layer their own
  /// [TextStyle.copyWith] for size and color.
  static const TextStyle heading = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w700,
  );

  /// Base style for celebratory/success messages — confetti overlays, BINGO
  /// congratulations, reward reveals.
  ///
  /// Carries only [fontFamily]; call sites layer their own
  /// [TextStyle.copyWith] for size, weight, and color.
  static const TextStyle celebration = TextStyle(fontFamily: 'LuckiestGuy');

  /// Width, in logical pixels, above which the default (unstyled) body text
  /// in [lightTheme] grows from [narrowDeviceFontSize] to
  /// [AppSizes.fontSizeBody].
  static const double wideDeviceBreakpoint = 375.0;

  /// Default body text size at or below [wideDeviceBreakpoint].
  static const double narrowDeviceFontSize = 16.0;

  /// [lightTheme] with its default body text sized for [width] —
  /// [narrowDeviceFontSize] at or below [wideDeviceBreakpoint],
  /// [AppSizes.fontSizeBody] above it.
  ///
  /// Only affects Text widgets that don't set their own fontSize (they
  /// inherit [TextTheme.bodyLarge]/[TextTheme.bodyMedium]); explicit
  /// `fontSize: AppSizes.xxx` usages elsewhere are untouched.
  static ThemeData themeForWidth(double width) {
    final bodyFontSize = width > wideDeviceBreakpoint
        ? AppSizes.fontSizeBody
        : narrowDeviceFontSize;
    final theme = lightTheme;
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(fontSize: bodyFontSize),
        bodyMedium: theme.textTheme.bodyMedium?.copyWith(fontSize: bodyFontSize),
      ),
    );
  }

  /// The main light theme for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.abiPink,
        brightness: Brightness.light,
        surface: AppColors.background,
      ),

      // Scaffold background
      scaffoldBackgroundColor: AppColors.background,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: title.copyWith(
          fontSize: AppSizes.fontSizeHeading,
          color: AppColors.textPrimary,
        ),
      ),

      // Elevated button theme (primary buttons)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonText,
          minimumSize: const Size(
            AppSizes.minTapTarget,
            AppSizes.buttonHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
            vertical: AppSizes.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.abiPink,
          minimumSize: const Size(
            AppSizes.minTapTarget,
            AppSizes.minTapTarget,
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.accentWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
        margin: const EdgeInsets.all(AppSizes.spacingSmall),
      ),

      // Text theme - child-friendly sizes
      textTheme: TextTheme(
        displayLarge: title.copyWith(
          fontSize: AppSizes.fontSizeTitle,
          color: AppColors.textPrimary,
        ),
        headlineMedium: heading.copyWith(
          fontSize: AppSizes.fontSizeHeading,
          color: AppColors.textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: AppSizes.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: AppSizes.fontSizeBody,
          color: AppColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: AppSizes.fontSizeBody,
          color: AppColors.textSecondary,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSizes.iconMedium,
      ),
    );
  }
}
