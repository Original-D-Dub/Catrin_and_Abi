import 'dart:async';
import 'dart:math';

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
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/game_level_map.dart';
import '../../bubble_shooter/services/bubble_shooter_map_prefs.dart';
import '../../bubble_shooter/widgets/map_dialogs.dart';
import '../providers/more_or_less_provider.dart';
import '../services/more_or_less_map_prefs.dart';
import '../widgets/symbol_card.dart';

class MoreOrLessScreen extends StatefulWidget {
  final String locale;

  const MoreOrLessScreen({super.key, this.locale = 'en'});

  @override
  State<MoreOrLessScreen> createState() => _MoreOrLessScreenState();
}

class _MoreOrLessScreenState extends State<MoreOrLessScreen> {
  /// Felt meadow green behind the level map, matching [GameLevelMap].
  static const Color _meadowGreen = Color(0xFF65A94F);

  /// Level whose BSL signs include teen numbers (11-19), so it retriggers
  /// the Rive teen-number animations periodically as a hint.
  static const int _hintLevelNumber = 13;
  static const Duration _hintInterval = Duration(seconds: 3);

  bool _locked = false;
  final ValueNotifier<int> _hintCounter = ValueNotifier(0);
  Timer? _hintTimer;

  final _mapPrefs = MoreOrLessMapPrefs();
  MapCharacter _character = MapCharacter.abi;

  /// Highest level finished, as on Bubble Shooter's map: levels up to it
  /// show as done, the character stands on the next one and later levels
  /// are locked.
  int _highestCompleted = 0;

  /// The level just finished, when it moved the player on to a new level —
  /// the map then shows the character walking from it to the next one.
  int? _movedFromLevel;

  /// Chest levels whose chest this player has already opened.
  Set<int> _openedChests = {};

  @override
  void initState() {
    super.initState();
    _mapPrefs.character().then((c) {
      if (mounted) setState(() => _character = c);
    });
    _mapPrefs.highestCompleted().then((level) {
      if (!mounted) return;
      setState(() => _highestCompleted = max(_highestCompleted, level));
    });
    _mapPrefs.openedChests().then((opened) {
      if (!mounted) return;
      setState(() => _openedChests = {..._openedChests, ...opened});
    });
    context.read<MoreOrLessProvider>().onLevelFinished = _onLevelFinished;
  }

