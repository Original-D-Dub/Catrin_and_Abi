import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/route_observers.dart';
import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/home/providers/trail_provider.dart';
import 'features/letter_bingo/providers/bingo_collection_provider.dart';
import 'features/sports_collection/providers/sports_collection_provider.dart';
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
        ChangeNotifierProvider(create: (_) => TrailProvider()),
        ChangeNotifierProvider(create: (_) => BingoCollectionProvider()),
        ChangeNotifierProvider(create: (_) => SportsCollectionProvider()),
      ],
      child: MaterialApp(
        title: 'Catrin & Abi BSL',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: AppTheme.lightTheme,

        // Re-themes for the device's current width on every build (screen
        // rotation, window resize) so the default body text size can react
        // to it — see AppTheme.themeForWidth.
        builder: (context, child) => Theme(
          data: AppTheme.themeForWidth(MediaQuery.sizeOf(context).width),
          child: child!,
        ),

        // Navigation
        initialRoute: AppRoutes.initial,
        onGenerateRoute: generateRoute,
        navigatorObservers: [_AudioStopObserver(), trailRouteObserver],
      ),
    );
  }
}
