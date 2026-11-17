import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/digraph_letter_spacing.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/sign_letter_image.dart';
import 'bingo_tile.dart';

/// The multiplayer caller's screen body (landscape).
///
/// - Left: the "Find the letter" box — the current letter's hand sign (BSL
///   or IAC; both share the sign-letter images, IAC adding the Welsh
///   digraphs) with the purple "Find the letter" pill beneath and a Next
///   button at the bottom.
/// - Right: a box listing every letter already called, each as its sign
///   with the printed letter beneath, in a fixed 4-row grid with one slot
///   per letter of the alphabet — 4×7 for BSL (26 letters), 4×8 for IAC
///   (29) — so every letter fits without scrolling. Tapping Next fills the
///   next slot with the current letter.
///
/// Silent on purpose: players' cards show printed letters, so speaking the
/// letter would give the answer away.
class CallerView extends StatefulWidget {
  /// The letter being shown, or null once the whole alphabet is called.
  final String? letter;

  /// Letters already called, oldest first.
  final List<String> calledLetters;

  /// How many letters can be called in all; sets the grid's columns.
  final int totalLetters;

  final VoidCallback onNext;
  final String locale;

  const CallerView({
    super.key,
    required this.letter,
    required this.calledLetters,
    required this.totalLetters,
    required this.onNext,
    required this.locale,
  });

  @override
  State<CallerView> createState() => _CallerViewState();
}

class _CallerViewState extends State<CallerView> {
  /// Rows in the called-letters grid; columns follow from [totalLetters].
  static const _calledRows = 4;

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    // Wide enough for the double-size sign box; it still scales down to
    // fit on short screens.
    final panelWidth = isTablet ? 480.0 : 320.0;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: panelWidth,
            child: _buildFindLetterPanel(localizer, isTablet),
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          Expanded(child: _buildCalledLettersBox(localizer)),
        ],
      ),
    );
  }

  /// Sign box + "Find the letter" pill, centred, with Next pinned below.
  Widget _buildFindLetterPanel(AppLocalizations localizer, bool isTablet) {
    final letter = widget.letter;
    final boxSize = isTablet ? 440.0 : 300.0;

    final Widget content;
    if (letter == null) {
      content = Text(
        localizer('letter_bingo.all_called'),
        style: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 48,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      );
    } else {
      content = AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Column(
          key: ValueKey('${widget.calledLetters.length}-$letter'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.headerBorderDark,
                  width: 8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SignLetterImage(letter: letter),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentPurple,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Text(
                localizer('letter_bingo.find_letter'),
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: content),
          ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        if (letter != null)
          TertiaryButton(
            label: localizer('general.next'),
            onPressed: widget.onNext,
          ),
      ],
    );
  }

  /// White box with a heading and a fixed grid of called letters — one
  /// slot per letter, empty slots outlined faintly until filled.
  Widget _buildCalledLettersBox(AppLocalizations localizer) {
    final called = widget.calledLetters;
    final cols = (widget.totalLetters / _calledRows).ceil();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(color: AppColors.headerBorderDark, width: 4),
      ),
      padding: const EdgeInsets.all(AppSizes.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizer('letter_bingo.called_letters'),
            style: const TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 6.0;
                final cellWidth =
                    (constraints.maxWidth - spacing * (cols - 1)) / cols;
                final cellHeight =
                    (constraints.maxHeight - spacing * (_calledRows - 1)) /
                    _calledRows;
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: cellHeight <= 0
                        ? 1
                        : cellWidth / cellHeight,
                  ),
                  itemCount: cols * _calledRows,
                  itemBuilder: (context, i) => i < called.length
                      ? _CalledLetterTile(
                          letter: called[i],
                          color: tileColorForIndex(i),
                        )
                      : const _EmptyCalledSlot(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One called letter: its sign above the printed letter, in a coloured
/// border.
class _CalledLetterTile extends StatelessWidget {
  final String letter;
  final Color color;

  const _CalledLetterTile({required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = letter.toLowerCase();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 3),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          Expanded(flex: 3, child: SignLetterImage(letter: letter)),
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                text,
                style: digraphAwareStyle(
                  text,
                  TextStyle(
                    fontFamily: 'OpenDyslexic',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A not-yet-filled slot in the called-letters grid.
class _EmptyCalledSlot extends StatelessWidget {
  const _EmptyCalledSlot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
    );
  }
}
