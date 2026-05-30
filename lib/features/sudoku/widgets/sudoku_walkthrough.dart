import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../bsl_maths/widgets/bsl_number_display.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kDark       = Color(0xFF1A237E);
const _kBorder     = 8.0;
const _kDemoBorder = 2.0; // outer border on the 9×9 demo grids

const _kBoxColors = [
  Color(0xFFEF9A9A), Color(0xFFA5D6A7), Color(0xFF90CAF9),
  Color(0xFFFFCC80), Color(0xFFCE93D8), Color(0xFF80DEEA),
  Color(0xFFFFAB91), Color(0xFFF48FB1), Color(0xFFE6EE9C),
];

const _stageDurations = [
  Duration(milliseconds: 3000),
  Duration(milliseconds: 6000), // extended for row-pause reading time
  Duration(milliseconds: 4000),
  Duration(milliseconds: 5500),
  Duration(milliseconds: 7000),
  Duration(milliseconds: 400),
];

// ─────────────────────────────────────────────────────────────────────────────
// Entry-point widget
// ─────────────────────────────────────────────────────────────────────────────

class SudokuWalkthrough extends StatefulWidget {
  final VoidCallback onComplete;
  const SudokuWalkthrough({required this.onComplete, super.key});

  @override
  State<SudokuWalkthrough> createState() => _SudokuWalkthroughState();
}

