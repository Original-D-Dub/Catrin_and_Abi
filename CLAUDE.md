# CLAUDE.md

## Environment limitations

- **Automated visual/GUI verification is not possible in this environment.**
  The Claude Code session's helper process does not have macOS Screen
  Recording permission, and it cannot be granted non-interactively (it
  requires a manual click in System Settings → Privacy & Security → Screen
  Recording). `screencapture` will reliably fail with "could not create
  image from display" — don't retry it, don't try alternate capture tools,
  and don't attempt to click-drive the running app to "see" the result.
- For UI/frontend changes: run `flutter analyze` (and any relevant
  widget/unit tests) as far as automated verification goes, then say
  explicitly that visual verification must be done manually — e.g. tell the
  user to run `flutter run -d macos`/`-d chrome`/on device and check by eye.
  Do not claim a UI change "looks correct," "renders as expected," or is
  "verified" without that manual check having actually happened.
