import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/tts_helper.dart';
import '../models/maths_question.dart';
import '../providers/bsl_maths_provider.dart';
import '../widgets/bsl_keyboard.dart';
import '../widgets/bsl_number_display.dart';

/// Main screen for the BSL Maths addition game.
///
/// Displays:
/// - Level selection screen (Bubble Pop style)
/// - AppBar with level name and score badge
/// - Question display: [BSL operand1] + [BSL operand2] = [answer slot(s)]
/// - Feedback area: "Correct!" with green tick or "Try again!" message
/// - BSL number keyboard with C (clear) button
///
/// Level 1: Single answer slot (sums 2-10)
/// Level 2: Two answer slots for tens/units (sums 2-20)
///
/// Uses [Consumer<BslMathsProvider>] to rebuild when game state changes.
class BslMathsScreen extends StatefulWidget {
  const BslMathsScreen({super.key});

  @override
  State<BslMathsScreen> createState() => _BslMathsScreenState();
}

class _BslMathsScreenState extends State<BslMathsScreen> {
  /// Size of BSL number SVGs in the question display area
  static const double _questionSvgSize = 80.0;

  /// Size of the answer slot box
  static const double _answerSlotSize = 80.0;

  /// TTS engine for level instructions
  final FlutterTts _tts = FlutterTts();

