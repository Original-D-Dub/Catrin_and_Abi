import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/welcome/screens/welcome_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/welsh_home_screen.dart';
import '../../features/card_matching/screens/card_game_screen.dart';
import '../../features/card_matching/providers/card_game_provider.dart';
import '../../features/bubble_pop/screens/bubble_pop_screen.dart';
import '../../features/bubble_pop/providers/bubble_pop_provider.dart';
import '../../features/colouring/screens/colouring_screen.dart';
import '../../features/colouring/providers/colouring_provider.dart';
import '../../features/vowel_hand/screens/vowel_hand_screen.dart';
import '../../features/vowel_hand/providers/vowel_hand_provider.dart';
import '../../features/bsl_maths/screens/bsl_maths_screen.dart';
import '../../features/bsl_maths/providers/bsl_maths_provider.dart';
import '../../features/letter_quest/screens/bungalow_quest_screen.dart';
import '../../features/letter_quest/screens/letter_quest_screen.dart';
import '../../features/letter_quest/screens/letter_quest_level_select_screen.dart';
import '../../features/letter_quest/screens/outdoor_quest_screen.dart';
import '../../features/letter_quest/screens/level2_quest_screen.dart';
import '../../features/letter_quest/screens/house_quest_screen.dart';
import '../../features/letter_quest/screens/intro_quest_screen.dart';
import '../../features/letter_quest/providers/letter_quest_provider.dart';
import '../../features/character_id/screens/character_id_screen.dart';
import '../../features/letter_bingo/screens/letter_bingo_screen.dart';
import '../../features/letter_bingo/screens/animal_collection_screen.dart';
import '../../features/letter_bingo/providers/letter_bingo_provider.dart';
import '../../features/counting_game/screens/counting_game_screen.dart';
import '../../features/counting_game/providers/counting_game_provider.dart';
import '../../features/number_line/screens/number_line_screen.dart';
import '../../features/number_line/providers/number_line_provider.dart';
import '../../features/counting_back/screens/counting_back_screen.dart';
import '../../features/counting_back/providers/counting_back_provider.dart';
import '../../features/bsl_sprint/screens/bsl_sprint_screen.dart';
import '../../features/bsl_sprint/providers/bsl_sprint_provider.dart';
import '../../features/clothes_line/screens/clothes_line_screen.dart';
import '../../features/clothes_line/providers/clothes_line_provider.dart';
import '../../features/more_or_less/screens/more_or_less_screen.dart';
import '../../features/more_or_less/providers/more_or_less_provider.dart';
import '../../features/sudoku/screens/sudoku_screen.dart';
import '../../features/privacy/screens/privacy_policy_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/videos_screen.dart';
import '../../features/profile/screens/scores_screen.dart';
import '../../features/profile/screens/profile_settings_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/word_whirl/providers/word_whirl_provider.dart';
import '../../features/word_whirl/screens/word_whirl_screen.dart';
import '../../features/number_race/providers/number_race_provider.dart';
import '../../features/number_race/screens/number_race_screen.dart';
import '../../features/zoo/models/enclosure_level_config.dart';
import '../../features/zoo/providers/enclosure_walk_provider.dart';
import '../../features/zoo/models/zoo_animal_zone.dart';
import '../../features/zoo/providers/zoo_provider.dart';
import '../../features/zoo/providers/zoo_quiz_provider.dart';
import '../../features/zoo/screens/enclosure_walk_screen.dart';
import '../../features/zoo/screens/zoo_level_select_screen.dart';
import '../../features/zoo/screens/zoo_quiz_screen.dart';
import '../../features/zoo/screens/zoo_screen.dart';
import '../../features/zoo/screens/zoo_building_screen.dart';
import '../../features/zoo/screens/zoo_pick_player_screen.dart';
import '../../features/zoo/screens/zoo_player_screen.dart';
import '../../features/zoo/screens/zoo_start_screen.dart';
import '../../shared/services/settings_provider.dart';
import '../constants/game_filters.dart';

