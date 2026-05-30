import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../services/audio_service.dart';

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
  });

  // Width reserved for the back arrow inside the rectangle row.
  static const double _arrowWidth = 48;
  // Width reserved in the row for the score circle (≈ half circle diameter).
  static const double _circleRowReservation = 52;

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
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
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.headerBackgroundLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.headerBorderDark,
                    width: 2,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.headerBorderDark,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Back arrow
                      GestureDetector(
                        onTap: () {
                          AudioService.stopAll();
                          onBack();
                        },
                        child: const SizedBox(
                          width: _arrowWidth,
                          child: Center(
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),

                      // Spacer for the score circle that overlaps this area
                      if (showScore)
                        const SizedBox(width: _circleRowReservation),

                      // Centre content
                      if (centerContent != null)
                        Expanded(child: centerContent!)
                      else
                        const Spacer(),

                      // Level number (right)
                      if (showLevel)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localizer('level_select.level_prefix'),
                                style: TextStyle(
                                  fontFamily: 'ComicRelief',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$levelNumber',
                                style: const TextStyle(
                                  fontFamily: 'ComicRelief',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Score circle — positioned after the arrow, overlapping the
            // rectangle vertically (104 px circle vs 72 px bar inner height).
            if (showScore)
            Positioned(
              left: _arrowWidth - 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.headerBackgroundLight,
                    border: Border.all(
                      color: AppColors.headerBorderDark,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.headerBackground,
                      border: Border.all(
                        color: AppColors.headerBorderDark,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scoreLabel.isEmpty ? localizer('general.score') : scoreLabel,
                          style: TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: scoreLabelFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          scoreValue,
                          style: TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: scoreValueFontSize,
                            fontWeight: FontWeight.w900,
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

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          localizer('general.time'),
          style: TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
              fontFamily: 'ComicRelief',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