  /// TTS instructions per level number
  static const Map<int, String> _levelInstructions = {
    1: 'Use the keyboard to answer the sums',
    2: "What number do you need to add to make ten?",
    3: 'Type your answer. Then press the equals to see if you are right',
    4: "What's the number that will make this sum correct",
    5: 'How many can you get right in a minute? One point for a right answer and lose one point for a wrong answer.',
  };

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await TtsHelper.configure(_tts);
  }

  /// Speaks the instruction for the given level number.
  Future<void> _speakLevelInstruction(int levelNumber) async {
    final instruction = _levelInstructions[levelNumber];
    if (instruction != null) {
      await _tts.speak(instruction);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BslMathsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: provider.showLevelSelect
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    'BSL Maths',
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentWhite,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.accentWhite),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                )
              : null,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgrounds/math-background-1080x1920.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: provider.showLevelSelect
                  ? _buildLevelSelectScreen(context, provider)
                  : Stack(
                      children: [
                        _buildGameContent(context, provider),
                        if (provider.gameState == BslMathsGameState.timeUp)
                          _buildTimeUpOverlay(provider),
                        // Back button overlay (top-left)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => provider.showLevelSelection(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the level selection screen matching Bubble Pop style.
  Widget _buildLevelSelectScreen(
    BuildContext context,
    BslMathsProvider provider,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'Choose a Level',
              style: TextStyle(
                fontSize: AppSizes.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            const Text(
              'Learn BSL numbers with addition!',
              style: TextStyle(
                fontSize: AppSizes.fontSizeBody,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingLarge),

            // Level buttons in 2-column grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.spacingMedium,
              crossAxisSpacing: AppSizes.spacingMedium,
              childAspectRatio: 1.3,
              children: BslMathsLevel.all.map((level) {
                return _buildLevelButton(
                  context: context,
                  provider: provider,
                  level: level,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a level selection button matching Bubble Pop style.
  Widget _buildLevelButton({
    required BuildContext context,
    required BslMathsProvider provider,
    required BslMathsLevel level,
  }) {
    // Assign colors to each level (one per level, cycles if more levels added)
    final levelColors = [
      AppColors.abiPink,
      AppColors.accentPurple,
      AppColors.accentLimeGreen,
      AppColors.accentOrange,
      AppColors.accentNavyBlue,
    ];
    final color = levelColors[(level.number - 1) % levelColors.length];

    return ElevatedButton(
      onPressed: () {
        provider.setLevel(level.number);
        provider.startGame();
        _speakLevelInstruction(level.number);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Level ${level.number}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXSmall),
          Text(
            level.name,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeBody,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the main game content.
  Widget _buildGameContent(BuildContext context, BslMathsProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildHeaderBar(provider),
        const SizedBox(height: 12),

        // Question + feedback in glass container
        Expanded(
          //flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingSmall,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizes.paddingMedium),

                      // Question display area (BSL SVG operands + answer slot(s))
                      Expanded(
                        child: _buildQuestionDisplay(provider),
                      ),

                      // Feedback area (correct/wrong message)
                      SizedBox(
                        height: 44,
                        child: _buildFeedback(provider),
                      ),

                      const SizedBox(height: AppSizes.spacingSmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const Spacer(),

        // BSL number keyboard — fixed height, pinned to bottom
        SizedBox(
          height: 360,
          child: BslKeyboard(
            onKeyPressed: (number) => provider.enterDigit(number),
            onClearPressed: () => provider.clearAnswer(),
            onSubmitPressed: () => provider.submitAnswer(),
            isDisabled: provider.isInputLocked,
            enteredAnswer: provider.enteredAnswer,
            isCorrect: provider.gameState == BslMathsGameState.correct
                ? true
                : provider.gameState == BslMathsGameState.wrong
                    ? false
                    : null,
            showZeroKey: provider.requiresTwoDigitInput,
          ),
        ),

        const SizedBox(height: AppSizes.spacingSmall),
      ],
    );
  }

  /// Formats seconds as MM:SS.
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Builds the game header bar with score circle, optional timer, and level.
  Widget _buildHeaderBar(BslMathsProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: SizedBox(
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Purple header rectangle
            Positioned(
              left: 40,
              right: 0,
              top: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.headerBackgroundLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.headerBorderDark,
                    width: 2,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.headerBorderDark,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Spacer for score circle area
                      const SizedBox(width: 48),

                      // Centre section: timer for competition, level name otherwise
                      if (provider.isCompetitionLevel)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Time',
                                style: TextStyle(
                                  fontFamily: 'ComicRelief',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.timeContainer,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  _formatTime(provider.secondsRemaining),
                                  style: const TextStyle(
                                    fontFamily: 'ComicRelief',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (provider.currentLevel.name.isNotEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              provider.currentLevel.name,
                              style: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        const Spacer(),

                      // Level section (right)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Level',
                              style: TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${provider.currentLevel.number}',
                              style: const TextStyle(
                                fontFamily: 'ComicRelief',
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Score circle (overlapping left edge)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.headerBackgroundLight,
                    border: Border.all(
                      color: AppColors.headerBorderDark,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.headerBackground,
                      border: Border.all(
                        color: AppColors.headerBorderDark,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Score',
                          style: TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${provider.score}',
                          style: const TextStyle(
                            fontFamily: 'ComicRelief',
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "Time's Up" overlay for competition mode.
  Widget _buildTimeUpOverlay(BslMathsProvider provider) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Time's Up!",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.accentWhite,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              'Score: ${provider.score}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.connectorGold,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            ElevatedButton(
              onPressed: () => provider.showLevelSelection(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.catrinBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLarge,
                  vertical: AppSizes.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusMedium),
                ),
              ),
              child: const Text(
                'Back to Levels',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the question display showing BSL SVG operands and answer slot(s).
  ///
  /// Normal levels: operand1 + operand2 = [?]
  /// Missing operand level (Level 3): operand1 + [?] = answer
  Widget _buildQuestionDisplay(BslMathsProvider provider) {
    final question = provider.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    // Level 3: Show "operand1 + ? = answer" format
    if (provider.isMissingOperandLevel) {
      return _buildMissingOperandDisplay(provider, question);
    }

    // Normal levels: Show "operand1 + operand2 = ?" format
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          
        
          children: [
            // First operand (BSL hand sign SVG)
            BslNumberDisplay(
              number: question.operand1,
              size: _questionSvgSize,
            ),

            // Plus sign
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Second operand (BSL hand sign SVG)
            BslNumberDisplay(
              number: question.operand2,
              size: _questionSvgSize,
            ),

            // Equals sign
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
              child: Text(
                '=',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Answer slot(s)
            if (provider.requiresTwoDigitInput)
              _buildTwoDigitAnswerSlots(provider)
            else
              _buildSingleAnswerSlot(provider),
          ],
        ),
      ),
    );
  }

  /// Builds the question display for "find the missing number" format.
  ///
  /// Shows: operand1 + [?] = answer
  Widget _buildMissingOperandDisplay(
    BslMathsProvider provider,
    MathsQuestion question,
  ) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // First operand (BSL hand sign SVG)
            BslNumberDisplay(
              number: question.operand1,
              size: _questionSvgSize,
            ),

            // Plus sign
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Missing operand slot (player's answer goes here)
            _buildSingleAnswerSlot(provider),

            // Equals sign
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingSmall),
              child: Text(
                '=',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Answer (the sum - shown as BSL hand sign)
            BslNumberDisplay(
              number: question.answer,
              size: _questionSvgSize,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single answer slot for Level 1 (answers 2-10).
  Widget _buildSingleAnswerSlot(BslMathsProvider provider) {
    if (provider.unitsDigit == null) {
      // No answer yet - show question mark placeholder
      return Container(
        width: _answerSlotSize,
        height: _answerSlotSize,
        decoration: BoxDecoration(
          color: AppColors.mathBackground.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          border: Border.all(
            color: AppColors.accentWhite.withValues(alpha: 0.75),
            width: 2,
          ),
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: AppSizes.fontSizeTitle,
              fontWeight: FontWeight.bold,
              color: AppColors.accentWhite,
            ),
          ),
        ),
      );
    }

    // Answer submitted - show numeral with green (correct) or red (wrong) styling
    final isCorrect = provider.gameState == BslMathsGameState.correct;
    final isWrong = provider.gameState == BslMathsGameState.wrong;
    final color = isCorrect
        ? AppColors.success
        : isWrong
            ? AppColors.accentRed
            : AppColors.catrinBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: _answerSlotSize,
      height: _answerSlotSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: color,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          '${provider.enteredAnswer}',
          style: TextStyle(
            fontSize: AppSizes.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Builds two answer slots for Level 2 (tens column left, units column right).
  Widget _buildTwoDigitAnswerSlots(BslMathsProvider provider) {
    final isCorrect = provider.gameState == BslMathsGameState.correct;
    final isWrong = provider.gameState == BslMathsGameState.wrong;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tens column (left)
        _buildDigitSlot(
          digit: provider.tensDigit,
          isCorrect: isCorrect,
          isWrong: isWrong,
        ),
        const SizedBox(width: AppSizes.spacingSmall),
        // Units column (right)
        _buildDigitSlot(
          digit: provider.unitsDigit,
          isCorrect: isCorrect,
          isWrong: isWrong,
        ),
      ],
    );
  }

  /// Builds a single digit slot for two-digit answers.
  Widget _buildDigitSlot({
    required int? digit,
    required bool isCorrect,
    required bool isWrong,
  }) {
    final hasDigit = digit != null;
    final color = isCorrect
        ? AppColors.success
        : isWrong
            ? AppColors.accentRed
            : AppColors.accentWhite;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: _answerSlotSize * 0.8,
      height: _answerSlotSize,
      decoration: BoxDecoration(
        color: hasDigit
            ? color.withValues(alpha: 0.2)
            : AppColors.mathBackground.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        border: Border.all(
          color: hasDigit ? AppColors.textPrimary : AppColors.accentWhite.withValues(alpha:0.4),
          width: hasDigit ? 3 : 2,
        ),
      ),
      child: Center(
        child: hasDigit
            ? Text(
                '$digit',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              )
            : Text(
                '?',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
      ),
    );
  }

  /// Builds the feedback text area below the question display.
  Widget _buildFeedback(BslMathsProvider provider) {
    if (provider.gameState == BslMathsGameState.correct) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: AppSizes.iconLarge,
          ),
          SizedBox(width: AppSizes.spacingSmall),
          Text(
            'Correct!',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      );
    }

    if (provider.gameState == BslMathsGameState.wrong) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.refresh,
            color: AppColors.accentRed,
            size: AppSizes.iconLarge,
          ),
          SizedBox(width: AppSizes.spacingSmall),
          Text(
            'Try again!',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.accentRed,
            ),
          ),
        ],
      );
    }

    // // Playing state - show hint for Level 2
    // if (provider.requiresTwoDigitInput && provider.enteredAnswer != null) {
    //   return Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       const Icon(
    //         Icons.touch_app,
    //         color: AppColors.textSecondary,
    //         size: AppSizes.iconMedium,
    //       ),
    //       const SizedBox(width: AppSizes.spacingSmall),
    //       Text(
    //         'Tap = to submit (${provider.enteredAnswer})',
    //         style: const TextStyle(
    //           fontSize: AppSizes.fontSizeBody,
    //           color: AppColors.textSecondary,
    //         ),
    //       ),
    //     ],
    //   );
    // }

    return const SizedBox.shrink();
  }
}
