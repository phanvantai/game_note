# Online League Performance & Realtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tối ưu luồng tạo và League Detail online để bootstrap hoàn toàn bằng realtime streams, lưu kết quả theo từng match bằng một Firestore transaction nguyên tử, và chỉ rebuild/render đúng vùng dữ liệu thay đổi.

**Architecture:** `TournamentDetailBloc` sẽ sở hữu duy nhất một subscription cho league, stats và matches; ba initial snapshot thay thế mọi explicit bootstrap read, còn cache `usersById` chỉ bổ sung profile thiếu. Mutation match đi qua một repository command duy nhất để resolve stat document legacy trước transaction rồi ghi match, hai stat rows và next knockout slot trong cùng commit; UI giữ pending theo `matchId`, tách selectors theo slice và chỉ dựng share cards trong lúc capture.

**Tech Stack:** Flutter 3.41+, Dart 3.10+, flutter_bloc, Equatable, Firestore transactions/snapshots, fake_cloud_firestore, mocktail, bloc_test, Flutter gen-l10n.

## Global Constraints

- Thực thi trên branch hiện tại `codex/optimize-online-league-flow`; người dùng đã từ chối worktree, vì vậy không tạo/switch worktree hoặc branch khác.
- Không đổi Firestore schema, không migration stat document sang deterministic ID, không thêm package, không sửa bất kỳ flow/file offline nào.
- Giữ nguyên fixture algorithm, cách tính điểm, giới hạn round robin 32 người, knockout advancement, cost behavior và các stat document ID ngẫu nhiên của dữ liệu cũ.
- Match update phải giữ `expectedUpdatedAt`/`ConcurrentMatchUpdateException`; document legacy chưa có timestamp được phép update lần đầu, các lần sau dùng `serverTimestamp`.
- League/group phase ghi match + hai stat rows; knockout phase ghi match + next slot và không ghi standings; full tournament group phase resolve stat đúng `groupId`.
- Remote league/stats/matches snapshot chỉ patch state: không toast, không global loading, không explicit get/full reload và không live announcement gây nhiễu.
- Create loading bắt đầu ngay trước `onAddLeague`, khóa submit/form/back/pop cho tới khi callback hoàn tất, và không trở lại trạng thái nút thường trước khi wizard pop thành công.
- TDD bắt buộc: mỗi behavior có RED command và expected failure trước khi production worker chạy; chỉ commit khi phase trở lại GREEN.
- Mọi worker chỉnh sửa dùng model `gpt-5.3-codex-spark` khi công cụ cho phép chọn model, sở hữu đúng **một** file, không chạy lệnh có thể rewrite file khác, và format file Dart do mình sở hữu trước khi trả kết quả.
- Prompt worker phải ghi rõ: target file tuyệt đối, read-only context được phép, lệnh verify, cấm chạm file khác và verification note của riêng file đó. Không có hai worker active cùng sở hữu một file; khi cùng file cần nhiều pha, dùng worker mới theo thứ tự dependency.
- Main agent chỉ điều phối/review diff/verify/commit. Sau mỗi worker: kiểm tra `git diff -- <owned-file>` và `git diff --check -- <owned-file>` trước khi nhận.
- File localization sinh tự động cũng là file độc lập. Sinh reference output vào `/tmp/game_note_l10n_online_league/`, rồi giao ba worker tuần tự áp đúng một output vào đúng một generated target; không chạy `flutter gen-l10n` trực tiếp trong repo từ worker.
- Không suy ra QA hai thiết bị hay Firebase Emulator từ unit/widget tests; báo riêng verification thực tế chưa chạy nếu môi trường không sẵn sàng.

---

## File Structure and Ownership Map

| File | Trách nhiệm sau thay đổi | Worker ownership |
|---|---|---|
| `lib/l10n/app_en.arb` | Copy tiếng Anh cho create loading và match pending | Một worker ARB tiếng Anh |
| `lib/l10n/app_vi.arb` | Copy tiếng Việt tương ứng | Một worker ARB tiếng Việt |
| `lib/l10n/generated/app_localizations.dart` | Contract getter localization | Một worker generated contract |
| `lib/l10n/generated/app_localizations_en.dart` | English generated implementation | Một worker generated English |
| `lib/l10n/generated/app_localizations_vi.dart` | Vietnamese generated implementation | Một worker generated Vietnamese |
| `lib/presentation/esport/tournament/create_esport_league_page.dart` | Submit lock, stable loading button, `PopScope`, error unlock | Một worker create widget |
| `lib/presentation/esport/tournament/tournament_view.dart` | Một create write, fixture generation, rollback, detail navigation rồi reload list | Một worker orchestration |
| `lib/firebase/firestore/esport/league/gn_firestore_esport_league.dart` | Nullable league stream khi document bị xóa | Một worker league stream |
| `lib/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart` | Atomic match/stat/next-slot command và legacy stat lookup | Một worker Firestore match command |
| `lib/domain/repositories/esport/esport_league_repository.dart` | Public `updateMatchAtomically` và nullable league stream contract | Một worker domain contract |
| `lib/data/repositories/esport/esport_league_repository_impl.dart` | Delegate atomic command, raw streams, bỏ detail aggregate read | Một worker data adapter |
| `lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_event.dart` | Open/snapshot/retry/mutation events | Một worker event file |
| `lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_state.dart` | Bootstrap slices, cache, pending/error maps, derived lists | Một worker state file |
| `lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart` | Subscription lifecycle, user/group cache, atomic mutation feedback | Một worker bloc file |
| `lib/presentation/esport/tournament/tournament_detail/tournament_detail_page.dart` | Inject league/group repositories, safe inactive/deleted close | Một worker page wiring |
| `lib/presentation/esport/tournament/tournament_detail/tournament_detail_view.dart` | Resume ensure, shell/header selectors, lazy share capture | Một worker detail view |
| `lib/presentation/esport/tournament/tournament_detail/table/table_view.dart` | Stats selector và stream-backed refresh | Một worker standings view |
| `lib/presentation/esport/tournament/tournament_detail/matches/matches_view.dart` | Matches selector, pending row lock, stream-backed refresh | Một worker matches view |
| `lib/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart` | Accessible per-row pending/error presentation | Một worker match item |
| `lib/presentation/esport/tournament/tournament_detail/groups/group_standings_view.dart` | Group selector và pending match lock | Một worker group view |
| `lib/presentation/esport/tournament/tournament_detail/bracket/bracket_view.dart` | Bracket selector và pending knockout lock | Một worker bracket view |
| `lib/presentation/esport/tournament/tournament_detail/cost/cost_split_view.dart` | Cost-specific selector và stream-backed refresh | Một worker cost view |
| Matching files under `test/` | RED coverage for the exact owned production file/flow | Mỗi test file có worker riêng, không đồng sở hữu production file |

