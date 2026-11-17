import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/falling_confetti_layer.dart';
import '../../../shared/widgets/paper_texture_overlay.dart';
import '../../../shared/widgets/sign_in_banner_button.dart';
import '../models/animal_model.dart';
import '../providers/bingo_collection_provider.dart';
import '../services/celebration_audio.dart';
import 'animal_card.dart';

/// Background of the BINGO celebration overlay. Shared with the animal
/// collection screen's pop-up so both overlays match.
final RadialGradient bingoOverlayGradient = RadialGradient(
  colors: [
    const Color(0xFF94E0FF).withValues(alpha: 0.88),
    const Color(0xFF00A8F3).withValues(alpha: 0.88),
  ],
);

/// Combined BINGO celebration screen.
///
/// Layout (top → bottom):
/// 1. Pulsing BINGO text — letters pop in one by one — with falling
///    confetti.
/// 2. Animal reward section (logged-in users only) — heading and card,
///    with an AbiPink "Tap to see your collection" roundel overlapping its
///    top-right corner — slides in after a short delay. Tapping the card
///    replays the animal's recorded name.
/// 3. "Play Again" button, full width.
/// 4. "Next Level" button, full width (when there is one).
///
/// In landscape the screen is fitted, not scrolled, so the buttons are
/// always visible: a smaller BINGO above the friend message, that text
/// block side by side with the card (which scales to fit), then Play Again
/// and Next Level side by side.
///
/// A fixed back arrow in the top-left corner — same treatment as the
/// shared success overlay's header arrow — triggers [onChangeLevel] to
/// leave the round.
///
/// A tap anywhere on the background fast-forwards to the finished state
/// (audio stopped, animations completed, buttons revealed) for repeat
/// plays. Ambient and entry animations are toned down when the OS
/// "reduce motion" accessibility setting is enabled.
class BingoCelebration extends StatefulWidget {
  final VoidCallback onPlayAgain;
  final VoidCallback onChangeLevel;

  /// Called when the player chooses to open their animal collection.
  /// Navigation stays with the owning screen so this widget isn't coupled
  /// to a specific route.
  final VoidCallback onSeeCollection;

  /// When non-null, shows a "Next Level" button — advances to the next
  /// letter_bingo level in normal play, or the next "Learn BSL trail" node
  /// when launched from the trail. Null hides the button (e.g. on the last
  /// level).
  final VoidCallback? onNextLevel;

  /// When non-null, shows a "Check" button (multiplayer player card) that
  /// closes the overlay so the marked letters can be checked against the
  /// caller's called-letters list.
  final VoidCallback? onCheck;

  /// Non-null only for logged-in users who earned a reward animal this round.
  final Animal? animal;
  final String? playerId;
  final int levelNumber;

  /// UI locale ('en' or 'cy') — selects which recorded celebration clips play.
  final String locale;

  /// Sign system this round was played in — selects which reward inventory
  /// table the earned animal is additionally recorded to (IAC only), via
  /// [bingoCollection].
  final SignSystem signSystem;

  /// Shared reward cache/persistence. Defaults to reading the app-wide
  /// [BingoCollectionProvider]; override in widget tests.
  final BingoCollectionProvider? bingoCollection;

  /// Audio playback seam. Defaults to real playback; override in tests.
  final CelebrationAudio audio;

  const BingoCelebration({
    super.key,
    required this.onPlayAgain,
    required this.onChangeLevel,
    required this.onSeeCollection,
    this.onNextLevel,
    this.onCheck,
    this.animal,
    this.playerId,
    required this.levelNumber,
    this.locale = 'en',
    this.signSystem = SignSystem.bsl,
    this.bingoCollection,
    this.audio = const CelebrationAudio(),
  });

  @override
  State<BingoCelebration> createState() => _BingoCelebrationState();
}

