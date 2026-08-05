import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/services/audio_service.dart';
import '../../bsl_maths/widgets/bsl_number_display.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../providers/more_or_less_provider.dart';

class MoreOrLessScreen extends StatefulWidget {
  final String locale;

  const MoreOrLessScreen({super.key, this.locale = 'en'});

  @override
  State<MoreOrLessScreen> createState() => _MoreOrLessScreenState();
}

class _MoreOrLessScreenState extends State<MoreOrLessScreen> {
  /// Level whose BSL signs include teen numbers (11-19), so it retriggers
  /// the Rive teen-number animations periodically as a hint.
  static const int _hintLevelNumber = 4;
  static const Duration _hintInterval = Duration(seconds: 3);

  bool _locked = false;
  final ValueNotifier<int> _hintCounter = ValueNotifier(0);
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    AudioService.playTitle('more_or_less', locale: widget.locale);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hintCounter.dispose();
    super.dispose();
  }

  /// Keeps the periodic hint timer running only while playing level 4.
  void _syncHintTimer(MoreOrLessProvider provider) {
    final shouldRun = !provider.showLevelSelect &&
        provider.levelNumber == _hintLevelNumber &&
        provider.state == MolGameState.playing;
    if (shouldRun) {
      _hintTimer ??= Timer.periodic(_hintInterval, (_) => _hintCounter.value++);
    } else {
      _hintTimer?.cancel();
      _hintTimer = null;
    }
  }

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
    final localizer = AppLocalizations(locale: widget.locale);
    return Consumer<MoreOrLessProvider>(
      builder: (context, provider, _) {
        _syncHintTimer(provider);
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('more_or_less.title'),
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
                      : _buildGame(context, provider, localizer),
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
      locale: localizer.locale,
      levels: [
        for (var i = 0; i < molLevels.length; i++)
          if (molLevels[i].number != 5)
            LevelSelectItem(
              number: molLevels[i].number,
              name: localizer(molLevels[i].name),
              color: levelColor(i),
              onTap: () {
                provider.startGame(i);
                AudioService.playIntro('more_or_less');
              },
            ),
      ],
    );
  }

  Widget _buildGame(BuildContext context, MoreOrLessProvider provider,
      AppLocalizations localizer) {
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
                  '${localizer('more_or_less.round_label')} ${provider.roundNumber} '
                  '${localizer('more_or_less.of_label')} ${MoreOrLessProvider.totalRounds}',
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
                  child: _buildQuestion(context, provider, localizer),
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
                            label: localizer('more_or_less.yes'),
                            disabled: _locked,
                            onTap: () => _onAnswerTapped(true, provider),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingSmall),
                        Expanded(
                          child: _YesNoButton(
                            label: localizer('more_or_less.no'),
                            disabled: _locked,
                            onTap: () => _onAnswerTapped(false, provider),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _YesNoButton(
                          label: localizer('more_or_less.yes'),
                          disabled: _locked,
                          onTap: () => _onAnswerTapped(true, provider),
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),
                        _YesNoButton(
                          label: localizer('more_or_less.no'),
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

  Widget _buildQuestion(BuildContext context, MoreOrLessProvider provider,
      AppLocalizations localizer) {
    final scale = MediaQuery.of(context).size.width >= 600 ? 2.0 : 1.0;
    final symbolSize = 72.0 * scale;
    final questionWordKey = provider.isHigherQuestion
        ? 'more_or_less.more_than'
        : 'more_or_less.less_than';

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
          Text(localizer('more_or_less.is_label'), style: textStyle),
          BslNumberDisplay(
            number: provider.firstNumber,
            size: symbolSize,
            hintCounter: _hintCounter,
          ),
          Text(localizer(questionWordKey), style: textStyle),
          BslNumberDisplay(
            number: provider.secondNumber,
            size: symbolSize,
            hintCounter: _hintCounter,
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
