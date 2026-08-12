# Repository Guidelines

## Project Structure & Module Organization

Game Note 4.0 is an Android/iOS Flutter app for online groups and tournaments. Dart source lives in `lib/`: contracts/use cases in `lib/domain/`, repositories in `lib/data/`, Firebase wrappers in `lib/firebase/`, UI and BLoCs in `lib/presentation/`, and cross-cutting helpers in `lib/core/`. Register runtime dependencies with `get_it`; keep business logic out of widgets.

Tests mirror source paths under `test/`; assets belong in matching `assets/` folders. Native projects are `android/` and `ios/`. Functions are in `functions/`; `game-note-landing/` is a retained static site. No Flutter Web app.

Firestore is the source of truth. Preserve membership, permissions, League/Cup/Full, realtime subscriptions, fixtures, results, standings, brackets, history, costs, and statistics aggregation. Trace full read/write paths before changing transactions, idempotency, or concurrent score/result updates.

## Build, Test, and Development Commands

Run Flutter commands from the root:

```bash
flutter pub get
flutter run
dart format .
flutter analyze
flutter test
flutter test --coverage
flutter build appbundle --release
flutter build ios --release --no-codesign
```

For Functions, run `cd functions && npm install`, then `npm test`, `npm run lint`, or `npm run serve`. Start with a focused test.

## Coding Style & Naming Conventions

Use Dart's two-space formatting and accept `dart format` output. Use `snake_case.dart` filenames, `PascalCase` types, and `lowerCamelCase` members. Keep BLoC files grouped by feature; prefer explicit dependency seams.

## Testing Guidelines

Work TDD-first: write an observable focused test, see the intended failure, make the smallest change, and rerun it. Use `flutter_test`, `bloc_test`, `mocktail`, and `fake_cloud_firestore` as appropriate. Name tests `*_test.dart`, mirror source paths, and describe behavior in English or Vietnamese. Production changes need matching tests; retain 100% line coverage for testable `lib/` code. Generated code, `main.dart`, DI, and platform glue are exempt. Report what was verified.

## Commit & Pull Request Guidelines

Use focused Conventional Commit-style subjects (`feat:`, `fix:`, `docs:`, `chore:`). Work on a short-lived branch and open a PR to `main`; never push directly to `main`. Explain scope and verification; include visual evidence where relevant. Required CI must be green before merge.

## Versioning Before Merge

Every merge to `main` triggers a production release. A PR touching `lib/`, `android/`, or `ios/` must bump `version:` in `pubspec.yaml` and add a matching dated `[X.Y.Z+N]` `CHANGELOG.md` entry. Increment `+N` by exactly one from latest `main`; never reuse it. Use minor for user-facing features, patch for fixes/internal work, and major only for an intentionally planned breaking release. Docs-only and test-only PRs are exempt.
