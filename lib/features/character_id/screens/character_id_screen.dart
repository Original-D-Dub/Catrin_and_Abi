import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../card_matching/widgets/confetti_overlay.dart';
import '../models/mixed_character.dart';
import '../providers/character_id_provider.dart';
import '../widgets/mixed_character_display.dart';

/// Main screen for the Character Identification game.
///
/// Displays:
/// - Level selection screen
/// - Level 1: Clothing colours with colour hints (10 to win)
/// - Level 2: Clothing colours without colour hints (10 to win)
/// - Level 3: Speed Round - 60 seconds
/// - Level 4: Compare Characters (10 to win)
///
/// The player must answer questions about the character to score points.
class CharacterIdScreen extends StatelessWidget {
  const CharacterIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CharacterIdProvider(),
      child: Consumer<CharacterIdProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: provider.showLevelSelect
                ? AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    title: const Text(
                      'Character ID',
                      style: TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: AppSizes.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentWhite,
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.accentWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
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
              child: SafeArea(
                child: provider.showLevelSelect
                    ? _buildBody(context, provider)
                    : Stack(
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildHeaderBar(provider),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildBody(context, provider),
                              ),
                            ],
                          ),

                          // Victory overlay for all levels
                          if (provider.gameState ==
                              CharacterIdGameState.finished)
                            ConfettiOverlay(
                              message: provider.isLevel3
                                  ? "Time's Up!\nYou got ${provider.score} correct!"
                                  : 'Well Done!\nYou got ${provider.score} correct!',
                              playAgainLabel: 'Play Again',
                              homeLabel: 'Home',
                              onPlayAgain: () => provider.resetGame(),
                              onHome: () => Navigator.pop(context),
                              onChangeLevel: () => provider.showLevelSelection(),
                            ),

