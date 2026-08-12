# Game Note 4.0 Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Game Note `4.0.0+49` as an Android/iOS-only, online-first PES group and tournament app while removing notifications, offline/sync, ads, Flutter Web, feedback, rating, and surplus personal statistics.

**Architecture:** Preserve Firebase Auth, Firestore, BLoC, `get_it`, SharedPreferences caches, multi-group membership, and every League/Cup/Full realtime path. Remove obsolete features from their outer wiring inward, then simplify the shell, dashboard, and profile without changing retained Firestore schemas, stats aggregation, or match concurrency behavior.

**Tech Stack:** Flutter 3.41+, Dart 3.10+, BLoC, `get_it`, Firebase Auth/Firestore/Storage, SharedPreferences, Firebase Cloud Functions Node.js 20, Flutter widget/unit tests, Node `node:test`.

## Global Constraints

- Release version is exactly `4.0.0+49`; increment build number from `+48` by one.
- Flutter application targets are Android and iOS only.
- Preserve `game-note-landing/` and `.github/workflows/deploy-landing.yml` byte-for-byte.
- Preserve authentication, multiple groups, membership/ownership permissions, League/Cup/Full, realtime subscriptions, concurrency controls, fixtures, results, standings, brackets, history, costs, and stats aggregation.
- Firestore remains the only tournament source of truth; do not migrate or delete production notification documents, historical token fields, online data, or local SQLite files.
- Use RED then GREEN for every changed behavior. Delete obsolete tests only with their production feature and after retained boundary tests exist.
- Each implementation subagent owns exactly one file, including deleted and generated files. Keep 2-4 workers active, never overlap ownership, and review every diff before acceptance.
- Request `gpt-5.3-codex-spark` for workers if it becomes available. It is unavailable in the current model list, so execution may use the inherited available model and must report that limitation.
- Main agent coordinates, reviews, integrates, formats, and verifies; it does not edit implementation files except an explicitly reported emergency fallback.
- Push, PR creation, merge, store release, production cleanup, and hosting teardown each require separate authorization. Open only one complete PR to `main` after every gate passes.

---

## File Map and Ownership Strategy

Retained behavior is centered on `lib/firebase/auth/`, `lib/firebase/firestore/esport/`, `lib/data/repositories/esport/`, `lib/presentation/esport/`, and their mirrored tests. These files are frozen except for one-file compile repairs caused directly by deleted integrations.

Primary modified files and responsibilities:

- `lib/main.dart`: mobile-only minimal startup.
- `lib/injection_container.dart`: retained online registrations only.
- `lib/routing.dart`: retained routes plus safe retired-route fallback.
- `lib/presentation/main/main_page.dart`, `main_view.dart`: four-tab shell without notification/ad wiring.
- `lib/presentation/home/dashboard/dashboard_view.dart`, `detail/dashboard_detail_page.dart`, `widgets/stat_card_grid.dart`: approved personal summary only.
- `lib/presentation/profile/profile_view.dart`: retained identity/settings/version/sign-out only.
- `lib/presentation/app/bloc/app_bloc.dart`, `app_event.dart`, `app_state.dart`, `app_view.dart`: remove the hidden football toggle.
- `lib/firebase/firestore/user/gn_user.dart`, `gn_firestore_user.dart`, `lib/firebase/auth/gn_auth.dart`: remove FCM state and writes while retaining auth behavior.
- `functions/index.js`: remove notification exports and notification cleanup only; retain every stats/group-deletion behavior.
- `functions/index.test.js`, `functions/package.json`: source-boundary regression test and `npm test`.
- `pubspec.yaml`, `pubspec.lock`, `ios/Podfile.lock`: release/dependency lock cleanup.
- `firebase.json`, `firestore.rules`, `firestore.indexes.json`: remove Flutter Web Hosting and notification-only configuration.
- Android/iOS manifests and entitlements: remove ads and push configuration while retaining Google/Apple sign-in.
- ARB and generated localization files: remove only retired feature strings.

For every task, create an ownership ledger before dispatch:

```text
path | worker | action(create/modify/delete/generate) | dependency task | status
```

Dispatch one worker for each ledger row. Directory deletion means one worker per tracked file, not one worker for the directory. For generated localization and lockfiles, generate candidate output in a temporary path or isolated command step; then assign each tracked output to its own owner for application and review.

---

### Task 1: Lock the Protected Online Core

**Files:**
- Test: existing tests under `test/data/repositories/esport/`
- Test: existing tests under `test/firebase/firestore/esport/`
- Test: existing tests under `test/presentation/esport/groups/`
- Test: existing tests under `test/presentation/esport/tournament/`
- Test: existing stats tests under `test/firebase/firestore/user/stats/`

**Interfaces:**
- Consumes: current `main` behavior at design commit `c1c3cf1`.
- Produces: a recorded green baseline; no production interface changes.

- [ ] **Step 1: Record the protected-core file list and confirm a clean tree**

```bash
git status --short
git diff main...HEAD -- lib/firebase/firestore/esport lib/data/repositories/esport lib/presentation/esport
```

Expected: only the approved design/plan documents differ; no implementation changes exist.

