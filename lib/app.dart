import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/providers/profile_provider.dart';
import 'shared/services/audio_service.dart';
import 'shared/services/auth_provider.dart';
import 'shared/services/settings_provider.dart';

/// Stops all audio whenever the Android hardware back button pops a route.
class _AudioStopObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AudioService.stopAll();
  }
}

/// The main application widget.
///
/// Configures:
/// - Material app with custom theme
/// - Named route navigation
/// - Initial route (welcome screen)
/// - AuthProvider available to all routes
class CatrinAbiApp extends StatelessWidget {
  const CatrinAbiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Catrin & Abi BSL',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: AppTheme.lightTheme,

        // Navigation
        initialRoute: AppRoutes.initial,
        onGenerateRoute: generateRoute,
        navigatorObservers: [_AudioStopObserver()],
      ),
    );
  }
}
