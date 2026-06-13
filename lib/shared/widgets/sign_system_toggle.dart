import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/game_filters.dart';
import '../services/settings_provider.dart';

/// Toggle between BSL and IAC sign systems for letter-sign games.
///
/// Persisted via [SettingsProvider] and shared across the English and
/// Welsh home screens — toggling here changes the sign language used in
/// games like Bubble Pop regardless of UI language.
class SignSystemToggle extends StatelessWidget {
  const SignSystemToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final signSystem = context.watch<SettingsProvider>().signSystem;

    return SegmentedButton<SignSystem>(
      segments: const [
        ButtonSegment(value: SignSystem.bsl, label: Text('BSL')),
        ButtonSegment(value: SignSystem.iac, label: Text('IAC')),
      ],
      selected: {signSystem},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          context.read<SettingsProvider>().setSignSystem(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
        selectedBackgroundColor: Colors.white,
        selectedForegroundColor: AppColors.accentPurple,
        side: const BorderSide(color: Colors.white70),
        textStyle: const TextStyle(
          fontFamily: 'ComicRelief',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