- [ ] **Step 2: Run focused protected-core tests before deletion work**

```bash
flutter test \
  test/data/repositories/esport \
  test/firebase/firestore/esport \
  test/firebase/firestore/user/stats \
  test/presentation/esport/groups \
  test/presentation/esport/tournament
```

Expected: PASS. Any pre-existing failure stops implementation and is diagnosed before edits.

- [ ] **Step 3: Save the exact command and result in the execution log**

Do not add a code file solely for the log; append the result to the task commentary and plan tracking state.

Task 1 is read-only and produces no commit. If the baseline fails, stop and diagnose it before starting Task 2.

---

### Task 2: Remove Notifications and FCM End to End

**Files:**
- Modify: `test/presentation/main/main_view_test.dart`
- Modify: `test/presentation/main/main_page_test.dart`
- Modify: `test/routing_redirect_test.dart`
- Modify: `test/firebase/auth/gn_auth_test.dart`
- Modify: `test/firebase/firestore/user/gn_user_test.dart`
- Modify: `test/firebase/firestore/user/gn_firestore_user_test.dart`
- Create: `functions/index.test.js`
- Modify: `functions/package.json`
- Modify: `lib/presentation/main/main_page.dart`
- Modify: `lib/presentation/main/main_view.dart`
- Modify: `lib/main.dart`
- Modify: `lib/injection_container.dart`
- Modify: `lib/firebase/auth/gn_auth.dart`
- Modify: `lib/firebase/firestore/user/gn_user.dart`
- Modify: `lib/firebase/firestore/user/gn_firestore_user.dart`
- Modify: `lib/core/helpers/shared_preferences_helper.dart`
- Modify: `lib/presentation/esport/groups/group_detail/services/group_overview_calculator.dart`
- Modify: `functions/index.js`
- Modify: `firestore.rules`
- Modify: `firestore.indexes.json`
- Delete: notification files listed in Appendix A.

**Interfaces:**
- Consumes: `GNUser` identity/profile fields and all retained Functions exports.
- Produces: `GNUser` without `fcmToken`; `GNAuth.signOut()` signs out without token cleanup; Functions export only retained triggers.

- [ ] **Step 1: Write failing shell and user-model tests**

In `test/presentation/main/main_view_test.dart`, replace notification fixtures with an assertion based on localized labels:

```dart
expect(find.text('Arena'), findsOneWidget);
expect(find.text('Groups'), findsOneWidget);
expect(find.text('Tournaments'), findsOneWidget);
expect(find.text('Profile'), findsOneWidget);
expect(find.text('Notifications'), findsNothing);
expect(find.byType(NavigationDestination), findsNWidgets(4));
```

In `test/firebase/firestore/user/gn_user_test.dart`, assert old documents deserialize while the new map no longer writes a token:

```dart
final doc = _MockDoc();
when(() => doc.id).thenReturn('u1');
when(() => doc.data()).thenReturn(<String, dynamic>{
  GNUser.displayNameKey: 'Tai',
  'fcmToken': 'legacy',
});
final user = GNUser.fromFireStore(doc);
expect(user.toMap().containsKey('fcmToken'), isFalse);
```

- [ ] **Step 2: Add failing Functions source-boundary tests**

Create `functions/index.test.js`:

```js
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const source = fs.readFileSync(path.join(__dirname, "index.js"), "utf8");

test("notification exports and messaging are absent", () => {
  for (const name of [
    "createEsportGroupNotification",
    "createEsportLeagueNotification",
    "sendPushNotification",
    "getMessaging",
    "deleteNotificationsFor",
  ]) assert.equal(source.includes(name), false, name);
});

test("retained core exports remain", () => {
  for (const name of [
    "onLeagueMatchWritten",
    "onLeagueStatusChanged",
    "onRecomputeUserSummaryRequest",
    "onGroupDeletionRequestCreated",
    "onEsportLeagueWritten",
    "onRecomputeGroupSummaryRequest",
  ]) assert.equal(source.includes(`exports.${name}`), true, name);
});
```

Add to `functions/package.json`:

```json
"test": "node --test index.test.js"
```

- [ ] **Step 3: Run RED tests**

```bash
flutter test test/presentation/main/main_view_test.dart test/firebase/firestore/user/gn_user_test.dart test/firebase/auth/gn_auth_test.dart
npm --prefix functions test
```

Expected: FAIL because notification UI, FCM fields/methods, messaging imports, and notification Functions still exist.

- [ ] **Step 4: Remove client notification and FCM behavior with one-file workers**

Delete notification UI/BLoC/repository/model files from Appendix A. In retained files:

```dart
// GNAuth.signOut
Future<void> signOut() => _auth.signOut();
```

Remove `fcmToken`, `fcmTokenKey`, `updateFcmToken`, `removeFcmToken`, SharedPreferences FCM accessors, Messaging startup/DI, notification provider/tab/badge, and notification route constants/pages. Update every `GNUser(...)` fixture in its own file to the constructor without `fcmToken`.

- [ ] **Step 5: Remove backend notification behavior only**

