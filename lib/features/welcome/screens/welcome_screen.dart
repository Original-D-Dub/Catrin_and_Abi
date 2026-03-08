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

/// The welcome/introduction screen for first-time users.
///
/// Shows story introduction with Catrin, Abi, and Pero.
/// Returning users are routed directly to home from the splash screen.
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
    if (mounted) {
      setState(() {});
    }
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
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return _buildStoryIntro(context, provider);
          },
        ),
      ),
    );
  }

  /// Builds the story introduction for first-time users.
  ///
  /// Shows full-screen park background, character with speech bubble
  /// just above the tap-to-continue instruction at bottom.
  Widget _buildStoryIntro(BuildContext context, WelcomeProvider provider) {
    final currentStep = provider.currentStep;

    // If story is complete, navigate to home (once only)
    if (provider.isStoryComplete) {
      if (!_isNavigating) {
        _isNavigating = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _completeIntroAndNavigate(provider);
        });
      }
      return const Center(child: CircularProgressIndicator());
    }

    final isPeroStep = currentStep?.speakerName == 'Pero';

    return GestureDetector(
      onTap: () => provider.nextStep(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background
          Image.asset(
            AssetPaths.backgroundParkSun,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Content overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                children: [
                  // Push content to bottom
                  const Spacer(),

                  // Character and speech bubble
                  if (currentStep != null && !isPeroStep)
                    CharacterSpeaker(
                      characterImagePath: currentStep.characterImagePath,
                      dialogue:
                          _localizer.translate(currentStep.dialogueKey),
                      characterOnLeft: true,
                      characterHeight: AppSizes.characterHeightWelcome,
                    ),
                  if (currentStep != null && isPeroStep)
                    PeroSpeaker(
                      key: ValueKey(provider.currentStepIndex),
                      characterHeight: AppSizes.characterHeightWelcome,
                    ),
                  const SizedBox(height: AppSizes.spacingMedium),

                  // Tap to continue instruction
                  Text(
                    _localizer.translate('welcome.tap_continue'),
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeBody,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingSmall),
                  // Progress indicator
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
        ],
      ),
    );
  }

  /// Completes the intro and navigates to home screen.
  Future<void> _completeIntroAndNavigate(
    WelcomeProvider provider,
  ) async {
    await provider.markIntroAsSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }
}
