# League Matchday Rounds — Design

Date: 2026-08-09
Status: Approved (revised after review)
Scope: Online esport tournament, league mode only

## Problem

`GnFirestoreEsportLeagueMatch.generateRound()` generates every pairing of a
round-robin leg in one flat batch (`for i < j`) with no notion of which
matchday a fixture belongs to. A 6-player league produces 15 fixtures shown as
one undifferentiated list; the user cannot tell that those 15 matches are
really 5 matchdays of 3 matches each.

Two consequences:

1. **No matchday grouping.** Neither the generated data nor the fixtures UI
   carries round information.
2. **The second leg is a duplicate, not a return leg.** Calling
   `generateRound` again emits the identical home/away orientation as the first
   call, so "lượt về" is a copy of "lượt đi" rather than a mirror.

The offline module already solves (1) correctly — `RoundModel` plus
`TournamentHelper.createRounds()` implements the circle method. This work
brings the same capability to the online league.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Matchday numbering | Continuous across legs | 6 players: leg 1 = matchdays 1–5, leg 2 = 6–10. Matches how real leagues number matchdays. |
| Numbering source | Persistent `matchdayCount` counter on the league doc, reserved inside a transaction | `max(matchday) + 1` computed from a prior read is neither atomic nor monotonic — see Concurrency below. |
| Enable/disable toggle | None — always on | Assigning a matchday is free and backward-compatible. A toggle would create mixed data inside one league for no benefit. |
| Home/away in later legs | Mirror the earlier leg | Makes "lượt về" meaningful. Fixed as part of the same change because both touch the generation algorithm. |
| Applies to | League mode only | Cup mode already has `knockoutRound`; full-mode group stage is out of scope. |
| Matches without a matchday | "Other matches" section at the end | Legacy leagues and custom matches created with the `+` button. No backfill, no bulk Firestore rewrite. |
| Results tab | Flat list + matchday badge | Keeps the existing name search working naturally. |
| Leg write | Single Firestore transaction, hard-capped at 32 participants | Guarantees a leg is all-or-nothing. See Atomicity below. |

Explicit non-goals: no changes to cup mode, full mode, group standings, or
match scheduling dates.

## Architecture

### 1. Data model

`GNEsportMatch` gains:

```dart
final int? matchday;
static const String fieldMatchday = 'matchday';
```

Threaded through `props`, `copyWith`, `toMap`, and `fromMap`. `toMap` writes it
conditionally (`if (matchday != null) fieldMatchday: matchday`), matching the
existing treatment of `phase`, `groupId`, and `knockoutRound`.

`GNEsportLeague` gains a field-name constant only:

```dart
static const String fieldMatchdayCount = 'matchdayCount';
```

**It is deliberately not added to the entity or to `GNEsportLeague.toMap()`.**
`updateLeague` at `gn_firestore_esport_league.dart:361` calls
`leagueRef.update(league.toMap())`; because `update` only touches the keys
present in the map, keeping `matchdayCount` out of `toMap()` prevents an
ordinary league edit from clobbering the counter. The counter is owned
exclusively by `generateRound`.

Backward compatibility: both fields are additive. Legacy match documents
deserialize to `matchday == null`; legacy league documents have no
`matchdayCount` and are seeded on first generation (see Concurrency).
`firestore.rules` already allows `update` on `esports_leagues/{leagueId}` for
league group members and `create/update/delete` on `leagues_matches/{matchId}`,
so no rules change is needed.

### 2. Round-robin scheduler (new, pure Dart)

New file `lib/firebase/firestore/esport/league/match/round_robin_scheduler.dart`.
No Firestore imports, so it is unit-testable without fakes or mocks.

```dart
class ScheduledPairing {
  final String homeId;
  final String awayId;
  final int matchday; // 1-based, relative to the leg
}

List<ScheduledPairing> buildRoundRobinSchedule({
  required List<String> teamIds,
  required List<GNEsportMatch> existingMatches,
});
```

Matchdays are numbered **relative to the leg** (1..k). The absolute offset is
applied by the caller once the transaction has reserved a range — the scheduler
stays a pure function of its inputs.