In `functions/index.js`, delete the three notification exports, Messaging initialization, `deleteNotificationsFor`, notification cleanup loops, and the `notifications` count from `deletedCounts`. Do not modify the names or bodies of retained stats exports except the minimal removal of notification-only statements.

Remove `/users/{userId}/notifications/...` from `firestore.rules` and the notifications `fieldOverrides` entry from `firestore.indexes.json`.

- [ ] **Step 6: Run GREEN tests and audits**

```bash
flutter test test/presentation/main test/firebase/auth/gn_auth_test.dart test/firebase/firestore/user
npm --prefix functions test
npm --prefix functions run lint
rg -n "NotificationBloc|GNNotification|GNFirebaseMessaging|FirebaseMessaging|fcmToken|createEsportGroupNotification|createEsportLeagueNotification|sendPushNotification|deleteNotificationsFor" lib test functions firestore.rules firestore.indexes.json
```

Expected: tests PASS; `rg` returns no matches.

- [ ] **Step 7: Commit notification removal**

```bash
git add lib test functions firestore.rules firestore.indexes.json
git commit -m "refactor: remove notifications and push messaging"
```

---

### Task 3: Remove Offline SQLite and Offline-to-Online Sync

**Files:**
- Modify: `test/presentation/auth/auth_view_test.dart`
- Modify: `test/presentation/profile/profile_view_test.dart`
- Modify: `test/routing_redirect_test.dart`
- Modify: `lib/presentation/auth/auth_view.dart`
- Modify: `lib/presentation/profile/profile_view.dart`
- Modify: `lib/routing.dart`
- Modify: `lib/main.dart`
- Modify: `lib/injection_container.dart`
- Delete: offline/sync files listed in Appendix B.

**Interfaces:**
- Consumes: Firebase Auth and Firestore online routes.
- Produces: no `/offline`, `/offline/league`, or `/sync-offline-data` feature route; exact legacy paths safely resolve Home.

- [ ] **Step 1: Write failing tests for removed entry points**

```dart
expect(find.byIcon(Icons.wifi_off_outlined), findsNothing);
expect(find.text('Offline mode'), findsNothing);
expect(find.text('Sync offline data'), findsNothing);
```

Add routing assertions:

```dart
expect(Routing.safeNextLocation('/offline'), Routing.app);
expect(Routing.safeNextLocation('/offline/league'), Routing.app);
expect(Routing.safeNextLocation('/sync-offline-data'), Routing.app);
```

- [ ] **Step 2: Run RED tests**

```bash
flutter test test/presentation/auth/auth_view_test.dart test/presentation/profile/profile_view_test.dart test/routing_redirect_test.dart
```

Expected: FAIL because offline/sync buttons and routes remain.

- [ ] **Step 3: Delete offline/sync files one worker per file**

Dispatch bounded workers over Appendix B. Remove imports, DI registrations, SQLite `open()`, auth/profile entry points, and route page builders. Keep SharedPreferences startup and caches.

- [ ] **Step 4: Implement retired-route rejection**

In `lib/routing.dart`, keep retired exact strings private and outside `_isKnownRoutePath`:

```dart
const _retiredPaths = <String>{
  '/offline',
  '/offline/league',
  '/sync-offline-data',
  '/notification',
  '/feedback',
};

String _safeNextLocation(String? next) {
  if (next == null || next.isEmpty) return Routing.app;
  final uri = Uri.tryParse(next);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return Routing.app;
  if (_retiredPaths.contains(uri.path)) return Routing.app;
  return _isKnownRoutePath(uri.path) ? uri.toString() : Routing.app;
}
```

- [ ] **Step 5: Run GREEN tests and stale-reference audit**

```bash
flutter test test/presentation/auth/auth_view_test.dart test/presentation/profile/profile_view_test.dart test/routing_redirect_test.dart
rg -n "package:pes_arena/offline|DatabaseManager|OfflineToOnline|SyncBloc|syncOfflineData|Routing\.offline" lib test
```

Expected: PASS and no matches.

- [ ] **Step 6: Commit online-only source-of-truth change**

```bash
git add lib test
git commit -m "refactor: remove offline mode and data sync"
```

---

### Task 4: Remove Ads and Ad-Only Remote Config

