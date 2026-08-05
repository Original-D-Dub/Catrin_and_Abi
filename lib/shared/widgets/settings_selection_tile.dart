import 'package:flutter/material.dart';

/// Titled, bordered box grouping a set of [SettingsSelectionTile]s —
/// shared between the app-wide `SettingsScreen` and `ProfileSettingsScreen`
/// so sections like "Language" look identical wherever they appear.
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({super.key, required this.title, required this.children});

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

/// A single tappable row with a leading icon/emoji, label, sublabel, and a
/// selected/unselected indicator — used for mutually-exclusive choices such
/// as language, game type, or age group.
class SettingsSelectionTile extends StatelessWidget {
  final Widget leading;
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const SettingsSelectionTile({
    super.key,
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

/// Thin divider between [SettingsSelectionTile] rows within a [SettingsSection].
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16);
}