Không sửa `lib/injection_container.dart`: `EsportGroupRepository` và `EsportLeagueRepository` đã được đăng ký sẵn; page chỉ resolve cả hai dependency hiện có.

---

### Task 1: Add localized progress and pending copy without multi-file generation

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/l10n/generated/app_localizations.dart`
- Modify: `lib/l10n/generated/app_localizations_en.dart`
- Modify: `lib/l10n/generated/app_localizations_vi.dart`

**Interfaces:**
- Consumes: existing Flutter gen-l10n config in `l10n.yaml`.
- Produces: `String get tournamentCreatingLeague` and `String get tournamentSavingMatch` on `AppLocalizations`.

- [ ] **Step 1: Assign one ARB worker per locale and add exact copy**

English worker adds:

```json
"tournamentCreatingLeague": "Creating league…",
"tournamentSavingMatch": "Saving result"
```

Vietnamese worker adds:

```json
"tournamentCreatingLeague": "Đang tạo giải…",
"tournamentSavingMatch": "Đang lưu kết quả"
```

Each worker may read `l10n.yaml` and the other ARB read-only, but edits only its target.

- [ ] **Step 2: Generate canonical reference files outside the repository**

Run from repo root after both ARBs are reviewed:

```bash
rm -rf /tmp/game_note_l10n_online_league
mkdir -p /tmp/game_note_l10n_online_league/arb /tmp/game_note_l10n_online_league/generated
cp lib/l10n/app_en.arb lib/l10n/app_vi.arb /tmp/game_note_l10n_online_league/arb/
flutter gen-l10n --arb-dir=/tmp/game_note_l10n_online_league/arb --template-arb-file=app_en.arb --output-dir=/tmp/game_note_l10n_online_league/generated --output-localization-file=app_localizations.dart --no-nullable-getter
```

Expected: exit 0; exactly three Dart files exist under `/tmp/game_note_l10n_online_league/generated` and contain both getters.

- [ ] **Step 3: Assign three sequential one-file workers to apply generated output**

Each worker reads only its matching `/tmp/.../generated/<name>.dart` and target, then makes target byte-equivalent to reference output. Verify each target separately:

```bash
cmp /tmp/game_note_l10n_online_league/generated/app_localizations.dart lib/l10n/generated/app_localizations.dart
cmp /tmp/game_note_l10n_online_league/generated/app_localizations_en.dart lib/l10n/generated/app_localizations_en.dart
cmp /tmp/game_note_l10n_online_league/generated/app_localizations_vi.dart lib/l10n/generated/app_localizations_vi.dart
```

Expected: all three commands exit 0. This avoids a worker rewriting three generated files.

- [ ] **Step 4: Verify localization getters compile**

Run:

```bash
flutter analyze lib/l10n
```

Expected: `No issues found!`

- [ ] **Step 5: Commit the green localization unit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_vi.arb lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_en.dart lib/l10n/generated/app_localizations_vi.dart
git commit -m "feat: localize online league progress states"
```

---

### Task 2: Lock the create wizard while submission is pending

**Files:**
- Test: `test/presentation/esport/tournament/create_esport_league_page_test.dart`
- Modify: `lib/presentation/esport/tournament/create_esport_league_page.dart`

**Interfaces:**
- Consumes: `OnAddLeagueCallback`, `context.l10n.tournamentCreatingLeague`.
- Produces: private `_isSubmitting: bool`; `_submit()` remains `Future<void>` and calls the callback at most once.

- [ ] **Step 1: Test worker writes failing widget tests**

Add a `_driveToFinalStep` helper and tests with `Completer<String>` covering:

```dart
final completer = Completer<String>();
var calls = 0;
final callback = ({/* existing named parameters */}) {
  calls++;
  return completer.future;
};

await _driveToFinalStep(tester, callback);
await tester.tap(find.text('Tạo giải đấu'));
await tester.pump();

expect(find.text('Đang tạo giải…'), findsOneWidget);
expect(find.byType(CircularProgressIndicator), findsOneWidget);
expect(calls, 1);
await tester.tap(find.text('Đang tạo giải…'));
await tester.pump();
expect(calls, 1);
```

Also assert `tester.binding.handlePopRoute()` does not close the wizard, close/back controls have null handlers, a text field cannot change, button size before/after is equal, semantics includes `Đang tạo giải…` with disabled button state, and no success result/toast appears before `completer.complete('L1')`.

Error tests complete with `RoundTooLargeException` and `Exception('network')`, then assert input text is unchanged, normal create button is enabled again and exactly one translated toast was recorded. Success test completes the future and asserts wizard pops with `L1` without rendering the normal label for an intermediate frame.

- [ ] **Step 2: Run RED widget suite**

Run:

```bash
flutter test test/presentation/esport/tournament/create_esport_league_page_test.dart --plain-name "pending"
```

Expected: FAIL because `_isSubmitting`, loading copy, `PopScope` and disabled controls do not exist; repeated tap can invoke the callback twice.

- [ ] **Step 3: Production worker implements the minimal submit lock**

Use this control flow:

```dart
bool _isSubmitting = false;

Future<void> _submit() async {
  if (_isSubmitting) return;
  // Existing synchronous validation and cost collection stay before the flag.
  setState(() => _isSubmitting = true);
  try {
    final leagueId = await widget.onAddLeague(/* existing arguments */);
    if (!mounted) return;
    Navigator.of(context).pop(leagueId); // keep flag true until dispose
  } on RoundTooLargeException catch (error) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    showToast(context.l10n.tournamentRoundTooLarge(error.maxParticipants));
  } catch (_) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    showToast(context.l10n.commonErrorTitle);
  }
}
```

Wrap the page in `PopScope(canPop: !_isSubmitting)`, set close/back callbacks to null while pending, block the `PageView` controls with `AbsorbPointer(absorbing: _isSubmitting)`, and render a fixed-width icon slot so spinner + localized label keeps the FilledButton dimensions stable. Use `Semantics(button: true, enabled: !_isSubmitting, label: ...)`; do not use a live region.

- [ ] **Step 4: Run GREEN create tests and format check**

Run:

```bash
dart format --output=none --set-exit-if-changed lib/presentation/esport/tournament/create_esport_league_page.dart test/presentation/esport/tournament/create_esport_league_page_test.dart
flutter test test/presentation/esport/tournament/create_esport_league_page_test.dart
```