**Files:**
- Modify: `test/presentation/main/main_view_test.dart`
- Modify: `test/presentation/esport/groups/group_detail/group_detail_view_test.dart`
- Modify: `test/presentation/esport/tournament/tournament_detail/tournament_detail_view_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/injection_container.dart`
- Modify: `lib/presentation/main/main_view.dart`
- Modify: `lib/presentation/esport/groups/group_detail/group_detail_view.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/tournament_detail_view.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Delete: `lib/core/helpers/admob_helper.dart`
- Delete: `lib/firebase/remote_config/gn_remote_config.dart`

**Interfaces:**
- Consumes: retained page bodies and tournament share behavior.
- Produces: the same screens without banner layout or monetization initialization.

- [ ] **Step 1: Write failing absence assertions**

```dart
expect(find.byType(BottomAppBar), findsNothing);
expect(find.byKey(const Key('tournament-detail-shell')), findsOneWidget);
```

Remove Remote Config/Messaging/ad mocks from shell/detail test harnesses; compilation is expected to fail until production wiring is removed.

- [ ] **Step 2: Run RED tests**

```bash
flutter test test/presentation/main/main_view_test.dart test/presentation/esport/groups/group_detail/group_detail_view_test.dart test/presentation/esport/tournament/tournament_detail/tournament_detail_view_test.dart
```

Expected: FAIL on obsolete imports, DI lookups, or banner expectations.

- [ ] **Step 3: Remove banner state and initialization**

For each page, delete `BannerAd`, `isAdsLoaded`, `_loadAd`, `didChangeDependencies` ad calls, ad disposal, and ad bottom bars. Keep normal `Scaffold` bodies and tournament share state.

Remove `GADApplicationIdentifier` from `ios/Runner/Info.plist` and `com.google.android.gms.ads.APPLICATION_ID` plus its comments from Android manifest.

- [ ] **Step 4: Run GREEN tests and audit**

```bash
flutter test test/presentation/main/main_view_test.dart test/presentation/esport/groups/group_detail/group_detail_view_test.dart test/presentation/esport/tournament/tournament_detail/tournament_detail_view_test.dart
rg -n "google_mobile_ads|MobileAds|BannerAd|AdmobHelper|GNRemoteConfig|GADApplicationIdentifier|APPLICATION_ID" lib test android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
```

Expected: PASS and no matches.

- [ ] **Step 5: Commit monetization removal**

```bash
git add lib test android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "refactor: remove advertising integrations"
```

---

### Task 5: Remove Flutter Web While Preserving the Static Site

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/main.dart`
- Modify: `lib/firebase_options.dart`
- Modify: `lib/firebase/auth/gn_auth.dart`
- Modify: `lib/presentation/auth/third_party/auth_buttons_view.dart`
- Modify: `lib/presentation/profile/profile_view.dart`
- Modify: `lib/routing.dart`
- Modify: `firebase.json`
- Delete: `lib/presentation/web_shell/web_shell.dart`
- Delete: `.github/workflows/web-build.yml`
- Delete: `.github/workflows/web-release.yml`
- Delete: all tracked files under `web/` listed in Appendix C.
- Preserve unchanged: `game-note-landing/**`, `.github/workflows/deploy-landing.yml`.

**Interfaces:**
- Consumes: native Android Google sign-in and iOS Apple/Google sign-in.
- Produces: `DefaultFirebaseOptions.currentPlatform` supports Android/iOS and rejects other platforms.

- [ ] **Step 1: Change auth tests to native-only expectations**

Delete tests that force `isWebForTesting: true`. Retain/add:

```dart
test('native Google sign-in authenticates and signs into Firebase', () async {
  final credential = await sut.signInWithGoogle();
  expect(credential, same(expectedCredential));
  verify(() => firebaseAuth.signInWithCredential(any())).called(1);
});
```

Keep the iOS Apple button widget test.

- [ ] **Step 2: Run RED tests**

```bash
flutter test test/firebase/auth/gn_auth_test.dart test/presentation/auth/third_party/auth_buttons_view_test.dart test/routing_redirect_test.dart
```

Expected: compilation/test failure until web constructor branches and guards are removed.

- [ ] **Step 3: Make code native-only**

Remove `WebShell`, `usePathUrlStrategy`, `kIsWeb` branches, web popup auth, web Firebase options, and web-specific transitions. Use:

```dart
if (defaultTargetPlatform == TargetPlatform.iOS) ...[
  // existing Apple button
]
```

In `firebase.json`, keep `firestore`, `flutter.android`, `flutter.ios`, `flutter.dart` Android/iOS mappings, and `functions`; remove the web mapping and `hosting` object only.

- [ ] **Step 4: Delete Flutter Web files/workflows one worker per file**

Dispatch Appendix C file owners. Before accepting each deletion, confirm its path is not under `game-note-landing/` and is not `.github/workflows/deploy-landing.yml`.

- [ ] **Step 5: Run GREEN tests and preservation audit**

```bash
flutter test test/firebase/auth/gn_auth_test.dart test/presentation/auth/third_party/auth_buttons_view_test.dart test/routing_redirect_test.dart
rg -n "kIsWeb|WebShell|flutter_web_plugins|url_strategy|flutter build web|build/web" lib pubspec.yaml firebase.json .github/workflows
git diff --exit-code main...HEAD -- game-note-landing .github/workflows/deploy-landing.yml
```

Expected: tests PASS; first audit has no matches; static site diff is empty.

- [ ] **Step 6: Commit mobile-only application support**

```bash
git add lib test firebase.json .github/workflows web
git commit -m "refactor: remove Flutter web application"
```

---

### Task 6: Finish the Four-Tab Shell and Retired-Route Fallback

**Files:**
- Modify: `test/presentation/main/main_view_test.dart`
- Modify: `test/presentation/main/main_page_test.dart`
- Modify: `test/presentation/esport/groups/groups_view_test.dart`
- Modify: `test/routing_redirect_test.dart`
- Modify: `lib/presentation/main/main_view.dart`
- Modify: `lib/presentation/main/main_page.dart`
- Modify: `lib/routing.dart`