/// Named route constants for navigation throughout the app.
///
/// Usage:
/// ```dart
/// Navigator.pushNamed(context, AppRoutes.home);
/// Navigator.pushReplacementNamed(context, AppRoutes.cardMatching);
/// ```
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  /// Splash screen
  static const String splash = '/';

  /// Welcome/introduction screen
  static const String welcome = '/welcome';

  /// Home screen with game selection
  static const String home = '/home';

  /// Card matching game
  static const String cardMatching = '/games/card-matching';

  /// Welsh home screen (Cymraeg game selection)
  static const String welshHome = '/welsh-home';

  /// Bubble pop game
  static const String bubblePop = '/games/bubble-pop';

  /// Colouring game
  static const String colouring = '/games/colouring';

  /// BSL vowel hand game
  static const String vowelHand = '/games/vowel-hand';

  /// BSL maths game (addition with BSL number signs)
  static const String bslMaths = '/games/bsl-maths';

  /// RPG letter collection game — level select
  static const String letterQuest = '/games/letter-quest';

  /// Letter Quest Level 1 (intro room — 3 letters only, vertical wall)
  static const String letterQuestLevel1 = '/games/letter-quest/level-1';

  /// Letter Quest Level 2 (simple room)
  static const String letterQuestLevel2 = '/games/letter-quest/level-2';

  /// Letter Quest House level (top floor of Catrin & Abi's house)
  static const String letterQuestHouse = '/games/letter-quest/house';

  /// Letter Quest Level 3 (indoor rooms)
  static const String letterQuestLevel3 = '/games/letter-quest/level-3';

  /// Letter Quest Level 5 — Bungalow (Gary chase)
  static const String letterQuestBungalow = '/games/letter-quest/bungalow';

  /// Letter Quest Level 6 (outdoor adventure)
  static const String letterQuestLevel4 = '/games/letter-quest/level-4';

  /// Ear game (placeholder for future)
  static const String earGame = '/games/ear-game';

  /// Letter Bingo game (BSL letter matching bingo)
  static const String letterBingo = '/games/letter-bingo';

  /// Character Identification game
  static const String characterId = '/games/character-id';

  /// Counting game
  static const String countingGame = '/games/counting';

  /// Number line game
  static const String numberLineGame = '/games/number-line';

  /// Counting back game
  static const String countingBackGame = '/games/counting-back';

/// BSL Sprint endless-runner game
  static const String bslSprint = '/games/bsl-sprint';

  /// Clothes Line colour-learning game
  static const String clothesLine = '/games/clothes-line';

  /// BSL Sudoku game
  static const String sudoku = '/games/sudoku';

  /// More or Less BSL number comparison game
  static const String moreLessGame = '/games/more-or-less';

  /// Sphere Runner endless-runner maths game

  /// BSL Word Search game
  static const String wordSearch = '/games/word-search';

  /// Zoo game entry (start screen)
  static const String zoo = '/games/zoo';

  /// Zoo pick-a-player character selection screen
  static const String zooPickPlayer = '/games/zoo/pick-player';

  /// Zoo player detail screen for one character
  static const String zooPlayer = '/games/zoo/player';

  /// Zoo choose-a-level screen (winding level map)
  static const String zooLevels = '/games/zoo/levels';

  /// Zoo exploration map
  static const String zooMap = '/games/zoo/map';

  /// Zoo enterable-building interior (aviary, reptile house, aquarium)
  static const String zooBuilding = '/games/zoo/building';

  /// Zoo BSL video photo quiz (level 1)
  static const String zooQuiz = '/games/zoo/quiz';

  /// Number Race game
  static const String numberRace = '/games/number-race';

  /// Animal collection screen (Letter Bingo earned animals)
  static const String animalCollection = '/games/letter-bingo/collection';

  /// Privacy policy
  static const String privacyPolicy = '/privacy-policy';

  /// Player profile: avatar, screen name, badges, account linking.
  static const String profile = '/profile';

  /// BSL video library (moved off the profile page).
  static const String profileVideos = '/profile/videos';

  /// Player scores (placeholder).
  static const String profileScores = '/profile/scores';

  /// Sound effects / instructions toggles.
  static const String profileSettings = '/profile/settings';

  /// App settings (language, etc.)
  static const String settings = '/settings';

  /// Initial route when app launches
  static const String initial = splash;
}

