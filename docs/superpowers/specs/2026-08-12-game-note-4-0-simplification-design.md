# Game Note 4.0 Simplification Design

**Date:** 2026-08-12

**Release:** `4.0.0+49`

**Target platforms:** Android and iOS

**Delivery:** one pull request to `main`, opened only after every phase and release gate is complete

## Purpose

Game Note 4.0 narrows the product around how it is actually used: signed-in players belong to one or more PES groups, create and play tournaments together, update results collaboratively, review standings or brackets, and settle playing costs. The release removes product surfaces and runtime services that do not support that loop while preserving the recently stabilized online data flow.

This is a simplification of the existing Flutter application, not a rewrite. Work may be split into dependency-aware phases and reviewable commits, but all phases ship together in one final PR because every merge to `main` is a production release.

## Product Scope

### Core flow retained

The supported product loop is:

1. A user signs in with an individual account.
2. The user creates, joins, or switches between multiple groups.
3. Group members manage membership and use the existing group detail and statistics surfaces.
4. Eligible members create League, Cup, or Full tournaments.
5. Tournament participants update match results through the existing authorization and realtime flow.
6. Members review fixtures, results, standings or brackets, tournament history, and cost allocation.
7. A user reviews a deliberately small personal summary.

Discovery and existing lists of other groups or tournaments remain available. This release must not collapse the product into a single-group model or a League-only model.

### Four-tab application shell

The authenticated mobile shell contains exactly four destinations, in this order:

1. **Home** — ongoing tournament context and the simplified personal dashboard.
2. **Groups** — multiple groups, membership, permissions, group detail, and group-related statistics.
3. **Tournaments** — League, Cup, and Full creation, discovery, management, and history.
4. **Profile** — name and avatar management, language, theme, account security, and sign out.

The notification destination and unread badge are removed. Existing routes such as `/groups` must still select the correct tab after the tab indexes change. An invalid `initialTabIndex` remains safely clamped to a valid destination.

### Simplified personal dashboard

The personal dashboard presents only:

- recent form;
- recent matches;
- date of the most recent championship;
- championship rate;
- runner-up rate;
- head-to-head records, including nemesis and prey.

The UI removes lifetime goal totals, lifetime goal difference, generic lifetime match aggregates, the per-league performance chart, and other overview cards that are not in the list above. Empty values use the current neutral empty representation rather than invented zero-percent success, and existing loading, cached-data, empty, failure, retry, and pull-to-refresh behavior is preserved where applicable.

The dashboard continues consuming the current stats summary. `DashboardStats`, its Firestore mapping, caches, repositories, and stats Cloud Functions may retain fields the 4.0 UI no longer renders. Presentation simplification is not a reason to shrink the persisted stats schema or recompute pipeline in this release.

### Simplified profile

The Profile tab retains the user identity header and avatar actions, profile editing, language and theme settings, account-security actions, and sign out. It removes:

- offline mode;
- offline-to-online sync;
- in-app feedback;
- rate-app actions;
- menu items or hidden interactions that do not support identity, preferences, account security, or sign out.

A passive version label may remain as diagnostic metadata, but it must not expose a hidden feature or gesture.

## Removed Capabilities

### Notifications

Remove the notification presentation pages, BLoC, repository contracts and implementations, models, routes, unread state and badges. Remove Firebase Messaging initialization, the background handler registration, device-token acquisition or refresh, notification permission prompts, and writes of FCM token fields.

Remove notification-only Cloud Function exports, helpers, and tests that create notification records or send push messages. Keep stats, group, tournament, cleanup, and other non-notification functions unchanged. Remove notification-only Firestore rule or index configuration only when it is no longer referenced; do not change core group, tournament, match, membership, or stats access rules as part of that cleanup.

Existing notification documents and historical token fields in production are left inert. The app and Functions stop reading or writing them, but this PR performs no destructive data migration.

### Offline mode and sync

Remove the complete offline tournament feature, including SQLite database management, local data sources, local repositories and use cases, offline presentation, local league state, and offline routes. Remove the offline-to-online migrator, gateway, sync BLoC, sync UI, and all related DI registrations and tests. Remove `sqflite`, `path`, or other packages that are present only for this feature after reference verification.

All required local tournament data has already been synchronized. Firestore becomes the only tournament source of truth. Existing SQLite files on installed devices are not opened, migrated, or explicitly deleted; they become unused app-container data that the operating system may remove on uninstall. The application must not fall back to offline tournament state when Firebase operations fail.