Expected: formatter exits 0; all create wizard tests pass.

- [ ] **Step 5: Commit the create widget phase**

```bash
git add lib/presentation/esport/tournament/create_esport_league_page.dart test/presentation/esport/tournament/create_esport_league_page_test.dart
git commit -m "feat: lock league creation while submitting"
```

---

### Task 3: Remove duplicate participant writes and defer list reload

**Files:**
- Test: `test/presentation/esport/tournament/tournament_view_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_view.dart`

**Interfaces:**
- Consumes: existing `repo.addLeague`, fixture generators and `Routing.tournamentDetailPath(String)`.
- Produces: `openCreateTournament(BuildContext) -> Future<void>` with list reload after awaited detail navigation.

- [ ] **Step 1: Test worker rewrites call-order expectations**

For league/cup/full create tests assert:

```dart
verify(() => repo.addLeague(/* captured args */)).called(1);
verifyNever(() => repo.addMultipleParticipants(
  leagueId: any(named: 'leagueId'),
  userIds: any(named: 'userIds'),
));
verify(() => repo.generateRound(/* league mode */)).called(1);
```

Use a controllable detail route `Completer<void>`/router page. Before detail pops, verify zero `LoadMyLeagues` and zero `LoadManagedLeagues`; after pop, verify each exactly once. Add generation-error coverage asserting `deleteLeague(id)` once, no detail navigation, and the original generation exception reaches the wizard. Add rollback-error coverage: generation throws `createError`, delete throws `rollbackError`, callback still exposes `createError` and logs rollback failure. Assert create success toast occurs once and only after the league plus fixtures complete.

- [ ] **Step 2: Run RED orchestration tests**

Run:

```bash
flutter test test/presentation/esport/tournament/tournament_view_test.dart --plain-name "Create callback"
```

Expected: FAIL because `addMultipleParticipants` is still called and both list events are dispatched before detail closes.

- [ ] **Step 3: Production worker changes create orchestration**

Inside callback call `addLeague` once and remove `addMultipleParticipants`. Preserve mode-specific generation. Rollback must keep the original stack:

```dart
} catch (createError, createStack) {
  try {
    await repo.deleteLeague(id);
  } catch (rollbackError, rollbackStack) {
    debugPrint('League create rollback failed: $rollbackError\n$rollbackStack');
  }
  Error.throwWithStackTrace(createError, createStack);
}
```

After wizard returns:

```dart
if (leagueId == null || !context.mounted) return;
showToast(createSuccessMessage);
try {
  await context.push(Routing.tournamentDetailPath(leagueId));
} finally {
  tournamentBloc.add(LoadMyLeagues());
  tournamentBloc.add(LoadManagedLeagues());
}
```

Do not expand rollback to recursive subcollection deletion in this scope; record it as a residual risk in handoff.

- [ ] **Step 4: Run GREEN orchestration suite**

Run:

```bash
dart format --output=none --set-exit-if-changed lib/presentation/esport/tournament/tournament_view.dart test/presentation/esport/tournament/tournament_view_test.dart
flutter test test/presentation/esport/tournament/tournament_view_test.dart
```

Expected: all tests pass; call counts are `addLeague == 1`, duplicate participant API `== 0`, selected generator `== 1`, list events after detail `== 1` each.

- [ ] **Step 5: Commit create orchestration**

```bash
git add lib/presentation/esport/tournament/tournament_view.dart test/presentation/esport/tournament/tournament_view_test.dart
git commit -m "perf: defer league list reload until detail closes"
```

---

### Task 4: Make the league document stream deletion-safe

**Files:**
- Test: `test/firebase/firestore/esport/league/gn_firestore_esport_league_test.dart`
- Modify: `lib/firebase/firestore/esport/league/gn_firestore_esport_league.dart`

**Interfaces:**
- Consumes: `DocumentSnapshot.exists`.
- Produces: `Stream<GNEsportLeague?> listenForLeagueUpdated(String leagueId)`.

- [ ] **Step 1: Test worker adds deletion stream regression**

Seed a league, subscribe, await first non-null value, delete its document, then expect the next value is null and the stream does not throw from `GNEsportLeague.fromFirestore`.

- [ ] **Step 2: Run RED Firestore league stream test**

Run:

```bash
flutter test test/firebase/firestore/esport/league/gn_firestore_esport_league_test.dart --plain-name "deleted document"
```

Expected: FAIL with mapping/cast error because the mapper assumes the snapshot exists.

- [ ] **Step 3: Production worker maps missing documents to null**

```dart
Stream<GNEsportLeague?> listenForLeagueUpdated(String leagueId) {
  return firestore
      .collection(GNEsportLeague.collectionName)
      .doc(leagueId)
      .snapshots()
      .map((snapshot) =>
          snapshot.exists ? GNEsportLeague.fromFirestore(snapshot) : null);
}
```

- [ ] **Step 4: Run GREEN test and commit**

```bash
flutter test test/firebase/firestore/esport/league/gn_firestore_esport_league_test.dart
git add lib/firebase/firestore/esport/league/gn_firestore_esport_league.dart test/firebase/firestore/esport/league/gn_firestore_esport_league_test.dart
git commit -m "fix: handle deleted league snapshots"
```

---

### Task 5: Prove atomic match, stats, next-slot and concurrency behavior

**Files:**
- Test: `test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart`
- Modify: `lib/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart`

**Interfaces:**
- Consumes: existing `_statRefForUser`, `_statContribution`, `_applyDeltaMap`, random stat IDs, `GNEsportMatch.updatedAt`.
- Produces:

```dart
Future<void> updateMatchAtomically({
  required String matchId,
  required String leagueId,
  int? homeScore,
  int? awayScore,
  int? matchCost,
  int? costPerGoal,
  Timestamp? expectedUpdatedAt,
});
```

- [ ] **Step 1: Test worker replaces split-write assumptions with atomic cases**

Add tests for:

1. League first result writes match + both random-ID stat rows; `costPerGoal` is persisted.
2. Editing a finished match undoes its old contribution and applies the new contribution exactly once.
3. Group phase only changes stat rows whose `groupId` equals the match group.
4. Knockout writes match + correct home/away next slot and leaves standings unchanged.
5. Missing home or away stat query throws before match write.
6. Stat doc deleted after reference resolution is detected in transaction and leaves match/other stat/next slot unchanged.
7. Stale `expectedUpdatedAt` throws `ConcurrentMatchUpdateException` and writes no document.
8. Legacy match with null timestamp accepts first update; resulting document has server timestamp; stale second update is rejected.
9. Two clients update two different matches sharing one player with `Future.wait`; final stats equal both deltas, with no lost update.
10. Two clients use the same version of one match; exactly one succeeds and one conflicts.