/// Generates routes for the application.
///
/// This function is passed to [MaterialApp.onGenerateRoute] to handle
/// navigation between screens. Each route creates the appropriate
/// screen widget with any required providers.
///
/// Usage in MaterialApp:
/// ```dart
/// MaterialApp(
///   onGenerateRoute: generateRoute,
///   initialRoute: AppRoutes.initial,
/// )
/// ```
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(
        builder: (_) => const SplashScreen(),
        settings: settings,
      );

    case AppRoutes.welcome:
      return MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
        settings: settings,
      );

    case AppRoutes.home:
      return MaterialPageRoute(
        builder: (_) => const HomeScreen(),
        settings: settings,
      );

    case AppRoutes.welshHome:
      return MaterialPageRoute(
        builder: (_) => const WelshHomeScreen(),
        settings: settings,
      );

    case AppRoutes.cardMatching:
      final cardMatchingLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => CardGameProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: CardGameScreen(locale: cardMatchingLocale),
        ),
        settings: settings,
      );

    case AppRoutes.bubblePop:
      // Provide BubblePopProvider scoped to this route, with the player's
      // current locale and sign-system (BSL/IAC) preference.
      final bubblePopLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => BubblePopProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: BubblePopScreen(locale: bubblePopLocale),
        ),
        settings: settings,
      );

    case AppRoutes.colouring:
      // Provide ColouringProvider scoped to this route
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ColouringProvider(),
          child: const ColouringScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.vowelHand:
      final vowelHandLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => VowelHandProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: VowelHandScreen(locale: vowelHandLocale),
        ),
        settings: settings,
      );

    case AppRoutes.bslMaths:
      // Provide BslMathsProvider scoped to this route, with the player's
      // current locale (English or Welsh UI text).
      final bslMathsLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BslMathsProvider(),
          child: BslMathsScreen(locale: bslMathsLocale),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuest:
      // Level selection screen (no provider needed)
      final letterQuestLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => LetterQuestLevelSelectScreen(locale: letterQuestLocale),
        settings: settings,
      );

    case AppRoutes.letterQuestLevel1:
      final letterQuestLevel1Locale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => LetterQuestProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: IntroQuestScreen(locale: letterQuestLevel1Locale),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuestLevel2:
      final letterQuestLevel2Locale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => LetterQuestProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: Level2QuestScreen(locale: letterQuestLevel2Locale),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuestHouse:
      final houseLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => LetterQuestProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: HouseQuestScreen(locale: houseLocale),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuestLevel3:
      final letterQuestLevel3Locale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => LetterQuestProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: LetterQuestScreen(locale: letterQuestLevel3Locale),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuestBungalow:
      final bungalowLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => LetterQuestProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: BungalowQuestScreen(locale: bungalowLocale),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuestLevel4:
      final letterQuestLevel4Locale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => LetterQuestProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: OutdoorQuestScreen(locale: letterQuestLevel4Locale),
        ),
        settings: settings,
      );

    case AppRoutes.letterBingo:
      // Letter Bingo game with provider, scoped with the player's current
      // locale and sign-system (BSL/IAC) preference.
      final letterBingoLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => LetterBingoProvider(
            signSystem: context.read<SettingsProvider>().signSystem,
          ),
          child: LetterBingoScreen(locale: letterBingoLocale),
        ),
        settings: settings,
      );

    case AppRoutes.characterId:
      // Character Identification game (provider created inside screen)
      return MaterialPageRoute(
        builder: (_) => const CharacterIdScreen(),
        settings: settings,
      );


    case AppRoutes.countingGame:
      final countingGameLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CountingGameProvider(),
          child: CountingGameScreen(locale: countingGameLocale),
        ),
        settings: settings,
      );

    case AppRoutes.numberLineGame:
      final numberLineLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => NumberLineGameProvider(),
          child: NumberLineGameScreen(locale: numberLineLocale),
        ),
        settings: settings,
      );

    case AppRoutes.countingBackGame:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CountingBackProvider(),
          child: const CountingBackScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.bslSprint:
      final bslSprintLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BslSprintProvider(locale: bslSprintLocale),
          child: BslSprintScreen(locale: bslSprintLocale),
        ),
        settings: settings,
      );

    case AppRoutes.clothesLine:
      final clothesLineLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ClothesLineProvider(locale: clothesLineLocale),
          child: const ClothesLineScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.sudoku:
      final sudokuLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => SudokuScreen(locale: sudokuLocale),
        settings: settings,
      );

    case AppRoutes.moreLessGame:
      final moreLessLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MoreOrLessProvider(),
          child: MoreOrLessScreen(locale: moreLessLocale),
        ),
        settings: settings,
      );

    case AppRoutes.wordSearch:
      final wordSearchLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => WordWhirlProvider(locale: wordSearchLocale),
          child: const WordWhirlScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.zoo:
      final zooLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ZooStartScreen(locale: zooLocale),
        settings: settings,
      );

    case AppRoutes.zooPickPlayer:
      final zooPickLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ZooPickPlayerScreen(locale: zooPickLocale),
        settings: settings,
      );

    case AppRoutes.zooPlayer:
      final zooPlayerArgs =
          settings.arguments as Map<String, String>? ?? const {};
      return MaterialPageRoute(
        builder: (_) => ZooPlayerScreen(
          locale: zooPlayerArgs['locale'] ?? 'en',
          characterId: zooPlayerArgs['character'] ?? 'abi',
        ),
        settings: settings,
      );

    case AppRoutes.zooLevels:
      final zooLevelsArgs =
          settings.arguments as Map<String, String>? ?? const {};
      return MaterialPageRoute(
        builder: (context) => ZooLevelSelectScreen(
          locale: zooLevelsArgs['locale'] ?? 'en',
          signSystem: context.read<SettingsProvider>().signSystem,
          characterId: zooLevelsArgs['character'] ?? 'abi',
        ),
        settings: settings,
      );

    case AppRoutes.zooMap:
      final zooMapArgs =
          settings.arguments as Map<String, String>? ?? const {};
      final zooMapTarget = zooMapArgs['building'];
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => ZooProvider(
            locale: zooMapArgs['locale'] ?? 'en',
            characterId: zooMapArgs['character'] ?? 'abi',
            signSystem: context.read<SettingsProvider>().signSystem,
            targetBuilding:
                (zooMapTarget != null && zooMapTarget.isNotEmpty)
                    ? zooMapTarget
                    : null,
            levelNumber: int.tryParse(zooMapArgs['level'] ?? '') ?? 1,
          ),
          child: const ZooScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.zooBuilding:
      final zooBuildingArgs =
          settings.arguments as Map<String, String>? ?? const {};
      final zooBuildingName = zooBuildingArgs['building'] ?? 'aquarium';
      final zooBuildingLocale = zooBuildingArgs['locale'] ?? 'en';
      final zooBuildingSigns =
          SignSystem.fromPrefsString(zooBuildingArgs['signSystem']);
      final zooBuildingLevel = int.tryParse(zooBuildingArgs['level'] ?? '') ?? 1;
      // Buildings with a walk-level config open the side-scrolling
      // enclosure walk; the rest keep the coming-soon placeholder.
      final walkConfig = EnclosureLevelConfig.forBuilding(zooBuildingName);
      if (walkConfig != null) {
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => EnclosureWalkProvider(
              config: walkConfig,
              locale: zooBuildingLocale,
              signSystem: zooBuildingSigns,
              levelNumber: zooBuildingLevel,
            ),
            child: const EnclosureWalkScreen(),
          ),
          settings: settings,
        );
      }
      return MaterialPageRoute(
        builder: (_) => ZooBuildingScreen(
          building: zooBuildingName,
          locale: zooBuildingLocale,
          signSystem: zooBuildingSigns,
        ),
        settings: settings,
      );

    case AppRoutes.zooQuiz:
      final zooQuizArgs =
          settings.arguments as Map<String, String>? ?? const {};
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ZooQuizProvider(
            locale: zooQuizArgs['locale'] ?? 'en',
            signSystem: SignSystem.fromPrefsString(zooQuizArgs['signSystem']),
            characterId: zooQuizArgs['character'] ?? 'abi',
            levelNumber: int.tryParse(zooQuizArgs['level'] ?? '') ?? 1,
            zones: zooQuizArgs['zones'] == 'farm'
                ? ZooAnimalZone.farm
                : ZooAnimalZone.all,
          ),
          child: const ZooQuizScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.numberRace:
      final numberRaceLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => NumberRaceProvider(locale: numberRaceLocale),
          child: NumberRaceScreen(locale: numberRaceLocale),
        ),
        settings: settings,
      );

    case AppRoutes.animalCollection:
      return MaterialPageRoute(
        builder: (_) => const AnimalCollectionScreen(),
        settings: settings,
      );

    case AppRoutes.privacyPolicy:
      return MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
        settings: settings,
      );

    case AppRoutes.profile:
      final profileLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ProfileScreen(locale: profileLocale),
        settings: settings,
      );

    case AppRoutes.profileVideos:
      final videosLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => VideosScreen(locale: videosLocale),
        settings: settings,
      );

    case AppRoutes.profileScores:
      final scoresLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ScoresScreen(locale: scoresLocale),
        settings: settings,
      );

    case AppRoutes.profileSettings:
      final profileSettingsLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ProfileSettingsScreen(locale: profileSettingsLocale),
        settings: settings,
      );

    case AppRoutes.settings:
      final locale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => SettingsScreen(currentLocale: locale),
        settings: settings,
      );

    // Placeholder routes for future games
    case AppRoutes.earGame:
      return MaterialPageRoute(
        builder: (_) => const HomeScreen(), // Redirect to home for now
        settings: settings,
      );

    default:
      // Unknown route - navigate to home
      return MaterialPageRoute(
        builder: (_) => const HomeScreen(),
        settings: settings,
      );
  }
}
