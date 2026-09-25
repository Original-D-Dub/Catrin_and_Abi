import '../../../shared/services/audio_service.dart';

/// Injectable audio seam for the BINGO celebration.
///
/// Wraps the static [AudioService] so widget tests can substitute a
/// silent/stub implementation (by passing a fake into
/// `BingoCelebration(audio: ...)`) without playing real audio or needing
/// the FlameAudio platform channels.
class CelebrationAudio {
  const CelebrationAudio();

  /// Triple-impact haptic for the win moment.
  void hapticSuccess() => AudioService.hapticSuccess();

  /// The recorded "Bingo!" clip for [locale].
  Future<void> playBingo({String locale = 'en'}) =>
      AudioService.playBingoCelebration(locale: locale);

  /// The "You have a (new) friend" clip announced before the animal's name.
  Future<void> playFriendGreeting({
    required bool isNew,
    String locale = 'en',
  }) =>
      AudioService.playFriendGreeting(isNew: isNew, locale: locale);

  /// The recorded animal name, keyed by the animal's bingo letter.
  Future<void> playAnimalName(String letter) =>
      AudioService.playAnimalName(letter);

  /// Stops any in-flight speech, then plays the animal name again
  /// (card tap-to-replay).
  Future<void> replayAnimalName(String letter) async {
    await AudioService.stopAll();
    await AudioService.playAnimalName(letter);
  }

  /// Stops all celebration audio (used by tap-to-skip).
  Future<void> stopAll() => AudioService.stopAll();
}
