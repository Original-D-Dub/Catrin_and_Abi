import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Supabase.initialize(
    url: 'https://dczagvdllqhzbiqljzfi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjemFndmRsbHFoemJpcWxqemZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjEwNTMsImV4cCI6MjA5MTI5NzA1M30.-reWzVGeuc69wVDi9-PeLxjBFhxsGeKJPwjU9I5xV5U',
  );

  runApp(const CatrinAbiApp());
}
