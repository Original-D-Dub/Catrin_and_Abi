import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' show Fit;

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/bsl_colour_sign.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_intro_countdown.dart';
import '../../../shared/widgets/game_level_map.dart';
import '../../../shared/widgets/level_transition_overlay.dart';
import '../models/bubble_shooter_models.dart';
import '../providers/bubble_shooter_provider.dart';
import '../services/bubble_shooter_map_prefs.dart';
import '../../sports_collection/models/sport_card.dart';
import '../../sports_collection/providers/sports_collection_provider.dart';
import '../widgets/bubble_board_painter.dart';
import '../widgets/bubble_shooter_background.dart';
import '../widgets/level_complete_modal.dart';
import '../widgets/map_dialogs.dart';

/// Bubble Shooter: aim the cannon and fire coloured bubbles into a hanging
/// cluster. The colour in the cannon is shown by its BSL sign (Rive
/// animation, in the cannon's round body). Three or more touching bubbles of the same
/// colour pop; anything left hanging from nothing falls away; the cluster
/// lowers as it shrinks until the board is clear.
///
/// The colour signs only exist for BSL, so this game varies by UI [locale]
/// only — there's no IAC variant.
class BubbleShooterScreen extends StatefulWidget {
  final String locale;

  const BubbleShooterScreen({super.key, this.locale = 'en'});

  @override
  State<BubbleShooterScreen> createState() => _BubbleShooterScreenState();
}