SharedPreferences remains in use for language, theme, caches, and other retained small preferences. Removing SQLite does not mean removing those preferences.

### Advertising and ad configuration

Remove Google Mobile Ads, banner state and widgets, ad helpers, ad initialization, platform ad identifiers or manifest entries, and ad-specific tests. Remove the Remote Config wrapper, dependency, initialization, and keys when their only purpose is advertising. No replacement monetization surface is introduced.

Firebase Analytics or another Firebase service must not be removed merely because advertising is removed; each dependency is removable only after confirming it has no retained caller.

### Flutter Web application

Remove support for building or running the Flutter application on Web:

- the Flutter `web/` platform directory and web-only shell;
- `flutter_web_plugins` and URL-strategy wiring;
- web-only branches and guards that exist solely to support Flutter Web;
- Flutter Web Firebase platform configuration that is no longer consumed;
- CI or deployment workflows and hosting targets that build or publish the Flutter Web application.

Android and iOS Firebase configuration remains intact. The standalone `game-note-landing/` website, including landing, privacy, and support pages and its own deployment configuration, remains fully supported and must not be deleted, renamed, or coupled to Flutter code. Any external teardown of a previously hosted Flutter Web deployment is a separate operational action and is not performed by this PR.

### Feedback and rating

Remove the feedback page, route, persistence or Firestore calls, models, tests, localization strings, and profile entry point when they exist only for in-app feedback. Remove rate-app URLs, launch actions, localization strings, and profile entry point. Retained support or privacy links on the standalone landing site are unaffected.

## Architecture Boundaries

### Protected online core

The following area is functionally frozen for this release except for the smallest import, registration, or compile repair strictly required after deleting an external module:

- Firebase Auth session restore, sign-in, profile completion, and account permissions;
- multiple groups, membership, ownership, member permissions, group deletion safeguards, group detail, and group statistics;
- League, Cup, and Full tournament creation and lifecycle;
- participants, fixtures, results, standings, brackets, history, and cost allocation;
- participant authorization to create or update results;
- Firestore repositories and live subscriptions for groups, tournaments, and matches;
- transactions, concurrency control, deduplication, refresh-on-resume, and asynchronous state handling;
- the current Firestore collections, document shapes, indexes, and security rules for retained core data;
- current user and group stats schemas, caches, aggregation triggers, recompute functions, and mapping logic.

Removing notification side effects from a trigger must not change the trigger's retained stats or domain behavior. If notification and retained logic currently share a handler, extract or delete only the notification branch and lock the retained behavior with tests before modifying it.

No new state-management pattern, repository abstraction, backend service, or local persistence layer is introduced. Existing BLoC, repository, `get_it`, and Firebase patterns remain the architectural baseline.

### Dependency direction after simplification

The mobile startup and shell may depend on retained auth, group, tournament, dashboard, profile, localization, theme, and Firebase services. None of those retained modules may import notification, offline, sync, ad, Remote Config, or Flutter Web code. Deleted modules must also disappear from DI registrations, routing imports, generated localization output, platform configuration, and package manifests so there are no dormant runtime paths.

### Source-of-truth rule

Firestore is the only source of truth for groups, tournaments, matches, and statistics. SharedPreferences may cache retained dashboard or group overview data for responsiveness, but cached values do not gain write authority and cannot replace the established Firestore refresh path.

## Startup Design

The Android and iOS startup sequence is reduced to:

1. initialize Flutter bindings;
2. initialize Firebase Core with the existing mobile options;
3. initialize dependency injection for retained online services and preferences;
4. load SharedPreferences-backed locale and theme state;
5. start the app and restore auth through the existing `AppBloc` flow.

Startup does not register a messaging background handler, request notification permission, initialize Messaging, initialize Remote Config, initialize Mobile Ads, open SQLite, or configure a web URL strategy. Firestore, Auth, Storage, and retained repositories preserve their current lazy or DI lifecycle unless a compile-safe cleanup is required.

Failure to initialize a retained mandatory service follows the existing startup error/reporting policy; it must not silently enter an offline mode. Optional dashboard data failures are handled inside the dashboard with retained cached-data and retry behavior rather than blocking app launch.

## Routing and Upgrade Behavior

