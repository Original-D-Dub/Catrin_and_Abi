import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../providers/more_or_less_provider.dart';

class MoreOrLessScreen extends StatefulWidget {
  const MoreOrLessScreen({super.key});

  @override
  State<MoreOrLessScreen> createState() => _MoreOrLessScreenState();
}

class _MoreOrLessScreenState extends State<MoreOrLessScreen> {
  bool _locked = false;

  void _onAnswerTapped(bool isYes, MoreOrLessProvider provider) {
    if (_locked || provider.state == MolGameState.won) return;
    setState(() => _locked = true);

    final isCorrect = provider.selectAnswer(isYes);
    if (isCorrect) {
      AudioService.playCorrect('more_or_less');
    } else {
      AudioService.playWrong('more_or_less');
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      provider.advance();
      setState(() => _locked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: 'en');
    return Consumer<MoreOrLessProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: 'More or Less',
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
                      ? _buildLevelSelect(context, provider, localizer)
                      : _buildGame(context, provider),
                ),
                if (!provider.showLevelSelect &&
                    provider.state == MolGameState.won)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'more_or_less',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () =>
                          provider.startGame(provider.levelNumber - 1),
                      onNextLevel: provider.levelNumber < molLevels.length
                          ? () => provider.startGame(provider.levelNumber)
                          : null,
                      onChangeLevel: () => provider.showLevelSelection(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelSelect(
      BuildContext context, MoreOrLessProvider provider, AppLocalizations localizer) {
    return LevelSelectScreen(
      subtitle: localizer('more_or_less.subtitle'),
      levels: List.generate(molLevels.length, (i) {
        final level = molLevels[i];
        return LevelSelectItem(
          number: level.number,
          name: localizer(level.name),
          color: levelColor(i),
          onTap: () {
            provider.startGame(i);
            AudioService.playIntro('more_or_less');
          },
        );
      }),
    );
  }

  Widget _buildGame(BuildContext context, MoreOrLessProvider provider) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return Column(
          children: [
            const SizedBox(height: 8),

            GameHeaderBar(
              onBack: () => provider.showLevelSelection(),
              scoreValue: '${provider.score}',
              levelNumber: provider.levelNumber,
              centerContent: Center(
                child: Text(
                  'Round ${provider.roundNumber} of ${MoreOrLessProvider.totalRounds}',
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: isLandscape ? 8 : 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge),
                child: _styledContainer(
                  child: _buildQuestion(context, provider),
                ),
              ),
            ),

            SizedBox(height: isLandscape ? 8 : 16),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
              child: isLandscape
                  ? Row(
                      children: [
                        Expanded(
                          child: _YesNoButton(
                            label: 'YES',
                            disabled: _locked,
                            onTap: () => _onAnswerTapped(true, provider),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingSmall),
                        Expanded(
                          child: _YesNoButton(
                            label: 'NO',
                            disabled: _locked,
                            onTap: () => _onAnswerTapped(false, provider),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _YesNoButton(
                          label: 'YES',
                          disabled: _locked,
                          onTap: () => _onAnswerTapped(true, provider),
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),
                        _YesNoButton(
                          label: 'NO',
                          disabled: _locked,
                          onTap: () => _onAnswerTapped(false, provider),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: isLandscape ? 8 : AppSizes.spacingLarge),
          ],
        );
      },
    );
  }

  Widget _buildQuestion(BuildContext context, MoreOrLessProvider provider) {
    final scale = MediaQuery.of(context).size.width >= 600 ? 2.0 : 1.0;
    final symbolSize = 72.0 * scale;
    final questionWord = provider.isHigherQuestion ? 'more' : 'less';

    final textStyle = TextStyle(
      fontFamily: 'ComicRelief',
      fontSize: AppSizes.fontSizeLarge * scale,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8 * scale,
        runSpacing: 8 * scale,
        children: [
          Text('Is', style: textStyle),
          SvgPicture.asset(
            AssetPaths.bslNumber(provider.firstNumber),
            width: symbolSize,
            height: symbolSize,
            fit: BoxFit.contain,
          ),
          Text('$questionWord than', style: textStyle),
          SvgPicture.asset(
            AssetPaths.bslNumber(provider.secondNumber),
            width: symbolSize,
            height: symbolSize,
            fit: BoxFit.contain,
          ),
          Text('?', style: textStyle),
        ],
      ),
    );
  }

  Widget _styledContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.headerBackgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.headerBorderDark, width: 2),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.accentWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.headerBorderDark, width: 2),
        ),
        child: Center(child: child),
      ),
    );
  }
}


class _YesNoButton extends StatelessWidget {
  final String label;
  final bool disabled;
  final VoidCallback onTap;

  const _YesNoButton({
    required this.label,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.headerBackgroundLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.headerBorderDark, width: 2),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.headerBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.headerBorderDark, width: 2),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentWhite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
