import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';

/// Settings screen — accessible from the home screen app bar.
///
/// Sections:
///   • Language — switches between English and Welsh home screens.
///   • Game Type — filters tiles by category (alphabet, numeracy, vocabulary).
///   • Age Group — filters tiles by school-year band.
///
/// Add new [_SettingsSection] widgets at the bottom of the ListView
/// body to extend the settings page.
class SettingsScreen extends StatelessWidget {
  /// The locale of the calling home screen ('en' or 'cy').
  final String currentLocale;

  const SettingsScreen({super.key, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = AppLocalizations(locale: currentLocale);

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
          t('settings.title'),
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Language ──────────────────────────────────────────────────────
          _SettingsSection(
            title: t('settings.language_section'),
            children: [
              _SelectionTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 28)),
                label: t('settings.english'),
                sublabel: t('settings.english_sub'),
                isSelected: currentLocale == 'en',
                onTap: () => _changeLanguage(context, 'en'),
              ),
              const _Divider(),
              _SelectionTile(
                leading: const Text('🏴󠁧󠁢󠁷󠁬󠁳󠁿', style: TextStyle(fontSize: 28)),
                label: t('settings.welsh'),
                sublabel: t('settings.welsh_sub'),
                isSelected: currentLocale == 'cy',
                onTap: () => _changeLanguage(context, 'cy'),
              ),
            ],
          ),

          // ── Game Type ─────────────────────────────────────────────────────
          _SettingsSection(
            title: t('settings.game_type_section'),
            children: [
              _SelectionTile(
                leading: const Icon(Icons.apps_rounded, color: Colors.white70, size: 28),
                label: t('settings.all_games'),
                sublabel: t('settings.all_games_sub'),
                isSelected: settings.gameCategory == GameCategory.all,
                onTap: () => context.read<SettingsProvider>().setGameCategory(GameCategory.all),
              ),
              const _Divider(),
              _SelectionTile(
                leading: const Icon(Icons.sort_by_alpha_rounded, color: Colors.white70, size: 28),
                label: t('settings.alphabet'),
                sublabel: t('settings.alphabet_sub'),
                isSelected: settings.gameCategory == GameCategory.alphabet,
                onTap: () => context.read<SettingsProvider>().setGameCategory(GameCategory.alphabet),
              ),
              const _Divider(),
              _SelectionTile(
                leading: const Icon(Icons.calculate_outlined, color: Colors.white70, size: 28),
                label: t('settings.numeracy'),
                sublabel: t('settings.numeracy_sub'),
                isSelected: settings.gameCategory == GameCategory.numeracy,
                onTap: () => context.read<SettingsProvider>().setGameCategory(GameCategory.numeracy),
              ),
              const _Divider(),
              _SelectionTile(
                leading: const Icon(Icons.record_voice_over_outlined, color: Colors.white70, size: 28),
                label: t('settings.vocabulary'),
                sublabel: t('settings.vocabulary_sub'),
                isSelected: settings.gameCategory == GameCategory.vocabulary,
                onTap: () => context.read<SettingsProvider>().setGameCategory(GameCategory.vocabulary),
              ),
            ],
          ),

          // ── Age Group ─────────────────────────────────────────────────────
          _SettingsSection(
            title: t('settings.age_group_section'),
            children: [
              _SelectionTile(
                leading: const _AgeBadge('All'),
                label: t('settings.all_ages'),
                sublabel: t('settings.all_ages_sub'),
                isSelected: settings.ageGroup == AgeGroup.all,
                onTap: () => context.read<SettingsProvider>().setAgeGroup(AgeGroup.all),
              ),
              const _Divider(),
              _SelectionTile(
                leading: const _AgeBadge('1–3'),
                label: t('settings.years1to3'),
                sublabel: t('settings.years1to3_sub'),
                isSelected: settings.ageGroup == AgeGroup.years1to3,
                onTap: () => context.read<SettingsProvider>().setAgeGroup(AgeGroup.years1to3),
              ),
              const _Divider(),
              _SelectionTile(
                leading: const _AgeBadge('3–5'),
                label: t('settings.years3to5'),
                sublabel: t('settings.years3to5_sub'),
                isSelected: settings.ageGroup == AgeGroup.years3to5,
                onTap: () => context.read<SettingsProvider>().setAgeGroup(AgeGroup.years3to5),
              ),
              const _Divider(),
              _SelectionTile(
                leading: const _AgeBadge('5+'),
                label: t('settings.years5plus'),
                sublabel: t('settings.years5plus_sub'),
                isSelected: settings.ageGroup == AgeGroup.years5plus,
                onTap: () => context.read<SettingsProvider>().setAgeGroup(AgeGroup.years5plus),
              ),
            ],
          ),

          // Add new _SettingsSection widgets here for future settings.
        ],
      ),
    );
  }

  void _changeLanguage(BuildContext context, String locale) {
    if (locale == currentLocale) {
      Navigator.pop(context);
      return;
    }
    context.read<SettingsProvider>().setLanguage(locale);
    final route = locale == 'cy' ? AppRoutes.welshHome : AppRoutes.home;
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }
}

// ── Shared section container ─────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Generic selection row ────────────────────────────────────────────────────

class _SelectionTile extends StatelessWidget {
  final Widget leading;
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.leading,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            SizedBox(width: 36, child: Center(child: leading)),
            const SizedBox(width: 14),
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
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF69F0AE), size: 26)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.white30, size: 26),
          ],
        ),
      ),
    );
  }
}

// ── Age badge leading widget ─────────────────────────────────────────────────

class _AgeBadge extends StatelessWidget {
  final String label;

  const _AgeBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'ComicRelief',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Section divider ───────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16);
}
