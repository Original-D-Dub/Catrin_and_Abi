import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/routes.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/localization/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/auth_provider.dart';
import 'button.dart';

/// Shows a "Sign in to save your scores" button for anonymous users.
///
/// The button gently double-pulses (scale 1.0→1.1→1.0 twice, 400 ms
/// ease-in-out beats) every 6 seconds, then holds flat until the next
/// cycle — a continuous reverse-repeat read as too busy for a persistent
/// banner. Held static under the OS "reduce motion" accessibility setting.
/// Renders nothing for signed-in users.
class SignInBannerButton extends StatefulWidget {
  /// UI locale ('en' or 'cy') used for the button label.
  final String locale;

  /// Label font size. Defaults to 14 — the shared button default
  /// ([MasterButton]'s `fontSizeLarge + 2`) is far too large for this CTA.
  final double fontSize;

  /// Overrides the label and icon drop-shadow offset. Null keeps the shared
  /// button default.
  final Offset? textShadowOffset;

  const SignInBannerButton({
    super.key,
    this.locale = 'en',
    this.fontSize = 14,
    this.textShadowOffset,
  });

  @override
  State<SignInBannerButton> createState() => _SignInBannerButtonState();
}

class _SignInBannerButtonState extends State<SignInBannerButton>
    with SingleTickerProviderStateMixin {
  static const Duration _pulseCycle = Duration(seconds: 6);
  static const Duration _pulseBeat = Duration(milliseconds: 400);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (context.read<AuthProvider>().isAnonymous) {
      AudioService.playSpeechMp3(
        'sign_in_to_save_scores',
        locale: widget.locale,
      );
    }
    _pulseController = AnimationController(vsync: this, duration: _pulseCycle)
      ..repeat();
    final beatWeight = _pulseBeat.inMilliseconds.toDouble();
    final holdWeight = (_pulseCycle - _pulseBeat * 4).inMilliseconds.toDouble();
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: beatWeight,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: beatWeight,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: beatWeight,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: beatWeight,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: holdWeight),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isAnonymous) {
      return const SizedBox.shrink();
    }
    final localizer = AppLocalizations(locale: widget.locale);
    return ScaleTransition(
      scale: MediaQuery.of(context).disableAnimations
          ? const AlwaysStoppedAnimation<double>(1.0)
          : _pulseAnimation,
      child: TertiaryButton(
        label: localizer('general.sign_in_to_save_scores'),
        icon: Icons.person_add,
        fontSize: widget.fontSize,
        textShadowOffset: widget.textShadowOffset,
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.profile,
          arguments: widget.locale,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium + 2,
          vertical: AppSizes.paddingSmall + 2,
        ),
      ),
    );
  }
}
