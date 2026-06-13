---
name: bilingual-sign-game-structure
description: Use when adding a new game, translating a game between English/Welsh, adding a BSL/IAC sign-language toggle, or touching any of the existing duplicated "welsh_*" game directories. Defines the GameConfig pattern (locale + sign system) so one provider/screen serves all combinations instead of forking directories per language.
---

# Bilingual & Sign-Language Game Structure

## The two independent axes

Every spelling/letter game in this app varies along **two independent axes**:

1. **UI language** — `en` or `cy`, handled by `AppLocalizations` (`lib/core/localization/`).
2. **Sign system** — `bsl` (British Sign Language fingerspelling, English alphabet) or
   `iac` (Iaith Arwyddion Cymru / Welsh fingerspelling, Welsh alphabet incl. digraphs
   ch, dd, ff, ng, ll, ph, rh, th).

These are **not the same thing**. A Welsh-speaking child can play a BSL spelling game
(`cy` UI + `bsl` signs/letters), and an English-speaking child can play an IAC spelling
game (`en` UI + `iac` signs/letters). Any new game or toggle must keep these two axes
separate rather than bundling them into one "Welsh version" of a game.

## Do NOT fork directories per language/sign-system

`lib/features/welsh_bubble_pop/`, `lib/features/welsh_card_matching/`, and
`lib/features/iac_vowels/` (vs `lib/features/vowel_hand/`) are pre-existing full
copy-paste forks of their English/BSL counterparts. **Treat these as migration
targets, not templates.** Copying a whole `lib/features/<game>` directory to make a
"Welsh" variant doubles the maintenance burden every time the game count grows, and
quadruples it once the BSL/IAC toggle is added on top.

For new games, and whenever you touch one of the forked pairs above, move toward:
**one provider + one screen per game**, parameterized by locale and sign system.

## Existing building blocks to reuse

- `AssetPaths.bslLetterSvg(letter)` → `assets/bsl_alphabet_svg/<letter>.svg` (single
  letters only).
- `AssetPaths.welshLetterSvg(letter)` → `assets/wyddor_iac_svg/<letter>.svg` (supports
  digraphs: ch, dd, ff, ng, ll, ph, rh, th).
- `BslAlphabetSvg` (`lib/shared/widgets/bsl_alphabet_svg.dart`) currently hardcodes
  `AssetPaths.bslLetterSvg` and applies the inline `cls-1`/`cls-2`/`dash` →
  fill/stroke substitution flutter_svg needs on Android. **This needs a `signSystem`
  (or `assetResolver`) param so it can load from `wyddor_iac_svg` too** — check
  whether those SVGs use the same `cls-1`/`cls-2`/`dash` class names before assuming
  the same substitution works unchanged.
- `AppLocalizations(locale: 'en'|'cy')` / `translations_en.dart` / `translations_cy.dart`
  for UI text.
- `GameStatsService` / `GameIds` for score tracking, with `level:` already supported
  for per-level stats keys.
- `game_filters.dart` (`GameCategory`, `AgeGroup`) and `SettingsProvider` for existing
  persisted, syncing user settings — the `SignSystem` toggle belongs here.

## The GameConfig pattern

A game's provider and screen should accept (directly or via constructor/Provider):

- `locale`: `'en' | 'cy'` — passed straight to `AppLocalizations`. Controls
  instructions, labels, level names, button text.
- `signSystem`: `SignSystem.bsl | SignSystem.iac` — controls:
  - which letter set / level data is used (English alphabet levels vs Welsh
    alphabet levels with digraphs),
  - which SVG family signs are loaded from (`bslLetterSvg` vs `welshLetterSvg`).

Concretely:

```dart
enum SignSystem { bsl, iac }
```

- `GameLevels` becomes `GameLevels.forSignSystem(SignSystem)` returning the
  appropriate `List<GameLevel>` (English alphabet vs Welsh alphabet+digraphs), rather
  than two separate `GameLevels` classes in two separate provider files.
- Translation keys for level names should be split by sign system but NOT by
  locale (locale is handled by `AppLocalizations` automatically), e.g.
  `'bubble_pop.bsl.level1.name'` and `'bubble_pop.iac.level1.name'`, each present
  in both `translations_en.dart` and `translations_cy.dart`.
- The sign-display widget takes `signSystem` and picks the asset family
  accordingly — single source of truth, one widget, no duplicated screen code.

## Wiring `locale` end-to-end through an existing game

When a game currently has English-only UI text and needs to become bilingual (the
`locale` axis only — no sign-system change), follow this exact wiring, established
for `word_search` and `clothes_line`:

1. **Provider** takes `locale` as a constructor field:
   ```dart
   final String locale;
   MyGameProvider({this.locale = 'en'});
   ```
   If the game has locale-dependent word/level data (not just UI labels), add a
   `static List<MyLevel> forLocale(String locale)` factory on the model — mirrors
   `forSignSystem`, but for data that differs by *language* rather than sign
   alphabet (e.g. word lists, item names).