- Existing authenticated sessions remain valid across the upgrade.
- No migration is required for group, tournament, match, membership, cost, or stats documents.
- Core deep links for retained group and tournament screens preserve their current auth redirect and destination behavior.
- Routes and page imports for notification, offline, sync, and feedback are removed.
- A launch or in-app navigation attempt to a retired route resolves to Home through a small router-level legacy-path fallback; it must not construct a deleted page, access deleted storage, or enter a redirect loop.
- Retired paths are rejected by `safeNextLocation`, so auth and locale bounce-back cannot restore a removed destination after login.
- Unknown malformed routes use the same safe Home fallback and produce no crash.
- Removing Flutter Web-specific transitions must leave the current mobile transition behavior unchanged.

The legacy-path fallback is compatibility routing only, not a retained feature API. It may recognize the former exact path strings without retaining public feature constants, DI registrations, page classes, or tests for deleted feature behavior.

## Error Handling

- Retained repositories continue returning their established failure types; this release does not recast online failures as local success.
- Dashboard load failure with no usable data shows a localized error and retry action. Failure during refresh may continue showing the last valid cached summary with the existing refresh indication.
- Empty recent matches, no completed tournament, and insufficient head-to-head sample data render explicit neutral states; they do not throw, divide by zero, or select a misleading nemesis or prey.
- Group and tournament realtime listeners preserve their current cancellation, deduplication, and stale-result protections.
- Result updates preserve current permission checks and concurrency behavior. Simplification must not introduce optimistic writes outside the established repository flow.
- Removed service calls are deleted rather than wrapped in broad exception suppression.
- Unsupported retired links return Home; authenticated core-link failures keep the existing auth and safe-next behavior.

## Test-Driven Delivery

Behavior changes follow RED, then GREEN, in small file-scoped phases. Deleting obsolete tests is acceptable only after replacement tests prove the retained public behavior.

### Required behavior tests

1. **Application shell:** begin with a failing widget test that expects exactly four destinations using the localized accessible labels for Home, Groups, Tournaments, and Profile; then remove Notification and make it pass. Assert ordering, selection, profile's shifted index, invalid-index clamping, and absence of unread badges.
2. **Startup and DI:** add focused tests or registration assertions proving retained services resolve while notification, offline, sync, ads, and Remote Config are neither initialized nor registered. Platform-glue exclusions do not waive tests for testable DI behavior.
3. **Routing:** test retained auth and locale redirects, retained group and tournament links, corrected tab selection, safe rejection of retired paths, and Home fallback without loops for retired or malformed links.
4. **Dashboard:** start from tests that fail while removed lifetime metrics or charts remain visible. Assert recent form and matches, last championship, championship and runner-up rates, H2H, nemesis, prey, empty data, insufficient H2H sample size, cached content, refresh, failure, and retry.
5. **Profile:** assert the retained identity, preference, security, and sign-out actions and the absence of offline, sync, feedback, rating, and hidden nonessential actions.
6. **Removed integrations:** update or remove tests together with notification, offline, sync, ads, feedback, and Web production code. Add narrow boundary checks where useful to prevent imports, routes, registrations, dependencies, or platform permissions from returning.
7. **Protected core regression:** run all existing unit, BLoC, widget, repository, serialization, and integration-style tests covering group membership and permissions, League/Cup/Full creation, participant result updates, realtime refresh, transactions or concurrency, standings, brackets, history, costs, and stats aggregation.
8. **Cloud Functions:** retain tests for every non-notification export and add a regression test when a shared trigger loses only its notification side effect.

Tests mirror `lib/` paths, use accessible roles and localized names for navigation and controls, and avoid fixed DOM identifiers. Pure presentation changes do not justify rewriting retained repositories or Firestore models.

## Implementation Phases

All phases occur on one short-lived `codex/` branch from the latest clean `main`. Each phase ends in a coherent local commit and targeted verification, but no push or PR is authorized merely by approving this design.

1. Lock protected group, tournament, realtime, and stats behavior with targeted regression tests.
2. Remove notification UI, client data layers, Messaging/token wiring, notification-only Functions behavior, and platform permissions.
3. Remove offline SQLite and offline-to-online sync end to end.
4. Remove ads and ad-only Remote Config end to end.
5. Remove Flutter Web app support while preserving `game-note-landing/`.
6. Convert the shell to four tabs and add retired-route fallback behavior.
7. Simplify dashboard and Profile presentation without changing current stats or core Firestore schemas.
8. Remove orphaned dependencies, imports, assets, localization keys, generated references, rules or indexes, tests, and configuration proven unused.
9. Set `pubspec.yaml` to `4.0.0+49` and add a dated `[4.0.0+49]` entry to `CHANGELOG.md` summarizing the breaking product simplification.
10. Run the complete release gate and perform a final protected-core diff review.

