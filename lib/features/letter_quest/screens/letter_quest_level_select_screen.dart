import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_constants.dart';

/// Level selection screen for the Letter Quest game.
///
/// Displays a 2-column grid of level buttons matching the Bubble Pop style.
///
/// Levels:
/// - **Level 1 — Intro Room**: Always available (3 letters only, vertical wall)
/// - **Level 2 — Simple Room**: Always available (beginner level)
/// - **Level 3 — Indoor Rooms**: Always available
/// - **Level 4 — Outdoor Adventure**: Locked until Level 3 completed
///
/// Unlock state is read from [SharedPreferences] using
/// [GameConstants.letterQuestLevel3CompletedKey].
class LetterQuestLevelSelectScreen extends StatefulWidget {
  const LetterQuestLevelSelectScreen({super.key});

  @override
  State<LetterQuestLevelSelectScreen> createState() =>
      _LetterQuestLevelSelectScreenState();
}

class _LetterQuestLevelSelectScreenState
    extends State<LetterQuestLevelSelectScreen> {
  /// Whether Level 4 is unlocked (Level 3 completed at least once)
  bool _level4Unlocked = false;

  /// Whether preferences have finished loading
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUnlockState();
  }

  /// Reads the Level 3 completion flag from SharedPreferences.
  Future<void> _loadUnlockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed =
          prefs.getBool(GameConstants.letterQuestLevel3CompletedKey) ?? false;
      if (mounted) {
        setState(() {
          _level4Unlocked = completed;
          _loaded = true;
        });
      }
    } catch (e) {
      // If prefs fail, keep Level 4 locked and continue
      if (mounted) {
        setState(() {
          _loaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Letter Quest',
          style: TextStyle(
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loaded
            ? _buildLevelSelectContent()
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Builds the level selection content with title and grid.
  Widget _buildLevelSelectContent() {
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

            // Subtitle
            const Text(
              'Move Pero to find the letters to spell the word!',
              style: TextStyle(
                fontSize: AppSizes.fontSizeBody,
                color: AppColors.textSecondary,
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
              children: [
                // Level 1 — Intro Room (always unlocked, 3 letters only)
                _buildLevelButton(
                  levelNumber: 1,
                  name: 'Intro Room',
                  color: AppColors.connectorGold,
                  isLocked: false,
                  onTap: () => _navigateToLevel1(context),
                ),
                // Level 2 — Simple Room (always unlocked, beginner level)
                _buildLevelButton(
                  levelNumber: 2,
                  name: 'Simple Room',
                  color: AppColors.abiPink,
                  isLocked: false,
                  onTap: () => _navigateToLevel2(context),
                ),
                // Level 3 — Indoor Rooms (always unlocked)
                _buildLevelButton(
                  levelNumber: 3,
                  name: 'Indoor Rooms',
                  color: AppColors.accentLimeGreen,
                  isLocked: false,
                  onTap: () => _navigateToLevel3(context),
                ),
                // Level 4 — Outdoor Adventure (locked until Level 3 complete)
                _buildLevelButton(
                  levelNumber: 4,
                  name: 'Outdoor Adventure',
                  color: AppColors.catrinBlue,
                  isLocked: !_level4Unlocked,
                  onTap: _level4Unlocked
                      ? () => _navigateToLevel4(context)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a level selection button.
  ///
  /// Parameters:
  /// - [levelNumber]: The level number to display
  /// - [name]: The level name/description
  /// - [color]: Background color for the button
  /// - [isLocked]: Whether the level is locked
  /// - [onTap]: Callback when button is tapped (null if locked)
  Widget _buildLevelButton({
    required int levelNumber,
    required String name,
    required Color color,
    required bool isLocked,
    required VoidCallback? onTap,
  }) {
    // Use grey color for locked levels
    final buttonColor = isLocked ? AppColors.textSecondary : color;

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
        ),
        // Reduce elevation for locked buttons
        elevation: isLocked ? 0 : 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lock icon for locked levels, level number for unlocked
          if (isLocked) ...[
            const Icon(
              Icons.lock,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(height: AppSizes.spacingXSmall),
          ],
          Text(
            'Level $levelNumber',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXSmall),
          Text(
            isLocked ? 'Complete Level 3' : name,
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

  /// Navigates to Level 1 (intro room).
  void _navigateToLevel1(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.letterQuestLevel1);
  }

  /// Navigates to Level 2 (simple room).
  void _navigateToLevel2(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.letterQuestLevel2);
  }

  /// Navigates to Level 3 (indoor rooms).
  void _navigateToLevel3(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.letterQuestLevel3);
  }

  /// Navigates to Level 4 (outdoor adventure).
  void _navigateToLevel4(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.letterQuestLevel4);
  }
}
