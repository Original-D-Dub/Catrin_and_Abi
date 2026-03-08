import 'package:flutter/material.dart';

import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';

/// The main application widget.
///
/// Configures:
/// - Material app with custom theme
/// - Named route navigation
/// - Initial route (welcome screen)
class CatrinAbiApp extends StatelessWidget {
  const CatrinAbiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catrin & Abi BSL',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,

      // Navigation
      initialRoute: AppRoutes.initial,
      onGenerateRoute: generateRoute,
    );
  }
}
