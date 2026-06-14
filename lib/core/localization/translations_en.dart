/// English translations for the Catrin & Abi BSL app.
///
/// All user-facing strings should be defined here for easy
/// maintenance and future localization updates.
const Map<String, String> translationsEn = {
// -------------------------
  // App Title
  // -------------------------
 'app.title': 'Catrin & Abi',

  // -------------------------
  // Welcome Screen - Story Introduction
  // -------------------------
  'welcome.catrin_intro': "Say hello to Catrin. She has a sister called Abi.",
  'welcome.abi_is_deaf': 'Abi is Deaf. She was born Deaf.',
  'welcome.bsl_explanation':
      'We use British Sign Language to talk to each other. It\'s called BSL!', //they use British Sign Language to talk to each other. It\'s called BSL! update audio and Welsh files
  'welcome.learn_bsl': 'Do you want to learn some BSL? Let\'s play some games!',
  'welcome.pero_intro': 'Say hello to Pero. He is my hearing dog.',
  'welcome.hearing_dog_explain':
      'Pero helps me know when there are sounds I need to hear, like the doorbell or an alarm.',
  'welcome.pero_woof': 'Woof!',
  

  // -------------------------    
  // Home Screen
  // -------------------------
  'home.title': 'Choose a Game',
  'home.sign_system_label': 'Sign Language',
  'card_matching.title': 'Card Match',
  'bubble_pop.title': 'Bubble Pop',
  'letter_quest.title': 'Letter Quest',
  'bsl_vowels.title': 'BSL Vowels',
  'iac_vowels.title': 'IAC Vowels',
  'iac_vowels.intro': 'Tap the correct fingertip or badge to make the sign for each Welsh vowel: a, e, i, o, u, w, y.',
  'colouring.title': 'Colouring',
  'counting.title': 'Counting',
  'number_line.title': 'Make 10',
  'more_or_less.title': 'More or Less',
  'bsl_maths.title': 'BSL Maths',
  'clothes_line.title': 'Clothes Line',
  'clothes_line.intro': 'Look at the clothes on the line and answer the question!',
  'clothes_line.level1.name': 'Starter',
  'clothes_line.level1.description': 'Red, blue and green only',
  'clothes_line.level2.name': 'Tap & Answer',
  'clothes_line.level2.description': 'Answer before you press play',
  'clothes_line.level3.name': 'Conveyor Belt',
  'clothes_line.level3.description': 'Answer before the clothes scroll away!',
  'clothes_line.question': 'What colour {verb} the {item}?',
  'clothes_line.verb_singular': 'is',
  'clothes_line.verb_plural': 'are',
  'clothes_line.item.socks': 'socks',
  'clothes_line.item.shirt': 'shirt',
  'clothes_line.item.trousers': 'trousers',
  'clothes_line.item.skirt': 'skirt',
  'clothes_line.item.t-shirt': 't-shirt',
  'clothes_line.item.shorts': 'shorts',
  'clothes_line.item.coat': 'coat',
  'clothes_line.speed': 'Speed',
  'bsl_sprint.title': 'BSL Sprint',
  'letter_bingo.title': 'Letter Bingo',
  'character_id.title': 'Who has blue shoes?',
  'number_race.title': 'Number Race',

  // -------------------------
  // Level Select (shared widget)
  // -------------------------
  'level_select.title': 'Choose a Level',
  'level_select.level_prefix': 'Level',

  // -------------------------
  // General UI
  // -------------------------
  'general.back': 'Back',
  'general.start': 'Start',
  'general.tap_continue': 'Tap to continue',
  'general.continue': 'Continue',
  'general.ok': 'OK',
  'general.play': 'Play',
  'general.play_again': 'Play Again',
  'general.next_level': 'Next Level',
  'general.change_level': 'Change Level',
  'general.you_scored': 'You scored {score}',
  'general.you_matched': 'You matched {score}',
  'general.got_10_correct': 'You got 10 correct',
  'general.personal_best': 'Personal Best! {score}{suffix}',
  'general.sign_in_to_save': 'Sign in to save your changes',
  'general.score': 'Score',
  'general.time': 'Time',
  'general.matches': 'Matches',
  'general.words': 'Words',
  'general.completed': 'Completed',
  'general.home': 'Home',
  'general.go': 'Go',
  'general.1': '1',
  'general.2': '2',
  'general.3': '3',
  'general.4': '4',
  'general.5': '5',
  'general.6': '6',
  'general.7': '7',
  'general.8': '8',
  'general.9': '9',
  'general.10': '10',
  'general.11': '11',
  'general.12': '12',
  'general.13': '13',
  'general.14': '14',
  'general.15': '15',
  'general.16': '16',
  'general.17': '17',
  'general.18': '18',
  'general.19': '19',
  'general.20': '20',
  'general.emph1': '1',
  'general.emph2': '2',
  'general.emph3': '3',
  'general.emph4': '4',
  'general.emph5': '5',
  'general.emph6': '6',
  'general.emph7': '7',
  'general.emph8': '8',
  'general.emph9': '9',
  'general.emph10': '10',
  'general.emph11': '11',
  'general.emph12': '12',
  'general.emph13': '13',
  'general.emph14': '14',
  'general.emph15': '15',
  'general.emph16': '16',
  'general.emph17': '17',
  'general.emph18': '18',
  'general.emph19': '19',
  'general.emph20': '20',
  'general.correct': 'Correct!',
  'general.welldone': 'Well Done!',
  'general.congratulations': 'Congratulations!',
  'general.almost_there': 'Almost there!',
  'general.try_again': 'Try Again!',

  // -------------------------
  // BSL Vowels (Vowel Hand) game
  // -------------------------
  'vowel_hand.title': 'BSL Vowels',
  'vowel_hand.level1.name': 'Vowel Match',
  'vowel_hand.level1.description': 'Tap the fingertips',
  'vowel_hand.level1.intro': 'Tap the correct fingertip to make the BSL vowel that matches the letter.',
  'vowel_hand.level2.name': 'Missing Vowels',
  'vowel_hand.level2.description': 'Find the missing vowels',
  'vowel_hand.level2.intro': 'Tap the correct fingertip to make the BSL vowel that matches the missing letter.',
  'vowel_hand.level3.name': 'Simple Words',
  'vowel_hand.level3.description': 'Find the missing vowels in four letter words',
  'vowel_hand.level3.intro': 'Now try four letter words. Tap the correct fingertip for the missing vowel.',
  'vowel_hand.level4.name': 'More Simple Words',
  'vowel_hand.level4.description': 'Find the missing vowels in the four letter words',
  'vowel_hand.level4.intro': 'Tap the correct fingertip for the missing vowel.',

  // -------------------------
  // My Special Dog game
  // -------------------------
  'my_special_dog.title': 'My Special Dog',
  'my_special_dog.level1.intro': 'Tap the correct fingertip to make the BSL vowel that matches the letter.',
  'my_special_dog.level1.name': 'Vowel Match',
  'my_special_dog.level1.description': 'Tap the fingertips',
  'my_special_dog.level2.intro': 'Tap the fingertip to make the BSL vowel that matches the missing letter.',
  'my_special_dog.level2.name': 'Vowel Words',
  'my_special_dog.level2.description': 'Missing vowel',
  'my_special_dog.level3.intro': 'Big Points! Score points for the words you guess correctly. The longer the word the more points you score',
  'my_special_dog.level3.name': 'Play for points',
  'my_special_dog.level3.description': 'More points for longer words',
  'my_special_dog.words_label': 'words',
  'my_special_dog.words_completed': 'Words completed:',

  // -------------------------
  // Card Matching Game
  // -------------------------
  'card_matching.tap_first': 'Tap a card to flip it!',
  'card_matching.tap_second': 'Tap another card to find a match',
  'card_matching.moves_label': 'Moves',
  'card_matching.pairs_label': 'pairs',
  'card_matching.success_moves': 'You did it in {n} moves!',
  'card_matching.moves_suffix': ' moves',
  'card_matching.bsl.intro': 'Match the BSL signs with their letters!',
  'card_matching.bsl.level1.name': 'Vowels',
  'card_matching.bsl.level2.name': 'a to e',
  'card_matching.bsl.level3.name': 'a to j',
  'card_matching.bsl.level4.name': 'i to r',
  'card_matching.bsl.level5.name': 'q to z',
  'card_matching.bsl.level6.name': 'Full Alphabet',
  'card_matching.iac.intro': 'Match the Welsh signs with their letters!',
  'card_matching.iac.level1.name': 'Welsh Vowels',
  'card_matching.iac.level2.name': 'a to e',
  'card_matching.iac.level3.name': 'e to i',
  'card_matching.iac.level4.name': 'j to s',
  'card_matching.iac.level5.name': 'o to y',
  'card_matching.iac.level6.name': 'Full Welsh Alphabet',

  // -------------------------
  // Bubble Pop Game
  // -------------------------
  'bubble_pop.intro': 'Look at the BSL letter sign. Pop the bubble that shows the matching letter!',
  'bubble_pop.find_label': 'Find the letter',
  'bubble_pop.bsl.level1.name': 'Vowels',
  'bubble_pop.bsl.level2.name': 'a to e',
  'bubble_pop.bsl.level3.name': 'a to j',
  'bubble_pop.bsl.level4.name': 'i to r',
  'bubble_pop.bsl.level5.name': 'q to z',
  'bubble_pop.bsl.level6.name': 'Full Alphabet',
  'bubble_pop.iac.level1.name': 'Welsh Vowels',
  'bubble_pop.iac.level2.name': 'a to f',
  'bubble_pop.iac.level3.name': 'a to i',
  'bubble_pop.iac.level4.name': 'a to o',
  'bubble_pop.iac.level5.name': 'a to u',
  'bubble_pop.iac.level6.name': 'Full Welsh Alphabet',

  // -------------------------
  // Welsh (IAC) Bubble Pop intro
  // -------------------------
  'welsh_bubble_pop.intro': 'Look at the IAC letter sign. Pop the bubble that shows the matching letter!',

  // -------------------------
  // Colouring Game
  // -------------------------


  // -------------------------
  // Counting Game
  // -------------------------
  'counting_game.intro': 'Count the circles and tap the matching BSL number sign!',
  'counting_game.subtitle': 'Count the circles!',
  'counting_game.level1.name': 'Orange',
  'counting_game.level2.name': 'Yellow',
  'counting_game.level3.name': 'Green',
  'counting_game.level4.name': 'Pink & Yellow',
  'counting_game.level5.name': 'Blue & Red',
  'counting_game.level6.name': 'Green & Purple',
  'counting_game.round_label': 'Round',
  'counting_game.of_label': 'of',
  'counting_game.question_colour': 'How many {colour} circles?',
  'counting_game.question_total_single': 'How many {colour} circles are there?',
  'counting_game.question_total_multi': 'How many circles altogether?',
  'counting_game.colour.orange': 'orange',
  'counting_game.colour.yellow': 'yellow',
  'counting_game.colour.green': 'green',
  'counting_game.colour.pink': 'pink',
  'counting_game.colour.blue': 'blue',
  'counting_game.colour.red': 'red',
  'counting_game.colour.purple': 'purple',

  // -------------------------
  // Number Line (Make 10)
  // -------------------------
  'number_line_game.intro':'Look at the number line. Work out how many more counters are needed to reach ten!',
  'number_line.subtitle': 'How many more do you need?',
  'number_line.level1.name': 'Make 5',
  'number_line.level2.name': 'Up to 10',
  'number_line.level3.name': 'Signs Only',
  'number_line.question': 'How many cakes do we need to make {n}?',
  'number_line.round_label': 'Round',
  'number_line.of_label': 'of',

// -------------------------
  // More or Less
  // -------------------------
  'more_or_less.intro': 'Which is more, which is less?',
  'more_or_less.subtitle': 'Is it more or less??',
  'more_or_less.level1.name': 'Numbers 1–5',
  'more_or_less.level2.name': 'Numbers 1–7',
  'more_or_less.level3.name': 'Numbers 1–10',
  'more_or_less.level4.name': 'Numbers 1–19',
  'more_or_less.level5.name': 'Numbers 20–99',
  'more_or_less.round_label': 'Round',
  'more_or_less.of_label': 'of',
  'more_or_less.is_label': 'Is',
  'more_or_less.more_than': 'more than',
  'more_or_less.less_than': 'less than',
  'more_or_less.yes': 'YES',
  'more_or_less.no': 'NO',

  // -------------------------
  // Number Race
  // -------------------------
  'number_race.intro': 'Count the dots and tap the matching BSL number sign to race ahead. Get 5 right to win!',
  'number_race.choose_character': 'Choose your racer!',
  'number_race.character.gary': 'Gary',
  'number_race.character.pero': 'Pero',
  'number_race.character.jamjam': 'JamJam',
  'number_race.question': 'How many dots?',
  'number_race.success_summary': '{character} won the race!',
  'number_race.change_character': 'Change Racer',
  'number_race.attempts_suffix': ' tries',

  // -------------------------
  // BSL Maths
  // -------------------------
  'bsl_maths.intro': 'Look at the BSL number signs and work out the answer!',
  'bsl_maths.subtitle': 'Learn BSL numbers with addition!',
  'bsl_maths.level1.name': 'Sums to 10',
  'bsl_maths.level2.name': 'Make 10',
  'bsl_maths.level3.name': 'Teen Numbers',
  'bsl_maths.level4.name': 'Missing Number',
  'bsl_maths.level5.name': 'Competition',
  'bsl_maths.level6.name': 'Take Away to 5',
  'bsl_maths.level7.name': 'Take Away to 10',
  'bsl_maths.level8.name': 'Take Away to 20',

  // -------------------------
  // BSL Sprint
  // -------------------------
  'bsl_sprint.level0.name': 'Training',
  'bsl_sprint.level0.description': 'Collect the correct letters',
  'bsl_sprint.level0.intro': 'Run and collect the BSL letters to spell the word. Swipe to move left, and swipe to move right. Swipe up to jump.',
  'bsl_sprint.level1.name': 'Beginner',
  'bsl_sprint.level1.description': 'Watch out for wrong letters!',
  'bsl_sprint.level1.intro': 'Run and collect the BSL letters to spell the word. Watch out for the wrong letters!',
  'bsl_sprint.level2.name': 'Sprint',
  'bsl_sprint.level2.description': 'Race for the highest score',
  'bsl_sprint.level2.intro': 'Run and collect the BSL letters to spell the word. Watch out for the wrong letters!',
  'bsl_sprint.get_ready': 'Get ready!',
  'bsl_sprint.collect_instruction': 'Collect the letters to spell:',
  'bsl_sprint.words_label': 'Words',
  'bsl_sprint.success_summary': 'Words: {words}  •  Score: {score}',

  // -------------------------
  // Letter Quest
  // -------------------------
  'letter_quest.subtitle': 'Move Pero to find the letters to spell the word!',
  'letter_quest.level1.name': 'Intro Room',
  'letter_quest.level2.name': 'Simple Room',
  'letter_quest.level3.name': 'Indoor Rooms',
  'letter_quest.level4.name': 'Outdoor Adventure',
  'letter_quest.victory_subtitle': 'You collected all the words!',
  'letter_quest.level4_unlocked': 'Congratulations Level 4 unlocked',
  'letter_quest.play_level4': 'Play Level 4',
  'letter_quest.found_gary': 'You found Gary! Congratulations',
  'letter_quest.words_found': 'words you found were:',


  // -------------------------
  // Letter Bingo
  // -------------------------
    'letter_bingo.bsl.intro': 'Match the BSL signs to the letters called at the bottom of the screen. Complete a line for BINGO!',
    'letter_bingo.iac.intro': 'Match the IAC signs to the letters called at the bottom of the screen. Complete a line for BINGO!',
    'letter_bingo.bingo': 'Bingo!',
    'letter_bingo.bsl.level1.name': 'a to e',
    'letter_bingo.bsl.level2.name': 'a to i',
    'letter_bingo.bsl.level3.name': 'a to o',
    'letter_bingo.bsl.level4.name': 'a to u',
    'letter_bingo.bsl.level5.name': 'full alphabet',
    'letter_bingo.iac.level1.name': 'a to d',
    'letter_bingo.iac.level2.name': 'a to dd',
    'letter_bingo.iac.level3.name': 'a to o',
    'letter_bingo.iac.level4.name': 'a to u',
    'letter_bingo.iac.level5.name': 'full Welsh alphabet',

  // -------------------------
  // So Many People Know Me
  // -------------------------


  // -------------------------
  // Who has Blue Shoes
  // -------------------------  
  'character_id.intro': 'Look at the character carefully and answer the question about them!',
  'character_id.level1.name': 'Clothing Colours',
  'character_id.level2.name': 'Clothing Colours',
  'character_id.level3.name': 'Speed Round',
  'character_id.level4.name': 'Compare',

  // -------------------------
  // Sphere Runner
  // -------------------------
  'sphere_runner.title': 'Sphere Runner',
  'sphere_runner.intro': 'Swipe left or right to steer through the gates and collect exactly 20 spheres!',
  'sphere_runner.spheres_label': 'Spheres',
  'sphere_runner.target_label': 'Target: 20',
  'sphere_runner.almost_there': 'Almost there!',
  'sphere_runner.win_title': 'You did it!',
  'sphere_runner.win_body': 'You collected exactly 20 spheres!',
  'sphere_runner.exit': 'Exit',

  // -------------------------
  // Word Search
  // -------------------------
  'word_search.title': 'Word Search',
  'word_search.level1.name': 'Questions',
  'word_search.level2.name': 'Colours',
  'word_search.level3.name': 'Weather',
  'word_search.drag_hint': 'Drag the letters to spell the sign',
  'word_search.video_coming_soon': 'Video coming soon',

  // -------------------------
  // Sudoku
  // -------------------------
  'sudoku.title':    'BSL Sudoku',
  'sudoku.subtitle': 'Choose your challenge',

  'sudoku.difficulty.mini':       'Mini Sudoku',
  'sudoku.difficulty.six_by_six': '6×6 Sudoku',
  'sudoku.difficulty.easy':       'Easy',
  'sudoku.difficulty.hard':       'Hard',
  'sudoku.difficulty.extreme':    'Extreme',

  'sudoku.level1.description': '4×4 grid — perfect for starting out',
  'sudoku.level2.description': '6×6 grid with 2×3 boxes',
  'sudoku.level3.description': 'Great introduction to Sudoku',
  'sudoku.level4.description': 'Fewer starting clues',
  'sudoku.level5.description': 'For true masters',

  'sudoku.clear':              'Clear',
  'sudoku.new_puzzle':         'New Puzzle',
  'sudoku.puzzle_solved':      'Puzzle solved!',
  'sudoku.expert_mode':          'Expert Mode',
  'sudoku.expert_mode_subtitle': 'No hint highlighting',

  // -------------------------
  // Sudoku Walkthrough
  // -------------------------
  'sudoku.walkthrough.skip':         'Skip',
  'sudoku.walkthrough.back':         '← Back',
  'sudoku.walkthrough.next':         'Next →',
  'sudoku.walkthrough.lets_play':    "Let's Play!",
  'sudoku.walkthrough.picker_label': 'BSL number picker',

  'sudoku.walkthrough.legend.selected': 'Selected',
  'sudoku.walkthrough.legend.related':  'Related',
  'sudoku.walkthrough.legend.same':     'Same no.',
  'sudoku.walkthrough.legend.conflict': 'Conflict',

  'sudoku.walkthrough.step0.title': 'Welcome to BSL Sudoku!',
  'sudoku.walkthrough.step0.body':  'Use BSL hand signs to fill the 9×9 grid\ninstead of written numbers.',

  'sudoku.walkthrough.step1.title':    'Rows & Columns',
  'sudoku.walkthrough.step1.body_row': 'Each row  ↔  must contain 1–9 with no repeats.',
  'sudoku.walkthrough.step1.body_col': 'Each column  ↕  must also contain 1–9 exactly once.',

  'sudoku.walkthrough.step2.title':      'The 3×3 Boxes',
  'sudoku.walkthrough.step2.body_intro': 'The grid is divided into nine 3×3 boxes.',
  'sudoku.walkthrough.step2.body_rule':  'Each box must contain the numbers 1–9 — once each.',

  'sudoku.walkthrough.step3.title':        'How to Play',
  'sudoku.walkthrough.step3.body_select':  'Tap any empty cell to select it.',
  'sudoku.walkthrough.step3.body_glow':    'The cell glows amber when selected.',
  'sudoku.walkthrough.step3.body_fill':    'Tap a BSL number below the grid to fill it in!',

  'sudoku.walkthrough.step4.title':        'Hints & Errors',
  'sudoku.walkthrough.step4.body_glow':    'Tap a cell — its row, column and box glow blue.',
  'sudoku.walkthrough.step4.body_blue':    'Blue cells show where the same number cannot appear.',
  'sudoku.walkthrough.step4.body_purple':  'Cells sharing the same number glow purple.',
  'sudoku.walkthrough.step4.body_red':     'A conflict turns cells red — fix it before moving on!',
  'sudoku.walkthrough.step4.body_clear':   "No red cells = you're on the right track!",

  'sudoku.walkthrough.step5.title':        'Ready to Play!',
  'sudoku.walkthrough.step5.body':         'Choose a difficulty and start solving.\nGood luck — you\'ve got this!',
  'sudoku.walkthrough.step5.normal_note':  'More starting clues',
  'sudoku.walkthrough.step5.hard_note':    'Fewer starting clues',
  'sudoku.walkthrough.step5.extreme_note': 'For true masters',

  // -------------------------
  // Settings Screen
  // -------------------------
  'settings.title': 'Settings',
  'settings.language_section': 'Language / Iaith',
  'settings.english': 'English',
  'settings.english_sub': 'British Sign Language games',
  'settings.welsh': 'Cymraeg',
  'settings.welsh_sub': 'Welsh language games',
  'settings.game_type_section': 'Game Type',
  'settings.all_games': 'All games',
  'settings.all_games_sub': 'Show everything',
  'settings.alphabet': 'Alphabet',
  'settings.alphabet_sub': 'Letters & BSL hand signs',
  'settings.numeracy': 'Numeracy',
  'settings.numeracy_sub': 'Counting, maths & numbers',
  'settings.vocabulary': 'Vocabulary & Phrases',
  'settings.vocabulary_sub': 'Colours, clothes & stories',
  'settings.age_group_section': 'Age Group',
  'settings.all_ages': 'All ages',
  'settings.all_ages_sub': 'No age restriction',
  'settings.years1to3': 'Years 1 – 3',
  'settings.years1to3_sub': 'Ages 5 to 8',
  'settings.years3to5': 'Years 3 – 5',
  'settings.years3to5_sub': 'Ages 7 to 10',
  'settings.years5plus': 'Year 5 +',
  'settings.years5plus_sub': 'Ages 10 and above',

};
