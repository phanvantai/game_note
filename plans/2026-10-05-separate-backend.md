# Plan: Separate backend (Firebase Auth only)

**Date:** 2026-10-05
**Status:** In progress
**Branch:** `feat/backend-server`

## Why

The app is slow for a small friend group because every screen chains several
Firestore round trips to a US region (~250 ms each from Vietnam), score saves
take 4+ sequential round trips plus a Cloud Function fan-out, and dashboard /
group overview wait on trigger-maintained summary docs (up to a 30 s timeout
when a recompute is requested).

The new backend runs on the existing Hanoi VPS (`examino-dev`, ~20 ms RTT),
stores everything in Postgres, and computes standings / summaries / head-to-head
directly from matches on each request. Firebase stays for Auth only.

## Architecture

```
Flutter app ──HTTPS + Firebase ID token──▶ Traefik (coolify-proxy, VPS)
                                              │
                                              ▼
                                   game-note-api (Fastify, Node 22)
                                              │
                                              ▼
                                   game-note-db (Postgres 17)
```

- `server/` — TypeScript, Fastify 5, `pg`, `zod`, `jose` (verifies Firebase ID
  tokens against Google's public JWKS; no service account needed).
- Realtime: `GET /v1/leagues/:id/events` Server-Sent Events. One connection per
  open tournament replaces the three Firestore listeners.
- Avatars: stored on a VPS volume, served at `/avatars/:file`.
- Derived data is never stored: standings, user summary, h2h and group summary
  are SQL/TS computations over `matches`. This deletes all six Cloud Functions,
  the recompute-request docs, tombstones and idempotency rings.
- Concurrency: match updates run in one Postgres transaction with
  `SELECT … FOR UPDATE`; optimistic version = `updatedAt` (millisecond
  precision) → HTTP 409 `concurrent_update`.

## Phases

1. **Server** — schema, endpoints, SSE, tests against real Postgres, Dockerfile.
2. **Flutter adapter** — `lib/api/` client + API repository implementations of
   the existing domain contracts; route remaining direct `GNFirestore` usages
   through repositories; drop the recompute/listen dance from stats blocs.
3. **Deploy** — docker compose on `examino-dev` behind the existing Traefik,
   memory-limited, nightly `pg_dump`.
4. **Migration** — one-shot `server/scripts/import-firestore.ts` (Firestore →
   Postgres, avatars re-hosted), then release 5.0.0 with forced update.
5. **Cleanup** — remove `lib/firebase/firestore`, `firebase_storage`,
   `cloud_firestore`, `functions/`, `firestore.rules`.

## API contract (v1)

All routes except `/health` and `/avatars/*` need
`Authorization: Bearer <Firebase ID token>`. JSON bodies, camelCase keys.
Timestamps are ISO-8601 UTC strings with milliseconds
(`2026-10-05T10:00:00.000Z`). Errors: `{ "error": "<code>", "message": "…" }`
with codes `unauthenticated` (401), `forbidden` (403), `not_found` (404),
`validation` (400), `concurrent_update` (409), `conflict` (409).

### Shapes

```jsonc
// User
{ "id": "uid", "displayName": "Tai", "phoneNumber": null, "email": "a@b.c",
  "photoUrl": null, "role": "user", "isPlaceholder": false,
  "deleted": false, "deletedAt": null }

// Group
{ "id": "g1", "groupName": "FC", "ownerId": "uid", "members": ["uid"],
  "deactivatedMembers": [], "description": "", "status": "active",
  "createdAt": "…", "updatedAt": "…" }

// League  (group is embedded on every league response; null if missing)
{ "id": "l1", "ownerId": "uid", "groupId": "g1", "name": "S1",
  "startDate": "…", "endDate": null, "isActive": true, "description": "",
  "participants": ["uid"], "status": "upcoming",
  "rankPayoutEnabled": false, "rankPayouts": [], "defaultMatchCost": 50000,
  "defaultPerGoalEnabled": false, "defaultCostPerGoal": 50000,
  "mergeCompleted": false, "mode": "league", "groupCount": 1,
  "advanceCount": 2, "knockoutSeeding": [], "group": { /* Group */ } }

// Match  (homeTeam/awayTeam embedded as User or null)
{ "id": "m1", "leagueId": "l1", "homeTeamId": "a", "awayTeamId": "b",
  "homeScore": 0, "awayScore": 0, "date": "…", "isFinished": false,
  "matchCost": null, "costPerGoal": null, "updatedAt": "…" | null,
  "phase": null | "group" | "knockout", "groupId": null | "A",
  "knockoutRound": null, "knockoutSlot": null, "nextMatchId": null,
  "matchday": 1, "homeTeam": { /* User */ }, "awayTeam": null }

// Stat (standings row; numbers computed from finished non-knockout matches)
{ "id": "s1", "userId": "a", "leagueId": "l1", "groupId": null | "A",
  "matchesPlayed": 0, "goals": 0, "goalsConceded": 0,
  "wins": 0, "draws": 0, "losses": 0, "user": { /* User */ } }

// UserStatsSummary — same keys as GNUserStatsSummary.toMap(), dates as ISO
// strings, plus "userId". recentMatches / leagueHistory / h2hSummary arrays
// use the GNUserRecentMatch / GNUserLeaguePerformance / GNUserOpponentStat keys.

// UserH2H — GNUserH2H.toMap() keys plus "userId".

// GroupStatsSummary — GNEsportGroupStatsSummary keys:
{ "groupId": "g1", "totalLeagues": 3, "finishedLeagues": 2,
  "playerStats": [ /* GNEsportGroupPlayerEntry.toJson() keys */ ],
  "updatedAt": "…", "schemaVersion": 1 }

// LeaguesPage
{ "items": [ /* League */ ], "nextCursor": "opaque" | null, "hasMore": true }
```

### Users

| Method | Path | Body / query | Response |
|---|---|---|---|
| POST | `/v1/me/bootstrap` | `{displayName?, email?, phoneNumber?, photoUrl?}` | `User` — creates the row on first sign-in (createUserIfNeeded); existing rows are returned unchanged |
| GET | `/v1/me` | | `User` (404 if never bootstrapped) |
| PATCH | `/v1/me` | `{displayName?, phoneNumber?, email?}` — empty strings ignored | `User` |
| DELETE | `/v1/me` | | 204 — soft delete (`deleted`, `deletedAt`, email/phone cleared). Client then deletes the Firebase user |
| PUT | `/v1/me/avatar` | multipart field `file` (≤ 5 MB image) | `User` |
| DELETE | `/v1/me/avatar` | | `User` |
| GET | `/v1/users/:id` | | `User` / 404 |
| POST | `/v1/users/batch` | `{ids: string[]}` | `{users: User[]}` (missing ids omitted) |
| GET | `/v1/users/search` | `q`, optional `groupId` | `User[]` — case-insensitive prefix on displayName/email/phone. With `groupId`: caller must be a member (403); only active members returned |
| POST | `/v1/users/placeholders` | `{displayName}` | `User` (id `placeholder_<id>`, `isPlaceholder: true`) |
| GET | `/v1/users/:id/summary` | | `UserStatsSummary` (always present; zeros when no data) |
| GET | `/v1/users/:id/h2h/:opponentId` | | `UserH2H` or 404 when they never met |

### Groups

| Method | Path | Body / query | Response |
|---|---|---|---|
| GET | `/v1/groups` | optional `ownerId` | `Group[]` with status `active` |
| POST | `/v1/groups` | `{groupName, description?}` | `Group` (caller is owner + first member) |
| GET | `/v1/groups/:id` | | `Group` / 404 |
| GET | `/v1/groups/:id/members` | | `User[]` in join order |
| POST | `/v1/groups/:id/members` | `{userId}` | 204 — caller must be a member |
| DELETE | `/v1/groups/:id/members/:userId` | | 204 — owner removes anyone, member removes self |
| PUT | `/v1/groups/:id/members/:userId/deactivation` | `{deactivated: bool}` | 204 — owner only |
| POST | `/v1/groups/:id/transfer-ownership` | `{newOwnerId}` | 204 — owner only, target must be a member |
| POST | `/v1/groups/:id/deactivate` | | 204 — owner only, status → `inactive` |
| DELETE | `/v1/groups/:id` | | 204 — owner only, hard cascade (leagues, matches, standings) |
| GET | `/v1/groups/:id/leagues` | | `League[]` active, newest first |
| GET | `/v1/groups/:id/summary` | | `GroupStatsSummary` |

### Leagues

| Method | Path | Body / query | Response |
|---|---|---|---|
| GET | `/v1/leagues` | `scope=mine\|managed\|others`, `cursor?`, `limit?` (default 20) | `LeaguesPage` — active only, `startDate` desc. `mine` = caller in participants; `managed` = caller is owner; `others` = neither |
| GET | `/v1/leagues` | `ownerId=<uid>` | `League[]` active, by owner |
| GET | `/v1/leagues` | `groupIds=a,b` | `League[]` active, in those groups |
| POST | `/v1/leagues` | addLeague fields (`name, groupId, startDate?, endDate?, description?, rankPayoutEnabled?, rankPayouts?, defaultMatchCost?, defaultPerGoalEnabled?, defaultCostPerGoal?, status?, mode?, groupCount?, advanceCount?, participants?, knockoutSeeding?`) | `{id}` — caller must be a member of the group |
| GET | `/v1/leagues/:id` | | `League` / 404 |
| PATCH | `/v1/leagues/:id` | any League field except `id, ownerId, groupId, group` | `League` |
| POST | `/v1/leagues/:id/deactivate` | | 204 (`isActive: false`) |
| DELETE | `/v1/leagues/:id` | | 204 hard delete |
| POST | `/v1/leagues/:id/transfer-ownership` | `{newOwnerId}` | 204 |
| POST | `/v1/leagues/:id/participants` | `{userIds}` | 204 — appends new ids, creates league-wide standings rows |
| POST | `/v1/leagues/:id/replace-participant` | `{oldUserId, newUserId}` | 204 — rewrites matches + standings rows atomically |
| PUT | `/v1/leagues/:id/merge-completed` | `{completed}` | 204 |
| POST | `/v1/leagues/:id/rounds` | `{teamIds}` | 204 — one round-robin leg, continuous matchdays |
| POST | `/v1/leagues/:id/group-rounds` | `{groupId, teamIds}` | 204 |
| POST | `/v1/leagues/:id/cup-bracket` | `{seededTeamIds}` | 204 / 400 if not a power of two |
| POST | `/v1/leagues/:id/full-tournament` | `{groups: string[][], advanceCount, knockoutSeeding?}` | 204 / 400 |
| GET | `/v1/leagues/:id/matches` | | `Match[]` |
| POST | `/v1/leagues/:id/matches` | Match fields without `id`/`updatedAt` | `Match` (custom match) |
| PATCH | `/v1/leagues/:id/matches/:matchId` | `{homeScore?, awayScore?, matchCost?, costPerGoal?, expectedUpdatedAt: string\|null}` | `Match` / 409 `concurrent_update` |
| DELETE | `/v1/leagues/:id/matches/:matchId` | | 204 (idempotent) |
| GET | `/v1/leagues/:id/stats` | | `Stat[]` |
| POST | `/v1/leagues/:id/stats/recompute` | | 204 — rebuilds standings rows (same rules as the old `recomputeLeagueStats`) |
| GET | `/v1/leagues/:id/events` | SSE | `event: snapshot` `data: {league: League\|null, matches: Match[], stats: Stat[]}` on connect and after every change; `: ping` comment every 25 s |

All league mutations require the caller to be a member of the league's group
(or `role == "admin"`). Reads require only a signed-in user, as before.

## Semantics carried over from Firestore / Cloud Functions

- Match update: scores set ⇒ `isFinished = true`; knockout winner (home wins
  ties) is written into `nextMatchId`'s home slot for even `knockoutSlot`,
  away slot for odd; participants changing mid-edit ⇒ 409 `conflict`.
- Standings rows: league/cup ⇒ one row per user (`groupId` null); full mode ⇒
  one row per (user, group). Only finished, non-knockout matches count, and a
  match counts for the row whose `groupId` equals the match's `groupId`.
- Ranking for champion / runner-up: points (3/1/0), then goal difference, then
  goals; ties keep row-id order.
- User summary: active leagues the user participates in; every finished match
  (including knockout) involving the user; `recentMatches` capped at 20 by
  date desc; `leagueHistory` capped at 20 by `lastPlayedAt` desc;
  champion / runner-up / `tournamentsFinished` from finished leagues.
- Group summary: active leagues of the group, excluding any league with a
  deactivated participant; finished matches with both sides set; champion /
  runner-up / `finishedLeaguesJoined` from finished leagues; rows with no
  contribution are dropped.
