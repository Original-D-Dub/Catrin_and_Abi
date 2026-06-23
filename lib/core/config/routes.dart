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
import '../../features/my_special_dog/screens/my_special_dog_screen.dart';
import '../../features/my_special_dog/providers/my_special_dog_provider.dart';
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
import '../../features/profile/screens/link_account_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/sphere_runner/screens/sphere_runner_screen.dart';
import '../../features/word_search/providers/word_search_provider.dart';
import '../../features/word_search/screens/word_search_screen.dart';
import '../../features/number_race/providers/number_race_provider.dart';
import '../../features/number_race/screens/number_race_screen.dart';
import '../../shared/services/settings_provider.dart';

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

  /// My Special Dog game
  static const String mySpecialDog = '/games/my-special-dog';

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
  static const String sphereRunner = '/games/sphere-runner';

  /// BSL Word Search game
  static const String wordSearch = '/games/word-search';

  /// Number Race game
  static const String numberRace = '/games/number-race';

  /// Animal collection screen (Letter Bingo earned animals)
  static const String animalCollection = '/games/letter-bingo/collection';

  /// Privacy policy
  static const String privacyPolicy = '/privacy-policy';

  /// Link / manage player account
  static const String linkAccount = '/profile/link-account';

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

    case AppRoutes.mySpecialDog:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MySpecialDogProvider(),
          child: const MySpecialDogScreen(),
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

    case AppRoutes.sphereRunner:
      return MaterialPageRoute(
        builder: (_) => const SphereRunnerScreen(),
        settings: settings,
      );

    case AppRoutes.wordSearch:
      final wordSearchLocale = settings.arguments as String? ?? 'en';
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => WordSearchProvider(locale: wordSearchLocale),
          child: const WordSearchScreen(),
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

    case AppRoutes.linkAccount:
      return MaterialPageRoute(
        builder: (_) => const LinkAccountScreen(),
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