**Pairing algorithm.** Circle method, ported from
`TournamentHelper.createRounds`: fix the first team, rotate the remainder. An
odd team count gets a synthetic bye entry whose pairings are filtered out. For
`n` teams this yields `n - 1` matchdays when `n` is even and `n` matchdays when
`n` is odd.

**Home/away orientation.** For each pairing `(a, b)`, count within
`existingMatches` how many times `a` has been home against `b` and how many
times `b` has been home against `a`. The team with fewer home games in that
head-to-head is placed at home; on a tie the circle-method order stands.

This rule is preferred over a simpler `legIndex.isOdd` flip because it stays
correct when the participant list changes between legs — a leg-parity counter
would mis-orient pairs that skipped a leg.

Orientation is computed from a read taken outside the transaction. A stale read
here is cosmetic only: the worst case is one pair getting a less-balanced
home/away assignment. It cannot corrupt numbering, which is what the
transaction protects.

**Duplicate handling.** `teamIds` is de-duplicated first, preserving the
existing `_uniqueTeamIds` behaviour.

### 3. Firestore layer — atomic leg generation

`generateRound` is restructured as:

1. **Outside the transaction:** query `leagues_matches` once. Two uses — the
   orientation input for the scheduler, and the legacy seed value
   `maxExistingMatchday`.
2. Build the relative schedule; let `matchCount = schedule.length` and
   `matchdayCount = number of distinct matchdays in the schedule`.
3. **Guard:** if `matchCount + 1 > 500`, throw `RoundTooLargeException`
   before any write. See Atomicity.
4. `_ensureLeagueStats(leagueId, uniqueTeamIds)` — unchanged, runs first,
   idempotent (creates only missing rows).
5. **Transaction** on the league document:
   - `tx.get(leagueRef)` → `allocated = data['matchdayCount'] as int?`
   - `start = (allocated ?? maxExistingMatchday) + 1`
   - `tx.update(leagueRef, {matchdayCount: allocated_or_seed + matchdayCount})`
   - `tx.set(...)` each match doc with `matchday: start + relativeMatchday - 1`

`generateGroupRound` and `generateCupBracket` are untouched.

#### Concurrency

Reserving the range inside the same transaction that writes the matches gives
two guarantees that `max(matchday) + 1` could not:

- **No collision.** Two members tapping "Thêm lượt đấu" at the same moment
  cannot both receive matchdays 6–10; the second transaction retries against
  the updated counter and gets 11–15. The per-device `ViewStatus.loading` guard
  in `TournamentDetailBloc._onGenerateRound` only serialises one client, which
  is why the invariant has to live in Firestore.
- **Monotonic numbering.** Deleting every match of the last matchday no longer
  frees that number for reuse, because the counter is independent of the
  matches that exist.

**Known limitation, accepted:** a legacy league whose document has no
`matchdayCount` seeds the counter from `maxExistingMatchday`, a value read
outside the transaction. Two exactly-simultaneous generations on such a league,
before the counter exists, can still collide. The window is one generation per
league in the app's lifetime, and the failure mode is a cosmetic duplicate
matchday number rather than data loss. Adding a migration to pre-seed every
league is not worth it.

#### Atomicity

`_writeBatched` commits independent chunks of 499. With 33 participants a leg
is 528 matches — two chunks — and a failure between them leaves a half-written
leg that a retry cannot complete, only duplicate. The fix chosen here is to
make a leg fit in one atomic write rather than to build resume machinery:

- League-mode generation writes through a single transaction (Firestore's limit
  is 500 operations, of which one is the counter update).
- `matchCount + 1 > 500` throws `RoundTooLargeException` before anything is
  written. `n(n-1)/2 ≤ 499` gives a ceiling of **32 participants** (32 → 496
  matches; 33 → 528).

This is a deliberate trade: 32 players in a single round-robin league is far
beyond the app's use case (a friend-group PES/football league), and a hard,
early, localized error is better than partial state that no retry path
repairs. `_writeBatched` stays in place for `generateGroupRound`,
`generateCupBracket`, and `generateFullTournament`, which are unchanged.

If a league ever legitimately needs more than 32 participants, the fix is a
resumable generation record — explicitly deferred, not designed here.

### 4. Presentation