Retain scheduler/generation/delete/recompute tests. Delete tests whose only contract is the obsolete two-step `updateMatch` then `applyMatchStatDelta` behavior.

- [ ] **Step 2: Run RED atomic tests**

Run:

```bash
flutter test test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart --plain-name "updateMatchAtomically"
```

Expected: compile FAIL because `updateMatchAtomically` does not exist.

- [ ] **Step 3: Production worker implements query-before-transaction compatibility**

For non-knockout rows, resolve both refs before `runTransaction` using existing `userId` query plus in-memory `groupId` filter. Do not derive deterministic paths and do not create missing stats.

Inside transaction, perform all reads before writes:

```dart
final current = GNEsportMatch.fromFirestore(await txn.get(matchRef));
if (expectedUpdatedAt != null && current.updatedAt != expectedUpdatedAt) {
  throw ConcurrentMatchUpdateException(matchId);
}
final updated = current.copyWith(
  homeScore: homeScore,
  awayScore: awayScore,
  isFinished: homeScore != null && awayScore != null,
  matchCost: matchCost ?? current.matchCost,
  costPerGoal: costPerGoal ?? current.costPerGoal,
);
```

If `current.phase != 'knockout'`, read both resolved stat documents, fail if either no longer exists, calculate undo from `current` plus apply from `updated` inside the transaction closure, and stage both stat updates. If knockout is finished and has `nextMatchId`, read the next match document before staging the winner slot update. Finally stage match data plus `GNEsportMatch.fieldUpdatedAt: FieldValue.serverTimestamp()`.

The closure must not emit state, toast, log success or capture a delta computed outside it. Firestore retries therefore re-read current match/stats and recalculate the delta.

- [ ] **Step 4: Run GREEN atomic and existing match suites**

Run:

```bash
dart format --output=none --set-exit-if-changed lib/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart
flutter test test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart
```

Expected: all tests pass, including legacy random stat lookup, full group isolation, knockout advancement, missing-stat rollback and shared-player aggregate.

- [ ] **Step 5: Commit the Firestore command**

```bash
git add lib/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart
git commit -m "feat: update online match and stats atomically"
```

---

### Task 6: Expose only the atomic repository command to League Detail

**Files:**
- Test: `test/data/repositories/esport/esport_league_repository_impl_test.dart`
- Modify: `lib/domain/repositories/esport/esport_league_repository.dart`
- Modify: `lib/data/repositories/esport/esport_league_repository_impl.dart`

**Interfaces:**
- Consumes: `GNFirestore.updateMatchAtomically(...)` from Task 5.
- Produces:

```dart
Future<void> updateMatchAtomically(GNEsportMatch match);
Stream<GNEsportLeague?> listenForLeagueUpdated(String leagueId);
```

- [ ] **Step 1: Test worker adds adapter RED coverage**

Seed a match and two random-ID stat documents through fake Firestore, construct a submitted `GNEsportMatch` carrying score, `matchCost`, `costPerGoal`, and `updatedAt`, call `repo.updateMatchAtomically(match)`, then assert all fields and stats changed. Add a league stream test that observes null after deletion.

- [ ] **Step 2: Run RED repository tests**

```bash
flutter test test/data/repositories/esport/esport_league_repository_impl_test.dart --plain-name "atomic"
```

Expected: compile FAIL because repository contract/implementation have no atomic method and league stream is non-nullable.

- [ ] **Step 3: Domain-contract worker adds the new signatures**

Add `updateMatchAtomically` and change the league stream to nullable. Keep old `updateMatch`/`applyMatchStatDelta` temporarily during migration; mark neither as a fallback path in new code. Keep `getLeagueStats` because group-management screens still use it.

- [ ] **Step 4: Data-adapter worker delegates every mutable match field**

```dart
Future<void> updateMatchAtomically(GNEsportMatch match) {
  return getIt<GNFirestore>().updateMatchAtomically(
    matchId: match.id,
    leagueId: match.leagueId,
    homeScore: match.homeScore,
    awayScore: match.awayScore,
    matchCost: match.matchCost,
    costPerGoal: match.costPerGoal,
    expectedUpdatedAt: match.updatedAt,
  );
}
```

Update `listenForLeagueUpdated` return type to nullable without enriching the league.

- [ ] **Step 5: Run GREEN repository tests**

```bash
flutter test test/data/repositories/esport/esport_league_repository_impl_test.dart
```

Expected: all repository tests pass.

- [ ] **Step 6: Commit the public atomic API**

```bash
git add lib/domain/repositories/esport/esport_league_repository.dart lib/data/repositories/esport/esport_league_repository_impl.dart test/data/repositories/esport/esport_league_repository_impl_test.dart
git commit -m "refactor: expose atomic online match command"
```

---

### Task 7: Specify stream-only detail state, caching, lifecycle and pending behavior

**Files:**
- Test: `test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_event.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_state.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart`

**Interfaces:**
- Consumes: `EsportLeagueRepository`, `EsportGroupRepository.getGroup(String)`, three repository streams, `updateMatchAtomically`.
- Produces:

```dart
enum TournamentDetailSlice { league, stats, matches }
enum DetailSliceStatus { waiting, ready, failed }
enum DetailBootstrapStatus { loading, ready, failure }

TournamentDetailBloc(
  EsportLeagueRepository leagueRepository,
  EsportGroupRepository groupRepository,
)
```

State fields:

```dart
final DetailSliceStatus leagueSliceStatus;
final DetailSliceStatus statsSliceStatus;
final DetailSliceStatus matchesSliceStatus;
final GNEsportLeague? league;
final List<GNEsportLeagueStat> participants;
final List<GNEsportMatch> matches;
final Map<String, GNUser> usersById;
final Set<String> pendingMatchIds;
final Map<String, String> matchErrorsById;
final Map<TournamentDetailSlice, String> streamErrors;
final bool leagueDeleted;
final int refreshTick;
```

Keep `List<GNUser> get users => usersById.values.toList(growable: false)` for existing dialogs. `bootstrapStatus` is loading while any slice waits, failure only when league cannot bootstrap/deleted, and ready when league is ready plus stats/matches have either initial data or a visible slice failure.

- [ ] **Step 1: Test worker replaces explicit-fetch tests with stream contracts**

Use broadcast `StreamController`s and a mock group repo. Cover:

- `OpenLeagueDetail('L1')` calls each listen method once and calls `getLeague`, `getParticipantsAndMatches`, `getLeagueStats`, `getMatches` zero times.
- Initial league/stats/matches snapshots independently patch only their slice and reach `DetailBootstrapStatus.ready` after all three initial outcomes.
- League metadata snapshot does not call/fetch stats or matches; stats snapshot does not call league/matches; matches snapshot does not call league/stats.
- First roster loads only missing IDs through `getUsersByIds`; score-only, cost-only and name-only snapshots keep the user call count unchanged. A newly added roster ID triggers one batch for that ID only.
- Group is reused from the current league/cache; a new `groupId` calls `groupRepository.getGroup(groupId)` exactly once and never calls `getLeague`.
- `EnsureDetailSubscriptions('L1')` while all subscriptions are active creates zero additional listens and bumps `refreshTick`; if one test controller closes/errors, only that slice rebinds.
- Stream errors populate `streamErrors`, preserve already confirmed other slices, and schedule finite retry delays 1s, 2s, 4s with at most three attempts. A successful snapshot resets that slice retry count.
- `close()` cancels all subscriptions and retry timers. Opening a different league cancels old subscriptions/cache before attaching exactly three new ones.
- Null league snapshot emits explicit deleted state; inactive league patches metadata without toast/global loading.
- Remote snapshots produce no toast and never set `viewStatus.loading`.
- `UpdateEsportMatch(M1)` adds only `M1` pending; a simultaneous `M2` stays interactive. While a `Completer<void>` is unresolved, there is no success toast.
- Atomic success calls the repository once, clears only that ID and toasts once; legacy split APIs and all explicit fetch APIs have zero calls.
- Offline/error clears pending, preserves stream-confirmed row, records translated per-match error and permits retry.
- Stale conflict clears pending, records `tournamentMatchConcurrentUpdate`, toasts once, and a later match snapshot reconciles server state.
- Two bloc clients consuming shared streams receive A's match/stats updates on B without toast/global loading.

- [ ] **Step 2: Run RED bloc suite**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart
```

Expected: compile/test failures because new enums/events/state maps/constructor and atomic handler are absent; old code performs explicit reads and global loading.

- [ ] **Step 3: Event worker defines exact public/internal events**

Create `OpenLeagueDetail`, `EnsureDetailSubscriptions`, `RetryDetailSlice`, `LeagueSnapshotReceived(GNEsportLeague?)`, `StatsSnapshotReceived(List<GNEsportLeagueStat>)`, `MatchesSnapshotReceived(List<GNEsportMatch>)`, `DetailStreamFailed(slice, error)`, and reuse `LeagueDeleted` as explicit lifecycle event. Keep mutation/admin events. Remove `ApplyMatchStatDelta` immediately because no caller may launch the split path after Task 6.

- [ ] **Step 4: State worker implements immutable slice/cache/pending state**

Use defensive immutable copies in `copyWith`:

```dart
usersById: Map.unmodifiable(usersById ?? this.usersById),
pendingMatchIds: Set.unmodifiable(pendingMatchIds ?? this.pendingMatchIds),
matchErrorsById: Map.unmodifiable(matchErrorsById ?? this.matchErrorsById),
streamErrors: Map.unmodifiable(streamErrors ?? this.streamErrors),
```

Add explicit clear flags for nullable `league` and `selectedGroupId`. Include every field in `props`. Preserve existing standings/fixtures/results/group computed getters.

- [ ] **Step 5: Bloc worker implements one-owner subscriptions and caches**

Maintain exactly three subscription fields, three retry counters/timers, `_activeLeagueId`, `_groupsById`, and `_loadingUserIds`. Stream callbacks only `add(...)`; they do not emit/toast.

User enrichment algorithm:

```dart
final requiredIds = <String>{
  ...?state.league?.participants,
  ...state.participants.map((e) => e.userId),
  for (final m in state.matches) ...[
    if (m.homeTeamId.isNotEmpty) m.homeTeamId,
    if (m.awayTeamId.isNotEmpty) m.awayTeamId,
  ],
};
final missing = requiredIds
    .difference(state.usersById.keys.toSet())
    .difference(_loadingUserIds);
```

Fetch `missing` once, merge cache, and re-enrich stats/matches with `copyWith(user:)` / `copyWith(homeTeam:, awayTeam:)`. Normalize collection snapshots by ID and emit only when Equatable content changes. Retain cached profiles until bloc dispose.

On atomic mutation, never alter `viewStatus`; update only pending/error maps. On success clear pending then local success toast. On conflict/generic failure clear pending and set localized error. Do not run an explicit read after any match/create/delete/generate/recompute mutation; streams provide confirmation.

Finite retry implementation uses `Timer(Duration(seconds: 1 << attempt), () => add(RetryDetailSlice(...)))` for attempts 0–2 only. `EnsureDetailSubscriptions` starts only null/missing subscriptions; if all are active, it emits only `refreshTick + 1`.

- [ ] **Step 6: Run GREEN bloc suite and API call-count scan**

```bash
dart format --output=none --set-exit-if-changed lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_event.dart lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_state.dart lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart
flutter test test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart
rg -n "getLeague\(|getParticipantsAndMatches\(|getLeagueStats\(|getMatches\(|applyMatchStatDelta\(" lib/presentation/esport/tournament/tournament_detail/bloc
```

Expected: bloc tests pass; final `rg` returns no matches.

- [ ] **Step 7: Commit stream-only bloc core**

```bash
git add lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_event.dart lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_state.dart lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart
git commit -m "perf: bootstrap league detail from realtime streams"
```

---

### Task 8: Wire detail dependencies and safe deletion navigation

**Files:**
- Create: `test/presentation/esport/tournament/tournament_detail/tournament_detail_page_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/tournament_detail_page.dart`

**Interfaces:**
- Consumes: constructor and `OpenLeagueDetail` from Task 7; existing GetIt registrations.
- Produces: page closes safely for `leagueDeleted` or inactive league without snapshot-driven toast.

- [ ] **Step 1: Test worker creates failing page tests**

Register mock league/group repositories in GetIt, pump `TournamentDetailPage(leagueId: 'L1')`, and verify both are injected and `OpenLeagueDetail('L1')` begins. Emit inactive and deleted states, then assert safe back navigation and no toast. Emit `streamErrors` for stats/matches and assert page remains mounted without toast.

- [ ] **Step 2: Run RED page tests**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/tournament_detail_page_test.dart
```

Expected: compile FAIL because page still builds the one-argument bloc and listener toasts every error.

- [ ] **Step 3: Page worker injects both repositories and narrows listener**