**Interfaces:**
- Consumes: `MainPage(initialTabIndex:)` and localized `mainTab*` strings.
- Produces: tab indices Home `0`, Groups `1`, Tournaments `2`, Profile `3`; input remains clamped.

- [ ] **Step 1: Write exact RED shell tests**

```dart
expect(find.byType(NavigationDestination), findsNWidgets(4));
for (final label in ['Arena', 'Groups', 'Tournaments', 'Profile']) {
  expect(find.text(label), findsOneWidget);
}
await tester.tap(find.text('Profile'));
await tester.pumpAndSettle();
expect(find.byType(ProfileView), findsOneWidget);
```

Add a `MainView(initialTabIndex: 99)` test and assert Home/Profile selection according to the existing clamp contract (`length - 1` for a high value).

- [ ] **Step 2: Run RED tests**

```bash
flutter test test/presentation/main test/presentation/esport/groups/groups_view_test.dart test/routing_redirect_test.dart
```

Expected: FAIL until all notification providers/mocks/index expectations are gone.

- [ ] **Step 3: Implement minimal four-tab shell**

```dart
enum _MainTab { arena, groups, tournaments, profile }
```

Keep current page instances and navigation accessibility labels. `MainPage` retains Profile, Group, Tournament, Dashboard, and OngoingTournament providers only.

- [ ] **Step 4: Run GREEN shell/routing tests**

```bash
flutter test test/presentation/main test/presentation/esport/groups/groups_view_test.dart test/routing_redirect_test.dart
```

Expected: PASS in both English and existing Vietnamese localization coverage.

- [ ] **Step 5: Commit shell change**

```bash
git add lib/presentation/main lib/routing.dart test/presentation/main test/presentation/esport/groups/groups_view_test.dart test/routing_redirect_test.dart
git commit -m "refactor: reduce navigation to four tabs"
```

---

### Task 7: Simplify Personal Dashboard Presentation

**Files:**
- Modify: `test/presentation/home/dashboard/dashboard_view_test.dart`
- Modify: `test/presentation/home/dashboard/detail/dashboard_detail_page_test.dart`
- Modify: `test/presentation/home/dashboard/widgets/stat_card_grid_test.dart`
- Modify: `lib/presentation/home/dashboard/dashboard_view.dart`
- Modify: `lib/presentation/home/dashboard/detail/dashboard_detail_page.dart`
- Modify: `lib/presentation/home/dashboard/widgets/stat_card_grid.dart`
- Delete: `lib/presentation/home/dashboard/widgets/league_performance_chart.dart`
- Delete: `test/presentation/home/dashboard/widgets/league_performance_chart_test.dart`
- Preserve: `lib/presentation/home/dashboard/models/league_performance_point.dart` and its test because the existing dashboard BLoC and `DashboardStats` still use this data.
- Preserve: dashboard BLoC, `DashboardStats`, repositories, caches, Firestore stats models/functions.

**Interfaces:**
- Consumes: existing `DashboardStats` including recent matches, champion/runner-up values, and opponents.
- Produces: UI showing only recent form/matches, last championship, champion rate, runner-up rate, H2H/nemesis/prey.

- [ ] **Step 1: Write RED presentation tests**

```dart
expect(find.text('Championship rate'), findsOneWidget);
expect(find.text('Runner-up rate'), findsOneWidget);
expect(find.text('Latest championship'), findsOneWidget);
expect(find.text('Recent form'), findsOneWidget);
expect(find.text('Recent matches'), findsOneWidget);
expect(find.text('Goal difference'), findsNothing);
expect(find.text('Matches'), findsNothing);
expect(find.byType(LeaguePerformanceChart), findsNothing);
```

Use localized strings from the test `BuildContext` where available instead of hard-coded English. Retain tests for loading, cached stats during refresh, empty data, failure, retry, H2H threshold, nemesis/prey selection, and match navigation.

- [ ] **Step 2: Run RED tests**

```bash
flutter test test/presentation/home/dashboard/dashboard_view_test.dart test/presentation/home/dashboard/detail/dashboard_detail_page_test.dart test/presentation/home/dashboard/widgets/stat_card_grid_test.dart
```

Expected: FAIL because lifetime hero metrics, overview metrics, or league chart remain.

- [ ] **Step 3: Implement approved sections only**

`StatCardGrid` has exactly three cards:

```dart
[
  _StatCard(title: l10n.dashboardChampionRate, value: _percent(...)),
  _StatCard(title: l10n.dashboardRunnerUpRate, value: _percent(...)),
  _StatCard(title: l10n.dashboardLatestChampion, value: _lastChampionLabel(...)),
]
```

Remove the Home hero's win-rate/goal-difference/match totals. Keep recent form and recent matches. In detail, keep the same approved cards plus `_HeadToHeadSection`; remove overview lifetime rows and `LeaguePerformanceChart`.

After deleting the chart widget, remove its import and the RED-only `find.byType(LeaguePerformanceChart)` assertion from the retained detail-page test so the GREEN suite compiles. Keep all `LeaguePerformancePoint` fixtures that exercise the unchanged BLoC/model pipeline.

