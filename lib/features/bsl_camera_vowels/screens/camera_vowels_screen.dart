import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../core/constants/asset_paths.dart';
import '../providers/camera_vowels_provider.dart';
import '../widgets/finger_cursor_overlay.dart';
import '../widgets/fingertip_highlight.dart';
import '../widgets/hand_guide_display.dart';

/// Main screen for the BSL Camera Vowels game.
///
/// The front camera runs invisibly to track the player's hands using
/// MediaPipe's 21-point hand skeleton. The player physically touches
/// their left hand's fingertips with their right index finger; the app
/// detects the contact and speaks the corresponding BSL vowel (a/e/i/o/u).
///
/// Level 1 – Practice: all fingertips active, TTS fires on any touch.
/// Level 2 – Challenge: a target vowel is shown; only the matching
///   fingertip scores a point.
class CameraVowelsScreen extends StatefulWidget {
  const CameraVowelsScreen({super.key});

  @override
  State<CameraVowelsScreen> createState() => _CameraVowelsScreenState();
}

class _CameraVowelsScreenState extends State<CameraVowelsScreen> {
  bool _showingIntro = false;

  @override
  void dispose() {
    AudioService.stopTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraVowelsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: 'Camera Vowels',
                  onBack: () => Navigator.of(context).pop(),
                )
              : null,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/backgrounds/math-background-1080x1920.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: provider.showLevelSelect
                      ? _buildLevelSelect(context, provider)
                      : _buildGame(context, provider),
                ),
                // Intro countdown — outside SafeArea, covers full screen
                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: 'camera_vowels',
                    onComplete: () =>
                        setState(() => _showingIntro = false),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Level select ───────────────────────────────────────────────────────────

  Widget _buildLevelSelect(
      BuildContext context, CameraVowelsProvider provider) {
    return LevelSelectScreen(
      levels: CameraVowelsLevel.all.map((level) {
        return LevelSelectItem(
          number: level.number,
          name: level.name,
          color: levelColor(level.number - 1),
          onTap: () {
            provider.selectLevel(level.number);
            setState(() => _showingIntro = true);
          },
        );
      }).toList(),
    );
  }

  // ── Game screen ────────────────────────────────────────────────────────────

  Widget _buildGame(BuildContext context, CameraVowelsProvider provider) {
    if (provider.gameState == CameraVowelsGameState.permissionDenied) {
      return _buildPermissionDenied(context, provider);
    }

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            GameHeaderBar(
              onBack: () => provider.showLevelSelection(),
              scoreValue: '${provider.score}',
              levelNumber: provider.currentLevel.number,
              centerContent: provider.currentLevel.name.isNotEmpty
                  ? Center(
                      child: Text(
                        provider.currentLevel.name,
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildGameArea(provider)),
            if (provider.currentLevel.number == 2 &&
                provider.targetVowel != null)
              _buildTargetVowelBanner(provider.targetVowel!),
            const SizedBox(height: AppSizes.spacingMedium),
          ],
        ),

      ],
    );
  }

  Widget _buildGameArea(CameraVowelsProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            // Left-hand guide (SVG or Rive)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium),
                child: HandGuideDisplay(
                  rivFilePath: AssetPaths.handPalmRiv,
                  activeFingertipIndex: provider.activeFingertipIndex,
                  wrongFingertipIndex: provider.wrongFingertipIndex,
                ),
              ),
            ),

            // Fingertip highlight rings
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium),
                child: FingertipHighlight(
                  handDisplaySize: size,
                  activeFingertipIndex: provider.activeFingertipIndex,
                  wrongFingertipIndex: provider.wrongFingertipIndex,
                ),
              ),
            ),

            // Right-hand index finger cursor
            FingerCursorOverlay(
              containerSize: size,
              cursorPosition: provider.cursorPosition,
              rivFilePath: AssetPaths.pointerRiv,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTargetVowelBanner(String vowel) {
    final vowelColors = <String, Color>{
      'a': AppColors.accentRed,
      'e': AppColors.accentNavyBlue,
      'i': AppColors.accentLimeGreen,
      'o': AppColors.accentOrange,
      'u': AppColors.accentPurple,
    };
    final color = vowelColors[vowel] ?? AppColors.catrinBlue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLarge,
        vertical: AppSizes.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Touch: ',
            style: TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            vowel.toUpperCase(),
            style: TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: AppSizes.fontSizeTitle,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(
      BuildContext context, CameraVowelsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.spacingMedium),
            const Text(
              'Camera permission is needed to track your hands.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: AppSizes.fontSizeLarge,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            ElevatedButton(
              onPressed: () => provider.showLevelSelection(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

}