                          // Back button overlay (top-left)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => provider.showLevelSelection(),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Formats seconds as MM:SS.
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Builds the game header bar with score circle, optional timer, and level.
  Widget _buildHeaderBar(CharacterIdProvider provider) {
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

                      // Centre section: timer for Level 3, level name otherwise
                      if (provider.isLevel3)
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
                                  _formatTime(provider.remainingSeconds),
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

  /// Builds the main body content.
  Widget _buildBody(BuildContext context, CharacterIdProvider provider) {
    // Show loading indicator
    if (provider.gameState == CharacterIdGameState.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error if loading failed
    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentRed,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            ElevatedButton(
              onPressed: () => provider.loadCharacterData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show level selection
    if (provider.showLevelSelect) {
      return _buildLevelSelectScreen(context, provider);
    }

    // Show Level 1, 2, or 3 content (same clothing questions)
    if (provider.isLevel1 || provider.isLevel2 || provider.isLevel3) {
      return _buildLevel1Content(context, provider);
    }

    // Show Level 4 content (Compare Characters)
    return _buildLevel4Content(context, provider);
  }

  /// Builds the level selection screen.
  Widget _buildLevelSelectScreen(
      BuildContext context, CharacterIdProvider provider) {
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
            
            const SizedBox(height: AppSizes.spacingLarge),

            // Level buttons in grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.spacingMedium,
              crossAxisSpacing: AppSizes.spacingMedium,
              childAspectRatio: 1.3,
              children: CharacterIdLevel.all.map((level) {
                return _buildLevelButton(
                  levelNumber: level.number,
                  name: level.name,
                  description: level.description,
                  color: _getLevelColor(level.number),
                  onTap: () => provider.selectLevel(level.number),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the color for a level button.
  Color _getLevelColor(int levelNumber) {
    switch (levelNumber) {
      case 1:
        return AppColors.abiPink;
      case 2:
        return AppColors.accentPurple;
      case 3:
        return AppColors.accentOrange;
      case 4:
        return AppColors.accentLimeGreen;
      default:
        return AppColors.accentOrange;
    }
  }

  /// Builds a level selection button.
  Widget _buildLevelButton({
    required int levelNumber,
    required String name,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
        elevation: 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Level $levelNumber',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXSmall),
          Text(
            name,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeBody,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds Level 1 content (trouser colour question).
  Widget _buildLevel1Content(
      BuildContext context, CharacterIdProvider provider) {
    if (provider.currentMixedCharacter == null) {
      return const Center(
        child: Text('No characters available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final isCompact = constraints.maxHeight < 500;

        if (isLandscape) {
          // Landscape: character on left, question and buttons on right
          return Row(
            children: [
              // Character display
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: MixedCharacterDisplay(
                    character: provider.currentMixedCharacter!,
                  ),
                ),
              ),

              // Question, feedback, and buttons
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Question
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: Text(
                        provider.currentQuestion,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Feedback message
                    SizedBox(
                      height: 50,
                      child: _buildFeedback(provider),
                    ),

                    // Color choice buttons
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: _buildColorChoiceButtons(provider),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Portrait layout
        return Column(
          children: [
            // Question (alternates between trousers and shoes)
            Padding(
              padding: EdgeInsets.all(
                isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
              ),
              child: Text(
                provider.currentQuestion,
                style: TextStyle(
                  fontSize:
                      isCompact ? AppSizes.fontSizeBody : AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Mixed character display (randomised body parts)
            Expanded(
              flex: isCompact ? 2 : 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                  ),
                  child: MixedCharacterDisplay(
                    character: provider.currentMixedCharacter!,
                  ),
                ),
              ),
            ),

            // Feedback message
            SizedBox(
              height: isCompact ? 40 : 50,
              child: _buildFeedback(provider),
            ),

            // Color choice buttons
            Padding(
              padding: EdgeInsets.all(
                isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
              ),
              child: _buildColorChoiceButtons(provider),
            ),

            SizedBox(height: isCompact ? 0 : AppSizes.spacingSmall),
          ],
        );
      },
    );
  }

  /// Builds the color choice buttons for Levels 1, 2, and 3.
  Widget _buildColorChoiceButtons(CharacterIdProvider provider) {
    final choices = provider.answerChoices;
    final isDisabled = provider.gameState != CharacterIdGameState.playing;
    // Level 1 shows colour hints, Level 2 and 3 do not
    final showColourHint = provider.isLevel1;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSizes.spacingMedium,
      runSpacing: AppSizes.spacingMedium,
      children: choices.map((color) {
        final isSelected = provider.selectedAnswer == color;
        final isCorrect = provider.gameState == CharacterIdGameState.correct &&
            isSelected;
        final isWrong =
            provider.gameState == CharacterIdGameState.wrong && isSelected;

        return _buildColorButton(
          colorName: color,
          isSelected: isSelected,
          isCorrect: isCorrect,
          isWrong: isWrong,
          isDisabled: isDisabled,
          showColourHint: showColourHint,
          onPressed: () => provider.selectLevel1Answer(color),
        );
      }).toList(),
    );
  }

  /// Builds a single color choice button with BSL image.
  ///
  /// When [showColourHint] is true (Level 1), shows colour-coded background
  /// and border. When false (Level 2 and 3), shows neutral styling.
  Widget _buildColorButton({
    required String colorName,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required bool isDisabled,
    required bool showColourHint,
    required VoidCallback onPressed,
  }) {
    Color backgroundColor;
    Color borderColor;

    if (isCorrect) {
      backgroundColor = AppColors.success.withValues(alpha: 0.2);
      borderColor = AppColors.success;
    } else if (isWrong) {
      backgroundColor = AppColors.accentRed.withValues(alpha: 0.2);
      borderColor = AppColors.accentRed;
    } else if (showColourHint) {
      // Level 1: Show colour-coded background and border
      final buttonColor = _getColorFromName(colorName);
      backgroundColor = buttonColor.withValues(alpha: 0.15);
      borderColor = buttonColor;
    } else {
      // Level 2 and 3: Neutral styling without colour hints
      backgroundColor = Colors.white;
      borderColor = AppColors.catrinBlue.withValues(alpha: 0.5);
    }

    // Build the BSL image path from the color name
    final imagePath =
        'assets/images/colours_BSL/${colorName.toLowerCase()}.png';

    // Level 1 has padding, Level 2 and 3 have no padding with cover fit
    final buttonPadding = showColourHint
        ? const EdgeInsets.all(AppSizes.paddingSmall)
        : EdgeInsets.zero;
    final imageFit = showColourHint ? BoxFit.contain : BoxFit.cover;

    // Scale up when correct or wrong to provide visual feedback without layout shift
    final scale = (isCorrect || isWrong) ? 1.1 : 1.0;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: buttonPadding,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: isDisabled && !isSelected ? 0.5 : 1.0,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.asset(
                imagePath,
                fit: imageFit,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to text if image not found
                  return Center(
                    child: Text(
                      _capitalise(colorName),
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeBody,
                        fontWeight: FontWeight.bold,
                        color: showColourHint
                            ? _getColorFromName(colorName)
                            : AppColors.textPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Converts a color name to a Color object.
  Color _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'pink':
        return Colors.pink;
      case 'blue':
        return Colors.blue;
      case 'navy':
        return const Color(0xFF000080);
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'brown':
        return Colors.brown;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey.shade300;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return AppColors.catrinBlue;
    }
  }

  /// Capitalises the first letter of a string.
  String _capitalise(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Builds Level 4 content (compare two characters).
  Widget _buildLevel4Content(
      BuildContext context, CharacterIdProvider provider) {
    if (provider.currentMixedCharacter == null ||
        provider.secondMixedCharacter == null) {
      return const Center(
        child: Text('No characters available'),
      );
    }

    final char1 = provider.currentMixedCharacter!;
    final char2 = provider.secondMixedCharacter!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 500;
        final isVeryWide = constraints.maxWidth > 600;

        return Column(
          children: [
            // Question
            Padding(
              padding: EdgeInsets.all(
                isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
              ),
              child: Text(
                provider.level4Question,
                style: TextStyle(
                  fontSize: isCompact
                      ? AppSizes.fontSizeBody
                      : AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Two characters side by side
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryWide
                      ? constraints.maxWidth * 0.1
                      : AppSizes.paddingSmall,
                ),
                child: Row(
                  children: [
                    // First character with name label
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingSmall,
                        ),
                        child: Column(
                          children: [
                            // Character name label
                            Text(
                              char1.identityName,
                              style: TextStyle(
                                fontSize: isCompact
                                    ? AppSizes.fontSizeSmall
                                    : AppSizes.fontSizeBody,
                                fontWeight: FontWeight.bold,
                                color: _getButtonColour(char1.identityName),
                              ),
                            ),
                            SizedBox(
                              height: isCompact
                                  ? AppSizes.spacingXSmall
                                  : AppSizes.spacingSmall,
                            ),
                            // Character display
                            Expanded(
                              child: MixedCharacterDisplay(
                                character: char1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Second character with name label
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingSmall,
                        ),
                        child: Column(
                          children: [
                            // Character name label
                            Text(
                              char2.identityName,
                              style: TextStyle(
                                fontSize: isCompact
                                    ? AppSizes.fontSizeSmall
                                    : AppSizes.fontSizeBody,
                                fontWeight: FontWeight.bold,
                                color: _getButtonColour(char2.identityName),
                              ),
                            ),
                            SizedBox(
                              height: isCompact
                                  ? AppSizes.spacingXSmall
                                  : AppSizes.spacingSmall,
                            ),
                            // Character display
                            Expanded(
                              child: MixedCharacterDisplay(
                                character: char2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Feedback message
            SizedBox(
              height: isCompact ? 40 : 50,
              child: _buildFeedback(provider),
            ),

            // Two answer buttons with character names
            Padding(
              padding: EdgeInsets.all(
                isCompact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
              ),
              child: _buildLevel4AnswerButtons(provider, char1, char2),
            ),

            SizedBox(height: isCompact ? 0 : AppSizes.spacingSmall),
          ],
        );
      },
    );
  }

  /// Builds the two answer buttons for Level 4.
  Widget _buildLevel4AnswerButtons(
    CharacterIdProvider provider,
    MixedCharacter char1,
    MixedCharacter char2,
  ) {
    final isDisabled = provider.gameState != CharacterIdGameState.playing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLevel4AnswerButton(
          name: char1.identityName,
          isSelected: provider.selectedName == char1.identityName,
          isCorrect: provider.gameState == CharacterIdGameState.correct &&
              provider.selectedName == char1.identityName,
          isWrong: provider.gameState == CharacterIdGameState.wrong &&
              provider.selectedName == char1.identityName,
          isDisabled: isDisabled,
          onPressed: () => provider.selectLevel4Answer(char1.identityName),
        ),
        _buildLevel4AnswerButton(
          name: char2.identityName,
          isSelected: provider.selectedName == char2.identityName,
          isCorrect: provider.gameState == CharacterIdGameState.correct &&
              provider.selectedName == char2.identityName,
          isWrong: provider.gameState == CharacterIdGameState.wrong &&
              provider.selectedName == char2.identityName,
          isDisabled: isDisabled,
          onPressed: () => provider.selectLevel4Answer(char2.identityName),
        ),
      ],
    );
  }

  /// Builds a single Level 4 answer button.
  Widget _buildLevel4AnswerButton({
    required String name,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required bool isDisabled,
    required VoidCallback onPressed,
  }) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isCorrect) {
      backgroundColor = AppColors.success.withValues(alpha: 0.2);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isWrong) {
      backgroundColor = AppColors.accentRed.withValues(alpha: 0.2);
      borderColor = AppColors.accentRed;
      textColor = AppColors.accentRed;
    } else {
      backgroundColor = _getButtonColour(name).withValues(alpha: 0.15);
      borderColor = _getButtonColour(name);
      textColor = AppColors.textPrimary;
    }

    // Scale up when correct or wrong to provide visual feedback without layout shift
    final scale = (isCorrect || isWrong) ? 1.1 : 1.0;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge * 1.5,
            vertical: AppSizes.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: isDisabled && !isSelected ? 0.5 : 1.0,
            child: Text(
              name,
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the feedback message area.
  Widget _buildFeedback(CharacterIdProvider provider) {
    if (provider.gameState == CharacterIdGameState.correct) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 28),
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

    if (provider.gameState == CharacterIdGameState.wrong) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, color: AppColors.accentRed, size: 28),
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

    return const SizedBox.shrink();
  }

  /// Returns a colour associated with a character name for buttons.
  Color _getButtonColour(String name) {
    switch (name.toLowerCase()) {
      case 'catrin':
        return AppColors.catrinBlue;
      case 'abi':
        return AppColors.abiPink;
      case 'chris':
        return Colors.amber;
      case 'jo':
        return Colors.orange;
      case 'robin':
        return Colors.green;
      default:
        return AppColors.catrinBlue;
    }
  }
}