- [ ] **Step 4: Prove schemas/pipeline were not changed**

```bash
git diff --exit-code main...HEAD -- \
  lib/firebase/firestore/user/stats \
  lib/data/repositories/user_stats_repository_impl.dart \
  lib/core/cache/dashboard_cache.dart
```

Expected: empty diff. `DashboardStats` and its BLoC may retain now-unrendered fields.

- [ ] **Step 5: Run GREEN dashboard tests**

```bash
flutter test test/presentation/home/dashboard
```

Expected: PASS, including empty and insufficient-H2H behavior.

- [ ] **Step 6: Commit presentation simplification**

```bash
git add lib/presentation/home/dashboard test/presentation/home/dashboard
git commit -m "refactor: focus personal dashboard on recent form"
```

---

### Task 8: Simplify Profile and Remove Feedback, Rating, and Hidden Toggle

**Files:**
- Modify: `test/presentation/profile/profile_view_test.dart`
- Modify: `test/presentation/app/app_bloc_test.dart`
- Modify: `test/routing_redirect_test.dart`
- Modify: `lib/presentation/profile/profile_view.dart`
- Modify: `lib/presentation/app/bloc/app_bloc.dart`
- Modify: `lib/presentation/app/bloc/app_event.dart`
- Modify: `lib/presentation/app/bloc/app_state.dart`
- Modify: `lib/presentation/app/app_view.dart`
- Modify: `lib/core/constants/constants.dart`
- Modify: `lib/routing.dart`
- Modify: `firestore.rules`
- Modify: `lib/firebase/gn_collection.dart`
- Delete: feedback files/tests listed in Appendix D.

**Interfaces:**
- Consumes: `ProfileBloc`, `SettingPage`, update profile, password/delete-account, locale/theme, `appInfo()`, sign-out.
- Produces: profile identity/avatar/edit, Settings, passive version, and sign-out only; no hidden state toggle.

- [ ] **Step 1: Write RED profile tests**

```dart
expect(find.text('Offline mode'), findsNothing);
expect(find.text('Sync offline data'), findsNothing);
expect(find.text('Rate'), findsNothing);
expect(find.text('Feedback'), findsNothing);
expect(find.text('Other options'), findsOneWidget);
expect(find.text('Version'), findsOneWidget);
expect(find.text('Sign out'), findsOneWidget);
```

Tap the version row at least ten times, pump the widget, and assert the profile remains on-screen with no dialog, navigation, or football-only content.

- [ ] **Step 2: Run RED tests**

```bash
flutter test test/presentation/profile/profile_view_test.dart test/presentation/app/app_bloc_test.dart test/presentation/profile/setting
```

Expected: FAIL while extra items and hidden toggle remain.

- [ ] **Step 3: Remove feedback/rating and hidden toggle**

Make `_VersionMenuItem` passive:

```dart
class _VersionMenuItem extends StatelessWidget {
  const _VersionMenuItem();
  // Render the existing AppInfo FutureBuilder inside a non-clickable container.
}
```

Remove `UpdateFootballFeature`, `enableFootballFeature`, its AppView listener, tests, URLs, feedback route/model/Firestore/UI, and `url_launcher` import. Delete the `/feedbacks/{feedbackId}` rule block from `firestore.rules`, then remove `GNCollection.feedbacks` and the complete `GNFeedbackFields` class from `lib/firebase/gn_collection.dart`. Keep settings navigation and all setting-page account protection.

- [ ] **Step 4: Run GREEN tests and audit**

```bash
flutter test test/presentation/profile test/presentation/app test/routing_redirect_test.dart
rg -n "FeedbackModel|GNFirestoreFeedback|profileFeedback|profileRateApp|playStoreUrl|appStoreUrl|UpdateFootballFeature|enableFootballFeature|url_launcher" lib test
```

Expected: PASS and no matches.

- [ ] **Step 5: Commit profile simplification**

```bash
git add lib test
git commit -m "refactor: simplify profile and settings entry points"
```

---

### Task 9: Clean Dependencies, Lockfiles, Localization, and Platform Push State

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify/generated: `lib/l10n/generated/app_localizations.dart`
- Modify/generated: `lib/l10n/generated/app_localizations_en.dart`
- Modify/generated: `lib/l10n/generated/app_localizations_vi.dart`
- Modify: `pubspec.yaml`
- Modify/generated: `pubspec.lock`
- Modify/generated: `ios/Podfile.lock`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner/Runner.entitlements`
- Modify: tests that directly assert generated localization keys.

**Interfaces:**
- Consumes: retained localized strings and native sign-in configuration.
- Produces: no dependency or generated accessor for removed features.

- [ ] **Step 1: Add a failing stale-key boundary test**

In `test/core/localization/generated_app_localizations_test.dart`, add `dart:io`, load both repository ARB files, and assert:

```dart
final english = File('lib/l10n/app_en.arb').readAsStringSync();
final vietnamese = File('lib/l10n/app_vi.arb').readAsStringSync();

