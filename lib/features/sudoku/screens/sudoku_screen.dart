import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../../../shared/widgets/level_select_screen.dart';
import '../../bsl_maths/widgets/bsl_number_display.dart';
import '../models/sudoku_models.dart';
import '../providers/sudoku_provider.dart';
import '../widgets/sudoku_walkthrough.dart';

class SudokuScreen extends StatelessWidget {
  final String locale;

  const SudokuScreen({super.key, this.locale = 'en'});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SudokuProvider(),
      child: _SudokuBody(locale: locale),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SudokuBody extends StatefulWidget {
  final String locale;

  const _SudokuBody({required this.locale});

  @override
  State<_SudokuBody> createState() => _SudokuBodyState();
}

class _SudokuBodyState extends State<_SudokuBody> {
  bool _showWalkthrough = false;

  static const _prefsKey = 'sudoku_walkthrough_seen';

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_prefsKey) ?? false) && mounted) {
      setState(() => _showWalkthrough = true);
    }
  }

  Future<void> _dismissWalkthrough() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (mounted) setState(() => _showWalkthrough = false);
  }

  static String _difficultyLabel(SudokuDifficulty d, AppLocalizations localizer) =>
      switch (d) {
        SudokuDifficulty.mini     => localizer('sudoku.difficulty.mini'),
        SudokuDifficulty.sixBySix => localizer('sudoku.difficulty.six_by_six'),
        SudokuDifficulty.normal   => localizer('sudoku.difficulty.easy'),
        SudokuDifficulty.hard     => localizer('sudoku.difficulty.hard'),
        SudokuDifficulty.extreme  => localizer('sudoku.difficulty.extreme'),
      };

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    return Consumer<SudokuProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? GameAppBar(
                  title: localizer('sudoku.title'),
                  onBack: () => Navigator.of(context).pop(),
                )
              : null,
          body: Stack(
            children: [
              // ── Background ───────────────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  'assets/backgrounds/math-background-1080x1920.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              // ── All content sits inside SafeArea ─────────────────────────
              SafeArea(
                child: provider.showLevelSelect
                    ? _buildLevelSelect(context, provider, localizer)
                    : _buildGame(context, provider, localizer),
              ),

              // ── Success overlay ──────────────────────────────────────────
              if (!provider.showLevelSelect && provider.isComplete)
                Positioned.fill(
                  child: GameSuccessOverlay(
                    gameId: 'sudoku',
                    scoreStyle: SuccessScoreStyle.custom,
                    customScoreLine: localizer('sudoku.puzzle_solved'),
                    showPersonalBest: false,
                    locale: widget.locale,
                    onPlayAgain: () => provider.nextPuzzle(),
                    onChangeLevel: () => provider.showLevelSelection(),
                  ),
                ),

              // ── Walkthrough — shown once to new players ───────────────────
              if (_showWalkthrough)
                Positioned.fill(
                  child: SudokuWalkthrough(onComplete: _dismissWalkthrough),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Game content (grid fills first, picker shrinks to fit) ────────────────

  Widget _buildGame(
      BuildContext context, SudokuProvider provider, AppLocalizations localizer) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Grid gets the square space first
        const minGrid = 180.0;
        const maxGrid = 600.0;
        final gridSize = math.min(w - 24.0, h * 0.55).clamp(minGrid, maxGrid);

        // Picker fills what remains after grid + fixed chrome
        final pickerCols    = math.max(provider.boxWidth, provider.boxHeight);
        final pickerRows    = provider.gridSize ~/ pickerCols;
        const pickerSpacing = 8.0;
        const actionBtnH    = 44.0;
        const totalSpacerH  = 4.0 + 8.0 + 8.0 + 8.0; // top + gaps + bottom
        final pickerTotalH  = h - gridSize - totalSpacerH - actionBtnH;
        final cellSize = ((pickerTotalH - pickerSpacing * (pickerRows - 1)) / pickerRows)
            .clamp(44.0, 96.0);

        return Column(
          children: [
            GameHeaderBar(
              onBack: () => provider.showLevelSelection(),
              showScore: false,
              showLevel: false,
              centerContent: Center(
                child: Text(
                  _difficultyLabel(provider.difficulty, localizer),
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Center(
              child: _SudokuGrid(provider: provider, size: gridSize),
            ),

            const SizedBox(height: 8),

            _NumberPicker(provider: provider, cellSize: cellSize),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  label: localizer('sudoku.clear'),
                  icon: Icons.backspace_outlined,
                  onTap: provider.clearSelectedCell,
                ),
                const SizedBox(width: 16),
                _ActionButton(
                  label: localizer('sudoku.new_puzzle'),
                  icon: Icons.refresh,
                  onTap: provider.nextPuzzle,
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ── Level select ──────────────────────────────────────────────────────────

  Widget _buildLevelSelect(
      BuildContext context, SudokuProvider provider, AppLocalizations localizer) {
    return Column(
      children: [
        Expanded(
          child: LevelSelectScreen(
            subtitle: localizer('sudoku.subtitle'),
            locale: localizer.locale,
            levels: [
              LevelSelectItem(
                number: 1,
                description: localizer('sudoku.level1.description'),
                displayLabel: localizer('sudoku.difficulty.mini'),
                color: levelColor(0),
                onTap: () =>
                    provider.selectDifficulty(SudokuDifficulty.mini),
              ),
              LevelSelectItem(
                number: 2,
                description: localizer('sudoku.level2.description'),
                displayLabel: localizer('sudoku.difficulty.six_by_six'),
                color: levelColor(1),
                onTap: () =>
                    provider.selectDifficulty(SudokuDifficulty.sixBySix),
              ),
              LevelSelectItem(
                number: 3,
                description: localizer('sudoku.level3.description'),
                displayLabel: localizer('sudoku.difficulty.easy'),
                color: levelColor(2),
                onTap: () =>
                    provider.selectDifficulty(SudokuDifficulty.normal),
              ),
              LevelSelectItem(
                number: 4,
                description: localizer('sudoku.level4.description'),
                displayLabel: localizer('sudoku.difficulty.hard'),
                color: levelColor(3),
                onTap: () =>
                    provider.selectDifficulty(SudokuDifficulty.hard),
              ),
              LevelSelectItem(
                number: 5,
                description: localizer('sudoku.level5.description'),
                displayLabel: localizer('sudoku.difficulty.extreme'),
                color: levelColor(4),
                onTap: () =>
                    provider.selectDifficulty(SudokuDifficulty.extreme),
              ),
            ],
          ),
        ),

        // ── Expert mode toggle ─────────────────────────────────────────────
        _ExpertModeToggle(provider: provider, localizer: localizer),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expert mode toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertModeToggle extends StatelessWidget {
  final SudokuProvider provider;
  final AppLocalizations localizer;

  const _ExpertModeToggle({required this.provider, required this.localizer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: provider.expertMode
                ? const Color(0xFF1A237E)
                : AppColors.catrinBlue,
            width: provider.expertMode ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.psychology_outlined,
              color: provider.expertMode
                  ? const Color(0xFF1A237E)
                  : AppColors.catrinBlue,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizer('sudoku.expert_mode'),
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: provider.expertMode
                          ? const Color(0xFF1A237E)
                          : AppColors.catrinBlue,
                    ),
                  ),
                  Text(
                    localizer('sudoku.expert_mode_subtitle'),
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: provider.expertMode,
              onChanged: (_) => provider.toggleExpertMode(),
              activeThumbColor: const Color(0xFF1A237E),
              activeTrackColor:
                  const Color(0xFF1A237E).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid
// ─────────────────────────────────────────────────────────────────────────────

class _SudokuGrid extends StatelessWidget {
  final SudokuProvider provider;
  final double size;

  const _SudokuGrid({required this.provider, required this.size});

  static const double _outerBorder = 2.5;
  static const double _boxBorder   = 2.5;
  static const double _cellBorder  = 0.8;

  static const Color _darkBlue     = Color(0xFF1A237E);
  static const Color _boxLineColor  = _darkBlue;
  static final Color _cellLineColor = _darkBlue.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final gridSize = provider.gridSize;
    final cellSize = (size - _outerBorder * 2) / gridSize;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.catrinBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: _outerBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: List.generate(gridSize, (row) {
            return SizedBox(
              height: cellSize,
              child: Row(
                children: List.generate(gridSize, (col) {
                  return _buildCell(context, row, col, cellSize);
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCell(
      BuildContext context, int row, int col, double cellSize) {
    final cell = provider.grid[row][col];
    final gridSize = provider.gridSize;
    final boxWidth = provider.boxWidth;
    final boxHeight = provider.boxHeight;
    final isSelected =
        provider.selectedRow == row && provider.selectedCol == col;
    final selRow = provider.selectedRow;
    final selCol = provider.selectedCol;
    final expert = provider.expertMode;

    Color bg;
    if (isSelected) {
      bg = Colors.amber.shade300;
    } else if (cell.hasError) {
      bg = Colors.red.shade200;
    } else if (!expert && selRow != null && selCol != null) {
      final sameBox =
          (row ~/ boxHeight == selRow ~/ boxHeight) && (col ~/ boxWidth == selCol ~/ boxWidth);
      final related = row == selRow || col == selCol || sameBox;
      final selVal = provider.grid[selRow][selCol].value;
      if (selVal != 0 && cell.value == selVal) {
        bg = const Color(0xFFCE93D8);
      } else if (related) {
        bg = Colors.lightBlue.shade50.withValues(alpha: 0.5);
      } else {
        bg = cell.isGiven
            ? Colors.white
            : Colors.white.withValues(alpha: 0.88);
      }
    } else {
      bg = cell.isGiven
          ? Colors.white
          : Colors.white.withValues(alpha: 0.88);
    }

    final isBoxRight  = (col + 1) % boxWidth == 0;
    final isBoxBottom = (row + 1) % boxHeight == 0;
    final rightW  = col == gridSize - 1 ? 0.0 : (isBoxRight  ? _boxBorder : _cellBorder);
    final bottomW = row == gridSize - 1 ? 0.0 : (isBoxBottom ? _boxBorder : _cellBorder);

    return GestureDetector(
      onTap: () => provider.selectCell(row, col),
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            right: rightW > 0
                ? BorderSide(
                    color: isBoxRight ? _boxLineColor : _cellLineColor,
                    width: rightW)
                : BorderSide.none,
            bottom: bottomW > 0
                ? BorderSide(
                    color: isBoxBottom ? _boxLineColor : _cellLineColor,
                    width: bottomW)
                : BorderSide.none,
          ),
        ),
        child: cell.value == 0
            ? const SizedBox.shrink()
            : _CellSymbol(
                value: cell.value,
                cellSize: cellSize,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cell BSL symbol
// ─────────────────────────────────────────────────────────────────────────────

class _CellSymbol extends StatelessWidget {
  final int value;
  final double cellSize;

  const _CellSymbol({required this.value, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    final imgSize = (cellSize * 0.78).clamp(14.0, 56.0);
    return Center(
      child: BslNumberDisplay(number: value, size: imgSize),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Number picker — 3 × 3 grid of BSL signs, size derived from available height
// ─────────────────────────────────────────────────────────────────────────────

class _NumberPicker extends StatelessWidget {
  final SudokuProvider provider;
  final double cellSize;

  const _NumberPicker({required this.provider, required this.cellSize});

  static const double _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final cols = math.max(provider.boxWidth, provider.boxHeight);
    final rows = provider.gridSize ~/ cols;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row < rows - 1 ? _spacing : 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cols, (col) {
              final n = row * cols + col + 1;
              return Padding(
                padding: EdgeInsets.only(right: col < cols - 1 ? _spacing : 0),
                child: _NumberKey(
                  number: n,
                  size: cellSize,
                  isSelected: provider.selectedNumber == n,
                  onTap: () => provider.selectNumber(n),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _NumberKey extends StatelessWidget {
  final int number;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  const _NumberKey({
    required this.number,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.shade300
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amber.shade700 : AppColors.catrinBlue,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: BslNumberDisplay(number: number, size: size * 0.72),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.catrinBlue, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.catrinBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.catrinBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