class _BubbleShooterScreenState extends State<BubbleShooterScreen>
    with
        SingleTickerProviderStateMixin,
        LevelTransitionMixin<BubbleShooterScreen> {
  static const String _gameId = 'bubble_shooter';

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool _showingIntro = false;

  final _mapPrefs = BubbleShooterMapPrefs();
  MapCharacter _character = MapCharacter.abi;
  int _highestCompleted = 0;

  /// The level just finished, when it moved the player on to a new level —
  /// the map then shows the character walking from it to the next one.
  int? _movedFromLevel;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _mapPrefs.character().then((c) {
      if (mounted) setState(() => _character = c);
    });
    _mapPrefs.highestCompleted().then((level) {
      if (mounted) setState(() => _highestCompleted = level);
    });
    final provider = context.read<BubbleShooterProvider>();
    provider.onLevelComplete = (_) => _onLevelComplete(provider.currentLevel.number);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final playerId = context.read<AuthProvider>().userId;
      if (playerId != null) {
        context.read<SportsCollectionProvider>().load(playerId);
      }
    });
  }

  void _onLevelComplete(int level) {
    _mapPrefs.recordCompleted(level);
    if (!mounted) return;
    final levelCount = context.read<BubbleShooterProvider>().levels.length;
    setState(() {
      if (level > _highestCompleted && level < levelCount) {
        _movedFromLevel = level;
      }
      _highestCompleted = max(_highestCompleted, level);
    });
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    context.read<BubbleShooterProvider>().tick(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    AudioService.stopTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);

    return Consumer<BubbleShooterProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('bubble_shooter.title'),
                  onBack: () {
                    provider.stopGame();
                    Navigator.pop(context);
                  },
                )
              : null,
          body: Container(
            // The level map paints its own felt meadow.
            decoration: provider.showLevelSelect
                ? const BoxDecoration(
                    color: BubbleShooterBackground.frontHillColour)
                : const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF7FD4FF),
                        Color(0xFFB9A6FF),
                        Color(0xFFFFA8D9),
                      ],
                    ),
                  ),
            child: Stack(
              children: [
                SafeArea(
                  child: provider.showLevelSelect
                      ? _buildLevelSelect(provider)
                      : _buildGame(provider, localizer),
                ),

                if (_showingIntro)
                  GameIntroCountdown(
                    gameId: _gameId,
                    levelNumber: provider.currentLevel.number,
                    locale: widget.locale,
                    characterImage: 'assets/characters/abi/abi_2025_001.png',
                    topText: localizer('bubble_shooter.intro_heading'),
                    roundedBubble: true,
                    onComplete: () {
                      setState(() => _showingIntro = false);
                      provider.startGame();
                    },
                    onBack: () {
                      setState(() => _showingIntro = false);
                      provider.showLevelSelection();
                    },
                  ),

                if (!provider.showLevelSelect && provider.gameOver)
                  Positioned.fill(
                    child: LevelCompleteModal(
                      score: provider.score,
                      locale: widget.locale,
                      onNext: provider.showLevelSelection,
                      openChest: _chestOpener(provider.currentLevel.number),
                    ),
                  ),

                Positioned.fill(
                  child:
                      LevelTransitionOverlay(opacity: levelTransitionOpacity),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelSelect(BubbleShooterProvider provider) {
    final localizer = AppLocalizations(locale: widget.locale);
    final sports = context.watch<SportsCollectionProvider>();
    final levelCount = provider.levels.length;
    final nextLevel = min(_highestCompleted + 1, levelCount);
    String playLabel(int level) => localizer('bubble_shooter.play_level')
        .replaceAll('{n}', '$level');

    return Stack(
      children: [
        GameLevelMap(
          levelCount: levelCount,
          highestCompleted: _highestCompleted,
          characterThumb: _character.thumbAsset,
          characterLabel: _character.name,
          isChestLevel: BubbleShooterLevels.isChestLevel,
          chestState: (level) {
            if (sports.isChestOpened(BubbleShooterLevels.chestSource(level))) {
              return ChestState.opened;
            }
            return _highestCompleted >= level
                ? ChestState.ready
                : ChestState.locked;
          },
          onLevelSelected: (level) => _startLevel(provider, level),
          onChestTapped: (level) => _onChestTapped(level, localizer),
          onCharacterTapped: () => _chooseCharacter(localizer),
          levelLabel: playLabel,
          movedFromLevel: _movedFromLevel,
          chestLabel: (level) =>
              '${playLabel(level)}, ${localizer('bubble_shooter.chest_title')}',
        ),
        Positioned(
          left: AppSizes.paddingMedium,
          right: AppSizes.paddingMedium,
          bottom: AppSizes.paddingMedium,
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: playLabel(nextLevel),
                  icon: Icons.play_arrow,
                  expanded: true,
                  onPressed: () => _startLevel(provider, nextLevel),
                ),
              ),
              const SizedBox(width: AppSizes.spacingSmall),
              TertiaryButton(
                label: localizer('bubble_shooter.my_sports_cards'),
                icon: Icons.style,
                iconOnly: true,
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.sportsCollection,
                  arguments: widget.locale,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// For a chest level whose chest is still closed (and a player to save
  /// the card for, with cards left to win), opens it; otherwise null, so
  /// the level-complete modal shows no chest.
  Future<SportCard?> Function()? _chestOpener(int level) {
    if (!BubbleShooterLevels.isChestLevel(level)) return null;
    final playerId = context.read<AuthProvider>().userId;
    final sports = context.read<SportsCollectionProvider>();
    final source = BubbleShooterLevels.chestSource(level);
    if (playerId == null ||
        sports.isChestOpened(source) ||
        sports.collected.length == SportCard.values.length) {
      return null;
    }
    return () => sports.openChest(playerId: playerId, source: source);
  }

  void _startLevel(BubbleShooterProvider provider, int level) {
    // The walk has been seen; don't replay it on the next visit to the map.
    _movedFromLevel = null;
    startLevelWithTransition(
      gameId: _gameId,
      levelNumber: level,
      locale: widget.locale,
      startLevel: () {
        provider.setLevel(level);
        provider.prepareForIntro();
        setState(() => _showingIntro = true);
      },
    );
  }

  /// A chest level: once the level is finished and its chest not yet
  /// opened, opens the chest (giving a new sports card); otherwise plays the
  /// level, like any other level.
  Future<void> _onChestTapped(int level, AppLocalizations localizer) async {
    final provider = context.read<BubbleShooterProvider>();
    final sports = context.read<SportsCollectionProvider>();
    final source = BubbleShooterLevels.chestSource(level);
    if (sports.isChestOpened(source) || _highestCompleted < level) {
      _startLevel(provider, level);
      return;
    }
    final playerId = context.read<AuthProvider>().userId;
    if (playerId == null) {
      await showMapMessage(context,
          message: localizer('general.sign_in_to_save_scores'),
          localizer: localizer);
      return;
    }
    final card = await sports.openChest(playerId: playerId, source: source);
    if (!mounted) return;
    if (card == null) {
      await showMapMessage(context,
          message: localizer('bubble_shooter.chest_empty'),
          localizer: localizer);
      return;
    }
    AudioService.playCorrect(_gameId);
    await showChestCardDialog(context,
        card: card,
        heading: localizer('bubble_shooter.chest_won'),
        localizer: localizer);
  }

  Future<void> _chooseCharacter(AppLocalizations localizer) async {
    final chosen = await showCharacterPicker(context,
        current: _character, localizer: localizer);
    if (chosen == null || !mounted) return;
    setState(() => _character = chosen);
    _mapPrefs.setCharacter(chosen);
  }

  Widget _buildGame(BubbleShooterProvider provider, AppLocalizations localizer) {
    return Column(
      children: [
        const SizedBox(height: 8),
        GameHeaderBar(
          onBack: () {
            provider.stopGame();
            provider.showLevelSelection();
          },
          scoreValue: '${provider.score}',
          levelNumber: provider.currentLevel.number,
          centerContent: provider.isSpeedRound
              ? GameTimerDisplay(
                  formattedTime: GameTimerDisplay.format(
                      Duration(seconds: provider.timeRemainingSeconds)),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep the board from getting too wide on landscape tablets,
                // so bubbles don't get huge and rows stay visible.
                final width = constraints.maxWidth
                    .clamp(0.0, constraints.maxHeight / 1.15);
                return Center(
                  child: SizedBox(
                    width: width,
                    height: constraints.maxHeight,
                    child: _buildBoard(provider, localizer, width,
                        constraints.maxHeight),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoard(
    BubbleShooterProvider provider,
    AppLocalizations localizer,
    double outerWidth,
    double outerHeight,
  ) {
    // Two 2px borders + 2px padding around the board on each side.
    const inset = 8.0;
    final width = outerWidth - inset * 2;
    final height = outerHeight - inset * 2;
    final scale = width / BubbleShooterProvider.boardWidth;
    provider.setBoardHeight(height / scale);

    Offset toUnits(Offset local) => local / scale;
    final cannon = provider.cannonPosition;
    const cannonRadius = BubbleShooterProvider.cannonRadius;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.headerBackgroundLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.headerBorderDark, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.headerBorderDark, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              const Positioned.fill(child: BubbleShooterBackground()),
              // Cannon: barrel underneath, then the round body holding the
              // BSL sign, then the board painter (bubbles fly over both).
              Positioned.fill(
                child: CustomPaint(
                  painter:
                      CannonBarrelPainter(provider: provider, scale: scale),
                ),
              ),
              Positioned(
                left: (cannon.dx - cannonRadius) * scale,
                top: (cannon.dy - cannonRadius) * scale,
                width: cannonRadius * 2 * scale,
                height: cannonRadius * 2 * scale,
                child: _CannonSign(
                  colours: provider.currentLevel.colours,
                  loaded: provider.loadedColour,
                  showColourHint: provider.currentLevel.showsColourHint,
                  scale: scale,
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => provider.aimAt(toUnits(d.localPosition)),
                  onPanUpdate: (d) =>
                      provider.aimAt(toUnits(d.localPosition)),
                  onPanEnd: (_) => provider.fire(),
                  onPanCancel: provider.cancelAim,
                  onTapUp: (d) => _onTap(provider, toUnits(d.localPosition)),
                  child: CustomPaint(
                    painter:
                        BubbleBoardPainter(provider: provider, scale: scale),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tapping above the cannon fires straight at that spot. Taps on the
  /// cannon itself, or level with/below it, are ignored.
  void _onTap(BubbleShooterProvider provider, Offset pos) {
    final cannon = provider.cannonPosition;
    if ((pos - cannon).distance < BubbleShooterProvider.cannonRadius ||
        pos.dy > cannon.dy - 1) {
      return;
    }
    provider.aimAt(pos);
    provider.fire();
  }
}

/// The cannon's round body: a rainbow ring around a white disc showing the
/// BSL sign for the loaded colour. When [showColourHint] is set the disc is
/// edged in the loaded colour; otherwise there's no edge and the rainbow
/// ring is wider instead.
///
/// The sign covers the whole white disc and is cropped to its circle.
/// The bottom of the body is clipped by the board frame, level with
/// [BubbleShooterProvider.cannonOffsetFromBottom] below the centre. One
/// [BslColourSign] is kept mounted
/// per level colour (in an [IndexedStack]) so switching colours doesn't
/// reload the .riv file.
class _CannonSign extends StatelessWidget {
  const _CannonSign({
    required this.colours,
    required this.loaded,
    required this.showColourHint,
    required this.scale,
  });

  final List<BubbleColour> colours;
  final BubbleColour? loaded;
  final bool showColourHint;
  final double scale;

  /// Width of the rainbow ring, and of the coloured edge inside it (units).
  static const double _ringWidth = 0.35;
  static const double _edgeWidth = 0.22;

  @override
  Widget build(BuildContext context) {
    final current = loaded ?? colours.first;
    final index = colours.indexOf(current).clamp(0, colours.length - 1);
    final tones = bubbleTones(current);

    return Container(
      // Without the coloured edge, the rainbow ring takes up its width, so
      // the white disc and sign stay the same size.
      padding: EdgeInsets.all(
          (showColourHint ? _ringWidth : _ringWidth + _edgeWidth) * scale),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [...BubbleBoardPainter.rainbow, Color(0xFFFF3B3B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 0.4 * scale,
            offset: Offset(0, 0.15 * scale),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: showColourHint
              ? Border.all(
                  color: current == BubbleColour.white
                      ? AppColors.headerBorderDark
                      : tones.base,
                  width: _edgeWidth * scale,
                )
              : null,
        ),
        // The sign fills the whole disc; the circle crops whatever overflows.
        child: ClipOval(
          child: IndexedStack(
            index: index,
            sizing: StackFit.expand,
            children: [
              for (final colour in colours)
                BslColourSign(
                  key: ValueKey(colour),
                  colourName: colour.name,
                  active: colour == current,
                  replayInterval: const Duration(seconds: 4),
                  fit: Fit.cover,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
