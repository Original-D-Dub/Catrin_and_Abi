import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/settings_selection_tile.dart';

/// Language choice, plus sound effects / instructions toggles — reached via
/// the "Settings" menu item on the profile page.
///
/// The language section mirrors the one on the app-wide `SettingsScreen`
/// (reached from the home screen) — both read and write the same
/// `SettingsProvider.language`, so changing it on either page updates the
/// other.
class ProfileSettingsScreen extends StatelessWidget {
  final String locale;

  const ProfileSettingsScreen({super.key, this.locale = 'en'});

  void _changeLanguage(BuildContext context, String newLocale) {
    final settings = context.read<SettingsProvider>();
    if (newLocale == settings.language) {
      Navigator.pop(context);
      return;
    }
    settings.setLanguage(newLocale);
    final route = newLocale == 'cy' ? AppRoutes.welshHome : AppRoutes.home;
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(locale: locale);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1250),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const BackArrowIcon(),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('profile_settings.title'),
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          children: [
            SettingsSection(
              title: t('settings.language_section'),
              children: [
                SettingsSelectionTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 28)),
                  label: t('settings.english'),
                  sublabel: t('settings.english_sub'),
                  isSelected: settings.language == 'en',
                  onTap: () => _changeLanguage(context, 'en'),
                ),
                const SettingsDivider(),
                SettingsSelectionTile(
                  leading: const Text('🏴󠁧󠁢󠁷󠁬󠁳󠁿', style: TextStyle(fontSize: 28)),
                  label: t('settings.welsh'),
                  sublabel: t('settings.welsh_sub'),
                  isSelected: settings.language == 'cy',
                  onTap: () => _changeLanguage(context, 'cy'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _ToggleTile(
                    label: t('profile_settings.sound_effects'),
                    sublabel: t('profile_settings.sound_effects_sub'),
                    value: settings.soundEffectsEnabled,
                    onChanged: (value) =>
                        context.read<SettingsProvider>().setSoundEffectsEnabled(value),
                  ),
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                  _ToggleTile(
                    label: t('profile_settings.instructions'),
                    sublabel: t('profile_settings.instructions_sub'),
                    value: settings.instructionsEnabled,
                    onChanged: (value) =>
                        context.read<SettingsProvider>().setInstructionsEnabled(value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF69F0AE),
            activeTrackColor: const Color(0xFF69F0AE).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
