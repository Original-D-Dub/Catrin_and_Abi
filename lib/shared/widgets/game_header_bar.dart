import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../services/audio_service.dart';
import 'back_arrow_icon.dart';
import 'button.dart';

/// In-game header bar: back arrow (inside rectangle, far left), score circle
/// (overlapping the rectangle just after the arrow), optional centre content,
/// and level number (right).
///
/// ```
/// ┌──────────────────────────────────────────────┐
/// │ ←  (Score)  │  centerContent or spacer  │ Lv │
/// └──────────────────────────────────────────────┘
///      ↑ circle overlaps rectangle vertically
/// ```
///
/// Pass [centerContent] as a widget that fills the centre expanded section.
/// Leave it null to show an empty spacer. Use [GameTimerDisplay] for the
/// standard timer pill shown in timed games.
class GameHeaderBar extends StatelessWidget {
  /// Called when the back arrow is tapped.
  final VoidCallback onBack;

  /// Label above the value in the score circle (e.g. "Score", "Matches").
  final String scoreLabel;

  /// Value displayed in the score circle (e.g. "5", "2/4").
  final String scoreValue;

  /// Font size for [scoreLabel]. Defaults to 16.
  final double scoreLabelFontSize;

  /// Font size for [scoreValue]. Defaults to 44.
  final double scoreValueFontSize;

  /// Level number shown on the right side of the bar.
  final int levelNumber;

  /// Widget shown in the centre expanded section. Null shows a spacer.
  final Widget? centerContent;

  /// When false the score circle is hidden and its row space is removed.
  final bool showScore;

  /// When false the level column on the right is hidden.
  final bool showLevel;

  /// Shown under [scoreLabel] in place of the [scoreValue] text, e.g. an
  /// animated counter. Scaled down if too wide for the score box.
  final Widget? scoreChild;

  const GameHeaderBar({
    super.key,
    required this.onBack,
    this.scoreLabel = '',
    this.scoreValue = '',
    this.scoreLabelFontSize = 16,
    this.scoreValueFontSize = 44,
    this.levelNumber = 0,
    this.centerContent,
    this.showScore = true,
    this.showLevel = true,
    this.scoreChild,
  });

  // Back arrow icon size, and the width reserved for it inside the rectangle
  // row (icon plus 11px either side). Both double on devices wider than
  // 600px.
  static const double _arrowIconSize = 26;
  static const double _arrowWidth = 48;
  // Width reserved in the row for the score box at its minimum width.
  static const double _scoreRowReservation = 52;
  // Score box height, and its minimum width (grows to fit wide scores).
  static const double _scoreBoxSize = 104;
  // Corner radius: fully rounded — a circle at minimum width, a pill when
  // the box widens for long scores.
  static const double _scoreBoxRadius = _scoreBoxSize / 2;
  // Horizontal breathing room around the score text inside the box.
  static const double _scoreTextPadding = 14;
  // Corner radius of the header rectangle.
  static const double _barRadius = 18;

  /// Felt gradient shared by the bar and the score box: the header colour
  /// with a lighter top edge and darker bottom edge, like the buttons.
  static const _fill = ButtonFill(
    AppColors.headerBackgroundLight,
    AppColors.headerBackground,
    AppColors.headerGradEnd,
  );

  /// Felt backdrop (gradient, fuzz texture, button stitching) for the bar
  /// and the score box, with [child] on top.
  static Widget _felt({required double radius, required Widget child}) {
    return FeltPanel(
      gradient: _fill.gradient,
      stitchColour: AppColors.headerBorderDark,
      radius: radius,
      child: child,
    );
  }

  /// Width of the score box: [_scoreBoxSize] unless the label or value text
  /// is too wide to fit, in which case it grows to fit.
  double _scoreBoxWidth(BuildContext context, String label) {
    final textScaler = MediaQuery.textScalerOf(context);
    double measure(String text, double fontSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      return painter.width;
    }

    final textWidth = [
      measure(label, scoreLabelFontSize),
      measure(scoreValue, scoreValueFontSize),
    ].reduce((a, b) => a > b ? a : b);
    // Room for the stitching (8px inset) on each side, plus text padding.
    final needed = textWidth + 2 * (4 + _scoreTextPadding);
    return needed > _scoreBoxSize ? needed : _scoreBoxSize;
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final scoreLabelText = scoreLabel.isEmpty
        ? localizer('general.score')
        : scoreLabel;
    final scoreBoxWidth = showScore
        ? _scoreBoxWidth(context, scoreLabelText)
        : _scoreBoxSize;
    final arrowScale = MediaQuery.sizeOf(context).width > 600 ? 2.0 : 1.0;
    final arrowIconSize = _arrowIconSize * arrowScale;
    final arrowWidth = _arrowWidth + _arrowIconSize * (arrowScale - 1);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: SizedBox(
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Purple header rectangle — full width
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              bottom: 8,
              child: _felt(
                radius: _barRadius,
                child: Row(
                  children: [
                    // Back arrow
                    GestureDetector(
                      onTap: () {
                        AudioService.stopAll();
                        onBack();
                      },
                      child: SizedBox(
                        width: arrowWidth,
                        child: Center(
                          child: BackArrowIcon(size: arrowIconSize),
                        ),
                      ),
                    ),

                    // Spacer for the score box that overlaps this area;
                    // grows with the box so wide scores don't cover the
                    // centre content.
                    if (showScore)
                      SizedBox(
                        width:
                            _scoreRowReservation +
                            (scoreBoxWidth - _scoreBoxSize),
                      ),

                    // Centre content
                    if (centerContent != null)
                      Expanded(child: centerContent!)
                    else
                      const Spacer(),

                    // Level number (right)
                    if (showLevel)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        // Label and number as one tight block (line height
                        // 1.0, 4px gap) centred vertically in the bar.
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizer('level_select.level_prefix'),
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$levelNumber',
                              style: const TextStyle(
                                fontFamily: 'Quicksand',
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Score box — rounded rectangle positioned after the arrow,
            // overlapping the rectangle vertically (104 px box vs 72 px bar
            // inner height). Widens to fit long scores.
            if (showScore)
              Positioned(
                left: arrowWidth - 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    width: scoreBoxWidth,
                    height: _scoreBoxSize,
                    child: _felt(
                      radius: _scoreBoxRadius,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            scoreLabelText,
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: scoreLabelFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (scoreChild != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: scoreChild,
                              ),
                            )
                          else
                            Text(
                              scoreValue,
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontSize: scoreValueFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Timer pill widget for use as [GameHeaderBar.centerContent] in timed games.
///
/// Shows a "Time" label above a rounded pill displaying [formattedTime].
class GameTimerDisplay extends StatelessWidget {
  /// Pre-formatted time string, e.g. "01:30" or "1:30".
  final String formattedTime;

  const GameTimerDisplay({super.key, required this.formattedTime});

  /// Formats [duration] as `m:ss`, e.g. "1:23", for [formattedTime].
  static String format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          localizer('general.time'),
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.timeContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            formattedTime,
            style: const TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
