import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen park background
        Image.asset(
          AssetPaths.backgroundParkSun,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Returning users skip straight to language choice
        if (provider.isStoryComplete || provider.hasSeenIntro)
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
            // Logos row — stays near the top
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AssetPaths.logoEnglishColour,
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Image.asset(
                  AssetPaths.logoWelshColour,
                  height: 64,
                  fit: BoxFit.contain,
                ),
              ],
            ),

            const Spacer(),

            // Welsh button
            _LanguageButton(
              label: 'Cymraeg',
              sublabel: 'Gemau Cymraeg',
              color: AppColors.abiPink,
              onTap: () =>
                  _navigateTo(context, provider, AppRoutes.welshHome),
            ),
            const SizedBox(height: 20),

            // English button
            _LanguageButton(
              label: 'English',
              sublabel: 'English Games',
              color: AppColors.accentNavyBlue,
              onTap: () => _navigateTo(context, provider, AppRoutes.home),
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

class _LanguageButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: color,
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