class _SudokuWalkthroughState extends State<SudokuWalkthrough>
    with TickerProviderStateMixin {
  int _stage = 0;
  static const _total = 6;
  bool _busy = false;

  late AnimationController _stageAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _illFade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        value: 1.0);
    _illFade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _stageAnim = AnimationController(
        vsync: this, duration: _stageDurations[0])
      ..forward();
  }

  @override
  void dispose() {
    _stageAnim.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _jump(int next) async {
    if (_busy) return;
    _busy = true;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _stage = next;
      _stageAnim
        ..duration = _stageDurations[next]
        ..reset()
        ..forward();
    });
    await _fadeCtrl.forward();
    _busy = false;
  }

  void _next() =>
      _stage < _total - 1 ? _jump(_stage + 1) : widget.onComplete();
  void _back() { if (_stage > 0) _jump(_stage - 1); }

  String _body(double t, AppLocalizations l) => switch (_stage) {
    0 => l('sudoku.walkthrough.step0.body'),
    1 => t < 0.54
        ? l('sudoku.walkthrough.step1.body_row')
        : l('sudoku.walkthrough.step1.body_col'),
    2 => t < 0.8
        ? l('sudoku.walkthrough.step2.body_intro')
        : l('sudoku.walkthrough.step2.body_rule'),
    3 => t < 0.32
        ? l('sudoku.walkthrough.step3.body_select')
        : t < 0.62
            ? l('sudoku.walkthrough.step3.body_glow')
            : l('sudoku.walkthrough.step3.body_fill'),
    4 => t < 0.22
        ? l('sudoku.walkthrough.step4.body_glow')
        : t < 0.45
            ? l('sudoku.walkthrough.step4.body_blue')
            : t < 0.65
                ? l('sudoku.walkthrough.step4.body_purple')
                : t < 0.82
                    ? l('sudoku.walkthrough.step4.body_red')
                    : l('sudoku.walkthrough.step4.body_clear'),
    _ => l('sudoku.walkthrough.step5.body'),
  };

  Widget _illustration(AppLocalizations l) => switch (_stage) {
    0 => _WelcomeIllustration(anim: _stageAnim),
    1 => _GridRulesIllustration(anim: _stageAnim),
    2 => _BoxesIllustration(anim: _stageAnim),
    3 => _HowToPlayIllustration(anim: _stageAnim, l: l),
    4 => _HintsErrorsIllustration(anim: _stageAnim, l: l),
    _ => _ReadyIllustration(l: l),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(locale: 'en');

    return Material(
      color: const Color(0xEE0D1B6B),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(l('sudoku.walkthrough.skip'),
                      style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          color: Colors.white54,
                          fontSize: 14)),
                ),
              ),

              // Illustration — same width as the game's playing grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenH = MediaQuery.of(context).size.height;
                    final playWidth = math.min(
                      constraints.maxWidth,
                      screenH * 0.55,
                    ).clamp(180.0, 600.0);

                    return Center(
                      child: SizedBox(
                        width: playWidth,
                        child: FadeTransition(
                          opacity: _illFade,
                          child: AnimatedBuilder(
                            animation: _stageAnim,
                            builder: (_, _) => _illustration(l),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Text card with 8 px dark-blue border
              _TextCard(
                l: l,
                stage: _stage,
                total: _total,
                title: l('sudoku.walkthrough.step$_stage.title'),
                body: AnimatedBuilder(
                  animation: _stageAnim,
                  builder: (_, _) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Text(
                      _body(_stageAnim.value, l),
                      key: ValueKey(_body(_stageAnim.value, l)),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: 14,
                        height: 1.55,
                        color: Colors.black.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                ),
                onBack: _stage > 0 ? _back : null,
                onNext: _next,
                isLast: _stage == _total - 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text card (8 px border, back + next inside)
// ─────────────────────────────────────────────────────────────────────────────

class _TextCard extends StatelessWidget {
  final AppLocalizations l;
  final int stage;
  final int total;
  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool isLast;

  const _TextCard({
    required this.l,
    required this.stage,
    required this.total,
    required this.title,
    required this.body,
    required this.onBack,
    required this.onNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDark, width: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _kDark,
                )),
            const SizedBox(height: 8),
            body,
            const SizedBox(height: 12),
            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == stage ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == stage ? _kDark : _kDark.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 10),
            // Navigation row
            Row(
              children: [
                if (onBack != null)
                  TextButton(
                    onPressed: onBack,
                    child: Text(l('sudoku.walkthrough.back'),
                        style: const TextStyle(
                            fontFamily: 'ComicRelief',
                            color: _kDark,
                            fontSize: 14)),
                  )
                else
                  const SizedBox(width: 72),
                const Spacer(),
                if (!isLast)
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                    ),
                    child: Text(l('sudoku.walkthrough.next'),
                        style: const TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (isLast) ...[
              const SizedBox(height: 8),
              Center(
                child: PrimaryButton(
                  label: l('sudoku.walkthrough.lets_play'),
                  icon: Icons.play_arrow_rounded,
                  onPressed: onNext,
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 0 — Welcome: BSL numbers fade in row by row
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _WelcomeIllustration({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (row) {
          final fade = CurvedAnimation(
            parent: anim,
            curve: Interval(row * 0.25, row * 0.25 + 0.40,
                curve: Curves.easeOut),
          );
          return FadeTransition(
            opacity: fade,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (col) {
                  final n = row * 3 + col + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: BslNumberDisplay(number: n, size: 62),
                  );
                }),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 1 — Grid Rules: row animates blue, then column animates blue
// ─────────────────────────────────────────────────────────────────────────────

class _GridRulesIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _GridRulesIllustration({required this.anim});

  static const _highlightRow = 3;
  static const _highlightCol = 5;

  @override
  Widget build(BuildContext context) {
    final t = anim.value;
    // First half: fill row left-to-right
    // Second half: fill column top-to-bottom
    return Center(
      child: SizedBox(
        width: 216,
        height: 216,
        child: CustomPaint(
          painter: _GridRulesPainter(
            // Row fills 0.05→0.30 (1.5 s), pause 0.30→0.55 (1.5 s reading time),
            // column fills 0.57→0.85 (1.7 s).
            rowFill: ((t - 0.05) / 0.25).clamp(0.0, 1.0),
            colFill: ((t - 0.57) / 0.28).clamp(0.0, 1.0),
            highlightRow: _highlightRow,
            highlightCol: _highlightCol,
          ),
        ),
      ),
    );
  }
}

class _GridRulesPainter extends CustomPainter {
  final double rowFill; // 0-1: how many cells of the row are coloured
  final double colFill;
  final int highlightRow;
  final int highlightCol;

  const _GridRulesPainter({
    required this.rowFill,
    required this.colFill,
    required this.highlightRow,
    required this.highlightCol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final rowColor = AppColors.catrinBlue.withValues(alpha: 0.55);
    final colColor = const Color(0xFF90CAF9).withValues(alpha: 0.6);

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        Color fill = Colors.white;
        if (r == highlightRow && c < (rowFill * 9).floor()) fill = rowColor;
        if (c == highlightCol && r < (colFill * 9).floor()) fill = colColor;
        if (r == highlightRow && c == highlightCol) {
          fill = rowFill > 0 || colFill > 0
              ? Color.lerp(rowColor, colColor, colFill) ?? rowColor
              : Colors.white;
        }
        canvas.drawRect(
          Rect.fromLTWH(c * cell, r * cell, cell, cell),
          Paint()..color = fill,
        );
      }
    }
    _drawGrid(canvas, size, cell);
  }

  void _drawGrid(Canvas canvas, Size size, double cell) {
    final thin = Paint()
      ..color = _kDark.withValues(alpha: 0.20)
      ..strokeWidth = 0.5;
    final box = Paint()
      ..color = _kDark
      ..strokeWidth = 1.8;
    final outer = Paint()
      ..color = _kDark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 9; i++) {
      final pos = i * cell;
      final p = (i == 0 || i == 9) ? outer : (i % 3 == 0 ? box : thin);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), p);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), p);
    }
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), outer);
  }

  @override
  bool shouldRepaint(_GridRulesPainter o) =>
      o.rowFill != rowFill || o.colFill != colFill;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 2 — Boxes: each of the 9 boxes fades in with its own colour
// ─────────────────────────────────────────────────────────────────────────────

class _BoxesIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _BoxesIllustration({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 216,
        height: 216,
        child: CustomPaint(
          painter: _BoxesPainter(progress: anim.value),
        ),
      ),
    );
  }
}

class _BoxesPainter extends CustomPainter {
  final double progress; // 0-1

  const _BoxesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    // Each box appears in sequence over 0.1-0.9 of progress
    for (int b = 0; b < 9; b++) {
      final boxStart = 0.08 + b * 0.09;
      final alpha = ((progress - boxStart) / 0.10).clamp(0.0, 1.0);
      final br = (b ~/ 3) * 3;
      final bc = (b % 3) * 3;
      final color = _kBoxColors[b].withValues(alpha: alpha * 0.70);
      for (int r = br; r < br + 3; r++) {
        for (int c = bc; c < bc + 3; c++) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell, cell),
            Paint()..color = color,
          );
        }
      }
    }
    _drawGrid(canvas, size, cell);
  }

  void _drawGrid(Canvas canvas, Size size, double cell) {
    final thin = Paint()
      ..color = _kDark.withValues(alpha: 0.18)
      ..strokeWidth = 0.5;
    final box = Paint()
      ..color = _kDark
      ..strokeWidth = 1.8;
    final outer = Paint()
      ..color = _kDark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i <= 9; i++) {
      final pos = i * cell;
      final p = (i == 0 || i == 9) ? outer : (i % 3 == 0 ? box : thin);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), p);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), p);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), outer);
  }

  @override
  bool shouldRepaint(_BoxesPainter o) => o.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 3 — How to Play: hand cursor + 9×9 game demo
