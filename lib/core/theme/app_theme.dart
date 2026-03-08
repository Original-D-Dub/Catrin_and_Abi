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
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: AppSizes.fontSizeHeading,
          fontWeight: FontWeight.bold,
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppSizes.fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppSizes.fontSizeHeading,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: AppSizes.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppSizes.fontSizeBody,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
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
