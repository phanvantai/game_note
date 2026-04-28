# AGENTS.md

This file gives coding agents the minimum working context for this repository.

## Project Summary

- Project: `pes_arena`
- Stack: Flutter mobile app with Firebase, SQLite, BLoC, and `get_it`
- Main product areas:
  - Offline tournament management stored locally with SQLite
  - Online football/esports community features backed by Firebase
  - Supporting web landing page in `game-note-landing/`
  - Firebase Cloud Functions in `functions/`

## Repository Layout

- `lib/`: production Dart code
- `test/`: Dart tests mirroring `lib/`
- `assets/`: app assets
- `android/`, `ios/`: platform projects
- `functions/`: Firebase Cloud Functions (Node.js 18)
- `game-note-landing/`: static landing/support site

## Architecture

The app mostly follows clean architecture.

- `lib/domain/`: repository interfaces and use cases
- `lib/data/`: online/Firebase repository implementations
- `lib/presentation/`: UI and BLoC for online/app-shell flows
- `lib/offline/`: offline feature set with its own domain/data/presentation split
- `lib/firebase/`: Firebase service wrappers and Firestore models
- `lib/injection_container.dart`: dependency registration
- `lib/routing.dart`: route definitions

When adding a feature, prefer this order:

1. Define or update domain contracts.
2. Implement data/repository logic.
3. Wire BLoC/state transitions.
4. Update UI.
5. Register dependencies in `lib/injection_container.dart` if needed.
6. Add or update tests.

## Common Commands

Run from repo root unless noted.

```bash
flutter pub get
flutter analyze
flutter test
flutter test --coverage
flutter run
flutter build apk
flutter build ios
```

For Cloud Functions:

```bash
cd functions
npm install
npm run lint
npm run serve
```

## Environment Notes

- Flutter SDK required: `>=3.41.0`
- Dart SDK required: `>=3.10.0 <4.0.0`
- Firebase is configured for app and functions, but local secrets/config may still be required for full end-to-end runs.
- Do not commit secrets or replace platform Firebase config files unless the task explicitly requires it.

## Code Conventions

- Use snake_case filenames and PascalCase types.
- Follow existing BLoC structure for feature work:
  - `bloc/..._bloc.dart`
  - `bloc/..._event.dart`
  - `bloc/..._state.dart`
- Keep business logic out of widgets when it can live in use cases, repositories, or bloc handlers.
- Reuse existing Firestore model patterns:
  - serialization/deserialization lives close to model/service code
  - prefer testable `fromMap(...)` style helpers when Firestore snapshots are awkward to mock
- Register new services and blocs in `lib/injection_container.dart`.

## Testing Expectations

- Keep `flutter analyze` clean.
- Run targeted tests for touched areas at minimum; run full `flutter test` when practical.
- Mirror `lib/` paths under `test/`.
- Add unit/widget tests for changed production behavior, especially:
  - BLoC transitions
  - repository logic
  - serialization/deserialization
  - widgets with conditional rendering or computed output

Existing repo guidance targets very high coverage for production code under `lib/`, with typical exclusions such as generated files, `main.dart`, and platform glue.

## Change Guardrails

- This repo may already contain user changes. Check `git status` before editing and do not revert unrelated work.
- Prefer minimal, local fixes over broad refactors unless the task explicitly asks for structural cleanup.
- Avoid introducing new dependencies unless there is a clear reason.
- Preserve existing architecture patterns instead of mixing new state-management or DI approaches.
- For Firebase/Firestore changes, update tests and related model mapping together.
- For SQLite schema changes, inspect the offline database managers carefully before editing.

## Area-Specific Tips

### Flutter App

- App entry is `lib/main.dart`.
- App-level shell/state is centered around `lib/app.dart` and `lib/presentation/app/`.
- Many features already separate offline and online flows; do not collapse them together casually.

### Firebase

- Firestore models/services live under `lib/firebase/firestore/`.
- Real-time tournament/group behavior likely depends on listener-driven repository code; watch for duplicated listeners or unbounded fetch loops.

### Functions

- `functions/index.js` is the Cloud Functions entrypoint.
- Keep Node changes isolated to `functions/` and validate with the package scripts there.

### Landing Page

- `game-note-landing/` is a standalone static site. Keep changes self-contained and avoid importing Flutter app assumptions into that folder.

## Preferred Agent Workflow

1. Inspect `git status` and touched files before making edits.
2. Read the local feature/module before changing it.
3. Edit only the necessary files.
4. Run the smallest useful verification first, then broader checks if needed.
5. Report what changed, what was verified, and any remaining risk.

## Existing Project Context

- `CLAUDE.md` already contains longer-form repo guidance. Use it as a secondary reference if deeper conventions are needed.
