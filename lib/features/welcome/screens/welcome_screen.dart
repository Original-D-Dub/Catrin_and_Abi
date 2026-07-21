import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
import '../providers/welcome_provider.dart';
import '../widgets/character_speaker.dart';
import '../widgets/pero_speaker.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late WelcomeProvider _provider;
  final AppLocalizations _localizer = AppLocalizations(locale: 'en');
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _provider = WelcomeProvider();
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await _provider.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<WelcomeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildContent(context, provider);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WelcomeProvider provider) {
    final isReturning = provider.isStoryComplete || provider.hasSeenIntro;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Returning users get a plain white background; first-time users
        // still get the park backdrop behind the story.
        if (isReturning)
          Container(color: Colors.white)
        else
          Image.asset(
            AssetPaths.backgroundParkSun,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

        // Returning users skip straight to language choice
        if (isReturning)
          _buildLanguageChoice(context, provider)
        else
          _buildStory(context, provider),
      ],
    );
  }

  Widget _buildStory(BuildContext context, WelcomeProvider provider) {
    final currentStep = provider.currentStep;
    final isPeroStep = currentStep?.speakerName == 'Pero';

    return GestureDetector(
      onTap: () => provider.nextStep(),
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            children: [
              const Spacer(),
              if (currentStep != null && !isPeroStep)
                CharacterSpeaker(
                  characterImagePath: currentStep.characterImagePath,
                  dialogue: _localizer.translate(currentStep.dialogueKey),
                  characterOnLeft: true,
                  characterHeight: AppSizes.characterHeightWelcome,
                ),
              if (currentStep != null && isPeroStep)
                PeroSpeaker(
                  key: ValueKey(provider.currentStepIndex),
                  characterHeight: AppSizes.characterHeightWelcome,
                ),
              const SizedBox(height: AppSizes.spacingMedium),
              Text(
                _localizer.translate('welcome.tap_continue'),
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeBody,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSizes.spacingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  provider.totalSteps,
                  (index) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= provider.currentStepIndex
                          ? AppColors.abiPink
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChoice(BuildContext context, WelcomeProvider provider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          children: [
            // Logo — centred vertically in the space above the buttons.
            const Expanded(
              child: Center(
                child: _AnimatedLogo(),
              ),
            ),

            // Welsh / English buttons, pulsing one at a time
            _PulsingLanguageButtons(
              onWelshTap: () =>
                  _navigateTo(context, provider, AppRoutes.welshHome),
              onEnglishTap: () => _navigateTo(context, provider, AppRoutes.home),
            ),
            const SizedBox(height: 20),

            // Privacy / grown-up button
            _PressAndHoldButton(
              onLongPress: () =>
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateTo(
    BuildContext context,
    WelcomeProvider provider,
    String route,
  ) async {
    if (_isNavigating) return;
    _isNavigating = true;
    final navigator = Navigator.of(context);
    await provider.markIntroAsSeen();
    if (!mounted) return;
    navigator.pushReplacementNamed(route);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Single, unmuted playback of the animated Catrin & Abi logo, filling the
/// available space up to a 16:9 box.
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset(AssetPaths.logoAnimated);
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      await controller.setLooping(false);
      await controller.setVolume(1);
      setState(() => _controller = controller);
      controller.play();
    } catch (_) {
      // Video not available — the space stays empty rather than erroring.
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // Clip to a box slightly shorter than 16:9 and cover-fit the video
    // within it — plain 16:9 left a sliver of the source file's black
    // letterbox bars visible top and bottom, so the box crops a bit more.
    return ClipRect(
      child: AspectRatio(
        aspectRatio: 16 / 8.9,
        child: controller != null && controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Wraps the Welsh/English buttons, pulsing one at a time — 10% bigger and
/// brighter — with a 6 second delay between pulses, looping forever.
class _PulsingLanguageButtons extends StatefulWidget {
  final VoidCallback onWelshTap;
  final VoidCallback onEnglishTap;

  const _PulsingLanguageButtons({
    required this.onWelshTap,
    required this.onEnglishTap,
  });

  @override
  State<_PulsingLanguageButtons> createState() =>
      _PulsingLanguageButtonsState();
}

class _PulsingLanguageButtonsState extends State<_PulsingLanguageButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  int _activeIndex = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _runSequence();
  }

  // 6 second delay, then Cymraeg pulses, then English pulses, looping.
  Future<void> _runSequence() async {
    while (!_disposed) {
      await Future.delayed(const Duration(seconds: 6));
      if (_disposed) return;

      setState(() => _activeIndex = 0);
      await _controller.forward(from: 0);
      if (_disposed) return;

      await Future.delayed(const Duration(milliseconds: 450));
      if (_disposed) return;

      setState(() => _activeIndex = 1);
      await _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Column(
          children: [
            _LanguageButton(
              label: 'Cymraeg',
              sublabel: 'Gemau Cymraeg',
              color: AppColors.abiPink,
              onTap: widget.onWelshTap,
              scale: _activeIndex == 0 ? 1 + 0.02 * _pulse.value : 1.0,
              brighten: _activeIndex == 0 ? _pulse.value : 0.0,
            ),
            const SizedBox(height: 20),
            _LanguageButton(
              label: 'English',
              sublabel: 'English Games',
              color: AppColors.accentNavyBlue,
              onTap: widget.onEnglishTap,
              scale: _activeIndex == 1 ? 1 + 0.02 * _pulse.value : 1.0,
              brighten: _activeIndex == 1 ? _pulse.value : 0.0,
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LanguageButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  final double scale;
  final double brighten;

  const _LanguageButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    this.scale = 1.0,
    this.brighten = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = Color.lerp(color, Colors.white, brighten * 0.3)!;
    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PressAndHoldButton extends StatelessWidget {
  final VoidCallback onLongPress;
  const _PressAndHoldButton({required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.5),
          border: Border.all(color: const Color(0xFF1A237E), width: 2),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Grown ups\nPress and hold',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
      ),
    );
  }
}
