import 'translations_en.dart';
import 'translations_cy.dart';

/// Provides localized strings for the application.
///
/// Supports English ('en') and Welsh ('cy') locales.
/// Defaults to English if a key is not found.
///
/// Usage:
/// ```dart
/// final localizer = AppLocalizations(locale: 'en');
/// final text = localizer.translate('welcome.catrin_intro');
/// ```
class AppLocalizations {
  /// The current locale code ('en' or 'cy')
  final String locale;

  /// Creates a localizer for the specified locale.
  ///
  /// [locale] should be 'en' for English or 'cy' for Welsh.
  AppLocalizations({required this.locale});

  /// Map of locale codes to their translation maps
  static const Map<String, Map<String, String>> _translations = {
    'en': translationsEn,
    'cy': translationsCy,
  };

  /// Translates a key to the localized string.
  ///
  /// [key] is the translation key (e.g., 'welcome.catrin_intro').
  /// Returns the translated string, or the key itself if not found.
  ///
  /// Example:
  /// ```dart
  /// translate('home.title') // Returns 'Choose a Game' for English
  /// ```
  String translate(String key) {
    final localeTranslations = _translations[locale];
    if (localeTranslations == null) {
      // Fallback to English if locale not found
      return _translations['en']?[key] ?? key;
    }
    return localeTranslations[key] ?? _translations['en']?[key] ?? key;
  }

  /// Shorthand for [translate].
  ///
  /// Allows usage like: `localizer('home.title')`
  String call(String key) => translate(key);

  /// Returns true if the current locale is Welsh
  bool get isWelsh => locale == 'cy';

  /// Returns true if the current locale is English
  bool get isEnglish => locale == 'en';

  /// List of supported locale codes
  static const List<String> supportedLocales = ['en', 'cy'];
}
