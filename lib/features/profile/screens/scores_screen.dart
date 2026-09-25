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

/// Below this width, rows switch to a table layout: a shared "Levels" /
/// "Best" column header replaces each row's own icon+label, freeing up room
/// for larger numbers on tight screens. Matches the tablet breakpoint used
/// elsewhere (e.g. videos_screen.dart).
const double _kTabletBreakpoint = 600;

/// Widths shared between [_ScoresHeader] and each row's [_LevelSwiper] so
/// their columns line up. [_scoreColumnWidth] is sized to comfortably fit
/// "88 moves" — card matching's widest realistic value — without wrapping.
const double _levelColumnWidth = 64;
const double _scoreColumnWidth = 132;

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

    return Column(
      children: [
        if (isCompact)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLarge,
              AppSizes.paddingLarge,
              AppSizes.paddingLarge,
              AppSizes.spacingSmall,
            ),
            child: _ScoresHeader(
              levelsLabel: t('profile.scores_levels_header'),
              bestLabel: t('profile.scores_best_label'),
            ),
          ),
        Expanded(
          child: ListView.separated(
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
                color: _rowColors[i % _rowColors.length],
                isCompact: isCompact,
                // The shared header only speaks for the generic "Best"
                // pill — a row with its own distinct label (e.g. Letter
                // Bingo's "Animals") keeps showing it inline regardless of
                // width, since there's no matching column header for it.
                showPillLabel:
                    !isCompact || entry.pillLabelKey != 'profile.scores_best_label',
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Column headers shown above the list on narrow (compact) screens: a blank
/// spacer over the game-title column, "Levels" over the level column, and
/// the trophy icon + "Best" over the score column — replacing what each
/// row's pill would otherwise show inline.
class _ScoresHeader extends StatelessWidget {
  final String levelsLabel;
  final String bestLabel;

  const _ScoresHeader({required this.levelsLabel, required this.bestLabel});

  static const TextStyle _style = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SizedBox.shrink()),
        const SizedBox(width: AppSizes.spacingMedium),
        SizedBox(
          width: _levelColumnWidth,
          child: Center(
            child: Text(levelsLabel, textAlign: TextAlign.center, style: _style),
          ),
        ),
        const SizedBox(width: AppSizes.spacingSmall),
        SizedBox(
          width: _scoreColumnWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(bestLabel, style: _style),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: Colors.white),
            const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
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

/// A single game's personal-best row. The level column on the right shows
/// one [LevelScore] at a time — swipe up/down on it to move between a
/// game's levels when it has more than one.
class _ScoreRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge,
        vertical: AppSizes.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.67),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          _LevelSwiper(
            levels: levels,
            pillLabel: pillLabel,
            pillIcon: pillIcon,
            suffix: suffix,
            levelLabel: levelLabel,
            isCompact: isCompact,
            showPillLabel: showPillLabel,
          ),
        ],
      ),
    );
  }
}

/// The level column for one [_ScoreRow]. Shows the score for one level at a
/// time; a vertical swipe moves to the next/previous level when the game has
/// more than one. Swiping up (finger moving toward the top of the screen)
/// advances to the next level, mirroring a vertical feed.
///
/// On narrow (compact) screens ([isCompact]) the "Level N" text collapses to
/// a bare number (a shared "Levels" column header — see [_ScoresHeader] —
/// already says what it is) and, when [showPillLabel] is false, the pill's
/// icon and label disappear too (replaced by the header's icon + "Best"),
/// leaving more room for the number itself.
class _LevelSwiper extends StatefulWidget {
  final List<LevelScore> levels;
  final String pillLabel;
  final IconData? pillIcon;
  final String suffix;
  final String levelLabel;
  final bool isCompact;
  final bool showPillLabel;

  const _LevelSwiper({
    required this.levels,
    required this.pillLabel,
    required this.pillIcon,
    required this.suffix,
    required this.levelLabel,
    required this.isCompact,
    required this.showPillLabel,
  });

  @override
  State<_LevelSwiper> createState() => _LevelSwiperState();
}

class _LevelSwiperState extends State<_LevelSwiper> {
  int _index = 0;

  /// Fixed score colour for every row — deliberately not tied to the
  /// row's own container colour, so every best score reads the same.
  static const Color _scoreColor = Colors.white;

  @override
  void didUpdateWidget(_LevelSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.levels.length) _index = 0;
  }

  void _move(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.levels.length) return;
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.levels[_index];
    final canGoUp = _index < widget.levels.length - 1;
    final canGoDown = _index > 0;

    final upArrow = Icon(
      Icons.keyboard_arrow_up,
      size: 16,
      color: canGoUp ? Colors.white70 : Colors.white24,
    );
    final downArrow = Icon(
      Icons.keyboard_arrow_down,
      size: 16,
      color: canGoDown ? Colors.white70 : Colors.white24,
    );

    // Letter Bingo-style rows (a single stat with no per-level breakdown,
    // shown with its own icon+label — see ScoresProvider) span the level
    // column too, so the empty level slot they'd otherwise leave blank
    // becomes extra room for their pill instead.
    final spansColumns =
        widget.isCompact && current.level == null && widget.showPillLabel;

    // Fixed so every pill in the compact table lines up; wide/tablet mode
    // keeps the pill sized to its content.
    final double? pillWidth = !widget.isCompact
        ? null
        : spansColumns
            ? _levelColumnWidth + AppSizes.spacingSmall + _scoreColumnWidth
            : _scoreColumnWidth;

    final scoreTextStyle = TextStyle(
      fontFamily: 'Quicksand',
      fontSize: widget.isCompact ? 18 : 15,
      fontWeight: FontWeight.w600,
      color: _scoreColor,
    );

    // Letter Bingo's "Animals" pill has no icon (see ScoresProvider) and
    // reads label-after-number ("5 Animals") instead of the usual
    // "Best: 5" ordering used by every other pill.
    final scoreNumber = !widget.showPillLabel
        ? Text('${current.score}${widget.suffix}', style: scoreTextStyle)
        : widget.pillIcon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.pillIcon, color: _scoreColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.pillLabel}: ${current.score}${widget.suffix}',
                    style: scoreTextStyle,
                  ),
                ],
              )
            : Text(
                '${current.score}${widget.suffix} ${widget.pillLabel}',
                style: scoreTextStyle,
              );

    // No boxed pill any more — the number sits directly on the row's own
    // coloured container. [pillWidth] still fixes the column's width (for
    // alignment with the header and other rows); numbers (and, for a
    // spanning row like Letter Bingo's "Animals", their label too)
    // right-align within it so digits line up down the column.
    final pill = pillWidth == null
        ? scoreNumber
        : SizedBox(
            width: pillWidth,
            child: Align(alignment: Alignment.centerRight, child: scoreNumber),
          );

    final content = !widget.isCompact
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: current.level == null
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.center,
            children: [
              upArrow,
              if (current.level != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${widget.levelLabel} ${current.level}',
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              pill,
              downArrow,
            ],
          )
        : spansColumns
            ? pill
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: _levelColumnWidth,
                    child: current.level == null
                        ? const SizedBox.shrink()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              upArrow,
                              Text(
                                '${current.level}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Quicksand',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              downArrow,
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSizes.spacingSmall),
                  pill,
                ],
              );

    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < 0) {
          _move(1);
        } else if (velocity > 0) {
          _move(-1);
        }
      },
      child: content,
    );
  }
}
