# Game Note Companion Guide

`AGENTS.md` is the canonical contributor guide. This document is a compact orientation for Game Note 4.0; when the two differ, follow `AGENTS.md`.

## Product and Architecture

Game Note is an Android/iOS Flutter application for online football and esports groups and tournaments. The app uses Firebase Auth, Cloud Firestore, Storage, BLoC, and `get_it`; SharedPreferences supports local preferences and caches. Firestore is the tournament source of truth.

Production Dart code is organized as follows:

- `lib/core/`: shared helpers, theme, cache, localization support, and widgets.
- `lib/domain/`: contracts, entities, and use cases.
- `lib/data/`: repository implementations and data coordination.
- `lib/firebase/`: Auth, Firestore, and Storage adapters/models.
- `lib/presentation/`: routes, screens, components, and BLoCs.

Tests mirror these paths under `test/`. Native projects are `android/` and `ios/`; Cloud Functions run from `functions/` on Node 20; and `game-note-landing/` is a retained standalone static site. Keep landing-site changes independent from the mobile app.

The retained product surface includes Apple, Google, and email/password authentication; group membership and ownership; protected account deletion; settings; English/Vietnamese localization; and League, Cup, and Full tournament formats. Preserve realtime subscriptions, fixtures, results, standings, brackets, history, costs, and aggregated statistics. Before changing a Firestore operation, trace its read/write path. Do not weaken transactions, idempotency, ownership checks, or concurrent score/result-update behavior.

## Working Practices

Keep presentation widgets focused on rendering and interactions. Put business rules in BLoC handlers, use cases, repositories, or Firebase adapters, and add runtime dependencies through `lib/injection_container.dart`. Follow existing feature BLoC grouping and repository contracts rather than introducing global state.

Use standard Dart formatting: two spaces, `snake_case.dart` files, `PascalCase` types, and `lowerCamelCase` members. Use generated localization APIs through the build context; update ARB-backed behavior with localization tests rather than hard-coded display strings.

Work TDD-first: add or revise a focused observable test, observe the intended failure, make the smallest implementation change, then rerun the target. Use `flutter_test`, `bloc_test`, `mocktail`, and `fake_cloud_firestore` as needed. Production changes require matching tests; target full line coverage for testable `lib/` code, with generated output, `main.dart`, DI, and platform glue exempt. State exactly which checks were run.

## Commands

Run Flutter commands from the repository root:

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

For Functions, run `cd functions && npm install`, then `npm test`, `npm run lint`, or `npm run serve`. Prefer a targeted test before the full suite.

## Pull Requests and Releases

Use focused Conventional Commit subjects and short-lived branches. All changes go through a PR to `main`; never push directly to `main`. Describe scope, verification, and visual evidence when relevant. Required CI must be green.

Every merge to `main` is a production release. A PR touching `lib/`, `android/`, or `ios/` must bump `version:` in `pubspec.yaml` and add a matching dated `[X.Y.Z+N]` entry to `CHANGELOG.md`. Increment `+N` by exactly one from latest `main` and never reuse it. Use a minor version for user-facing features, a patch for fixes/internal work, and a major version only for an intentionally planned breaking release. Docs-only and test-only PRs are exempt.
