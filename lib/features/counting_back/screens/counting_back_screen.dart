import 'dart:math' show cos, pi, sin, sqrt;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/services/audio_service.dart';
import '../../../core/tts_helper.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../providers/counting_back_provider.dart';

class CountingBackScreen extends StatefulWidget {
  const CountingBackScreen({super.key});

  @override
  State<CountingBackScreen> createState() => _CountingBackScreenState();
}

class _CountingBackScreenState extends State<CountingBackScreen>
    with TickerProviderStateMixin {
  FlutterTts? _tts;
  String? _lastRoundKey;

  // ── animation state ────────────────────────────────────────────────────────

  bool _isAnimating = false;

  /// Which hop is currently being drawn (0-based). -1 = none.
  int _currentHop = -1;

  /// The answer the player tapped.
  int? _selectedAnswer;

  /// Whether the animation has finished and result is being shown.
  bool _showingResult = false;

  late AnimationController _hopController;
  late Animation<double> _hopProgress;

  @override
  void initState() {
    super.initState();
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _hopProgress = CurvedAnimation(
      parent: _hopController,
      curve: Curves.easeInOut,
    );
    _hopController.addStatusListener(_onHopStatus);
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await TtsHelper.configure(_tts!);
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
    }
  }

  void _speak(String text) {
    try {
      _tts?.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  @override
  void dispose() {
    _hopController.removeStatusListener(_onHopStatus);
    _hopController.dispose();
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }

  // ── answer handling ────────────────────────────────────────────────────────

  void _onAnswerTapped(int answer, CountingBackProvider provider) {
    if (_isAnimating || _showingResult) return;
    setState(() {
      _selectedAnswer = answer;
      _isAnimating = true;
      _currentHop = 0;
    });
    _speak('${provider.startNumber}');
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _speak('${provider.startNumber - 1}');
      _hopController.forward(from: 0);
    });
  }

  void _onHopStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted) return;

    final provider =
        context.read<CountingBackProvider>();
    final totalHops = provider.takeAway;

    final nextHop = _currentHop + 1;
    if (nextHop < totalHops) {
      setState(() => _currentHop = nextHop);
      _speak('${provider.startNumber - nextHop - 1}');
      _hopController.forward(from: 0);
    } else {
      // All hops done — show result
      setState(() {
        _isAnimating = false;
        _showingResult = true;
      });

      final isCorrect = _selectedAnswer == provider.correctAnswer;
      if (isCorrect) {
        AudioService.playCorrect('counting_back');
        _speak('Well done!');
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _showingResult = false;
            _currentHop = -1;
            _selectedAnswer = null;
          });
          provider.recordCorrect();
        });
      } else {
        AudioService.playWrong('counting_back');
        _speak('Try again!');
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            _showingResult = false;
            _currentHop = -1;
            _selectedAnswer = null;
          });
        });
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<CountingBackProvider>(
      builder: (context, provider, _) {
        // Speak question on new round
        if (!provider.showLevelSelect &&
            provider.state == CountingBackState.playing) {
          final key = '${provider.roundNumber}';
          if (key != _lastRoundKey) {
            _lastRoundKey = key;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _speak(
                  'What is ${provider.startNumber} take away ${provider.takeAway}?');
            });
          }
        }

        if (provider.state == CountingBackState.won &&
            _lastRoundKey != 'won') {
          _lastRoundKey = 'won';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speak('Well Done!');
          });
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: 'Counting Back',
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
                if (!provider.showLevelSelect &&
                    provider.state == CountingBackState.won)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'counting_back',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      showPersonalBest: true,
                      isNewPersonalBest:
                          provider.lastResult?.isNewPersonalBest ?? false,
                      personalBest: provider.lastResult?.personalBest,
                      onPlayAgain: () =>
                          provider.startGame(provider.levelNumber - 1),
                      onNextLevel:
                          provider.levelNumber < countingBackLevels.length
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

  // ── Level select ──────────────────────────────────────────────────────────

  Widget _buildLevelSelect(
      BuildContext context, CountingBackProvider provider) {
    return LevelSelectScreen(
      subtitle: 'Count back to find the answer!',
      levels: List.generate(countingBackLevels.length, (i) {
        final level = countingBackLevels[i];
        return LevelSelectItem(
          number: level.number,
          name: level.name,
          color: levelColor(i),
          onTap: () {
            provider.startGame(i);
            AudioService.playIntro('counting_back');
          },
        );
      }),
    );
  }

  // ── Game layout ───────────────────────────────────────────────────────────

  Widget _buildGame(BuildContext context, CountingBackProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 8),

        GameHeaderBar(
          onBack: () => provider.showLevelSelection(),
          scoreValue: '${provider.score}',
          levelNumber: provider.levelNumber,
          centerContent: Center(
            child: Text(
              'Round ${provider.roundNumber} of ${CountingBackProvider.totalRounds}',
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Question + BSL sum + number line — one container
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _styledContainer(
            child: Column(
              children: [
                // Written question
                Text(
                  'What is ${provider.startNumber} take away ${provider.takeAway}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // BSL subtraction sum: X  −  Y  =  ?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bslNumberTile(provider.startNumber),
                    _operatorText('−'),
                    _bslNumberTile(provider.takeAway),
                    _operatorText('='),
                    _questionMark(),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.white60),
                const SizedBox(height: 12),

                // Number line with hop animation
                AnimatedBuilder(
                  animation: _hopProgress,
                  builder: (_, _) => _CountBackNumberLine(
                    startNumber: provider.startNumber,
                    totalHops: provider.takeAway,
                    currentHop: _currentHop,
                    hopProgress: _hopProgress.value,
                    selectedAnswer: _selectedAnswer,
                    correctAnswer: provider.correctAnswer,
                    showingResult: _showingResult,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Try again message
        if (_showingResult && _selectedAnswer != null &&
            _selectedAnswer != context.read<CountingBackProvider>().correctAnswer)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: AppColors.accentRed, size: 24),
                const SizedBox(width: AppSizes.spacingSmall),
                const Text(
                  'Try again!',
                  style: TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentRed,
                  ),
                ),
              ],
            ),
          ),

        // Answer buttons
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _NumberAnswerButton(
            n: provider.answerOptions[0],
            disabled: _isAnimating || _showingResult,
            onTap: () => _onAnswerTapped(provider.answerOptions[0], provider),
          ),
        ),

        const SizedBox(height: AppSizes.spacingSmall),

        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: _NumberAnswerButton(
            n: provider.answerOptions[1],
            disabled: _isAnimating || _showingResult,
            onTap: () => _onAnswerTapped(provider.answerOptions[1], provider),
          ),
        ),

        const SizedBox(height: AppSizes.spacingLarge),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _bslNumberTile(int n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(AssetPaths.bslNumber(n), height: 48),
          Text(
            '$n',
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _operatorText(String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        symbol,
        style: const TextStyle(
          fontFamily: 'ComicRelief',
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _questionMark() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SizedBox(
        width: 48,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
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
        child: child,
      ),
    );
  }
}

// ── Number line with hop arcs ─────────────────────────────────────────────────

class _CountBackNumberLine extends StatelessWidget {
  final int startNumber;
  final int totalHops;
  final int currentHop;
  final double hopProgress; // 0.0–1.0 for the arc being drawn
  final int? selectedAnswer;
  final int correctAnswer;
  final bool showingResult;

  const _CountBackNumberLine({
    required this.startNumber,
    required this.totalHops,
    required this.currentHop,
    required this.hopProgress,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.showingResult,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      const int divisions = 5;
      final cellWidth = w / divisions;
      const double lineY = 28.0;
      const double tickH = 12.0;
      const double totalHeight = lineY + tickH / 2 + 4 + 24.0;

      return SizedBox(
        height: totalHeight + 60, // extra space for arcs above the line
        child: CustomPaint(
          painter: _HopPainter(
            cellWidth: cellWidth,
            lineY: lineY + 60,
            tickH: tickH,
            startNumber: startNumber,
            totalHops: totalHops,
            currentHop: currentHop,
            hopProgress: hopProgress,
            selectedAnswer: selectedAnswer,
            correctAnswer: correctAnswer,
            showingResult: showingResult,
          ),
          size: Size(w, totalHeight + 60),
        ),
      );
    });
  }
}

class _HopPainter extends CustomPainter {
  final double cellWidth;
  final double lineY;
  final double tickH;
  final int startNumber;
  final int totalHops;
  final int currentHop;
  final double hopProgress;
  final int? selectedAnswer;
  final int correctAnswer;
  final bool showingResult;

  const _HopPainter({
    required this.cellWidth,
    required this.lineY,
    required this.tickH,
    required this.startNumber,
    required this.totalHops,
    required this.currentHop,
    required this.hopProgress,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.showingResult,
  });

  double _cx(int number) => cellWidth * (number - 1 + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final tickPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Horizontal line
    canvas.drawLine(Offset(_cx(1), lineY), Offset(_cx(5), lineY), linePaint);

    // Ticks and labels
    for (int i = 1; i <= 5; i++) {
      final x = _cx(i);
      canvas.drawLine(
        Offset(x, lineY - tickH / 2),
        Offset(x, lineY + tickH / 2),
        tickPaint,
      );

      Color labelColor = Colors.black87;
      if (showingResult && selectedAnswer != null && i == selectedAnswer) {
        labelColor = selectedAnswer == correctAnswer
            ? AppColors.accentLimeGreen
            : AppColors.accentRed;
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, lineY + tickH / 2 + 4));
    }

    // Completed hops
    final completedHops = currentHop < 0 ? 0 : currentHop;
    for (int h = 0; h < completedHops; h++) {
      _drawArc(canvas, startNumber - h, startNumber - h - 1, 1.0, h);
    }

    // Current hop (partial)
    if (currentHop >= 0) {
      _drawArc(canvas, startNumber - currentHop,
          startNumber - currentHop - 1, hopProgress, currentHop);
    }
  }

  void _drawArc(
      Canvas canvas, int from, int to, double progress, int hopIndex) {
    if (from < 1 || to < 1) return;

    final x1 = _cx(from);
    final x2 = _cx(to);
    final midX = (x1 + x2) / 2;
    final arcHeight = 18.0 + hopIndex * 8.0;
    final cpX = midX;
    final cpY = lineY - arcHeight;

    final arcPaint = Paint()
      ..color = AppColors.accentPurple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(x1, lineY);

    if (progress >= 1.0) {
      path.quadraticBezierTo(cpX, cpY, x2, lineY);
    } else {
      final t = progress;
      path.quadraticBezierTo(
        _bez(x1, cpX, cpX, t),
        _bez(lineY, cpY, cpY, t),
        _bez(x1, cpX, x2, t),
        _bez(lineY, cpY, lineY, t),
      );
    }

    canvas.drawPath(path, arcPaint);

    if (progress >= 1.0) {
      _drawArrowTip(canvas, arcPaint, x2, lineY, cpX, cpY);
    }
  }

  double _bez(double p0, double p1, double p2, double t) =>
      (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;

  void _drawArrowTip(Canvas canvas, Paint paint, double ex, double ey,
      double cpX, double cpY) {
    final dx = ex - cpX;
    final dy = ey - cpY;
    final len = sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;

    const arrowSize = 8.0;
    const angle = pi / 6;
    final ax1 = ex - arrowSize * (ux * cos(angle) - uy * sin(angle));
    final ay1 = ey - arrowSize * (uy * cos(angle) + ux * sin(angle));
    final ax2 = ex - arrowSize * (ux * cos(angle) + uy * sin(angle));
    final ay2 = ey - arrowSize * (uy * cos(angle) - ux * sin(angle));

    canvas.drawPath(
      Path()
        ..moveTo(ax1, ay1)
        ..lineTo(ex, ey)
        ..lineTo(ax2, ay2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HopPainter old) =>
      old.currentHop != currentHop ||
      old.hopProgress != hopProgress ||
      old.showingResult != showingResult ||
      old.selectedAnswer != selectedAnswer;
}

// ── Answer button (same style as number_line) ─────────────────────────────────

class _NumberAnswerButton extends StatelessWidget {
  final int n;
  final bool disabled;
  final VoidCallback onTap;

  const _NumberAnswerButton({
    required this.n,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingMedium,
              vertical: AppSizes.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.headerBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.headerBorderDark, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$n',
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: AppSizes.fontSizeHeading,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMedium),
                SvgPicture.asset(
                  AssetPaths.bslNumber(n),
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
