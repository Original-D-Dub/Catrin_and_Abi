import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/welcome/screens/welcome_screen.dart';
import '../../features/home/screens/home_screen.dart';
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
import '../../features/letter_quest/screens/letter_quest_screen.dart';
import '../../features/letter_quest/screens/letter_quest_level_select_screen.dart';
import '../../features/letter_quest/screens/outdoor_quest_screen.dart';
import '../../features/letter_quest/screens/level2_quest_screen.dart';
import '../../features/letter_quest/screens/intro_quest_screen.dart';
import '../../features/letter_quest/providers/letter_quest_provider.dart';
import '../../features/character_id/screens/character_id_screen.dart';
import '../../features/letter_bingo/screens/letter_bingo_screen.dart';
import '../../features/letter_bingo/screens/animal_collection_screen.dart';
import '../../features/letter_bingo/providers/letter_bingo_provider.dart';
import '../../features/bsl_camera_vowels/screens/camera_vowels_screen.dart';
import '../../features/bsl_camera_vowels/providers/camera_vowels_provider.dart';
import '../../features/wave_hello/screens/wave_hello_screen.dart';
import '../../features/wave_hello/providers/wave_hello_provider.dart';
import '../../features/counting_game/screens/counting_game_screen.dart';
import '../../features/counting_game/providers/counting_game_provider.dart';
import '../../features/number_line/screens/number_line_screen.dart';
import '../../features/number_line/providers/number_line_provider.dart';
import '../../features/counting_back/screens/counting_back_screen.dart';
import '../../features/counting_back/providers/counting_back_provider.dart';
import '../../features/more_or_less/screens/more_or_less_screen.dart';
import '../../features/more_or_less/providers/more_or_less_provider.dart';
import '../../features/bsl_sprint/screens/bsl_sprint_screen.dart';
import '../../features/bsl_sprint/providers/bsl_sprint_provider.dart';
import '../../features/clothes_line/screens/clothes_line_screen.dart';
import '../../features/clothes_line/providers/clothes_line_provider.dart';
import '../../features/higher_or_lower/screens/higher_or_lower_screen.dart';
import '../../features/higher_or_lower/providers/higher_or_lower_provider.dart';
import '../../features/sudoku/screens/sudoku_screen.dart';
import '../../features/privacy/screens/privacy_policy_screen.dart';
import '../../features/profile/screens/link_account_screen.dart';
import '../../features/sphere_runner/screens/sphere_runner_screen.dart';
import '../../features/word_search/providers/word_search_provider.dart';
import '../../features/word_search/screens/word_search_screen.dart';

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

  /// Letter Quest Level 3 (indoor rooms)
  static const String letterQuestLevel3 = '/games/letter-quest/level-3';

  /// Letter Quest Level 4 (outdoor adventure)
  static const String letterQuestLevel4 = '/games/letter-quest/level-4';

  /// Ear game (placeholder for future)
  static const String earGame = '/games/ear-game';

  /// Letter Bingo game (BSL letter matching bingo)
  static const String letterBingo = '/games/letter-bingo';

  /// Character Identification game
  static const String characterId = '/games/character-id';

  /// BSL Camera Vowels game (MediaPipe hand tracking)
  static const String cameraVowels = '/games/camera-vowels';

  /// Wave Hello game (wave at camera, Catrin waves back)
  static const String waveHello = '/games/wave-hello';

  /// Counting game
  static const String countingGame = '/games/counting';

  /// Number line game
  static const String numberLineGame = '/games/number-line';

  /// Counting back game
  static const String countingBackGame = '/games/counting-back';

  /// More or less game
  static const String moreLessGame = '/games/more-or-less';

  /// BSL Sprint endless-runner game
  static const String bslSprint = '/games/bsl-sprint';

  /// Clothes Line colour-learning game
  static const String clothesLine = '/games/clothes-line';

  /// BSL Sudoku game
  static const String sudoku = '/games/sudoku';

  /// Higher or Lower BSL number comparison game
  static const String higherOrLower = '/games/higher-or-lower';

  /// Sphere Runner endless-runner maths game
  static const String sphereRunner = '/games/sphere-runner';

  /// BSL Word Search game
  static const String wordSearch = '/games/word-search';

  /// Animal collection screen (Letter Bingo earned animals)
  static const String animalCollection = '/games/letter-bingo/collection';

  /// Privacy policy
  static const String privacyPolicy = '/privacy-policy';

  /// Link / manage player account
  static const String linkAccount = '/profile/link-account';

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

    case AppRoutes.cardMatching:
      // Provide CardGameProvider scoped to this route
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CardGameProvider(),
          child: const CardGameScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.bubblePop:
      // Provide BubblePopProvider scoped to this route
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BubblePopProvider(),
          child: const BubblePopScreen(),
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
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => VowelHandProvider(),
          child: const VowelHandScreen(),
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
      // Provide BslMathsProvider scoped to this route
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BslMathsProvider(),
          child: const BslMathsScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuest:
      // Level selection screen (no provider needed)
      return MaterialPageRoute(
        builder: (_) => const LetterQuestLevelSelectScreen(),
        settings: settings,
      );

    case AppRoutes.letterQuestLevel1:
      // Level 1: Intro room with provider (3 letters only)
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LetterQuestProvider(),
          child: const IntroQuestScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuestLevel2:
      // Level 2: Simple room with provider
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LetterQuestProvider(),
          child: const Level2QuestScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuestLevel3:
      // Level 3: Indoor rooms with provider
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LetterQuestProvider(),
          child: const LetterQuestScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.letterQuestLevel4:
      // Level 4: Outdoor adventure with provider
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LetterQuestProvider(),
          child: const OutdoorQuestScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.letterBingo:
      // Letter Bingo game with provider
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LetterBingoProvider(),
          child: const LetterBingoScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.characterId:
      // Character Identification game (provider created inside screen)
      return MaterialPageRoute(
        builder: (_) => const CharacterIdScreen(),
        settings: settings,
      );

    case AppRoutes.cameraVowels:
      // Camera Vowels uses device camera + MediaPipe — not available on web.
      // Redirect to home if somehow reached on web.
      if (kIsWeb) {
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      }
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CameraVowelsProvider(),
          child: const CameraVowelsScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.waveHello:
      if (kIsWeb) {
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      }
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => WaveHelloProvider(),
          child: const WaveHelloScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.countingGame:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CountingGameProvider(),
          child: const CountingGameScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.numberLineGame:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => NumberLineGameProvider(),
          child: const NumberLineGameScreen(),
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

    case AppRoutes.moreLessGame:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MoreLessProvider(),
          child: const MoreOrLessScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.bslSprint:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BslSprintProvider(),
          child: const BslSprintScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.clothesLine:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ClothesLineProvider(),
          child: const ClothesLineScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.sudoku:
      return MaterialPageRoute(
        builder: (_) => const SudokuScreen(),
        settings: settings,
      );

    case AppRoutes.higherOrLower:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => HigherOrLowerProvider(),
          child: const HigherOrLowerScreen(),
        ),
        settings: settings,
      );

    case AppRoutes.sphereRunner:
      return MaterialPageRoute(
        builder: (_) => const SphereRunnerScreen(),
        settings: settings,
      );

    case AppRoutes.wordSearch:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => WordSearchProvider(),
          child: const WordSearchScreen(),
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