```dart
create: (_) => TournamentDetailBloc(
  getIt<EsportLeagueRepository>(),
  getIt<EsportGroupRepository>(),
)..add(OpenLeagueDetail(leagueId)),
```

Listener reacts only to explicit local page-level navigation conditions. It calls `smartBack()` for deleted/inactive and does not toast stream errors or remote metadata. Mutation feedback remains owned by the initiating bloc command.

- [ ] **Step 4: Run GREEN page tests and commit**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/tournament_detail_page_test.dart
git add lib/presentation/esport/tournament/tournament_detail/tournament_detail_page.dart test/presentation/esport/tournament/tournament_detail/tournament_detail_page_test.dart
git commit -m "refactor: wire realtime league detail lifecycle"
```

---

### Task 9: Render accessible per-match pending state in ordinary match lists

**Files:**
- Test: `test/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart`
- Test: `test/presentation/esport/tournament/tournament_detail/matches/matches_view_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/matches/matches_view.dart`

**Interfaces:**
- Consumes: `pendingMatchIds`, `matchErrorsById`, `tournamentSavingMatch`, `EnsureDetailSubscriptions`.
- Produces:

```dart
EsportMatchItem({
  required GNEsportMatch match,
  bool isPending = false,
  String? errorMessage,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
})
```

- [ ] **Step 1: Match-item test worker adds semantics RED tests**

Assert `isPending: true` renders a small progress indicator plus `Đang lưu kết quả`, exposes that text through semantics, and ignores tap/long-press. Assert error text is readable and ordinary rows retain current behavior.

- [ ] **Step 2: Run RED match-item tests**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item_test.dart --plain-name "pending"
```

Expected: compile FAIL because `isPending` and `errorMessage` parameters do not exist.

- [ ] **Step 3: Match-item production worker implements local-only lock**

Wrap the row in `Semantics(container: true, label: isPending ? context.l10n.tournamentSavingMatch : null, enabled: !isPending)`. Set InkWell callbacks null while pending and append the visible localized status; do not identify pending by color/animation alone.

- [ ] **Step 4: Matches-view test worker adds selector/refresh/pending RED cases**

Verify only the pending match loses score/edit/delete interactions, another row remains interactive, its error renders at that row, and pull refresh dispatches `EnsureDetailSubscriptions(leagueId)` rather than aggregate fetch. Emit a league-name-only state and assert the keyed match-list subtree widget instance is identical; emit a match snapshot and assert it updates.

- [ ] **Step 5: Matches-view production worker selects only needed data**

Use `BlocSelector` with an immutable record containing matches, participants/users needed for actions, membership, pending IDs, match error map, match slice status and refresh tick. Pass pending/error to each `EsportMatchItem`, disable its `SlidableAction` while pending, and replace `_refresh` dispatch with `EnsureDetailSubscriptions` plus `refreshTick` wait. A matches slice failure shows translated retry UI dispatching `RetryDetailSlice(TournamentDetailSlice.matches)` without clearing old rows.

- [ ] **Step 6: Run GREEN ordinary-match suites**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item_test.dart
flutter test test/presentation/esport/tournament/tournament_detail/matches/matches_view_test.dart
```

Expected: both suites pass; no `GetParticipantsAndMatches` expectation remains.

- [ ] **Step 7: Commit pending list UI**

```bash
git add lib/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart test/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item_test.dart lib/presentation/esport/tournament/tournament_detail/matches/matches_view.dart test/presentation/esport/tournament/tournament_detail/matches/matches_view_test.dart
git commit -m "feat: show per-match online save state"
```

---

### Task 10: Apply pending locks to group and knockout match surfaces

**Files:**
- Test: `test/presentation/esport/tournament/tournament_detail/groups/group_standings_view_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/groups/group_standings_view.dart`
- Test: `test/presentation/esport/tournament/tournament_detail/bracket/bracket_view_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/bracket/bracket_view.dart`

**Interfaces:**
- Consumes: same pending/error state from Task 9.
- Produces: no score dialog/action for a pending group/knockout match; visible and semantic pending label.

- [ ] **Step 1: Group test worker adds RED coverage**

Pump two group matches with one ID pending. Assert pending row displays `Đang lưu kết quả`, cannot open the score dialog, the second can, and a league-name-only state does not replace the keyed group-content widget instance.

- [ ] **Step 2: Group production worker narrows selector and locks row**

Include matches, participants, selected group, league advance count/admin capability, pending IDs and match errors in the selector record. Pass `isPending` into group row/card rendering and disable only that card.

- [ ] **Step 3: Bracket test worker adds RED coverage**

Cover one pending knockout match and one ordinary match. Assert local lock/semantics, next match remains interactive when allowed, and standings-only updates do not rebuild the keyed bracket rounds subtree.

- [ ] **Step 4: Bracket production worker selects matches plus pending capability**

Replace the current `context.read(...).state` inside `_BracketMatchCard` with values passed from a `BlocSelector` record: knockout matches, admin/group-stage gate, pending IDs, errors. Disable pending tap and show localized status; no global loading.

- [ ] **Step 5: Run GREEN group/bracket suites and commit**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/groups/group_standings_view_test.dart
flutter test test/presentation/esport/tournament/tournament_detail/bracket/bracket_view_test.dart
git add lib/presentation/esport/tournament/tournament_detail/groups/group_standings_view.dart test/presentation/esport/tournament/tournament_detail/groups/group_standings_view_test.dart lib/presentation/esport/tournament/tournament_detail/bracket/bracket_view.dart test/presentation/esport/tournament/tournament_detail/bracket/bracket_view_test.dart
git commit -m "feat: lock pending group and bracket matches"
```

---

### Task 11: Isolate League Detail shell/header rebuilds and lazily render share cards

**Files:**
- Test: `test/presentation/esport/tournament/tournament_detail/tournament_detail_view_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/tournament_detail_view.dart`

**Interfaces:**
- Consumes: `DetailBootstrapStatus`, slice errors, `EnsureDetailSubscriptions`, existing share preview API.
- Produces: shell selector by mode/bootstrap; header selector by league metadata/capabilities; temporary share layer only while capture is active.

- [ ] **Step 1: Test worker adds RED render/lifecycle/share coverage**

Add stable keys `tournament-detail-shell`, `tournament-detail-header`, `tournament-share-layer`. Tests assert:

- Resume dispatches `EnsureDetailSubscriptions('L1')`, never aggregate fetch.
- Score/stats-only state keeps the exact same keyed header widget instance.
- League name update replaces header content but keeps standings subtree independent.
- Before share tap, `find.byType(LeagueShareCard)` is empty.
- Share tap creates only required dark/light variants, capture waits one frame, preview opens, and closing preview disposes all cards.
- While preview/capture is open, a realtime state emission does not recreate the stored share layer.
- Initial bootstrap loading is page-level; stats/matches slice error after league bootstrap keeps shell and exposes retry without toast.

- [ ] **Step 2: Run RED detail-view tests**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/tournament_detail_view_test.dart
```

Expected: failures because resume dispatches aggregate fetch, one large BlocBuilder rebuilds everything and 2–4 share cards always exist off-screen.

- [ ] **Step 3: Production worker introduces selectors and captured share payload**

Outer selector contains only `(bootstrapStatus, mode, leagueDeleted)`. Header selector contains league metadata and member/admin capabilities. Do not include participants/matches in either.

Store an immutable private `_ShareRenderPayload` when share is selected and set `_renderShareCards = true`; render its off-screen `RepaintBoundary` variants, await `WidgetsBinding.instance.endOfFrame`, capture, open preview, then clear payload/layer in `finally`. Cards read the captured payload, not live bloc state, so remote updates do not rebuild them.

On app resume dispatch `EnsureDetailSubscriptions(activeLeagueId)`. Remove global `LinearProgressIndicator` for local match pending; retain page bootstrap indicator only while `bootstrapStatus == loading`.

- [ ] **Step 4: Run GREEN detail-view suite and commit**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/tournament_detail_view_test.dart
git add lib/presentation/esport/tournament/tournament_detail/tournament_detail_view.dart test/presentation/esport/tournament/tournament_detail/tournament_detail_view_test.dart
git commit -m "perf: isolate league detail rendering and sharing"
```

---

### Task 12: Narrow standings and cost rebuilds; remove full-fetch refreshes

**Files:**
- Test: `test/presentation/esport/tournament/tournament_detail/table/table_view_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/table/table_view.dart`
- Create: `test/presentation/esport/tournament/tournament_detail/cost/cost_split_view_test.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/cost/cost_split_view.dart`

**Interfaces:**
- Consumes: `EnsureDetailSubscriptions`, `RetryDetailSlice`, stats/matches/league slices.
- Produces: standings ignores metadata-only changes; cost observes only cost config, stats and applicable matches.

- [ ] **Step 1: Table test worker adds RED selector tests**

Assert score/stat snapshot updates standings; league name-only update keeps the keyed table body instance; match update only changes metric count, not header rows; refresh dispatches `EnsureDetailSubscriptions`; stats slice failure preserves existing rows and provides retry.

- [ ] **Step 2: Table production worker uses a narrow record selector**

Select `(participants, league cost/rank metadata needed by summary, matches.length, statsSliceStatus, streamError, refreshTick)`. Replace aggregate refresh with ensure/retry events.

- [ ] **Step 3: Cost test worker creates RED coverage**

Assert irrelevant league name/status change does not replace keyed cost body; cost-config, relevant stats or relevant finished match change does. Refresh must not dispatch any explicit fetch. Slice error leaves confirmed cost summary visible.

- [ ] **Step 4: Cost production worker uses a cost-only selector**

Select league cost fields, admin capability, participants, matches needed by `CostSummaryPanel`, and slice status/errors. Use `EnsureDetailSubscriptions` for pull refresh. Do not subscribe to pending IDs unless a pending overlay is rendered in this cost view.

