import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/letter_quest_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/game_header_bar.dart';

class GameHud extends StatelessWidget {
  final int levelNumber;

  final String locale;

  const GameHud({super.key, required this.levelNumber, this.locale = 'en'});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: locale);

    return Consumer<LetterQuestProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) return const SizedBox.shrink();

        final word = provider.currentWord;
        final isComplete = provider.phase == LetterQuestPhase.wordComplete;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: GameHeaderBar(
              onBack: () => Navigator.of(context).pop(),
              scoreLabel: localizer('general.words'),
              scoreValue: '${provider.wordsCompleted}',
              levelNumber: levelNumber,
              centerContent: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    _HudLetterTile(
                      letter: word.letterAt(i),
                      isCollected: word.collected[i],
                      isPulsing: isComplete,
                    ),
                    if (i < 2) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HudLetterTile extends StatefulWidget {
  final String letter;
  final bool isCollected;
  final bool isPulsing;

  const _HudLetterTile({
    required this.letter,
    required this.isCollected,
    required this.isPulsing,
  });

  @override
  State<_HudLetterTile> createState() => _HudLetterTileState();
}

class _HudLetterTileState extends State<_HudLetterTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _HudLetterTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static const double _tileSize = 42.0;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _tileSize,
      height: _tileSize,
      decoration: BoxDecoration(
        color: widget.isCollected ? AppColors.success : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.headerBorderDark,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          widget.letter.toUpperCase(),
          style: TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: widget.isCollected
                ? Colors.white
                : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );

    if (widget.isPulsing) {
      return ScaleTransition(scale: _scaleAnimation, child: child);
    }
    return child;
  }
}
