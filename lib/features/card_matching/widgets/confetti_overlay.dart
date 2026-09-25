import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/button.dart';

/// Confetti celebration overlay shown when player wins.
///
/// Displays confetti animation with "Well Done!" message
/// and Play Again / Home buttons.
///
/// Usage:
/// ```dart
/// if (provider.hasWon) {
///   ConfettiOverlay(
///     message: 'Well Done!',
///     onPlayAgain: () => provider.resetGame(),
///     onHome: () => Navigator.pop(context),
///   )
/// }
/// ```
class ConfettiOverlay extends StatefulWidget {
  /// The celebration message to display
  final String message;

  /// Label for the play again button
  final String playAgainLabel;

  /// Label for the home button
  final String homeLabel;

  /// Callback when play again is pressed
  final VoidCallback onPlayAgain;

  /// Callback when home is pressed
  final VoidCallback onHome;

  /// Optional callback when change level is pressed
  final VoidCallback? onChangeLevel;

  /// Optional widget shown between the message and the buttons (e.g. sign-in banner)
  final Widget? signInBanner;

  const ConfettiOverlay({
    super.key,
    required this.message,
    required this.playAgainLabel,
    required this.homeLabel,
    required this.onPlayAgain,
    required this.onHome,
    this.onChangeLevel,
    this.signInBanner,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Start confetti immediately
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          color: Colors.black.withValues(alpha: 0.5),
        ),

        // Confetti from top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.accentRed,
              AppColors.accentOrange,
              AppColors.accentYellow,
              AppColors.accentLimeGreen,
              AppColors.accentNavyBlue,
              AppColors.accentPurple,
              AppColors.abiPink,
            ],
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            gravity: 0.2,
          ),
        ),

        // Celebration card
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusXLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge * 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star icon
                  const Icon(
                    Icons.star,
                    size: AppSizes.iconXLarge * 2,
                    color: AppColors.connectorGold,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),

                  // Well done message
                  Text(
                    widget.message,
                    style: AppTheme.title.copyWith(
                      fontSize: AppSizes.fontSizeTitle,
                      color: AppColors.abiPink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.signInBanner != null) ...[
                    const SizedBox(height: AppSizes.spacingMedium),
                    widget.signInBanner!,
                  ],
                  const SizedBox(height: AppSizes.spacingXLarge),

                  // Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Play Again button
                      PrimaryButton(
                        label: widget.playAgainLabel,
                        icon: Icons.replay,
                        expanded: true,
                        onPressed: widget.onPlayAgain,
                      ),
                      const SizedBox(height: AppSizes.spacingMedium),

                      // Home button
                      TertiaryButton(
                        label: widget.homeLabel,
                        icon: Icons.home,
                        expanded: true,
                        onPressed: widget.onHome,
                      ),

                      // Change Level button (optional)
                      if (widget.onChangeLevel != null) ...[
                        const SizedBox(height: AppSizes.spacingMedium),
                        Center(
                          child: TertiaryButton(
                            label: 'Change Level',
                            icon: Icons.grid_view,
                            onPressed: widget.onChangeLevel,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingLarge,
                              vertical: AppSizes.paddingSmall,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ],
    );
  }
}