for (final key in [
  'mainTabNotifications',
  'profileOfflineMode',
  'profileSyncOfflineData',
  'profileRateApp',
  'profileFeedback',
  'feedbackTitle',
]) {
  expect(english.contains('"$key"'), isFalse, reason: key);
  expect(vietnamese.contains('"$key"'), isFalse, reason: key);
}
```

- [ ] **Step 2: Run RED localization test**

```bash
flutter test test/core/localization/generated_app_localizations_test.dart
```

Expected: FAIL because retired keys remain.

- [ ] **Step 3: Remove retired ARB entries one file owner each**

Delete notification, offline, sync, feedback/rating-only keys and metadata. Do not delete retained strings containing ordinary words such as tournament score “synced” when they describe online recomputation.

Run generation mechanically, then assign each generated file to a dedicated reviewer/owner:

```bash
flutter gen-l10n
```

- [ ] **Step 4: Remove only proven-unused dependencies**

From `pubspec.yaml`, remove `sqflite`, `path`, `flutter_web_plugins`, `firebase_messaging`, `firebase_remote_config`, `google_mobile_ads`, `url_launcher`, and dependencies now used only by deleted files (`dartz`, `file_picker`, `fl_chart`, `collection`, `flutter_fortune_wheel`, `cupertino_icons`, `font_awesome_flutter`) only after `rg` proves no retained import. Keep `share_plus`, `flutter_svg`, and other retained tournament dependencies.

Remove the launcher icon `web:` block. Regenerate:

```bash
flutter pub get
cd ios && pod install
```

Dedicated owners review/apply `pubspec.lock` and `ios/Podfile.lock`.

- [ ] **Step 5: Remove native push capability without removing Apple sign-in**

From `ios/Runner/Info.plist`, remove the complete `UIBackgroundModes` key/array. The current repository search has no retained background-fetch caller; its two values are the retired `fetch` and `remote-notification` modes. From `Runner.entitlements`, remove `aps-environment` but retain:

```xml
<key>com.apple.developer.applesignin</key>
<array><string>Default</string></array>
```

- [ ] **Step 6: Run GREEN tests and dependency audit**

```bash
flutter test test/core/localization test/presentation/auth test/presentation/profile
flutter analyze
rg -n "sqflite|flutter_web_plugins|firebase_messaging|firebase_remote_config|google_mobile_ads|url_launcher|aps-environment|remote-notification" lib test pubspec.yaml ios android
```

Expected: tests/analyze PASS; audit has no removed integration matches.

- [ ] **Step 7: Commit cleanup**

```bash
git add lib/l10n test/core/localization pubspec.yaml pubspec.lock ios/Podfile.lock ios/Runner/Info.plist ios/Runner/Runner.entitlements
git commit -m "chore: remove retired platform dependencies"
```

---

### Task 10: Set the 4.0 Release Metadata

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: completed implementation scope.
- Produces: store version `4.0.0+49` and matching dated changelog entry.

- [ ] **Step 1: Write the release assertions before editing**

```bash
rg -n '^version: 4\.0\.0\+49$' pubspec.yaml
rg -n '^##? \[4\.0\.0\+49\]' CHANGELOG.md
```

Expected RED: both commands return no match.

- [ ] **Step 2: Set exact version**

```yaml
version: 4.0.0+49
```

- [ ] **Step 3: Add dated changelog entry**

Use the repository's existing heading style and date `2026-08-12`. State that 4.0 retains online groups and League/Cup/Full while removing notifications, offline/sync, ads, Flutter Web app, feedback/rating, and surplus personal dashboard metrics.

- [ ] **Step 4: Run GREEN release assertions**

```bash
rg -n '^version: 4\.0\.0\+49$' pubspec.yaml
rg -n '\[4\.0\.0\+49\]' CHANGELOG.md
```

Expected: exactly one matching version and one matching changelog heading.

- [ ] **Step 5: Commit release metadata**

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: prepare Game Note 4.0.0+49"
```

---

### Task 11: Run Complete Verification and Protected-Core Review

**Files:**
- Verify only: entire repository.
- Modify only through a new dedicated one-file worker if a gate exposes a defect.

**Interfaces:**
- Consumes: all prior task outputs.
- Produces: evidence that the single final PR is complete and safe to request.

- [ ] **Step 1: Format changed Dart files**

```bash
git diff --name-only main...HEAD -- '*.dart' | xargs dart format
git diff --check
```

Expected: formatter completes and diff check is clean. If formatting modifies multiple files, those are mechanical changes already owned/reviewed by their original one-file workers.

- [ ] **Step 2: Run static analysis and full coverage suite**

```bash
flutter pub get
flutter analyze
flutter test --coverage
```

Expected: all PASS; inspect `coverage/lcov.info` for every changed retained production file.

- [ ] **Step 3: Verify Functions**

```bash
npm --prefix functions test
npm --prefix functions run lint
```

Expected: both PASS and retained export assertions succeed.

- [ ] **Step 4: Build production artifacts locally**

```bash
flutter build appbundle --release
flutter build ios --release --no-codesign
```

Expected: Android build succeeds. iOS no-sign build succeeds; if Apple infrastructure alone blocks it, capture the exact error and do not claim it verified.

