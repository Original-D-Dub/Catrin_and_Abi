import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/asset_paths.dart';
import '../providers/wave_hello_provider.dart';

/// Wave Hello game screen.
///
/// The front camera runs invisibly to detect a waving gesture (wrist
/// horizontal oscillation). When a wave is detected, the Catrin Rive
/// character plays her 2-second wave animation in response.
///
/// Rive file:      [AssetPaths.catrinVectorOutlineRiv]
/// State machine:  "State Machine 1"
/// Trigger input:  "wave"
class WaveHelloScreen extends StatefulWidget {
  const WaveHelloScreen({super.key});

  @override
  State<WaveHelloScreen> createState() => _WaveHelloScreenState();
}

class _WaveHelloScreenState extends State<WaveHelloScreen> {
  static const _stateMachineSelector = StateMachineNamed('State Machine 1');

  RiveWidgetController? _riveController;
  TriggerInput? _waveTrigger;

  /// Tracks the last wave count we reacted to so we fire the Rive trigger
  /// exactly once per new wave event from the provider.
  int _lastWaveCount = 0;
  bool _showHello = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaveHelloProvider>().start();
    });
  }

  void _onRiveLoaded(RiveLoaded state) {
    _riveController = state.controller;
    // ignore: deprecated_member_use
    _waveTrigger = state.controller.stateMachine.trigger('wave');
  }

  void _triggerWaveAnimation() {
    _waveTrigger?.fire();
    setState(() => _showHello = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHello = false);
    });
  }

  @override
  void dispose() {
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaveHelloProvider>(
      builder: (context, provider, _) {
        // React to each new wave detected by the provider.
        if (provider.waveCount != _lastWaveCount) {
          _lastWaveCount = provider.waveCount;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _triggerWaveAnimation(),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.accentWhite),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Wave Hello!',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.accentWhite,
              ),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/backgrounds/home-screen-background.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: provider.gameState == WaveHelloGameState.permissionDenied
                  ? _buildPermissionDenied(context)
                  : _buildGame(),
            ),
          ),
        );
      },
    );
  }

  // ── Game layout ────────────────────────────────────────────────────────────

  Widget _buildGame() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Catrin Rive character — takes up most of the screen.
        Expanded(
          child: RiveWidgetBuilder(
            fileLoader: FileLoader.fromAsset(
              AssetPaths.catrinVectorOutlineRiv,
              riveFactory: Factory.flutter,
            ),
            stateMachineSelector: _stateMachineSelector,
            onLoaded: _onRiveLoaded,
            builder: (context, state) {
              return switch (state) {
                RiveLoading() => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentWhite,
                    ),
                  ),
                RiveLoaded(:final controller) => RiveWidget(
                    controller: controller,
                  ),
                RiveFailed(:final error) => Center(
                    child: Text(
                      'Could not load character: $error',
                      style: const TextStyle(
                        fontFamily: 'ComicRelief',
                        color: AppColors.accentWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              };
            },
          ),
        ),

        const SizedBox(height: 12),

        // "Hello!" response — fades in when a wave is detected.
        AnimatedOpacity(
          opacity: _showHello ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.catrinBlue.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Hello! 👋',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: AppColors.accentWhite,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Prompt — fades out while "Hello!" is showing.
        AnimatedOpacity(
          opacity: _showHello ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Wave at the camera! 👋',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.catrinBlue,
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),
      ],
    );
  }

  // ── Permission denied layout ───────────────────────────────────────────────

  Widget _buildPermissionDenied(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: AppColors.accentWhite,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera permission is needed to detect your wave.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 20,
                color: AppColors.accentWhite,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