// ─────────────────────────────────────────────────────────────────────────────

// 9×9 demo board (Wikipedia puzzle). 0 = empty.
const _demo9x9 = [
  [5, 3, 0, 0, 7, 0, 0, 0, 0],
  [6, 0, 0, 1, 9, 5, 0, 0, 0],
  [0, 9, 8, 0, 0, 0, 0, 6, 0],
  [8, 0, 0, 0, 6, 0, 0, 0, 3],
  [4, 0, 0, 8, 0, 3, 0, 0, 1],
  [7, 0, 0, 0, 2, 0, 0, 0, 6],
  [0, 6, 0, 0, 0, 0, 2, 8, 0],
  [0, 0, 0, 4, 1, 9, 0, 0, 5],
  [0, 0, 0, 0, 8, 0, 0, 7, 9],
];
// Target empty cell and the answer to fill in for the demo
const _demoTargetRow = 0;
const _demoTargetCol = 2;
const _demoAnswer    = 4; // correct value for that cell

class _HowToPlayIllustration extends StatelessWidget {
  final Animation<double> anim;
  final AppLocalizations l;
  const _HowToPlayIllustration({required this.anim, required this.l});

  @override
  Widget build(BuildContext context) {
    final t = anim.value;
    final cellSelected = t > 0.32;
    final numFilled    = t > 0.70;

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      // Grid fills full width; cap height so picker fits below
      const pickerH  = 44.0;
      const pickerGap = 20.0; // label + gap above picker
      final gridSize  = math.min(w, h - pickerH - pickerGap - 8).clamp(120.0, w);
      final cellSize  = (gridSize - _kDemoBorder * 2) / 9;

      // Grid anchored to top-centre
      final gridL = (w - gridSize) / 2;
      const gridT = 0.0;

      // Target cell (row=0, col=2) centre in absolute coords
      final targetCx = gridL + (_demoTargetCol + 0.5) * cellSize;
      final targetCy = gridT + (_demoTargetRow + 0.5) * cellSize;

      // Picker: centred below grid, showing numbers 3 4 5 (answer=4 in middle)
      final pickerTop = gridT + gridSize + pickerGap;
      final pickerCx  = w * 0.50;          // centre key (answer=4)
      final pickerCy  = pickerTop + pickerH / 2;

      // Hand start: just off the right edge of the grid
      final startX = gridL + gridSize + 16;
      final startY = gridT + cellSize * 0.5;

      Offset handPos;
      if (t < 0.15) {
        handPos = Offset(startX, startY);
      } else if (t < 0.34) {
        final p = ((t - 0.15) / 0.19).clamp(0.0, 1.0);
        handPos = Offset(
          lerpDouble(startX, targetCx, p)!,
          lerpDouble(startY, targetCy, p)!,
        );
      } else if (t < 0.56) {
        handPos = Offset(targetCx, targetCy);
      } else if (t < 0.72) {
        final p = ((t - 0.56) / 0.16).clamp(0.0, 1.0);
        handPos = Offset(
          lerpDouble(targetCx, pickerCx, p)!,
          lerpDouble(targetCy, pickerCy, p)!,
        );
      } else {
        handPos = Offset(pickerCx, pickerCy);
      }

      final tapping = (t > 0.33 && t < 0.38) || (t > 0.70 && t < 0.75);

      return Stack(clipBehavior: Clip.hardEdge, children: [
        // 9×9 demo grid
        Positioned(
          left: gridL,
          top: gridT,
          child: _DemoGrid9x9(
            cellSize: cellSize,
            cellSelected: cellSelected,
            numFilled: numFilled,
          ),
        ),

        // Picker label
        Positioned(
          left: 0, right: 0,
          top: gridT + gridSize + 4,
          child: Text(l('sudoku.walkthrough.picker_label'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'ComicRelief', fontSize: 10,
                  color: Colors.white70)),
        ),

        // Mini picker: keys 3 4 5 (answer 4 is the middle key)
        Positioned(
          top: pickerTop,
          left: w / 2 - (pickerH * 3 + 8 * 2) / 2,
          child: Row(
            children: [3, 4, 5].map((n) {
              final isAnswer = n == _demoAnswer;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: pickerH, height: pickerH,
                  decoration: BoxDecoration(
                    color: isAnswer && t > 0.68 && t < 0.78
                        ? Colors.amber.shade300
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.catrinBlue, width: 1.5),
                  ),
                  child: Center(
                      child: BslNumberDisplay(number: n, size: pickerH * 0.68)),
                ),
              );
            }).toList(),
          ),
        ),

