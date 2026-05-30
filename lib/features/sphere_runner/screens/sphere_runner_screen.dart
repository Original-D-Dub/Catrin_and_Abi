import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../game/sphere_runner_game.dart';

/// Flutter screen that hosts the [SphereRunnerGame] Flame game.
///
/// All word-level UI (HUD labels, win overlay) is built as Flutter
/// [overlayBuilderMap] widgets so they go through [AppLocalizations].
/// Mathematical gate labels (+5, ×2 …) are rendered directly on the
/// Flame canvas and need no localisation.
class SphereRunnerScreen extends StatefulWidget {
  const SphereRunnerScreen({super.key});

  @override
  State<SphereRunnerScreen> createState() => _SphereRunnerScreenState();
}

class _SphereRunnerScreenState extends State<SphereRunnerScreen> {
  late final SphereRunnerGame _game;

  @override
  void initState() {
    super.initState();
    _game = SphereRunnerGame();
  }

  @override
  void dispose() {
    _game.sphereCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<SphereRunnerGame>(
        game: _game,
        overlayBuilderMap: {
          'hud': _buildHud,
          'win': _buildWin,
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }

  // ── HUD overlay ────────────────────────────────────────────────────────────

  Widget _buildHud(BuildContext context, SphereRunnerGame game) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button + sphere count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Back arrow
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                const Spacer(),

                // Live sphere count badge
                ValueListenableBuilder<int>(
                  valueListenable: game.sphereCountNotifier,
                  builder: (_, count, _) {
                    final nearTarget = count > 15;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: nearTarget
                              ? Colors.amber
                              : Colors.white.withAlpha(70),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l('sphere_runner.spheres_label'),
                            style: TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: nearTarget
                                  ? Colors.amber
                                  : Colors.white.withAlpha(200),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontFamily: 'ComicRelief',
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: nearTarget ? Colors.amber : Colors.white,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 6, right: 2),
                            child: Text(
                              '/ 20',
                              style: TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 16,
                                color: Colors.white.withAlpha(160),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Target label (keeps layout balanced)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l('sphere_runner.target_label'),
                    style: const TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // "Almost there!" hint when in endgame mode
          ValueListenableBuilder<int>(
            valueListenable: game.sphereCountNotifier,
            builder: (_, count, _) {
              if (!game.endgameMode) return const SizedBox.shrink();
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    l('sphere_runner.almost_there'),
                    style: const TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Win overlay ────────────────────────────────────────────────────────────

  Widget _buildWin(BuildContext context, SphereRunnerGame game) {
    final l = AppLocalizations.of(context);
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(190),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(
                l('sphere_runner.win_title'),
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l('sphere_runner.win_body'),
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 20,
                  color: Colors.white.withAlpha(210),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _overlayButton(
                    label: l('general.play_again'),
                    color: const Color(0xFF4CAF50),
                    onTap: game.reset,
                  ),
                  const SizedBox(width: 16),
                  _overlayButton(
                    label: l('sphere_runner.exit'),
                    color: Colors.blueGrey,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
