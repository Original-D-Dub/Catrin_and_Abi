import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

/// Entry point for the Catrin & Abi BSL Learning App.
///
/// This app teaches children (ages 6-11) British Sign Language
/// finger-spelling through interactive games.
///
/// Features:
/// - Welcome screen with character introductions
/// - Card matching game (BSL signs to letters)
/// - Bilingual support (English/Welsh)
/// - Accessibility considerations for Deaf users
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait mode for consistent game experience)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const CatrinAbiApp());
}