        // Animated hand cursor
        if (t > 0.08)
          Positioned(
            left: handPos.dx - 18,
            top:  handPos.dy - 18,
            child: AnimatedScale(
              scale: tapping ? 0.65 : 1.0,
              duration: const Duration(milliseconds: 90),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.touch_app, size: 22, color: _kDark),
              ),
            ),
          ),
      ]);
    });
  }
}

class _DemoGrid9x9 extends StatelessWidget {
  final double cellSize;
  final bool cellSelected;
  final bool numFilled;

  const _DemoGrid9x9({
    required this.cellSize,
    required this.cellSelected,
    required this.numFilled,
  });

  @override
  Widget build(BuildContext context) {
    final gridSize = cellSize * 9 + _kDemoBorder * 2;
    return Container(
      width: gridSize,
      height: gridSize,
      decoration: BoxDecoration(
        color: AppColors.catrinBlue,
        border: Border.all(color: _kDark, width: _kDemoBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Column(
          children: List.generate(9, (row) => SizedBox(
            height: cellSize,
            child: Row(
              children: List.generate(9, (col) {
                final given = _demo9x9[row][col];
                final isTarget = row == _demoTargetRow && col == _demoTargetCol;
                final value = isTarget && numFilled ? _demoAnswer : given;
                Color bg = given != 0
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55);
                if (isTarget && cellSelected) bg = Colors.amber.shade300;

                final isBoxRight  = col == 2 || col == 5;
                final isBoxBottom = row == 2 || row == 5;
                return Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      right: col < 8
                          ? BorderSide(
                              color: isBoxRight ? _kDark : _kDark.withValues(alpha: 0.25),
                              width: isBoxRight ? 1.8 : 0.5)
                          : BorderSide.none,
                      bottom: row < 8
                          ? BorderSide(
                              color: isBoxBottom ? _kDark : _kDark.withValues(alpha: 0.25),
                              width: isBoxBottom ? 1.8 : 0.5)
                          : BorderSide.none,
                    ),
                  ),
                  child: value == 0
                      ? const SizedBox.shrink()
                      : Center(
                          child: BslNumberDisplay(
                              number: value, size: cellSize * 0.70)),
                );
              }),
            ),
          )),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 4 — Hints & Errors: colours appear in sequence, wrong move → red
// Selected cell (4,4). Related = row 4, col 4, box (3-5 × 3-5).
// Same value (5) at (1,5). Conflict: placing 3 conflicts with (4,5)=3.
// ─────────────────────────────────────────────────────────────────────────────

class _HintsErrorsIllustration extends StatefulWidget {
  final Animation<double> anim;
  final AppLocalizations l;
  const _HintsErrorsIllustration({required this.anim, required this.l});

  @override
  State<_HintsErrorsIllustration> createState() =>
      _HintsErrorsIllustrationState();
}

class _HintsErrorsIllustrationState extends State<_HintsErrorsIllustration>
    with TickerProviderStateMixin {
  static const _selRow = 4;
  static const _selCol = 4;

  // 12-second linear controller: 4 phases × 3 s each (0 = selected … 3 = conflict)
  late final AnimationController _seqCtrl;

  // 900 ms oscillator that supplies the breathing pulse value
  late final AnimationController _oscillateCtrl;
  late final Animation<double>   _oscillate;

  bool _seqStarted = false;

  @override
  void initState() {
    super.initState();

    _seqCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _oscillateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _oscillate = CurvedAnimation(parent: _oscillateCtrl, curve: Curves.easeInOut);

    // Stop oscillator when the full sequence finishes
    _seqCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _oscillateCtrl.stop();
    });

    // Watch the stage animation; start the sequence once the fade-in is done
    widget.anim.addListener(_onStageUpdate);
  }

