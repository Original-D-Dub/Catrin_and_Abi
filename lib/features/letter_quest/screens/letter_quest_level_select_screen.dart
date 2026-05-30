import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/routes.dart';
import '../../../core/constants/game_constants.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_app_bar.dart';
import '../../../shared/widgets/level_select_screen.dart';

/// Level selection screen for the Letter Quest game.
///
/// Levels:
/// - **Level 1 — Intro Room**: Always available (3 letters only)
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
      extendBodyBehindAppBar: true,
      appBar: GameAppBar(
        title: 'Letter Quest',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/backgrounds/math-background-1080x1920.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _loaded
              ? _buildLevelSelect(context)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildLevelSelect(BuildContext context) {
    return LevelSelectScreen(
      subtitle: 'Move Pero to find the letters to spell the word!',
      levels: [
        LevelSelectItem(
          number: 1,
          name: 'Intro Room',
          color: levelColor(0),
          onTap: () {
            AudioService.playIntro('letter_quest_1');
            Navigator.pushNamed(context, AppRoutes.letterQuestLevel1);
          },
        ),
        LevelSelectItem(
          number: 2,
          name: 'Simple Room',
          color: levelColor(1),
          onTap: () {
            AudioService.playIntro('letter_quest_2');
            Navigator.pushNamed(context, AppRoutes.letterQuestLevel2);
          },
        ),
        LevelSelectItem(
          number: 3,
          name: 'Indoor Rooms',
          color: levelColor(2),
          onTap: () {
            AudioService.playIntro('letter_quest_3');
            Navigator.pushNamed(context, AppRoutes.letterQuestLevel3);
          },
        ),
        LevelSelectItem(
          number: 4,
          name: 'Outdoor Adventure',
          color: levelColor(3),
          isLocked: !_level4Unlocked,
          onTap: () {
            AudioService.playIntro('letter_quest_4');
            Navigator.pushNamed(context, AppRoutes.letterQuestLevel4);
          },
        ),
      ],
    );
  }
}