class _BingoCelebrationState extends State<BingoCelebration>
    with TickerProviderStateMixin {
  // ── Timing constants ───────────────────────────────────────────────────────
  static const _pulseDuration = Duration(milliseconds: 700);
  static const _bingoIntroDuration = Duration(milliseconds: 1200);
  static const _cardEntranceDuration = Duration(milliseconds: 600);
  static const _cardEntranceDelay = Duration(milliseconds: 400);
  static const _newnessFadeDuration = Duration(milliseconds: 300);
  static const _friendClipGap = Duration(milliseconds: 300);
  static const _buttonsRevealDelay = Duration(milliseconds: 700);
  static const _buttonsBaseDelay = Duration(milliseconds: 500);

  /// Pause after the spoken sequence finishes before the card pulses again,
  /// to draw attention back to the new friend.
  static const _attentionPulseDelay = Duration(seconds: 6);

  // BINGO pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // BINGO letter pop-in
  late final AnimationController _bingoIntroCtrl;

  // Animal card entry
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  // Animal card pulse — plays twice once the audio sequence finishes
  late final AnimationController _cardPulseCtrl;
  late final Animation<double> _cardPulseAnim;

  // Button fade-in
  late final AnimationController _buttonCtrl;
  late final Animation<double> _buttonFade;

  late final BingoCollectionProvider _bingoCollection =
      widget.bingoCollection ?? context.read<BingoCollectionProvider>();

  /// Resolves once the newness check finishes (true on error). The spoken
  /// sequence and the reward save both wait on it, so the save can't race
  /// ahead of the fetch that decides "new friend" vs "friend", and the
  /// correct greeting clip always plays.
  final Completer<bool> _newness = Completer<bool>();
  bool? _isNew;
  bool _saved = false;

  /// Bumped to cancel the pending card/button reveal chain (tap-to-skip).
  int _uiGen = 0;

  /// Bumped to cancel the spoken sequence (tap-to-skip, name replay).
  int _audioGen = 0;

  /// Mirrors `MediaQuery.disableAnimations` — set in
  /// [didChangeDependencies], so it is valid by the time any delayed
  /// sequence step runs.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: _pulseDuration)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _bingoIntroCtrl = AnimationController(
      vsync: this,
      duration: _bingoIntroDuration,
    )..forward();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: _cardEntranceDuration,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn));

    _cardPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardPulseAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_cardPulseCtrl);

    _buttonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(_buttonCtrl);

    widget.audio.hapticSuccess();
    unawaited(_checkIfNew());
    unawaited(_playAudioSequence());
    unawaited(_revealSequence());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    _reduceMotion = reduce;
    if (reduce) {
      if (_pulseCtrl.isAnimating) _pulseCtrl.stop();
      _pulseCtrl.value = 0;
      if (!_bingoIntroCtrl.isCompleted) _bingoIntroCtrl.value = 1;
    } else {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    }
  }

  /// Slides the reward card in, saves it, then reveals the buttons.
  Future<void> _revealSequence() async {
    final gen = ++_uiGen;
    // Short pause so the BINGO text registers before the card slides in.
    await Future.delayed(_cardEntranceDelay);
    if (!mounted || gen != _uiGen) return;

    if (widget.animal != null) {
      if (_reduceMotion) {
        _entryCtrl.value = 1;
      } else {
        await _entryCtrl.forward();
      }
      if (!mounted || gen != _uiGen) return;
      unawaited(_saveReward());
      await Future.delayed(_buttonsRevealDelay);
    } else {
      await Future.delayed(_buttonsBaseDelay);
    }
    if (!mounted || gen != _uiGen) return;

    if (_reduceMotion) {
      _buttonCtrl.value = 1;
    } else {
      unawaited(_buttonCtrl.forward());
    }
  }

  /// Spoken sequence: "Bingo!" → friend greeting → animal name, then the
  /// card pulses now and again after [_attentionPulseDelay] to draw the
  /// eye back. Each step bails if the widget is gone or a generation bump
  /// (skip / replay) superseded the sequence.
  Future<void> _playAudioSequence() async {
    final gen = ++_audioGen;
    await widget.audio.playBingo(locale: widget.locale);
    if (!mounted || gen != _audioGen || widget.animal == null) return;
    await Future.delayed(_friendClipGap);
    if (!mounted || gen != _audioGen) return;
    // Wait for the newness check so the greeting always matches what the
    // heading says (previously the clip was chosen before the check
    // resolved, so new animals often heard the "already a friend" line).
    final isNew = await _newness.future;
    if (!mounted || gen != _audioGen) return;
    await widget.audio.playFriendGreeting(isNew: isNew, locale: widget.locale);
    if (!mounted || gen != _audioGen) return;
    await widget.audio.playAnimalName(widget.animal!.letter);
    if (!mounted || gen != _audioGen) return;
    _pulseCard();
    await Future.delayed(_attentionPulseDelay);
    if (!mounted || gen != _audioGen || _reduceMotion) return;
    _pulseCard();
  }

  void _pulseCard() {
    if (_reduceMotion) return;
    unawaited(_cardPulseCtrl.forward(from: 0));
  }

  /// Saves the reward animal exactly once. Waits for the newness check to
  /// resolve first so the insert can't race ahead of the fetch that decides
  /// whether the child is told they have a "new" friend. Persistence and
  /// the local/cached "collected" state are both handled by
  /// [BingoCollectionProvider.markCollected].
  Future<void> _saveReward() async {
    if (_saved || widget.animal == null || widget.playerId == null) return;
    _saved = true;
    await _newness.future;
    await _bingoCollection.markCollected(
      animal: widget.animal!,
      playerId: widget.playerId!,
      levelNumber: widget.levelNumber,
      signSystem: widget.signSystem,
    );
  }

  /// Whether this animal is already in the player's collection. Reads the
  /// shared cache, preloaded when the bingo game was entered (see
  /// routes.dart) — normally already available here with no further wait;
  /// falls back to loading it if it somehow isn't yet.
  Future<void> _checkIfNew() async {
    bool isNew;
    try {
      if (!_bingoCollection.isCollectedLoaded(widget.playerId)) {
        await _bingoCollection.preload(
          signSystem: widget.signSystem,
          playerId: widget.playerId,
        );
      }
      isNew = !_bingoCollection.collectedLetters.contains(
        widget.animal!.letter.toLowerCase(),
      );
    } catch (_) {
      isNew = true;
    }
    if (!_newness.isCompleted) _newness.complete(isNew);
    if (mounted) setState(() => _isNew = isNew);
  }

  /// Fast-forwards to the finished state: stops audio, snaps every
  /// animation to its end and reveals the buttons. Used for repeat plays
  /// where the child has seen the celebration before. Tapping a button
  /// itself still reaches the button, not this handler.
  void _skipToControls() {
    if (_buttonCtrl.isCompleted) return;
    _uiGen++;
    _audioGen++;
    unawaited(widget.audio.stopAll());
    unawaited(_saveReward());
    if (!_bingoIntroCtrl.isCompleted) _bingoIntroCtrl.value = 1;
    if (!_entryCtrl.isCompleted) _entryCtrl.value = 1;
    _cardPulseCtrl.stop();
    if (!_buttonCtrl.isCompleted) _buttonCtrl.value = 1;
  }

  void _replayAnimalName() {
    final animal = widget.animal;
    if (animal == null) return;
    _audioGen++; // supersede the spoken sequence — the child took over
    _pulseCard();
    unawaited(widget.audio.replayAnimalName(animal.letter));
  }

  String _congratulationsText(AppLocalizations localizer) {
    final isNew = _isNew ?? false;
    final friendLine = localizer(
      isNew ? 'letter_bingo.new_friend' : 'letter_bingo.friend',
    );
    return isNew
        ? '${localizer('general.congratulations')}\n$friendLine'
        : friendLine;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bingoIntroCtrl.dispose();
    _entryCtrl.dispose();
    _cardPulseCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final localizer = AppLocalizations(locale: widget.locale);
    return GestureDetector(
      // Tap any empty space to fast-forward to the buttons; taps on buttons
      // or the card win the gesture arena and never reach this handler.
      onTap: _skipToControls,
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(gradient: bingoOverlayGradient),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned.fill(child: PaperTextureOverlay()),
            SafeArea(
              child: Stack(
                children: [
                  const FallingConfettiLayer(),

                  // Landscape fits everything on one screen (no scrolling)
                  // so the buttons are always visible; portrait scrolls.
                  if (mq.orientation == Orientation.landscape)
                    _buildLandscapeContent(context, localizer, size, mq)
                  else
                    _buildPortraitContent(context, localizer, size, mq),

                  // Fixed back arrow — same treatment as the shared success
                  // overlay's header arrow. Sits above the scrolling content
                  // so it stays reachable while the column scrolls.
                  Positioned(
                    top: AppSizes.paddingMedium,
                    left: AppSizes.paddingMedium,
                    child: GestureDetector(
                      onTap: widget.onChangeLevel,
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: Center(child: BackArrowIcon(size: 48)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Portrait: everything stacked in one scrolling column — BINGO, friend
  /// message, card, then full-width Play Again and Next Level buttons.
  Widget _buildPortraitContent(
    BuildContext context,
    AppLocalizations localizer,
    Size size,
    MediaQueryData mq,
  ) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: size.height - mq.padding.top - mq.padding.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
                vertical: AppSizes.paddingLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBingoWord(localizer),
                  const SizedBox(height: AppSizes.spacingLarge),

                  // ── Animal reward section ───────────────────
                  if (widget.animal != null) ...[
                    _buildFriendMessage(localizer),
                    const SizedBox(height: AppSizes.spacingMedium),
                    Center(child: _buildAnimalCard(localizer)),
                    const SizedBox(height: AppSizes.spacingLarge),
                  ],

                  // ── Sign-in banner (anonymous users) ────────
                  if (context.watch<AuthProvider>().isAnonymous) ...[
                    SignInBannerButton(locale: widget.locale),
                    const SizedBox(height: AppSizes.spacingMedium),
                  ],

                  // ── Play Again, full width ──────────────────
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSizes.spacingMedium,
                    ),
                    child: _buildPlayAgainButton(localizer),
                  ),

                  // ── Next Level, full width ─────────────────
                  if (widget.onNextLevel != null)
                    _buildNextLevelButton(localizer),

                  // ── Check, full width (multiplayer) ─────────
                  if (widget.onCheck != null) _buildCheckButton(localizer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Landscape: a text block (a smaller BINGO above the friend message)
  /// side by side with the animal card, and Play Again / Next Level side by
  /// side along the bottom. Sized to the screen so nothing scrolls off it —
  /// the card scales down to fit the height left over.
  Widget _buildLandscapeContent(
    BuildContext context,
    AppLocalizations localizer,
    Size size,
    MediaQueryData mq,
  ) {
    final available = size.height - mq.padding.vertical;
    final bingoHeight = (available * 0.22).clamp(48.0, 120.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
            vertical: AppSizes.paddingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Text block (BINGO over the friend message) + card ──
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: bingoHeight,
                            child: _buildBingoWord(localizer),
                          ),
                          if (widget.animal != null) ...[
                            const SizedBox(height: AppSizes.spacingSmall),
                            Flexible(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: _buildFriendMessage(localizer),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.animal != null) ...[
                      const SizedBox(width: AppSizes.spacingMedium),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _buildAnimalCard(
                              localizer,
                              padForRoundel: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Sign-in banner (anonymous users) ────────
              if (context.watch<AuthProvider>().isAnonymous) ...[
                const SizedBox(height: AppSizes.spacingSmall),
                Center(child: SignInBannerButton(locale: widget.locale)),
              ],
              const SizedBox(height: AppSizes.spacingSmall),

              // ── Play Again + Next Level, in a row ─────────
              Row(
                children: [
                  Expanded(child: _buildPlayAgainButton(localizer)),
                  if (widget.onNextLevel != null) ...[
                    const SizedBox(width: AppSizes.spacingMedium),
                    Expanded(child: _buildNextLevelButton(localizer)),
                  ],
                  if (widget.onCheck != null) ...[
                    const SizedBox(width: AppSizes.spacingMedium),
                    Expanded(child: _buildCheckButton(localizer)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pulsing BINGO — letters pop in one by one. Scales down to fit whatever
  /// height it's given.
  Widget _buildBingoWord(AppLocalizations localizer) {
    return Semantics(
      header: true,
      excludeSemantics: true,
      label: localizer('letter_bingo.bingo'),
      child: ScaleTransition(
        scale: _pulseAnim,
        child: _BingoText(intro: _bingoIntroCtrl),
      ),
    );
  }

  /// "You have a (new) friend" line, fading in once newness is known.
  Widget _buildFriendMessage(AppLocalizations localizer) {
    final text = _congratulationsText(localizer);
    final baseStyle = AppTheme.celebrationAt(AppSizes.fontSizeHeading).copyWith(
      // Tighter than the app-wide celebration spacing.
      letterSpacing: AppSizes.fontSizeHeading * -0.18,
    );
    return AnimatedOpacity(
      opacity: _isNew != null ? 1.0 : 0.0,
      duration: _newnessFadeDuration,
      child: Semantics(
        liveRegion: true,
        excludeSemantics: true,
        label: text,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = AppColors.accentOrange,
                shadows: const [
                  Shadow(color: Color(0xFF462200), offset: Offset(2, 3)),
                ],
              ),
            ),
            Text(
              text,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(color: AppColors.celebrationGold),
            ),
          ],
        ),
      ),
    );
  }

  /// The reward card sliding in, with the see-collection roundel on its
  /// top-right corner. With [padForRoundel] (landscape) it's padded so the
  /// overhanging roundel sits inside the widget's bounds and scales down
  /// with the card; padded on both sides so the card stays centred.
  Widget _buildAnimalCard(
    AppLocalizations localizer, {
    bool padForRoundel = false,
  }) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: padForRoundel
              ? const EdgeInsets.fromLTRB(40, 14, 40, 0)
              : EdgeInsets.zero,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ScaleTransition(
                scale: _cardPulseAnim,
                child: AnimalCard(
                  animal: widget.animal!,
                  onTap: _replayAnimalName,
                  feltName: true,
                ),
              ),
              Positioned(
                top: -14,
                right: -40,
                child: _RevealOnFade(
                  fade: _buttonFade,
                  child: _SeeCollectionRoundel(
                    label: localizer('letter_bingo.see_collection'),
                    onTap: widget.onSeeCollection,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayAgainButton(AppLocalizations localizer) {
    return _RevealOnFade(
      fade: _buttonFade,
      child: Primary2Button(
        label: localizer('general.play_again'),
        icon: Icons.replay,
        expanded: true,
        onPressed: widget.onPlayAgain,
      ),
    );
  }

  Widget _buildNextLevelButton(AppLocalizations localizer) {
    return _RevealOnFade(
      fade: _buttonFade,
      child: SecondaryButton(
        label: localizer('general.next_level'),
        expanded: true,
        onPressed: widget.onNextLevel,
      ),
    );
  }

  Widget _buildCheckButton(AppLocalizations localizer) {
    return _RevealOnFade(
      fade: _buttonFade,
      child: SecondaryButton(
        label: localizer('letter_bingo.check'),
        icon: Icons.fact_check,
        expanded: true,
        onPressed: widget.onCheck,
      ),
    );
  }
}

// ── See-collection roundel ───────────────────────────────────────────────────

/// Small tappable AbiPink circle overlapping the reward card's top-right
/// corner, nudging the player toward their animal collection.
class _SeeCollectionRoundel extends StatelessWidget {
  const _SeeCollectionRoundel({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  static const double _size = 90;

  /// Breaks [label] onto up to 3 lines, spreading its words as evenly as
  /// possible so it reads cleanly inside the circular badge. The full
  /// sentence is still used as the accessible label.
  String get _wrappedLabel {
    final words = label.split(' ');
    if (words.length <= 3) return words.join('\n');
    final perLine = (words.length / 3).ceil();
    final lines = <String>[];
    for (var i = 0; i < words.length; i += perLine) {
      lines.add(words.skip(i).take(perLine).join(' '));
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSizes.spacingSmall),
          decoration: const BoxDecoration(
            color: AppColors.abiPink,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _wrappedLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reveal helper ────────────────────────────────────────────────────────────

/// Fades [child] in with [fade] and blocks taps *and* screen-reader focus
/// until the fade completes, so "invisible" buttons can't be activated
/// early (a bare FadeTransition keeps its child hit-testable).
class _RevealOnFade extends StatelessWidget {
  const _RevealOnFade({required this.fade, required this.child});

  final Animation<double> fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fade,
      builder: (context, child) {
        final hidden = fade.status != AnimationStatus.completed;
        return IgnorePointer(
          ignoring: hidden,
          child: ExcludeSemantics(
            excluding: hidden,
            child: FadeTransition(opacity: fade, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

// ── BINGO text ───────────────────────────────────────────────────────────────

class _BingoText extends StatelessWidget {
  const _BingoText({required this.intro});

  /// Drives the staggered letter pop-in; 0 = nothing shown, 1 = all five
  /// letters at full size.
  final Animation<double> intro;

  static const _letters = ['B', 'I', 'N', 'G', 'O'];
  static const _colors = [
    AppColors.accentRed,
    AppColors.accentNavyBlue,
    AppColors.accentLimeGreen,
    AppColors.accentOrange,
    AppColors.accentPurple,
  ];
  static const _letterSize = 80.0;
  static const _letterStagger = 0.12;
  static const _letterPopWindow = 0.45;

  /// Width of the white outline outside each letter's edge. Flutter centres
  /// a stroke on the glyph outline, so it's drawn at twice this width behind
  /// the fill, which covers the inner half.
  static const _outerStroke = 12.0;

  /// Letter spacing as a fraction of [_letterSize]. Each letter is its own
  /// [Text], and letter spacing shortens a glyph's advance, so this pulls
  /// neighbouring letters closer exactly as it would within one word.
  static const _letterSpacing = _letterSize * -0.18;

  /// Felt texture scale, matching the grain on the [AnimalCard] name strip
  /// (the 600px-wide texture covering the 220px card).
  static const _feltScale = AnimalCard.cardWidth / 600;

  @override
  Widget build(BuildContext context) {
    // Strokes and fills are separate rows, stacked strokes-first, so one
    // letter's thick white outline never paints over its neighbour's fill.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        // Room for the outline beyond the text's own layout box.
        padding: const EdgeInsets.all(_outerStroke),
        child: Stack(
          children: [
            _buildRow(
              (i) => AppTheme.celebration.copyWith(
                fontSize: _letterSize,
                letterSpacing: _letterSpacing,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = _outerStroke * 2
                  ..strokeJoin = StrokeJoin.round
                  ..color = Colors.white,
              ),
            ),
            _buildRow(
              (i) => AppTheme.celebration.copyWith(
                fontSize: _letterSize,
                letterSpacing: _letterSpacing,
                color: _colors[i],
              ),
            ),
            // Felt texture blended over the fills, clipped to the glyphs.
            FuzzTextureBuilder(
              builder: (context, image) {
                if (image == null) return const SizedBox.shrink();
                final paint = fuzzTextPaint(image, scale: _feltScale);
                return _buildRow(
                  (i) => AppTheme.celebration.copyWith(
                    fontSize: _letterSize,
                    letterSpacing: _letterSpacing,
                    foreground: paint,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// One row of the five letters, each popping in on its own staggered
  /// interval of [intro], styled by [styleFor].
  Widget _buildRow(TextStyle Function(int index) styleFor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_letters.length, (i) {
        final start = i * _letterStagger;
        return ScaleTransition(
          scale: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: intro,
              curve: Interval(
                start,
                start + _letterPopWindow,
                curve: Curves.easeOutBack,
              ),
            ),
          ),
          child: Text(_letters[i], style: styleFor(i)),
        );
      }),
    );
  }
}