  void _onStageUpdate() {
    if (!_seqStarted && widget.anim.value >= 0.96) {
      _seqStarted = true;
      _seqCtrl.forward();
      _oscillateCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    widget.anim.removeListener(_onStageUpdate);
    _seqCtrl.dispose();
    _oscillateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.anim, _seqCtrl, _oscillateCtrl]),
      builder: (context, _) {
        final t        = widget.anim.value;
        final seqVal   = _seqCtrl.value;
        final seqDone  = _seqCtrl.isCompleted;
        final oscVal   = _oscillate.value;

        // Active pulse phase: 0=selected, 1=related, 2=same, 3=conflict, 4=done
        final phase = seqDone ? 4 : (seqVal * 4).floor().clamp(0, 3);
        final pulseVal = 0.55 + oscVal * 0.45; // breathes 0.55 → 1.0

        // Per-colour pulse mods — only the active phase colour breathes
        final selMod      = (!seqDone && phase == 0) ? pulseVal : 1.0;
        final relatedMod  = (!seqDone && phase == 1) ? pulseVal : 1.0;
        final sameMod     = (!seqDone && phase == 2) ? pulseVal : 1.0;
        final conflictMod = (!seqDone && phase == 3) ? pulseVal : 1.0;

        // Base fade-in alphas from the stage animation
        final relatedRaw = ((t - 0.10) / 0.22).clamp(0.0, 1.0);
        final sameRaw    = ((t - 0.40) / 0.18).clamp(0.0, 1.0);
        final redIn      = ((t - 0.68) / 0.12).clamp(0.0, 1.0);
        // Suppress the fade-OUT once the sequence has started so the conflict
        // colour stays alive for its pulse phase (phase 3)
        final redOut     = _seqStarted ? 0.0 : ((t - 0.88) / 0.08).clamp(0.0, 1.0);
        final redRaw     = (redIn * (1 - redOut)).clamp(0.0, 1.0);

        // Once the sequence is running, freeze faded-in colours at full opacity
        final effRelated  = _seqStarted ? 1.0 : relatedRaw;
        final effSame     = _seqStarted ? 1.0 : sameRaw;
        final effRed      = _seqStarted ? math.max(redRaw, phase >= 3 ? 1.0 : redRaw) : redRaw;

        return LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          const legendH   = 36.0;
          const legendGap = 6.0;
          final gridSize  = math.min(w, h - legendH - legendGap).clamp(120.0, w);
          final cellSize  = (gridSize - _kDemoBorder * 2) / 9;

          return Column(
            children: [
              Center(
                child: _HintsGrid9x9(
                  cellSize: cellSize,
                  selRow: _selRow,
                  selCol: _selCol,
                  effRelated: effRelated,
                  effSame: effSame,
                  effRed: effRed,
                  selMod: selMod,
                  relatedMod: relatedMod,
                  sameMod: sameMod,
                  conflictMod: conflictMod,
                ),
              ),

              const SizedBox(height: legendGap),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InlineLegend(
                    color: Colors.amber.shade300,
                    border: Colors.amber.shade700,
                    label: widget.l('sudoku.walkthrough.legend.selected'),
                    alpha: selMod,
                  ),
                  const SizedBox(width: 8),
                  _InlineLegend(
                    color: Colors.lightBlue.shade100,
                    border: AppColors.catrinBlue,
                    label: widget.l('sudoku.walkthrough.legend.related'),
                    alpha: effRelated * relatedMod,
                  ),
                  const SizedBox(width: 8),
                  _InlineLegend(
                    color: const Color(0xFFCE93D8),
                    border: Colors.purple,
                    label: widget.l('sudoku.walkthrough.legend.same'),
                    alpha: effSame * sameMod,
                  ),
                  const SizedBox(width: 8),
                  _InlineLegend(
                    color: Colors.red.shade200,
                    border: Colors.red,
                    label: widget.l('sudoku.walkthrough.legend.conflict'),
                    alpha: effRed * conflictMod,
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }
}

class _HintsGrid9x9 extends StatelessWidget {
  final double cellSize;
  final int    selRow;
  final int    selCol;
  // Effective alphas (freeze at full once sequence starts; conflict revived for phase 3)
  final double effRelated;
  final double effSame;
  final double effRed;
  // Per-colour pulse mods (0.55-1.0 during active phase, 1.0 otherwise)
  final double selMod;
  final double relatedMod;
  final double sameMod;
  final double conflictMod;

  const _HintsGrid9x9({
    required this.cellSize,
    required this.selRow,
    required this.selCol,
    required this.effRelated,
    required this.effSame,
    required this.effRed,
    required this.selMod,
    required this.relatedMod,
    required this.sameMod,
    required this.conflictMod,
  });

  Color _cellColor(int row, int col) {
    final isSelected = row == selRow && col == selCol;
    final sameBox    = (row ~/ 3 == selRow ~/ 3) && (col ~/ 3 == selCol ~/ 3);
    final isRelated  = (row == selRow || col == selCol || sameBox) && !isSelected;
    final isSame     = row == 1 && col == 5;
    final isConflict = (row == selRow && col == 5) || isSelected;

    if (isSelected && effRed > 0.05) {
      final pulsedAmber = Color.lerp(Colors.white, Colors.amber.shade300, selMod)!;
      return Color.lerp(pulsedAmber, Colors.red.shade200, effRed * conflictMod)!;
    }
    if (isSelected) {
      return Color.lerp(Colors.white, Colors.amber.shade300, selMod)!;
    }
    if (isConflict && effRed > 0.05) {
      return Color.lerp(Colors.white, Colors.red.shade200, effRed * conflictMod)!;
    }
    if (isSame) {
      return Color.lerp(Colors.white, const Color(0xFFCE93D8), effSame * sameMod)!;
    }
    if (isRelated) {
      return Color.lerp(Colors.white, Colors.lightBlue.shade100, effRelated * relatedMod)!;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = cellSize * 9 + _kDemoBorder * 2;
    return Container(
      width: gridSize,
      height: gridSize,
      decoration: BoxDecoration(
        color: AppColors.catrinBlue,
        border: Border.all(color: _kDark, width: _kDemoBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Column(
          children: List.generate(9, (row) => SizedBox(
            height: cellSize,
            child: Row(
              children: List.generate(9, (col) {
                final given = _demo9x9[row][col];
                final isBoxRight  = col == 2 || col == 5;
                final isBoxBottom = row == 2 || row == 5;
                return Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: _cellColor(row, col),
                    border: Border(
                      right: col < 8
                          ? BorderSide(
                              color: isBoxRight ? _kDark : _kDark.withValues(alpha: 0.22),
                              width: isBoxRight ? 1.8 : 0.5)
                          : BorderSide.none,
                      bottom: row < 8
                          ? BorderSide(
                              color: isBoxBottom ? _kDark : _kDark.withValues(alpha: 0.22),
                              width: isBoxBottom ? 1.8 : 0.5)
                          : BorderSide.none,
                    ),
                  ),
                  child: given == 0
                      ? const SizedBox.shrink()
                      : Center(
                          child: BslNumberDisplay(
                              number: given, size: cellSize * 0.70)),
                );
              }),
            ),
          )),
        ),
      ),
    );
  }
}

/// Compact single-row legend item for stage 4.
class _InlineLegend extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;
  final double alpha;

  const _InlineLegend({
    required this.color,
    required this.border,
    required this.label,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: alpha.clamp(0.18, 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: border, width: 1.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 11,
                  color: Colors.white)),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Stage 5 — Ready: difficulty chips + centred Let's Play button
// ─────────────────────────────────────────────────────────────────────────────

class _ReadyIllustration extends StatelessWidget {
  final AppLocalizations l;
  const _ReadyIllustration({required this.l});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DifficultyChip(label: 'Normal',  color: const Color(0xFFE91E8C), note: l('sudoku.walkthrough.step5.normal_note')),
            const SizedBox(height: 10),
            _DifficultyChip(label: 'Hard',    color: const Color(0xFF1565C0), note: l('sudoku.walkthrough.step5.hard_note')),
            const SizedBox(height: 10),
            _DifficultyChip(label: 'Extreme', color: const Color(0xFF2E7D32), note: l('sudoku.walkthrough.step5.extreme_note')),
          ],
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final Color color;
  final String note;

  const _DifficultyChip(
      {required this.label, required this.color, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text(label,
            style: const TextStyle(
              fontFamily: 'ComicRelief', fontSize: 16,
              fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          Text(note,
            style: TextStyle(
              fontFamily: 'ComicRelief', fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