**Grouping (new file):**
`lib/presentation/esport/tournament/tournament_detail/matches/fixture_grouping.dart`

A pure function mapping `List<GNEsportMatch>` to `List<FixtureSection>`, sorted
by matchday ascending, with all `matchday == null` matches collected into a
trailing "other" section. Kept out of the widget so it can be tested without
pumping, and so `matches_view.dart` (already 285 lines) does not grow further.

**`matches_view.dart`:** the fixtures list changes from `ListView.separated`
over matches to `ListView.builder` over a flattened list of header and match
items. `RefreshIndicator` and `Slidable` behaviour is preserved. The results
tab keeps its flat list and name search.

**`esport_match_item.dart`:** renders a compact badge when
`match.matchday != null`, using the localized `tournamentMatchdayBadge` key —
`V{n}` in Vietnamese, `MD {n}` in English. Visible in both tabs.

**Error surface:** `TournamentDetailBloc._onGenerateRound` catches
`RoundTooLargeException` specifically and shows the localized
`tournamentRoundTooLarge` toast instead of leaking `e.toString()` into
`errorMessage`. Other exceptions keep the current behaviour.

### 5. Offline-to-online migrator

`_buildOnlineMatches` in `lib/data/sync/offline_to_online_migrator.dart`
already iterates `offlineLeague.rounds`. It sets `matchday: roundIndex + 1` on
each produced `GNEsportMatch`, so migrated offline leagues keep their existing
round structure.

The migrator also writes `matchdayCount = offlineLeague.rounds.length` on the
created league document, so the first online `generateRound` after a migration
continues from the right number instead of restarting at 1.

### 6. Localization

New keys in `lib/l10n/app_en.arb` / `app_vi.arb`:

| Key | en | vi |
|---|---|---|
| `tournamentMatchdayLabel` (param `n`, int) | `Round {n}` | `Vòng {n}` |
| `tournamentMatchdayBadge` (param `n`, int) | `MD {n}` | `V{n}` |
| `tournamentOtherMatches` | `Other matches` | `Trận khác` |
| `tournamentRoundTooLarge` | `This league has too many players to generate a leg in one go (max 32).` | `Giải có quá nhiều người chơi để tạo một lượt (tối đa 32).` |

Reworded values (keys unchanged). "Round" previously meant *leg*; now that real
rounds exist, every string in the generation flow is disambiguated together —
not just the button:

| Key | en (new) | vi (new) |
|---|---|---|
| `tournamentAddRound` | `Add leg` | `Thêm lượt đấu` |
| `tournamentGenerateRoundMessage` | `Create a new leg? Fixtures will be split into matchdays.` | `Tạo lượt đấu mới? Các trận sẽ được chia theo vòng.` |
| `tournamentGenerateRoundWithExisting` | `There are {count} fixtures already. Create another leg, split into matchdays?` | `Hiện có {count} trận trong lịch. Tạo thêm một lượt mới, chia theo vòng?` |
| `tournamentRoundCreated` | `Leg created successfully` | `Tạo lượt đấu thành công` |
| `tournamentGroupRoundMinimum` | `Group needs at least 2 players to create a leg` | `Bảng cần ít nhất 2 người chơi để tạo lượt đấu` |

`tournamentAddRound`, `tournamentRoundCreated`, and
`tournamentGroupRoundMinimum` are shared with the full-mode group flow
(`group_standings_view.dart:386`, `tournament_detail_bloc.dart:658`).
`generateGroupRound` likewise creates a whole round-robin leg for one group, so
"leg" reads correctly there too — group matches simply do not get matchday
numbers in this change. No message split is needed.

Regenerate `lib/l10n/generated/` via the project's l10n build.

## Data flow

```
User taps "Thêm lượt đấu"
  → matches_view._confirmGenerateRound
  → TournamentDetailBloc GenerateRound
  → EsportLeagueRepository.generateRound
  → GnFirestoreEsportLeagueMatch.generateRound
      query existing matches (orientation + legacy seed)
      buildRoundRobinSchedule(teamIds, existingMatches)   // relative 1..k
      guard: matchCount + 1 <= 500 else RoundTooLargeException
      _ensureLeagueStats
      runTransaction: read counter → reserve range → write counter + matches
  → bloc GetMatches → state.fixtures
  → fixture_grouping → sectioned ListView
```