2. **Screen** reads the locale from the provider and builds one localizer for the
   whole build:
   ```dart
   final locale = provider.locale;
   final localizer = AppLocalizations(locale: locale);
   ```
   Every `Text(...)` in the screen — AppBar titles, score labels, level names,
   button labels, slider labels, empty-state hints, "well done"/"correct" banners —
   must go through `localizer(...)`. Grep the screen file for string literals in
   `Text(`/`title:`/`label:` before considering the work done. If a widget (e.g. a
   video player or attempt strip) needs translated text, pass `localizer` down to
   it as a constructor param rather than hardcoding `AppLocalizations(locale: 'en')`
   inside the child.

3. **Dynamically-built sentences** (e.g. "What colour is the shirt?", "Score: 3")
   are NOT translated word-by-word in code. Add a template key with `{placeholder}`
   tokens to both translation files, plus per-item-name keys, then assemble with
   `.replaceAll`:
   ```dart
   // translations_en.dart
   'clothes_line.question': 'What colour {verb} the {item}?',
   'clothes_line.item.coat': 'coat',
   // translations_cy.dart
   'clothes_line.question': "Pa liw ydy'r {item}?",
   'clothes_line.item.coat': 'got', // mutated form — article is baked into the template
   ```
   ```dart
   localizer('clothes_line.question')
       .replaceAll('{verb}', localizer(plural ? '...verb_plural' : '...verb_singular'))
       .replaceAll('{item}', localizer('clothes_line.item.${item.definition.name}'));
   ```
   Unused placeholders are harmless — `.replaceAll` on a string that doesn't
   contain the token is a no-op, so a Welsh template can drop `{verb}` entirely if
   Welsh grammar doesn't need it (e.g. "ydy" serves both singular and plural).
   Keep any **asset-path keys** (e.g. `ClothingDefinition.name`, `clothingColours`
   used for `assets/images/colours_BSL/<name>.png`) in English and untranslated —
   those are identifiers, not display text. Only add translation keys for the
   *display* string built from them.

4. **`routes.dart`** parses the locale argument and passes it to the provider
   (and to the screen too, if the screen doesn't read it from the provider):
   ```dart
   case AppRoutes.myGame:
     final myGameLocale = settings.arguments as String? ?? 'en';
     return MaterialPageRoute(
       builder: (_) => ChangeNotifierProvider(
         create: (_) => MyGameProvider(locale: myGameLocale),
         child: const MyGameScreen(),
       ),
       settings: settings,
     );
   ```
   The Welsh home screen tile for the game must pass `arguments: 'cy'`.

5. **Shared widgets need `locale:` passed explicitly** — they default to `'en'`:
   - `GameSuccessOverlay(locale: locale, ...)`
   - `LevelSelectScreen(locale: locale, ...)`

6. **Don't double-wrap the provider.** If the screen's `build()` still has its own
   `ChangeNotifierProvider(create: (_) => MyGameProvider(), child: ...)` left over
   from before routing was added, the route-level provider (with the correct
   `locale`) is shadowed and never used. Remove the inner wrapper — the screen
   should just return its content directly, relying on the ancestor provider
   created in `routes.dart`.

## Settings & the home-screen toggle

- Add `SignSystem` to `game_filters.dart` (alongside `GameCategory`/`AgeGroup`) with
  `toPrefsString`/`fromPrefsString`.
- Add `_signSystem` state + `setSignSystem()` to `SettingsProvider`, persisted the
  same way as `language`/`gameCategory`/`ageGroup` (local prefs + Supabase metadata
  for signed-in users).
- Each home screen (`home_screen.dart` English, `welsh_home_screen.dart` Welsh) gets
  a BSL/IAC toggle control. Sensible defaults: English home screen defaults to
  `bsl`, Welsh home screen defaults to `iac` — but both toggles should be available
  on both screens since the axes are independent.
- Game tiles / routes stay singular per game (no separate "Welsh" route) — the
  screen reads `signSystem` from `SettingsProvider` via `context.watch`.

## Migration checklist for an existing forked pair

When asked to "translate" or "add IAC support to" a game that already has a
`welsh_*` fork:

1. Pick the English/BSL version as the base.
2. Extract its letter/level data into `forSignSystem(SignSystem)`, merging in the
   Welsh-alphabet data from the `welsh_*` fork's `GameLevels`.
3. Generalize the sign-display widget to take `signSystem`.
4. Merge translation keys as `<game>.bsl.*` / `<game>.iac.*` into both
   `translations_en.dart` and `translations_cy.dart`.
5. Point the single route at the merged provider/screen; delete the `welsh_*`
   directory and its route/GameIds entry once the merged version is verified with
   `flutter analyze` and a manual playthrough of all four combinations
   (en+bsl, en+iac, cy+bsl, cy+iac).

## Checklist for a brand-new game

1. One `lib/features/<game>/{providers,screens,widgets}` directory — never `welsh_<game>`.
2. Provider/screen take `locale` and `signSystem` (read from `AppLocalizations.of`/
   `SettingsProvider`, not hardcoded).
3. `GameLevels.forSignSystem()` for any letter/level data that differs between
   English and Welsh alphabets.
4. Sign images via the shared sign-display widget with `signSystem` passed through.
5. Translation keys: `<game>.title`, `<game>.intro`, `<game>.<bsl|iac>.levelN.name`,
   etc., added to both `translations_en.dart` and `translations_cy.dart`.
6. Single `AppRoutes.<game>` entry, single `GameIds.<game>` entry.
7. One tile, shown on both home screens, reading the user's current `signSystem`.
