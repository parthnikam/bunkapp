# Repository guide for agents

## What this repository contains

**Bunk** is a Flutter student attendance and timetable app. It lets a student
track classes they skip ("bunks"), see attendance projections, and plan around
holidays and long weekends. The main app is in Dart/Flutter, uses Riverpod for
state, persists student data with `shared_preferences`, and can refresh
timetable data from Supabase. The repository also contains timetable JSON data,
Flutter platform projects, and a few data/icon utilities.

Git history currently contains only the initial commit. Treat the checked-in
source, tests, and configuration as the record of current behavior; do not
infer undocumented past decisions or claim a feature is production-ready just
because a platform folder exists.

## Project map

- `lib/main.dart`: app startup, optional Supabase initialization, theme, app
  initialization, onboarding gate, and the main tab layout.
- `lib/screens/`: Home, Calendar, Statistics, Settings, Long Weekends, and
  onboarding screens.
- `lib/state/`: models, settings/UI/bunk/holiday state, timetable parsing and
  derived providers, attendance calculations, app initialization, and
  long-weekend calculations. `lib/state.dart` re-exports the state API used by
  screens and tests.
- `lib/widgets/` and `lib/theme/`: shared UI components and the app's custom
  light/dark theme.
- `lib/timetable_fetch.dart`: optional Supabase timetable fetch and local
  persistence.
- `time_tables/`: checked-in timetable datasets organized by department.
  Payloads can contain year and semester date ranges, section timetables, and
  course information. `lib/state/timetable_provider.dart` also supports
  semester-nested and legacy flat timetable shapes.
- `test/`: Flutter tests for attendance modes and UI, calendar previews,
  statistics, long weekends, theme, and contact UI.
- `assets/`: app images, logo, and audio.
- `tool/generate_icons.py`: regenerates web/PWA and desktop/mobile icons from
  `assets/logo/logo.png`; it requires Pillow.
- `parse_timetable.py`: an OCR-oriented helper that reads a root-level
  `ocr.txt` and writes `lib/timetable_data.dart`. It is not the current
  Supabase/JSON timetable loading path.
- `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and `web/`: Flutter
  platform projects. `vercel.json` configures a web release build and SPA
  fallback routing.

## Architecture and behavior to preserve

- Keep UI in screens/widgets, shared domain/state logic in `lib/state/`, and
  reusable presentation tokens in `lib/theme/`. Prefer extending an existing
  provider or helper to duplicating calculations in a screen.
- Riverpod providers are the source for app state and derived values. Settings,
  UI selections, bunk records, and user holidays are persisted locally. Use
  their notifiers for changes so in-memory state and persistence stay aligned.
- A timetable may have `sem1`/`sem2`; resolve the active semester from its
  start/end dates rather than trusting a stale saved `current_sem`. Section
  data is selected from the active semester, with fallback support for other
  semester/root layouts.
- A bunk is recorded for a date and subject. Preserve the date-based storage
  behavior when semester start dates change; do not silently reinterpret saved
  bunk records as different calendar days.
- Attendance supports two display/calculation modes: **Overall** projects
  against all planned classes in the semester/filter window; **Current**
  divides attendance by classes held through today. A future class previewed
  as bunked affects its projected result. Maintain the existing distinction
  between classes held, classes attended, missed classes, and planned total.
- User-added holidays and timetable-provided holidays are combined. Exam days
  are represented separately and excluded from normal class/holiday-based
  attendance and bunk planning as implemented by the providers. Long-weekend
  suggestions must not offer an exam day as a bunk day.
- Be careful with timetable input: data is JSON from more than one source and
  can have nested semesters, varying key types, and date/time formats. Reuse
  the parsing/normalization helpers in `lib/state/utils.dart` and
  `lib/state/timetable_provider.dart`; keep malformed or absent optional
  timetable data from crashing the UI.
- Supabase is initialized only when both `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` compile-time values are present. Keep credentials
  out of source control. The local timetable payload remains the app's
  persisted read source; a failed/empty remote refresh should not erase it.
- The app is Cupertino-oriented with a custom theme, while using selected
  Material widgets where useful. Preserve light/dark theme behavior and
  provide responsive layouts for narrow screens when changing UI.

## Coding conventions

- Follow the existing Dart/Flutter style: two-space indentation, trailing
  commas for multiline Dart calls/collections, `UpperCamelCase` types,
  `lowerCamelCase` members, and `snake_case.dart` file names.
- Run `dart format` on changed Dart files. The analyzer includes
  `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`; do not
  disable a lint broadly to hide an issue. Keep state/models typed and use
  existing safe parsing helpers at untrusted JSON boundaries.
- Model state changes immutably (existing state models use `copyWith`) and
  keep derived values in providers. In widgets, watch narrowly with
  `ref.watch`/`select` where practical; trigger side effects through the
  relevant notifier.
- Follow nearby import and widget patterns rather than introducing a new
  architecture or dependency for a local change. Avoid unrelated refactors.
- Add or update tests under `test/` for behavior changes. For provider tests,
  use the existing `ProviderContainer`/provider-override approach; mock local
  preferences with `SharedPreferences.setMockInitialValues({})`. Keep widget
  tests deterministic by setting explicit dates and app state.
- Keep timetable data changes consistent with the shapes consumed by the
  timetable providers. The root `.gitignore` ignores `*.json`; already tracked
  JSON files remain tracked, but a newly added JSON data file may need to be
  explicitly force-added.

## Useful commands

Run from the repository root with Flutter/Dart available:

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
```

For a web build, provide the Supabase compile-time values when using remote
timetable fetching:

```sh
flutter build web --release \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Supabase values are optional for startup; without them the app skips
initialization and remote timetable fetching. Do not put real credentials in
tracked files or command examples committed to the repository.
