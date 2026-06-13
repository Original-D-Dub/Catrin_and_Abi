// Category and age-group enums used to tag every game on the home screen.
// [SettingsProvider] holds the user's selected values; [HomeScreen]
// and [WelshHomeScreen] filter their tile lists against them.

enum GameCategory {
  all,
  alphabet,
  numeracy,
  vocabulary;

  String toPrefsString() => name;

  static GameCategory fromPrefsString(String? s) => switch (s) {
    'alphabet' => GameCategory.alphabet,
    'numeracy' => GameCategory.numeracy,
    'vocabulary' => GameCategory.vocabulary,
    _ => GameCategory.all,
  };
}

enum AgeGroup {
  all,
  years1to3,
  years3to5,
  years5plus;

  String toPrefsString() => name;

  static AgeGroup fromPrefsString(String? s) => switch (s) {
    'years1to3' => AgeGroup.years1to3,
    'years3to5' => AgeGroup.years3to5,
    'years5plus' => AgeGroup.years5plus,
    _ => AgeGroup.all,
  };
}

/// Sign language used for letter signs in spelling/letter games.
///
/// Independent of UI language ([SettingsProvider.language]): a Welsh-speaking
/// child can play with [bsl] (English alphabet fingerspelling) and an
/// English-speaking child can play with [iac] (Welsh alphabet fingerspelling,
/// Iaith Arwyddion Cymru).
enum SignSystem {
  bsl,
  iac;

  String toPrefsString() => name;

  static SignSystem fromPrefsString(String? s) => switch (s) {
    'iac' => SignSystem.iac,
    _ => SignSystem.bsl,
  };
}
