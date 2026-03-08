/// Represents a single step in the welcome story sequence.
///
/// Each story step displays a character with a speech bubble
/// containing their dialogue.
///
/// Used by [WelcomeProvider] to manage the introduction flow.
class StoryStep {
  /// The name of the character speaking (for reference/debugging).
  final String speakerName;

  /// Asset path to the character's image.
  final String characterImagePath;

  /// Translation key for the dialogue text.
  /// The actual text is retrieved via [AppLocalizations].
  final String dialogueKey;

  /// Creates a story step.
  ///
  /// [speakerName] identifies who is speaking.
  /// [characterImagePath] points to the character asset.
  /// [dialogueKey] is the localization key for the dialogue.
  const StoryStep({
    required this.speakerName,
    required this.characterImagePath,
    required this.dialogueKey,
  });
}
