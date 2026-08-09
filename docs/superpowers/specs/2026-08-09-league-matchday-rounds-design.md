# League Matchday Rounds — Design

Date: 2026-08-09
Status: Approved
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
| Matchday numbering | Continuous across legs | 6 players: leg 1 = matchdays 1–5, leg 2 = 6–10. Matches how real leagues number matchdays. Needs one `int` field, no leg tracking. |
| Enable/disable toggle | None — always on | Assigning a matchday is free and backward-compatible. A toggle would create mixed data inside one league for no benefit. |
| Home/away in later legs | Mirror the earlier leg | Makes "lượt về" meaningful. Fixed as part of the same change because both touch the generation algorithm. |
| Applies to | League mode only | Cup mode already has `knockoutRound`; full-mode group stage is out of scope. |
| Matches without a matchday | "Other matches" section at the end | Legacy leagues and custom matches created with the `+` button. No backfill, no bulk Firestore rewrite. |
| Results tab | Flat list + matchday badge | Keeps the existing name search working naturally. |

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

Backward compatibility: the field is additive. Legacy documents deserialize to
`matchday == null`. `firestore.rules` allows `create, update, delete` on
`leagues_matches/{matchId}` for league group members without validating
individual fields, so no rules change is needed.

### 2. Round-robin scheduler (new, pure Dart)

New file `lib/firebase/firestore/esport/league/match/round_robin_scheduler.dart`.
No Firestore imports, so it is unit-testable without fakes or mocks.

```dart
class ScheduledPairing {
  final String homeId;
  final String awayId;
  final int matchday;
}

List<ScheduledPairing> buildRoundRobinSchedule({
  required List<String> teamIds,
  required int startMatchday,
  required List<GNEsportMatch> existingMatches,
});
```

**Pairing algorithm.** Circle method, ported from
`TournamentHelper.createRounds`: fix the first team, rotate the remainder. An
odd team count gets a synthetic bye entry whose pairings are filtered out. For
`n` teams this yields `n - 1` matchdays when `n` is even and `n` matchdays when
`n` is odd, numbered `startMatchday`, `startMatchday + 1`, …

**Home/away orientation.** For each pairing `(a, b)`, count within
`existingMatches` how many times `a` has been home against `b` and how many
times `b` has been home against `a`. The team with fewer home games in that
head-to-head is placed at home; on a tie the circle-method order stands.

This rule is preferred over a simpler `legIndex.isOdd` flip because it stays
correct when the participant list changes between legs — a leg-parity counter
would mis-orient pairs that skipped a leg.

**Duplicate handling.** `teamIds` is de-duplicated first, preserving the
existing `_uniqueTeamIds` behaviour.

### 3. Firestore layer

`generateRound` gains a read step before the write:

1. Query `esports_leagues/{leagueId}/leagues_matches`.
2. `startMatchday = (max non-null matchday) + 1`, defaulting to `1`.
3. Call `buildRoundRobinSchedule` with the existing matches.
4. `_ensureLeagueStats`, then `_writeBatched` — unchanged.

The extra read is one subcollection query per leg generation, negligible next
to the batch write that follows it.

`generateGroupRound` and `generateCupBracket` are untouched.

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

**`esport_match_item.dart`:** renders a compact `V{n}` chip when
`match.matchday != null`. Visible in both tabs.

### 5. Offline-to-online migrator

`_buildOnlineMatches` in `lib/data/sync/offline_to_online_migrator.dart`
already iterates `offlineLeague.rounds`. It sets `matchday: roundIndex + 1` on
each produced `GNEsportMatch`, so migrated offline leagues keep their existing
round structure.

### 6. Localization

`lib/l10n/app_en.arb` / `app_vi.arb`:

| Key | en | vi |
|---|---|---|
| `tournamentMatchdayLabel` (param `n`) | `Round {n}` | `Vòng {n}` |
| `tournamentOtherMatches` | `Other matches` | `Trận khác` |

Three existing values are reworded (keys unchanged) because "Add round" now
collides with the new, genuine round concept — the button creates a whole leg:

| Key | en (new) | vi (new) |
|---|---|---|
| `tournamentAddRound` | `Add leg` | `Thêm lượt đấu` |
| `tournamentGenerateRoundMessage` | `Create a new leg? Fixtures will be split into matchdays.` | `Tạo lượt đấu mới? Các trận sẽ được chia theo vòng.` |
| `tournamentGenerateRoundWithExisting` | `There are {count} fixtures already. Create another leg, split into matchdays?` | `Hiện có {count} trận trong lịch. Tạo thêm một lượt mới, chia theo vòng?` |

`tournamentAddRound` is also used by `group_standings_view.dart` for
`generateGroupRound`, which likewise creates a full round-robin leg for one
group — "Add leg" reads correctly there too, even though group matches do not
get matchday numbers in this change.

Regenerate `lib/l10n/generated/` via the project's l10n build.

## Data flow

```
User taps "Thêm lượt đấu"
  → matches_view._confirmGenerateRound
  → TournamentDetailBloc GenerateRound
  → EsportLeagueRepository.generateRound
  → GnFirestoreEsportLeagueMatch.generateRound
      read existing matches → startMatchday
      buildRoundRobinSchedule(teamIds, startMatchday, existingMatches)
      _ensureLeagueStats → _writeBatched
  → bloc GetMatches → state.fixtures
  → fixture_grouping → sectioned ListView
```

## Error handling

Unchanged from today. `generateRound` failures propagate to
`TournamentDetailBloc._onGenerateRound`, which emits `ViewStatus.failure` with
the error message. The new read step can throw the same Firestore exceptions as
the existing write path and needs no special handling.

`buildRoundRobinSchedule` returns an empty list for fewer than two unique
teams; the bloc already guards on `state.participants.length < 2` before
calling.

## Testing

Per the repository's 100% line coverage policy, every file touched ships with
tests in the same change.

| Test file | Cases |
|---|---|
| `test/firebase/firestore/esport/league/match/round_robin_scheduler_test.dart` (new) | 6 teams → 5 matchdays × 3 matches; every pair appears exactly once; every team appears exactly once per matchday; 5 teams (odd) → 5 matchdays with one team resting each; second leg mirrors home/away of the first; `startMatchday` offsets the numbering; duplicate ids de-duplicated; fewer than 2 teams → empty |
| `test/firebase/firestore/esport/league/match/gn_firestore_esport_league_match_test.dart` (extend) | matchday persisted on generated docs; a second `generateRound` continues numbering from 6; a league whose existing matches have no matchday starts at 1 |
| `test/firebase/firestore/esport/league/match/gn_esport_match_test.dart` (new — no test file exists for this model yet) | `matchday` round-trips through `toMap`/`fromMap`; absent field → `null`; `copyWith` and `props` include it |
| `test/presentation/esport/tournament/tournament_detail/matches/fixture_grouping_test.dart` (new) | ascending matchday order; null-matchday matches land in the trailing section; empty input; all-null input produces only the other section |
| `test/presentation/esport/tournament/tournament_detail/matches/matches_view_test.dart` (extend) | matchday headers render; "other matches" header renders only when such matches exist |
| `test/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item_test.dart` (extend) | badge shown when `matchday != null`, hidden otherwise |
| `test/data/sync/offline_to_online_migrator_test.dart` (extend) | migrated matches carry `matchday = roundIndex + 1` |

Verification: `flutter analyze` clean, `flutter test --coverage` with no new
uncovered lines under `lib/`.
