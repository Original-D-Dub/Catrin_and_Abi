import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/button.dart';
import '../providers/scores_provider.dart';

/// Player scores — reached via the "Score" menu item on the profile screen.
///
/// Lists every game's personal-best score, once it's greater than zero.
/// Fetched lazily via [ScoresProvider.loadIfNeeded] in [initState] — nothing
/// is downloaded from Supabase until this screen is actually opened.
class ScoresScreen extends StatefulWidget {
  final String locale;

  const ScoresScreen({super.key, this.locale = 'en'});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ScoresProvider>().loadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(locale: widget.locale);
    final isAnonymous = context.watch<AuthProvider>().isAnonymous;
    final scores = context.watch<ScoresProvider>();

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
          t('profile.scores_title'),
          style: AppTheme.title.copyWith(fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isAnonymous
            ? _SignInPrompt(
                message: t('profile.scores_sign_in_message'),
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.profile,
                  arguments: {'locale': widget.locale, 'scrollToAccount': 'true'},
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLarge,
                      0,
                      AppSizes.paddingLarge,
                      AppSizes.spacingSmall,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _SignSystemFilter(
                        selected: scores.selectedSignSystem,
                        onChanged: scores.setSelectedSignSystem,
                      ),
                    ),
                  ),
                  Expanded(
                    child: scores.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _ScoresList(t: t, entries: scores.entries),
                  ),
                ],
              ),
      ),
    );
  }
}

/// BSL/IAC filter for which sign system's scores are shown below. Local to
/// this screen (backed by [ScoresProvider], not [SettingsProvider]) — unlike
/// the app-wide [SignSystemToggle], switching this shouldn't change which
/// games/content show elsewhere in the app.
class _SignSystemFilter extends StatelessWidget {
  final SignSystem selected;
  final ValueChanged<SignSystem> onChanged;

  const _SignSystemFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SignSystem>(
      segments: const [
        ButtonSegment(value: SignSystem.bsl, label: Text('BSL')),
        ButtonSegment(value: SignSystem.iac, label: Text('IAC')),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
        selectedBackgroundColor: Colors.white,
        selectedForegroundColor: AppColors.accentPurple,
        side: const BorderSide(color: Colors.white70),
        textStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Cycled through by row index so each game's card gets a distinct colour —
/// the same palette used for profile avatars, for brand consistency.
const List<Color> _rowColors = [
  AppColors.accentRed,
  AppColors.accentOrange,
  AppColors.accentYellow,
  AppColors.accentLimeGreen,
  AppColors.accentNavyBlue,
  AppColors.accentPurple,
  AppColors.abiPink,
  AppColors.catrinBlue,
];

/// Below this width, a row's score font shrinks slightly to leave more room
/// for larger numbers on tight screens. Matches the tablet breakpoint used
/// elsewhere (e.g. videos_screen.dart).
const double _kTabletBreakpoint = 600;

/// Width of the score value column, shared by every row's collapsed summary
/// and the per-level lines inside its expanded table so scores line up in a
/// single column down the page. Sized to comfortably fit "88 moves" — card
/// matching's widest realistic value — without wrapping.
const double _scoreColumnWidth = 132;

/// Width reserved for the expand/collapse chevron. Every row reserves this
/// space — even a row with nothing to expand leaves it empty — so the score
/// column just before it lines up whether or not a chevron is drawn there.
const double _chevronColumnWidth = 28;

/// How long a row's level table takes to open/close.
const Duration _kExpandDuration = Duration(milliseconds: 300);

/// Renders a [_ScoreRow]'s collapsed summary value: "`<label>: <score><suffix>`"
/// (with an optional icon), "`<score><suffix> <label>`" when there's no icon,
/// or a bare "`<score><suffix>`" when [showPillLabel] is false (card
/// matching — see [GameScoreEntry.showPillLabel]).
Widget _scoreValue({
  required LevelScore level,
  required String pillLabel,
  required IconData? pillIcon,
  required String suffix,
  required bool showPillLabel,
  required TextStyle style,
}) {
  if (!showPillLabel) {
    return Text('${level.score}$suffix', style: style);
  }
  if (pillIcon != null) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(pillIcon, color: style.color, size: 16),
        const SizedBox(width: 6),
        Text('$pillLabel: ${level.score}$suffix', style: style),
      ],
    );
  }
  return Text('${level.score}$suffix $pillLabel', style: style);
}

class _ScoresList extends StatelessWidget {
  final AppLocalizations t;
  final List<GameScoreEntry> entries;