The implementation plan must decompose edits according to the repository's one-worker-per-file rule and sequence shared contracts before dependent files. The main agent owns integration review and final verification.

## Verification and Release Gate

Run the smallest relevant test after each RED/GREEN cycle. Before opening the single final PR, all of the following must pass from the repository root:

```bash
flutter pub get
git diff --name-only --diff-filter=ACMR -- '*.dart' | xargs dart format
flutter analyze
flutter test --coverage
npm --prefix functions run lint
flutter build appbundle --release
flutter build ios --release --no-codesign
git diff --check
```

In addition:

- run targeted tests for every changed phase before the full suite;
- inspect coverage for newly changed production code under `lib/` against the repository's coverage policy;
- search the repository for removed module imports, routes, DI types, package names, FCM token writes, notification function exports, web build commands, and ad identifiers;
- review Android and iOS permission/config diffs to confirm only removed integrations changed;
- review Functions exports to confirm stats and other non-notification handlers remain;
- review the final diff specifically for changes to group, tournament, match, stats, Firestore rules, and concurrency code;
- confirm `game-note-landing/` and its deployment path remain untouched and operational;
- confirm the version is exactly `4.0.0+49` and the changelog heading matches;
- confirm the branch contains all phases before any PR is opened.

If an iOS build is blocked only by unavailable signing or Apple infrastructure, `--no-codesign` is the required local boundary and the limitation must be reported exactly. Authenticated device behavior, production Firestore, Google Play, App Store Connect, and external hosting are not claimed verified by local commands.

Push, PR creation, and merge are separate remote actions and each requires explicit user authorization. The PR targets `main`; it must not be merged until all required CI checks are green because the merge releases Android production.

## Acceptance Criteria

Game Note 4.0 is ready for its final PR only when all of the following are true:

- Android and iOS are the only Flutter application targets.
- `game-note-landing/`, privacy, and support content remain intact.
- The authenticated shell shows exactly Home, Groups, Tournaments, and Profile in that order.
- Multiple groups, membership, ownership and permissions, group detail and statistics, and group or tournament discovery still work through their current online paths.
- League, Cup, and Full creation and lifecycle remain available.
- Eligible participants can update results with the existing realtime and concurrency protections.
- Fixtures, results, standings, brackets, history, and costs remain available and their regression tests pass.
- The personal dashboard shows only the approved recent form, recent matches, last championship, championship rate, runner-up rate, and H2H/nemesis/prey information.
- Profile exposes only retained identity, preference, account-security, sign-out behavior, and optional passive version metadata.
- No notification page, unread badge, notification repository/model/BLoC, Messaging runtime, permission prompt, FCM token write, or notification-only Cloud Function remains active.
- No offline page, SQLite initialization, local tournament repository, or sync path remains active.
- No ad UI, Mobile Ads runtime, ad platform configuration, or ad-only Remote Config path remains active.
- No Flutter Web app build, runtime branch, workflow, or hosting target remains active.
- Retired routes and malformed links return safely to Home without a crash or redirect loop.
- Existing notification documents, token fields, and SQLite files are left untouched and inert; there is no destructive production migration.
- Core Firestore schemas and retained stats functions are unchanged except for removal of isolated notification side effects.
- `pubspec.yaml` and `CHANGELOG.md` identify the release as `4.0.0+49`.
- Targeted tests, full coverage tests, analysis, Functions lint, Android release build, iOS no-sign build, and diff checks satisfy the release gate.
- One complete PR contains all phases; no partial phase is proposed for merge to `main`.

## Explicitly Out of Scope

- Redesigning or removing existing group detail, statistics, discovery, League, Cup, or Full tournament features.
- Reworking participant permissions, Firestore transactions, realtime listeners, concurrency, result conflict handling, standings, brackets, or cost calculations.
- Shrinking or migrating retained Firestore schemas, stats documents, or historical group/tournament data.
- Deleting historical notification documents, historical token fields, or SQLite files from user devices.
- Replacing Firebase, BLoC, repositories, `get_it`, or SharedPreferences.
- Introducing a new monetization, notification, offline, or web application strategy.
- Redesigning or removing the standalone landing, privacy, or support website.
- Performing an external hosting teardown, production database cleanup, Play Store release action, App Store Connect action, push, PR creation, or merge without separate authorization.
- Broad visual redesign beyond the navigation, dashboard, and Profile simplifications specified here.
