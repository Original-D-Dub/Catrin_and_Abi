import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/game_stats_service.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../game/enclosure_walk_game.dart';
import '../providers/enclosure_walk_provider.dart';
import '../widgets/bsl_question_video.dart';
import '../widgets/captured_photo_card.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/zoo_camera_button.dart';
import 'zoo_level_select_screen.dart';

/// Screen for a side-scrolling enclosure walk building (aquarium,
/// reptile house — chosen by the [EnclosureWalkProvider]'s config, which
/// the route provides).
///
/// Plays the same BSL video quiz as the zoo's map levels: hosts the Flame
/// [GameWidget] for [EnclosureWalkGame] with the current question's video
/// below the header bar. The player walks to the matching enclosure and
/// presses Take a Picture; a correct picture reveals a photo of the
/// animal and plays the next video. After three correct answers the
/// success overlay celebrates.
class EnclosureWalkScreen extends StatefulWidget {
  const EnclosureWalkScreen({super.key});

  @override
  State<EnclosureWalkScreen> createState() => _EnclosureWalkScreenState();
}

class _EnclosureWalkScreenState extends State<EnclosureWalkScreen> {
  late final EnclosureWalkGame _game;

  bool _flash = false;

  /// Whether the photo-reveal card for the last correct answer is up.
  bool _showingCapture = false;

  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _game = EnclosureWalkGame(
      provider: context.read<EnclosureWalkProvider>(),
      // Exit door after the last enclosure: back to the zoo map.
      onExitTapped: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _takePicture(EnclosureWalkProvider provider) async {
    final correct = provider.takeQuizPicture();
    if (correct == null) return;

    // The provider's currentQuestion has already advanced (on a correct
    // answer), so hide the video now, synchronously — before any await —
    // so the next question can't flash into view mid-sequence. It stays
    // hidden until the whole success sequence (shutter, delay, sound,
    // photo reveal) has played out below.
    if (correct) setState(() => _showingCapture = true);

    // Flash fires with the shutter sound, not the later correct/wrong
    // sound — that's when a real camera flash goes off.
    setState(() => _flash = true);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _flash = false);
    });
    await AudioService.playCameraShutter();
    if (!mounted) return;

    if (!correct) {
      AudioService.playWrong('zoo');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    AudioService.playCorrect('zoo');
    // Let the photo land, then move on (or celebrate after the last one).
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _showingCapture = false;
        _showSuccess = provider.isComplete;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EnclosureWalkProvider>();
    final localizer = AppLocalizations(locale: provider.locale);

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: Consumer<EnclosureWalkProvider>(
              builder: (context, provider, _) => GameHeaderBar(
                onBack: () => Navigator.of(context).pop(),
                scoreLabel: localizer('zoo.photos_label'),
                scoreValue:
                    '${provider.answeredCount} / ${provider.questionCount}',
                scoreLabelFontSize: 12,
                scoreValueFontSize: 26,
                levelNumber: provider.levelNumber,
                centerContent: GameTimerDisplay(
                  formattedTime: GameTimerDisplay.format(provider.elapsedTime),
                ),
              ),
            ),
          ),
          // Current question's BSL video: full size below the header,
          // shrinking to a bottom-left reminder thumbnail once it has
          // played twice. Hidden while the photo reveal is up; naturally
          // hidden once the level is complete since currentQuestion is
          // then null.
          Consumer<EnclosureWalkProvider>(
            builder: (context, provider, _) {
              final question = provider.currentQuestion;
              if (question == null || _showingCapture) {
                return const SizedBox.shrink();
              }
              return SafeArea(
                child: BslQuestionVideo(
                  key: ValueKey(question.id),
                  videoAssetPath: AssetPaths.zooQuizVideo(question.id),
                  // TESTING: shows the answer instead of the neutral
                  // "watch the sign" placeholder — revert to
                  // localizer('zoo.quiz.watch_sign') once real BSL
                  // footage is recorded.
                  placeholderLabel:
                      localizer(provider.config.enclosureNameKey(question)),
                ),
              );
            },
          ),
          // Take a Picture button — visible while the player is stopped
          // in front of an enclosure with a question outstanding.
          if (!_showSuccess && !_showingCapture)
            Consumer<EnclosureWalkProvider>(
              builder: (context, provider, _) {
                if (provider.activeEnclosure == null || provider.isComplete) {
                  return const SizedBox.shrink();
                }
                return Align(
                  alignment: Alignment.bottomRight,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ZooCameraButton(
                        key: ValueKey(provider.activeEnclosure!.id),
                        tooltip: localizer('zoo.take_picture'),
                        onPressed: () => _takePicture(provider),
                      ),
                    ),
                  ),
                );
              },
            ),
          // Photo reveal for the enclosure just captured.
          if (_showingCapture)
            Consumer<EnclosureWalkProvider>(
              builder: (context, provider, _) {
                final captured = provider.lastCaptured;
                if (captured == null) return const SizedBox.shrink();
                return CapturedPhotoCard(
                  photoAssetPath: AssetPaths.zooAnimalPhoto(captured.id),
                  animalName: localizer(provider.config.enclosureNameKey(captured)),
                );
              },
            ),
          // Camera shutter flash.
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flash ? 0.85 : 0,
              duration: const Duration(milliseconds: 60),
              child: Container(color: Colors.white),
            ),
          ),
          if (_showSuccess)
            GameSuccessOverlay(
              locale: provider.locale,
              gameId: GameIds.zoo,
              scoreStyle: SuccessScoreStyle.custom,
              customScoreLine: localizer('zoo.quiz.success'),
              centerExtraContent: true,
              extraContent: ScatteredPhotoGallery(
                photos: [
                  for (final question in provider.questions)
                    MiniPhotoCard(
                      photoAssetPath: AssetPaths.zooAnimalPhoto(question.id),
                      animalName:
                          localizer(provider.config.enclosureNameKey(question)),
                    ),
                ],
              ),
              onPlayAgain: () {
                provider.reset();
                setState(() => _showSuccess = false);
              },
              onNextLevel: provider.levelNumber < ZooLevelSelectScreen.levels.length
                  ? () {
                      final next =
                          ZooLevelSelectScreen.levels[provider.levelNumber];
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        next.route,
                        ModalRoute.withName(AppRoutes.zooLevels),
                        arguments: {
                          'building': next.building,
                          'zones': next.zones,
                          'level': '${provider.levelNumber + 1}',
                          'locale': provider.locale,
                          'signSystem': provider.signSystem.toPrefsString(),
                          // EnclosureWalkProvider doesn't carry the chosen
                          // character (the zooBuilding route never receives
                          // one either) — the next screen's provider
                          // defaults to 'abi' the same way.
                          'character': 'abi',
                        },
                      );
                    }
                  : null,
              onChangeLevel: () => Navigator.popUntil(
                  context, ModalRoute.withName(AppRoutes.zooLevels)),
              changeLevelLabel: localizer('level_select.title'),
            ),
        ],
      ),
    );
  }
}