- [ ] **Step 5: Run GREEN view suites**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/table/table_view_test.dart
flutter test test/presentation/esport/tournament/tournament_detail/cost/cost_split_view_test.dart
```

Expected: both pass; metadata-only and unrelated snapshot cases preserve keyed subtree instances.

- [ ] **Step 6: Commit selector cleanup**

```bash
git add lib/presentation/esport/tournament/tournament_detail/table/table_view.dart test/presentation/esport/tournament/tournament_detail/table/table_view_test.dart lib/presentation/esport/tournament/tournament_detail/cost/cost_split_view.dart test/presentation/esport/tournament/tournament_detail/cost/cost_split_view_test.dart
git commit -m "perf: narrow league standings and cost rebuilds"
```

---

### Task 13: Delete obsolete split-write and aggregate-detail APIs after caller migration

**Files:**
- Modify: `lib/domain/repositories/esport/esport_league_repository.dart`
- Modify: `lib/data/repositories/esport/esport_league_repository_impl.dart`
- Modify: `lib/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_event.dart`
- Modify: `lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart`
- Test: `test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart`
- Test: `test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart`

**Interfaces:**
- Consumes: all callers now use streams and `updateMatchAtomically`.
- Produces: exactly one active match write path; no `LeagueDetailData` aggregate loader.

- [ ] **Step 1: Test workers remove assertions for obsolete behavior and add negative call scans**

Keep atomic/stat/concurrency tests. BLoC tests must use `verifyNever` for old repository methods while those methods still exist immediately before deletion; after contract deletion, replace those with source `rg` gate below because mocks can no longer reference removed members.

- [ ] **Step 2: Run pre-delete caller scan**

```bash
rg -n "updateMatch\(|applyMatchStatDelta\(|LeagueDetailData|GetParticipantsAndMatches|GetParticipantStats|GetMatches|UpdateMatches" lib --glob '*.dart'
```

Expected: only declarations/implementations scheduled in this task remain; no UI/bloc caller remains.

- [ ] **Step 3: Run sequential one-file cleanup workers**

In dependency order:

1. Event worker removes obsolete explicit-fetch/update helper events.
2. Bloc worker removes their registrations/handlers and all explicit refresh dispatches after add/delete/generate/recompute.
3. Domain worker removes `LeagueDetailData`, `getParticipantsAndMatches`, old `updateMatch`, and `applyMatchStatDelta`; keep `getLeagueStats` and `getMatches` because they remain valid repository capabilities outside reactive detail even if currently lightly used.
4. Data worker removes matching aggregate/split adapters.
5. Firestore match worker removes old split methods only after the atomic implementation and delete/recompute helpers no longer call them.
6. Test workers remove obsolete groups while preserving every atomic regression.

- [ ] **Step 4: Run GREEN cleanup gates**

```bash
flutter test test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart
flutter test test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart
flutter test test/data/repositories/esport/esport_league_repository_impl_test.dart
rg -n "applyMatchStatDelta\(|LeagueDetailData|GetParticipantsAndMatches|GetParticipantStats|UpdateMatches" lib test --glob '*.dart'
```

Expected: tests pass; final scan returns no matches. `getLeagueStats` remains for group management; no compatibility fallback keeps two write paths alive.

- [ ] **Step 5: Commit API deletion**

```bash
git add lib/domain/repositories/esport/esport_league_repository.dart lib/data/repositories/esport/esport_league_repository_impl.dart lib/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_event.dart lib/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart
git commit -m "refactor: remove split online match write path"
```

---

### Task 14: Run integrated realtime, accessibility and regression gates

**Files:**
- Test scope only; no production edits are authorized in this task. Any discovered fix starts a new RED cycle with a fresh one-file worker.

**Interfaces:**
- Consumes: all tasks above.
- Produces: evidence for targeted suites, analyzer, full suite and manual-risk boundary.

- [ ] **Step 1: Verify one-file ownership and scope**

```bash
git diff --name-only main...HEAD
git diff --name-only main...HEAD | rg '^lib/offline/|^test/offline/'
git diff --check
```

Expected: changed files match the ownership map; offline scan has no output; diff check exits 0.

- [ ] **Step 2: Verify generated localization deterministically outside repo**

Repeat the `/tmp/game_note_l10n_online_league` generation from Task 1 and `cmp` all three generated targets. Expected: all comparisons exit 0.

- [ ] **Step 3: Run targeted suites in dependency order**

```bash
flutter test test/presentation/esport/tournament/create_esport_league_page_test.dart
flutter test test/presentation/esport/tournament/tournament_view_test.dart
flutter test test/firebase/firestore/esport/league/
flutter test test/data/repositories/esport/esport_league_repository_impl_test.dart
flutter test test/presentation/esport/tournament/tournament_detail/
```

Expected: every suite passes. These cover create call ordering, stream call counts/cache, atomic writes/conflicts, per-row pending, selectors, lazy share and semantics.

- [ ] **Step 4: Run formatting, analyzer and full test gates**

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Expected: formatter/analyzer exit 0 and full suite passes. If full suite has an unrelated timing failure, rerun that exact test once and report both outputs; do not change unrelated code.

- [ ] **Step 5: Perform Firebase/two-device QA when credentials and devices are available**

Use two signed-in app instances on the same league:

1. Open detail on both and record that each initial view performs one league/stats/matches listener bootstrap with no repeated user reads.
2. Device A edits one match; B receives match + standings with no toast/loading.
3. Both open the same match version; A saves, B saves stale and receives localized conflict without overwriting A.
4. A and B save two different matches sharing a player; verify final aggregate includes both.
5. Disable network on A before save; only that row stays pending, no success appears, then failure clears pending and confirmed snapshot remains.
6. Start create flow, hold callback/network, verify submit/back/form lock and stable accessible loading button; after detail closes, list reloads once.
7. Open and close share preview; verify cards are absent before and after capture.

Expected: all seven behaviors match. If Firebase Emulator is available, repeat cases 2–4 there to observe SDK transaction retries. If it is unavailable, explicitly report that fake Firestore tests do not prove real SDK contention timing.

- [ ] **Step 6: Final branch evidence**

```bash
git status --short
git log --oneline --decorate -8
```

Expected: only intentional branch changes; no untracked generated artifacts; commits correspond to green boundaries above.

---

## Spec Requirement Traceability

| Spec requirement | Implemented/tested in |
|---|---|
| Create spinner/localized stable button; duplicate submit/form/back/pop lock; error unlock; success stays pending to pop | Tasks 1–2 |
| One `addLeague`, zero duplicate participant write, fixture generator once, rollback preserves original error | Task 3 |
| Reload My/Managed only once after detail closes | Task 3 |
| Exactly one league/stats/matches subscription; initial snapshots are bootstrap; no explicit reads | Tasks 4, 7–8 |
| Resume/retry reuses or rebinds lost stream; finite backoff; close/switch cleanup | Tasks 7, 9, 11–12 |
| League metadata patches only league; group resolved once without rereading league | Task 7 |
| Raw stream rows + `usersById` cache; only missing profile IDs fetched | Task 7 |
| Remote updates do not toast/global-load and patch only the relevant slice | Tasks 7–8 |
| Atomic match + two stats / next knockout slot; delta computed in retried closure | Tasks 5–6 |
| Random-ID stat compatibility and full group `groupId` resolution | Task 5 |
| Missing stat/transaction failure/conflict writes nothing partially | Task 5 |
| Legacy timestamp first update and subsequent optimistic lock | Task 5 |
| Per-match pending/offline/local feedback; other matches remain interactive | Tasks 7, 9–10 |
| Two-device same-match conflict and different-match shared-player aggregation | Tasks 5, 7, 14 |
| Header/standings/fixtures/bracket/cost selectors and rebuild isolation | Tasks 9–12 |
| Share cards absent until share, captured variants disposed afterward | Task 11 |
| Bootstrap vs mutation errors separated; deletion/inactive closes safely | Tasks 7–8 |
| Remove legacy split APIs only after all callers migrate | Task 13 |
| Accessibility for create loading, pending match, disabled actions and conflict | Tasks 1–2, 7, 9–10 |
| No schema/dependency/offline/fixture algorithm changes | Global Constraints, Task 14 scope scan |

## Final Pre-flight / Self-review Checklist

- [ ] Every spec row above points to at least one RED test and production task.
- [ ] Signatures are consistent end-to-end: repository and GNFirestore use `updateMatchAtomically`; `costPerGoal` and `expectedUpdatedAt` are forwarded; league stream is nullable.
- [ ] `TournamentDetailBloc` constructor receives both repository types and page injection matches it.
- [ ] No snapshot handler calls toast, sets global loading or launches a full read.
- [ ] Every local command owns only its own pending/error/feedback; remote clients receive none.
- [ ] Every Firestore transaction read happens before staged writes and delta calculation lives inside the retryable closure.
- [ ] Random stat IDs remain query-resolved by `userId` plus in-memory `groupId`; no deterministic ID or backfill appeared.
- [ ] All old split-write callers and aggregate detail-loader symbols are absent after Task 13.
- [ ] Create input remains intact on both known and generic failure; rollback failure cannot replace the original create failure.
- [ ] Localization output matches clean `/tmp` generation and each generated target had one-file ownership.
- [ ] No worker touched more than its assigned file; main reviewed every diff before integration commit.
- [ ] No offline path, schema file, dependency manifest or fixture algorithm changed.
- [ ] Focused tests, `flutter analyze`, full `flutter test`, formatter check and `git diff --check` have recorded exit status.
- [ ] Two-device/Firebase Emulator evidence is reported honestly and separately from fake/unit/widget evidence.
- [ ] Residual risk is stated: create rollback still deletes only the league document and does not recursively clean orphan subcollections.
