import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../models/word_search_models.dart';
import '../providers/word_search_provider.dart';

class WordSearchScreen extends StatelessWidget {
  const WordSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WordSearchProvider>(
      builder: (context, provider, _) {
        final locale = provider.locale;
        final localizer = AppLocalizations(locale: locale);

        if (provider.showLevelSelect) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A237E),
            appBar: GameAppBar(
              title: localizer('word_search.title'),
              onBack: () => Navigator.of(context).pop(),
            ),
            body: SafeArea(
              child: LevelSelectScreen(
                locale: locale,
                levels: WordSearchLevel.forLocale(locale).map((level) {
                  return LevelSelectItem(
                    number: level.number,
                    name: localizer(level.category),
                    color: levelColor(level.number - 1),
                    onTap: () => provider.setLevel(level.randomVariant()),
                  );
                }).toList(),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1A237E),
          appBar: GameAppBar(
            title: localizer(provider.level.category),
            onBack: provider.showLevelSelection,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _VideoPlayer(
                            key: ValueKey(provider.wordIndex),
                            videoPath: provider.currentWord.videoAssetPath,
                            localizer: localizer,
                          ),
                          const SizedBox(height: 10),
                          _ProgressDots(provider: provider),
                          const SizedBox(height: 10),
                          _AttemptStrip(provider: provider, localizer: localizer),
                          const SizedBox(height: 6),
                          Expanded(
                            child: _LetterCircle(provider: provider),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (provider.state == WordSearchState.correct)
                  Positioned.fill(
                    child: _CorrectBanner(
                      word: provider.currentWord.word,
                      localizer: localizer,
                    ),
                  ),
                if (provider.state == WordSearchState.complete)
                  Positioned.fill(
                    child: GameSuccessOverlay(
                      gameId: 'word_search',
                      scoreStyle: SuccessScoreStyle.youScored,
                      score: provider.score,
                      locale: locale,
                      onChangeLevel: () => Navigator.of(context).pop(),
                      onNextLevel: provider.nextLevel != null
                          ? () => provider.setLevel(
                                provider.nextLevel!.randomVariant(),
                              )
                          : null,
                      changeLevelIsButton: true,
                      changeLevelLabel: localizer('general.home'),
                      changeLevelIcon: Icons.home_rounded,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video player
// ─────────────────────────────────────────────────────────────────────────────

class _VideoPlayer extends StatefulWidget {
  final String videoPath;
  final AppLocalizations localizer;
  const _VideoPlayer({
    super.key,
    required this.videoPath,
    required this.localizer,
  });

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset(widget.videoPath);
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      await controller.setLooping(true);
      controller.play();
    } catch (_) {
      // Video not yet available — placeholder is shown.
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: _initialized && _controller != null
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off_outlined,
                        color: Colors.white30, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      widget.localizer('word_search.video_coming_soon'),
                      style: const TextStyle(
                          color: Colors.white30, fontFamily: 'ComicRelief'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress dots — one per word, filled green when answered
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final WordSearchProvider provider;
  const _ProgressDots({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(provider.wordCount, (i) {
        final answered = i < provider.wordIndex ||
            (i == provider.wordIndex &&
                provider.state == WordSearchState.correct);
        final current = i == provider.wordIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: current ? 14 : 9,
          height: current ? 14 : 9,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: answered
                ? const Color(0xFF69F0AE)
                : current
                    ? Colors.white
                    : Colors.white30,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attempt strip — shows letters selected so far
// ─────────────────────────────────────────────────────────────────────────────

class _AttemptStrip extends StatelessWidget {
  final WordSearchProvider provider;
  final AppLocalizations localizer;
  const _AttemptStrip({required this.provider, required this.localizer});

  @override
  Widget build(BuildContext context) {
    final letters = provider.selectedIndices
        .map((i) => provider.level.letterPool[i].toUpperCase())
        .toList();

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: letters.isEmpty
            ? Text(
                localizer('word_search.drag_hint'),
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  color: Colors.white38,
                  fontSize: 13,
                ),
              )
            : Text(
                letters.join(' '),
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: provider.flashWrong
                      ? const Color(0xFFEF9A9A)
                      : Colors.white,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Letter circle — drag-to-spell interaction
// ─────────────────────────────────────────────────────────────────────────────

class _LetterCircle extends StatefulWidget {
  final WordSearchProvider provider;
  const _LetterCircle({required this.provider});

  @override
  State<_LetterCircle> createState() => _LetterCircleState();
}

class _LetterCircleState extends State<_LetterCircle> {
  Offset? _dragPos;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final pool = provider.level.letterPool;

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final center = Offset(w / 2, h / 2);
      final circleR = min(w, h) * 0.36;
      final tileR = circleR * 0.22;

      final positions = List.generate(pool.length, (i) {
        final angle = 2 * pi * i / pool.length - pi / 2;
        return center + Offset(circleR * cos(angle), circleR * sin(angle));
      });

      int? hitTest(Offset pos) {
        for (int i = 0; i < positions.length; i++) {
          if ((pos - positions[i]).distance < tileR * 1.3) return i;
        }
        return null;
      }

      return GestureDetector(
        onPanStart: (d) {
          if (provider.state != WordSearchState.playing) return;
          final idx = hitTest(d.localPosition);
          if (idx != null) {
            provider.onLetterEntered(idx);
            setState(() => _dragPos = d.localPosition);
          }
        },
        onPanUpdate: (d) {
          if (provider.state != WordSearchState.playing) return;
          final idx = hitTest(d.localPosition);
          if (idx != null) provider.onLetterEntered(idx);
          setState(() => _dragPos = d.localPosition);
        },
        onPanEnd: (_) {
          provider.onDragEnd();
          setState(() => _dragPos = null);
        },
        onPanCancel: () {
          provider.onDragEnd();
          setState(() => _dragPos = null);
        },
        child: CustomPaint(
          painter: _LinePainter(
            positions: positions,
            selectedIndices: provider.selectedIndices,
            dragPos: provider.state == WordSearchState.playing ? _dragPos : null,
            flashWrong: provider.flashWrong,
            circleR: circleR,
            center: center,
          ),
          child: Stack(
            children: [
              for (int i = 0; i < pool.length; i++)
                Positioned(
                  left: positions[i].dx - tileR,
                  top: positions[i].dy - tileR,
                  width: tileR * 2,
                  height: tileR * 2,
                  child: _LetterTile(
                    letter: pool[i].toUpperCase(),
                    isSelected: provider.selectedIndices.contains(i),
                    flashWrong: provider.flashWrong &&
                        provider.selectedIndices.contains(i),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connecting-line painter
// ─────────────────────────────────────────────────────────────────────────────

class _LinePainter extends CustomPainter {
  final List<Offset> positions;
  final List<int> selectedIndices;
  final Offset? dragPos;
  final bool flashWrong;
  final double circleR;
  final Offset center;

  const _LinePainter({
    required this.positions,
    required this.selectedIndices,
    required this.dragPos,
    required this.flashWrong,
    required this.circleR,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Faint guide circle
    canvas.drawCircle(
      center,
      circleR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (selectedIndices.isEmpty) return;

    final lineColor =
        flashWrong ? const Color(0xFFEF5350) : const Color(0xFF69F0AE);

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.85)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Lines between consecutively selected letters
    for (int i = 0; i < selectedIndices.length - 1; i++) {
      canvas.drawLine(
        positions[selectedIndices[i]],
        positions[selectedIndices[i + 1]],
        linePaint,
      );
    }

    // Ghost line: last selected → current finger position
    if (dragPos != null && !flashWrong) {
      canvas.drawLine(
        positions[selectedIndices.last],
        dragPos!,
        Paint()
          ..color = lineColor.withValues(alpha: 0.30)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Letter tile
// ─────────────────────────────────────────────────────────────────────────────

class _LetterTile extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final bool flashWrong;

  const _LetterTile({
    required this.letter,
    required this.isSelected,
    required this.flashWrong,
  });

  @override
  Widget build(BuildContext context) {
    final bg = flashWrong
        ? const Color(0xFFEF5350)
        : isSelected
            ? const Color(0xFF69F0AE)
            : const Color(0xFF3949AB);

    final textColor =
        isSelected && !flashWrong ? const Color(0xFF1A237E) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              letter,
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Correct banner — shown briefly after a right answer
// ─────────────────────────────────────────────────────────────────────────────

class _CorrectBanner extends StatelessWidget {
  final String word;
  final AppLocalizations localizer;
  const _CorrectBanner({required this.word, required this.localizer});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 60),
                const SizedBox(height: 10),
                Text(
                  localizer('general.correct'),
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  word.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 26,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