  const _ScoresList({required this.t, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState(
        icon: Icons.emoji_events_outlined,
        message: t('profile.scores_empty'),
      );
    }
    final isCompact = MediaQuery.of(context).size.width < _kTabletBreakpoint;
    final levelLabel = t('level_select.level_prefix');

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.spacingMedium),
      itemBuilder: (_, i) {
        final entry = entries[i];
        return _ScoreRow(
          title: t(entry.titleKey),
          levels: entry.levels,
          pillLabel: t(entry.pillLabelKey),
          pillIcon: entry.pillIcon,
          suffix: entry.suffixKey != null ? t(entry.suffixKey!) : '',
          levelLabel: levelLabel,
          showPillLabel: entry.showPillLabel,
          color: _rowColors[i % _rowColors.length],
          isCompact: isCompact,
        );
      },
    );
  }
}

/// Widest the sign-in button is allowed to grow — narrow enough that
/// [_SignInPrompt]'s message wraps onto two lines on its own, without a
/// manual line break.
const double _kSignInButtonMaxWidth = 280;

/// Shown instead of the scores list for anonymous players. Tapping the
/// message opens the profile screen scrolled to its account section, where
/// they can sign in.
class _SignInPrompt extends StatelessWidget {
  final String message;
  final VoidCallback onPressed;

  const _SignInPrompt({required this.message, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: Colors.white),
            const SizedBox(height: AppSizes.spacingMedium),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kSignInButtonMaxWidth),
              child: TertiaryButton(
                label: message,
                icon: Icons.person_add,
                expanded: true,
                onPressed: onPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white38),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single game's personal-best row. Collapsed, it shows just the highest
/// level the player has reached; tapping the row animates open a table of
/// every level they've played (tapping again animates it shut). Rows with
/// only one played level (e.g. Letter Bingo's single animal-count stat)
/// aren't tappable — there's nothing more to show.
class _ScoreRow extends StatefulWidget {
  final String title;
  final List<LevelScore> levels;
  final String pillLabel;
  final IconData? pillIcon;
  final String suffix;
  final String levelLabel;
  final Color color;
  final bool isCompact;
  final bool showPillLabel;

  const _ScoreRow({
    required this.title,
    required this.levels,
    required this.pillLabel,
    required this.pillIcon,
    required this.suffix,
    required this.levelLabel,
    required this.color,
    required this.isCompact,
    required this.showPillLabel,
  });

  @override
  State<_ScoreRow> createState() => _ScoreRowState();
}

class _ScoreRowState extends State<_ScoreRow> {
  bool _expanded = false;

  bool get _expandable => widget.levels.length > 1;

  void _toggle() {
    if (!_expandable) return;
    setState(() => _expanded = !_expanded);
  }

  /// The highest level the player has reached — shown alone while collapsed.
  /// [levels] is sorted ascending by [ScoresProvider], so it's the last one.
  LevelScore get _highest => widget.levels.last;

  @override
  Widget build(BuildContext context) {
    final scoreTextStyle = TextStyle(
      fontFamily: 'Quicksand',
      fontSize: widget.isCompact ? 18 : 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    final scoreValue = _scoreValue(
      level: _highest,
      pillLabel: widget.pillLabel,
      pillIcon: widget.pillIcon,
      suffix: widget.suffix,
      showPillLabel: widget.showPillLabel,
      style: scoreTextStyle,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: AppSizes.paddingMedium,
        ),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.67),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMedium),
                SizedBox(
                  width: _scoreColumnWidth,
                  child: Align(alignment: Alignment.centerRight, child: scoreValue),
                ),
                const SizedBox(width: AppSizes.spacingSmall),
                SizedBox(
                  width: _chevronColumnWidth,
                  child: _expandable
                      ? AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: _kExpandDuration,
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 22,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            AnimatedSize(
              duration: _kExpandDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expandable && _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSizes.spacingSmall),
                      child: _LevelTable(
                        levels: widget.levels.reversed.toList(),
                        suffix: widget.suffix,
                        levelLabel: widget.levelLabel,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// The table revealed by expanding a [_ScoreRow]: one line per level the
/// player has played, highest first, each showing that level's own best
/// score right-aligned in the same [_scoreColumnWidth] column as the row's
/// collapsed summary above, with a matching blank [_chevronColumnWidth]
/// spacer after it so every score in the row lines up in one column.
class _LevelTable extends StatelessWidget {
  final List<LevelScore> levels;
  final String suffix;
  final String levelLabel;

  const _LevelTable({
    required this.levels,
    required this.suffix,
    required this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    const rowStyle = TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    return Column(
      children: [
        const Divider(color: Colors.white24, height: AppSizes.spacingMedium),
        for (final level in levels)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '$levelLabel ${level.level}',
                  style: rowStyle.copyWith(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                SizedBox(
                  width: _scoreColumnWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('${level.score}$suffix', style: rowStyle),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingSmall),
                const SizedBox(width: _chevronColumnWidth),
              ],
            ),
          ),
      ],
    );
  }
}