- [ ] **Step 5: Audit removed capabilities**

```bash
rg -n "NotificationBloc|GNNotification|GNFirebaseMessaging|FirebaseMessaging|fcmToken|sqflite|DatabaseManager|OfflineToOnline|SyncBloc|GNRemoteConfig|google_mobile_ads|BannerAd|WebShell|kIsWeb|flutter build web|FeedbackModel|GNFirestoreFeedback|UpdateFootballFeature|enableFootballFeature" \
  lib test functions pubspec.yaml firebase.json .github/workflows android ios
```

Expected: no matches. Historical release notes/design/plan documents are excluded from this source audit.

- [ ] **Step 6: Audit static-site preservation and protected core**

```bash
git diff --exit-code main...HEAD -- game-note-landing .github/workflows/deploy-landing.yml
git diff --stat main...HEAD -- \
  lib/firebase/firestore/esport \
  lib/data/repositories/esport \
  lib/domain/repositories/esport \
  lib/presentation/esport/tournament/tournament_detail/bloc \
  lib/firebase/firestore/user/stats
flutter test \
  test/data/repositories/esport \
  test/firebase/firestore/esport \
  test/firebase/firestore/user/stats \
  test/presentation/esport/groups \
  test/presentation/esport/tournament
```

Expected: static-site diff empty; protected-core diff contains only approved compile removals (ads/FCM fixture arguments) and no concurrency/transaction algorithm changes; all tests PASS.

- [ ] **Step 7: Confirm branch completeness and clean tree**

```bash
git status --short
git log --oneline main..HEAD
git diff --name-status main...HEAD
```

Expected: clean tree, all phases present, no file under `game-note-landing/` changed, exact version/changelog present.

- [ ] **Step 8: Stop before remote actions**

Report verification evidence and remaining real-device/production limitations. Ask separately for authorization to push. Do not create a PR until push is authorized and completes; do not merge until required CI is green and merge is separately authorized.

---

## Appendix A: Notification/FCM Deletion Inventory

Assign one deletion worker per path:

```text
lib/domain/repositories/notification_repository.dart
lib/data/repositories/notification_repository_impl.dart
lib/firebase/firestore/notification/gn_firestore_notification.dart
lib/firebase/firestore/notification/gn_notification.dart
lib/firebase/messaging/gn_firebase_messaging.dart
lib/presentation/notification/bloc/notification_bloc.dart
lib/presentation/notification/bloc/notification_event.dart
lib/presentation/notification/bloc/notification_state.dart
lib/presentation/notification/notification_item.dart
lib/presentation/notification/notification_page.dart
lib/presentation/notification/notification_view.dart
test/presentation/notification/notification_item_test.dart
test/presentation/notification/notification_view_test.dart
```

Files that construct `GNUser` must each get a dedicated modification owner after the constructor changes; discover the exact current list with:

```bash
rg -l "fcmToken" lib test | sort
```

---

## Appendix B: Offline and Sync Deletion Inventory

Generate the exact ledger from tracked files, then dispatch one worker per output line:

```bash
git ls-files \
  lib/offline \
  lib/data/sync \
  lib/presentation/sync \
  test/_helpers/sync_fixtures.dart \
  test/data/sync \
  test/presentation/sync
```

Also delete with dedicated owners:

```text
lib/presentation/app/offline_button.dart
lib/presentation/app/online_button.dart
```

Before accepting the task, repeat the command and expect no output.

---

## Appendix C: Flutter Web Deletion Inventory

Assign one deletion worker per path:

```text
lib/presentation/web_shell/web_shell.dart
.github/workflows/web-build.yml
.github/workflows/web-release.yml
web/favicon.png
web/icons/Icon-192.png
web/icons/Icon-512.png
web/icons/Icon-maskable-192.png
web/icons/Icon-maskable-512.png
web/index.html
web/manifest.json
```

Never include these retained paths in a deletion brief:

```text
game-note-landing/**
.github/workflows/deploy-landing.yml
```

---

## Appendix D: Feedback Deletion Inventory

Assign one deletion worker per path:

```text
lib/firebase/firestore/feedback/feedback_model.dart
lib/firebase/firestore/feedback/feedback_status.dart
lib/firebase/firestore/feedback/gn_firestore_feedback.dart
lib/presentation/profile/feedback/feedback_item.dart
lib/presentation/profile/feedback/feedback_view.dart
test/presentation/profile/feedback/feedback_item_test.dart
test/presentation/profile/feedback/feedback_view_test.dart
```

After deleting the feedback files, remove `GNCollection.feedbacks` and the complete `GNFeedbackFields` class from `lib/firebase/gn_collection.dart`; that file gets its own worker. Remove the `/feedbacks/{feedbackId}` rule block from `firestore.rules` in its dedicated worker.

---

## Execution Handoff

This plan is intended for **Subagent-Driven execution** in the current session: dispatch fresh one-file workers in dependency-aware waves, review every file, then run integration gates. Inline execution is permitted only through `superpowers:executing-plans`, while still honoring the repository's mandatory one-file-subagent rule for every edit.