## Error handling

| Failure | Behaviour |
|---|---|
| More than 32 participants | `RoundTooLargeException` thrown before any write; bloc shows `tournamentRoundTooLarge` toast; no state change. |
| Transaction fails (network, contention, permission) | Nothing is written — no partial leg, no burned matchday numbers. Bloc emits `ViewStatus.failure` with the message, as today. |
| Fewer than 2 unique teams | `buildRoundRobinSchedule` returns an empty list and `generateRound` returns without writing. The bloc already guards on `state.participants.length < 2`. |
| `_ensureLeagueStats` fails | Propagates before the transaction; no matches written. Unchanged from today. |

## Testing

Per the repository's 100% line coverage policy, every file touched ships with
tests in the same change.

| Test file | Cases |
|---|---|
| `test/firebase/firestore/esport/league/match/round_robin_scheduler_test.dart` (new) | 6 teams → 5 matchdays × 3 matches; every pair appears exactly once; every team appears exactly once per matchday; 5 teams (odd) → 5 matchdays with one team resting each; second leg mirrors home/away of the first; a pair that skipped a leg still orients correctly; duplicate ids de-duplicated; fewer than 2 teams → empty |
| `test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart` (extend) | matchday persisted on generated docs; `matchdayCount` written to the league doc; a second `generateRound` continues from 6; a legacy league with no counter seeds from `max(matchday)`; a legacy league with no matchday at all starts at 1; **two sequential reservations never overlap** (fake_cloud_firestore is single-threaded, so this asserts the counter contract rather than a true race); **deleting every match of the last matchday does not free its number**; 33 participants throws `RoundTooLargeException` and writes nothing; 32 participants succeeds |
| `test/firebase/firestore/esport/league/match/gn_esport_match_test.dart` (new — no test file exists for this model yet) | `matchday` round-trips through `toMap`/`fromMap`; absent field → `null`; `copyWith` and `props` include it |
| `test/firebase/firestore/esport/league/gn_esport_league_test.dart` (extend) | `toMap()` does **not** contain `matchdayCount`, so `updateLeague` cannot clobber it |
| `test/presentation/esport/tournament/tournament_detail/matches/fixture_grouping_test.dart` (new) | ascending matchday order; null-matchday matches land in the trailing section; empty input; all-null input produces only the other section; gaps in matchday numbers render as-is |
| `test/presentation/esport/tournament/tournament_detail/matches/matches_view_test.dart` (extend) | matchday headers render; "other matches" header renders only when such matches exist |
| `test/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item_test.dart` (extend) | badge shown when `matchday != null`, hidden otherwise; renders `V3` under `vi` and `MD 3` under `en` |
| `test/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc_test.dart` (extend) | `RoundTooLargeException` surfaces the localized toast, not `e.toString()` |
| `test/data/sync/offline_to_online_migrator_test.dart` (extend) | migrated matches carry `matchday = roundIndex + 1`; league doc carries `matchdayCount = rounds.length` |

Verification: `flutter analyze` clean, `flutter test --coverage` with no new
uncovered lines under `lib/`.

## Review notes

Revised after review feedback. Changes from the first draft:

- **Numbering moved from `max(matchday) + 1` to a transaction-reserved counter**
  on the league document, closing the concurrent-generation collision and the
  delete-and-reuse hole. The residual legacy-seed window is documented above as
  an accepted limitation.
- **Leg writes are a single transaction with a 32-participant cap** instead of
  chunked `_writeBatched`. The reviewer offered three options (size limit,
  resumable generation record, backend orchestration); the size limit is the
  one that fits the app's scale, and folding it into the same transaction as
  the counter also removes the matchday-gap problem that a separate reserve
  step would have introduced.
- **Badge is localized** via `tournamentMatchdayBadge` (`V{n}` / `MD {n}`) with
  a test in both locales, rather than a hardcoded `V{n}`.
- **Terminology rename extended** to `tournamentRoundCreated` and
  `tournamentGroupRoundMinimum`, and the shared league/group usage is
  documented rather than split.
