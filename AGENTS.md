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

## Release / PR Guardrails

- The standard workflow is intentionally simple: start from `main`, create a short-lived branch, open a PR, merge it, then clean up the branch.
- Never work directly on `main`. Before any file edit, commit, reset, merge, cherry-pick, implementation task, or documentation task, check `git status` and switch/create a branch from the latest `main`.
- Never push directly to `main`. All changes go through a pull request targeting `main`.
- After a PR is merged, delete the remote branch and any local branches that are no longer needed, keeping `main` as the clean baseline.
- Before opening or updating a PR, verify the relevant checks for the change, such as `flutter analyze`, targeted tests, or docs-only review.

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

1. Fetch/check the latest `main`, inspect `git status`, and create a short-lived branch from `main` before editing.
2. Break the request into small, file-scoped tasks before implementation.
3. Read the local feature/module before changing it.
4. Edit only the necessary files.
5. Run the smallest useful verification first, then broader checks if needed.
6. Commit, push the branch, open a PR targeting `main`, and merge only after review/checks are acceptable.
7. Clean up the merged remote/local branch and return to a clean `main`.
8. Report what changed, what was verified, and any remaining risk.

## Parallel Agent Workflow

- For every non-trivial task flow, including feature implementation, bug fixes, refactors, UI work, test writing, and test failure repair, first split the work into small independent tasks.
- When the current environment exposes a multi-agent tool, spawn subagents for independent tasks so work can run in parallel.
- Prefer spawning each subagent with model `gpt-5.3-codex-spark` when model selection is supported.
- Treat subagents as best-effort parallel help, not as blockers for the main task flow:
  - the main agent must keep the critical path moving locally
  - do not wait indefinitely for a subagent
  - use short, bounded waits; if a subagent stalls, inspect the relevant diff directly
  - if the file already has a correct patch or the main agent can finish safely, close the stalled subagent and continue
  - do not wait for every subagent to return before reviewing completed work
- Keep subagent ownership narrow:
  - one production-code subagent may modify only one production file
  - one test subagent may modify only one test file
  - a subagent may read related files, but must not edit files outside its assigned ownership
  - if a change requires touching multiple files, split it into multiple subagent tasks or keep integration edits in the main agent
- Use subagents for clearly separated scopes, such as:
  - one widget/page file
  - one BLoC/repository/use-case file
  - one failing test file
  - one new test file mirroring a changed production file
  - one isolated documentation/config file
- Do not spawn subagents for tiny single-file edits where the overhead is clearly higher than the work, or when the environment does not expose a multi-agent tool.
- Avoid spawning subagents when the expected coordination, wait time, or review cost is likely to exceed doing the edit directly.
- Give each subagent a self-contained prompt with:
  - the exact single file it may edit
  - the related files it may read for context
  - the test command or failure it should focus on
  - constraints to avoid touching unrelated files
  - a requirement to preserve user changes and not revert work from other agents
  - a final summary listing changed files, root cause, and verification run
- The main agent remains responsible for integration:
  - decompose the work before dispatching subagents
  - review subagent changes before accepting them
  - trust the actual git diff and verification output more than the subagent's final message
  - resolve conflicts or overlapping edits deliberately
  - make any required cross-file wiring edits directly when coordination is safer than delegating
  - run targeted tests after integration
  - run broader `flutter test` or `flutter analyze` when practical before reporting completion

## Existing Project Context

- `CLAUDE.md` already contains longer-form repo guidance. Use it as a secondary reference if deeper conventions are needed.
