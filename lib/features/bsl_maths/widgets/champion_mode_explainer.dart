import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/champion_rosette.dart';
import 'bsl_number_display.dart';
import 'champion_mode_unlocked_banner.dart';

/// Opens [ChampionModeExplainer] as a full-screen page. Each game calls
/// this from [ChampionModeUnlockedBanner]'s Continue button, after
/// switching itself back to its level select — so "Let's go!" only has to
/// close the page to land the player there.
Future<void> showChampionModeExplainer(
  BuildContext context, {
  required String locale,
  required String bodyKey,
  required Widget demo,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          ChampionModeExplainer(locale: locale, bodyKey: bodyKey, demo: demo),
    ),
  );
}

/// Full-screen "what's changed" page shown after Champion Mode unlocks:
/// the rosette, a heading, a looping [demo] of the game's change (e.g. the
/// card borders or answer-key digits fading away), a translated
/// explanation ([bodyKey]) and a "Let's go!" button that closes the page.
class ChampionModeExplainer extends StatelessWidget {
  static const Color _background = Color(0xFF14213D);
  static const double _rosetteMaxWidth = 245;

  final String locale;

  /// Translation key for the game-specific explanation.
  final String bodyKey;

  /// Looping animation of what Champion Mode changes in this game.
  final Widget demo;

  const ChampionModeExplainer({
    super.key,
    required this.locale,
    required this.bodyKey,
    required this.demo,
  });

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);
    const bodyStyle = TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.35,
    );

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLarge,
                  vertical: AppSizes.paddingMedium,
                ),
                // Centred so the capped-width column sits in the middle on
                // wide screens rather than hugging the left edge.
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        // Half the column's width, capped at 245px.
                        LayoutBuilder(
                          builder: (context, constraints) => Image.asset(
                            kChampionRosetteAsset,
                            width: (constraints.maxWidth * 0.5).clamp(
                              0.0,
                              _rosetteMaxWidth,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        ChampionHeadingText(
                          localizer('champion_mode.explainer_title'),
                        ),
                        const SizedBox(height: AppSizes.spacingLarge),
                        demo,
                        const SizedBox(height: AppSizes.spacingLarge),
                        Text(
                          localizer(bodyKey),
                          textAlign: TextAlign.center,
                          style: bodyStyle,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        Text(
                          localizer('champion_mode.explainer_turn_off'),
                          textAlign: TextAlign.center,
                          style: bodyStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: PrimaryButton(
                label: localizer('champion_mode.lets_go'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far a looping "fade away" demo has faded at [t] (0–1 through the
/// loop): shown for the first fifth, fades out, stays gone, then fades
/// back in at the end so the loop restarts from the normal look.
double championDemoFade(double t) {
  if (t < 0.2) return 0;
  if (t < 0.45) return Curves.easeInOut.transform((t - 0.2) / 0.25);
  if (t < 0.85) return 1;
  return 1 - Curves.easeInOut.transform((t - 0.85) / 0.15);
}

/// Mixin that runs one repeating controller for a Champion Mode demo.
mixin ChampionDemoLoop<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  /// Length of one loop of the demo.
  Duration get loopDuration => const Duration(milliseconds: 5000);

  late final AnimationController loop = AnimationController(
    vsync: this,
    duration: loopDuration,
  )..repeat();

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

/// Champion Mode demo for the number games: three BSL answer keys whose
/// digit labels fade away, leaving only the signs.
class AnswerDigitsFadeDemo extends StatefulWidget {
  const AnswerDigitsFadeDemo({super.key});

  @override
  State<AnswerDigitsFadeDemo> createState() => _AnswerDigitsFadeDemoState();
}

class _AnswerDigitsFadeDemoState extends State<AnswerDigitsFadeDemo>
    with SingleTickerProviderStateMixin, ChampionDemoLoop {
  static const List<int> _numbers = [3, 5, 8];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final digitOpacity = 1 - championDemoFade(loop.value);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final n in _numbers)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingSmall,
                ),
                child: _buildKey(n, digitOpacity),
              ),
          ],
        );
      },
    );
  }

  /// A white answer key like the games' own: the sign above its digit.
  /// The digit keeps its space while fading so the sign doesn't move.
  Widget _buildKey(int n, double digitOpacity) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingSmall),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(color: AppColors.catrinBlue, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BslNumberDisplay(number: n, size: 72),
          const SizedBox(height: 4),
          Opacity(
            opacity: digitOpacity,
            child: Text(
              '$n',
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontSize: AppSizes.fontSizeHeading,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