  /// Finishing a level unlocks the next one. Finishing a level past the
  /// furthest one so far sets up the walk to the next.
  void _onLevelFinished(int level) {
    _mapPrefs.recordCompleted(level);
    if (!mounted) return;
    setState(() {
      if (level > _highestCompleted && level < molLevels.length) {
        _movedFromLevel = level;
      }
      _highestCompleted = max(_highestCompleted, level);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hintCounter.dispose();
    super.dispose();
  }

  /// Keeps the periodic hint timer running only while playing level 13.
  void _syncHintTimer(MoreOrLessProvider provider) {
    final shouldRun =
        !provider.showLevelSelect &&
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
            // The level map paints its own felt meadow.
            decoration: provider.showLevelSelect
                ? const BoxDecoration(color: _meadowGreen)
                : const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/backgrounds/felt-background.jpg',
                      ),
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
                          _startLevel(provider, provider.levelNumber),
                      // Back to the level map, where the character walks
                      // on to the next level (see _onLevelFinished).
                      onNextLevel: provider.levelNumber < molLevels.length
                          ? provider.showLevelSelection
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
    BuildContext context,
    MoreOrLessProvider provider,
    AppLocalizations localizer,
  ) {
    final nextLevel = min(_highestCompleted + 1, molLevels.length);
    String playLabel(int level) =>
        localizer('more_or_less.play_level').replaceAll('{n}', '$level');
    String levelLabel(int level) =>
        '${playLabel(level)}: ${localizer(molLevels[level - 1].name)}';

    // The map is split into three patches of meadow — "more than" (1–4),
    // "less than" (5–8) and mixed (9–13) — each signposted between its
    // second and third levels.
    // The timed levels (4, 8 and 12) are treasure chests. Finishing one
    // makes its chest ready; opening it wins that level's symbol card.
    return Stack(
      children: [
        GameLevelMap(
          levelCount: molLevels.length,
          highestCompleted: _highestCompleted,
          characterThumb: _character.thumbAsset,
          characterLabel: _character.name,
          isChestLevel: SymbolCard.isChestLevel,
          chestState: _chestState,
          onLevelSelected: (level) => _startLevel(provider, level),
          onChestTapped: (level) => _onChestTapped(provider, level, localizer),
          onCharacterTapped: () => _chooseCharacter(localizer),
          levelLabel: levelLabel,
          movedFromLevel: _movedFromLevel,
          chestLabel: (level) =>
              '${levelLabel(level)}, ${localizer('bubble_shooter.chest_title')}',
          sections: [
            MapSection(
              firstLevel: 1,
              lastLevel: 4,
              grassColour: const Color(0xFF65A94F),
              label: localizer('more_or_less.section.more_than'),
            ),
            MapSection(
              firstLevel: 5,
              lastLevel: 8,
              grassColour: const Color(0xFF3F8E6A),
              groundPattern: MapGroundPattern.mownStripes,
              label: localizer('more_or_less.section.less_than'),
            ),
            MapSection(
              firstLevel: 9,
              lastLevel: 13,
              grassColour: const Color(0xFF9DB843),
              groundPattern: MapGroundPattern.flowers,
              label: localizer('more_or_less.section.mixed'),
            ),
          ],
        ),
        Positioned(
          left: AppSizes.paddingMedium,
          right: AppSizes.paddingMedium,
          bottom: AppSizes.paddingMedium,
          child: PrimaryButton(
            label: playLabel(nextLevel),
            icon: Icons.play_arrow,
            expanded: true,
            onPressed: () => _startLevel(provider, nextLevel),
          ),
        ),
      ],
    );
  }

  ChestState _chestState(int level) {
    if (_openedChests.contains(level)) return ChestState.opened;
    return _highestCompleted >= level ? ChestState.ready : ChestState.locked;
  }

  void _startLevel(MoreOrLessProvider provider, int level) {
    // The walk has been seen; don't replay it on the next visit to the map.
    _movedFromLevel = null;
    provider.startGame(level - 1);
    AudioService.playIntro('more_or_less');
  }

  /// A chest level: once the level is finished and its chest not yet
  /// opened, opens the chest and awards that level's symbol card;
  /// otherwise plays the level, like any other level.
  Future<void> _onChestTapped(
    MoreOrLessProvider provider,
    int level,
    AppLocalizations localizer,
  ) async {
    final card = SymbolCard.forLevel(level);
    if (card == null || _chestState(level) != ChestState.ready) {
      _startLevel(provider, level);
      return;
    }
    setState(() => _openedChests = {..._openedChests, level});
    _mapPrefs.recordChestOpened(level);
    AudioService.playCorrect('more_or_less');
    await showSymbolCardWon(context, card: card, localizer: localizer);
  }

  Future<void> _chooseCharacter(AppLocalizations localizer) async {
    final chosen = await showCharacterPicker(
      context,
      current: _character,
      localizer: localizer,
    );
    if (chosen == null || !mounted) return;
    setState(() => _character = chosen);
    _mapPrefs.setCharacter(chosen);
  }

  Widget _buildGame(
    BuildContext context,
    MoreOrLessProvider provider,
    AppLocalizations localizer,
  ) {
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
                child: provider.currentLevel.isTimed
                    ? GameTimerDisplay(
                        formattedTime: GameTimerDisplay.format(
                          Duration(seconds: provider.secondsLeft),
                        ),
                      )
                    : Text(
                        '${localizer('more_or_less.round_label')} ${provider.roundNumber} '
                        '${localizer('more_or_less.of_label')} ${provider.totalRounds}',
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            SizedBox(height: isLandscape ? 8 : 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLarge,
                ),
                child: _styledContainer(
                  child: _buildQuestion(context, provider, localizer),
                ),
              ),
            ),

            SizedBox(height: isLandscape ? 8 : 16),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
              ),
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

  Widget _buildQuestion(
    BuildContext context,
    MoreOrLessProvider provider,
    AppLocalizations localizer,
  ) {
    final scale = MediaQuery.of(context).size.width >= 600 ? 2.0 : 1.0;
    final symbolSize = 72.0 * scale;
    final questionWordKey = provider.isHigherQuestion
        ? 'more_or_less.more_than'
        : 'more_or_less.less_than';

    final textStyle = TextStyle(
      fontFamily: 'Quicksand',
      fontSize: AppSizes.fontSizeLarge * scale,
      fontWeight: FontWeight.w600,
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
                  fontFamily: 'Quicksand',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
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
