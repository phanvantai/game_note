import type { Queryable } from "../db.js";
import { newId } from "../ids.js";
import {
  findGroup,
  groupJson,
  leagueJson,
  matchJson,
  usersByIds,
  type LeagueRow,
  type MatchRow,
  type StatRow,
} from "../rows.js";
import type { NewMatch } from "./bracket.js";
import { foldStandings } from "./standings.js";

export async function findLeague(db: Queryable, id: string): Promise<LeagueRow | null> {
  const { rows } = await db.query<LeagueRow>("SELECT * FROM leagues WHERE id = $1", [id]);
  return rows[0] ?? null;
}

export async function leagueWithGroup(db: Queryable, league: LeagueRow) {
  const group = await findGroup(db, league.group_id);
  return leagueJson(league, group ? groupJson(group) : null);
}

export async function listMatches(db: Queryable, leagueId: string) {
  const { rows } = await db.query<MatchRow>("SELECT * FROM matches WHERE league_id = $1 ORDER BY id", [leagueId]);
  const users = await usersByIds(db, rows.flatMap((m) => [m.home_team_id, m.away_team_id]));
  return rows.map((m) => matchJson(m, users));
}

export async function listStats(db: Queryable, leagueId: string) {
  const [{ rows }, { rows: matches }] = await Promise.all([
    db.query<StatRow>("SELECT * FROM league_stat_rows WHERE league_id = $1 ORDER BY id", [leagueId]),
    db.query<MatchRow>("SELECT * FROM matches WHERE league_id = $1 AND is_finished", [leagueId]),
  ]);
  const users = await usersByIds(db, rows.map((r) => r.user_id));
  return foldStandings(rows, matches).map((s) => ({
    id: s.row.id,
    userId: s.row.user_id,
    leagueId: s.row.league_id,
    groupId: s.row.group_label,
    matchesPlayed: s.matchesPlayed,
    goals: s.goals,
    goalsConceded: s.goalsConceded,
    wins: s.wins,
    draws: s.draws,
    losses: s.losses,
    user: users.get(s.row.user_id) ?? null,
  }));
}

/** Everything a tournament screen shows; pushed over SSE on every change. */
export async function leagueSnapshot(db: Queryable, leagueId: string) {
  const league = await findLeague(db, leagueId);
  if (!league) return { league: null, matches: [], stats: [] };
  const [leagueOut, matches, stats] = await Promise.all([
    leagueWithGroup(db, league),
    listMatches(db, leagueId),
    listStats(db, leagueId),
  ]);
  return { league: leagueOut, matches, stats };
}

/** Creates the standings rows that don't exist yet. */
export async function ensureStatRows(
  db: Queryable,
  leagueId: string,
  rows: { userId: string; groupLabel: string | null }[],
): Promise<void> {
  const valid = rows.filter((r) => r.userId);
  if (valid.length === 0) return;
  await db.query(
    `INSERT INTO league_stat_rows (id, league_id, user_id, group_label)
     SELECT * FROM unnest($1::text[], $2::text[], $3::text[], $4::text[])
     ON CONFLICT DO NOTHING`,
    [valid.map(() => newId()), valid.map(() => leagueId), valid.map((r) => r.userId), valid.map((r) => r.groupLabel)],
  );
}

/** Bulk-inserts generated fixtures with 0-0 scores, unfinished. */
export async function insertMatches(db: Queryable, leagueId: string, matches: NewMatch[]): Promise<void> {
  if (matches.length === 0) return;
  const col = <K extends keyof NewMatch>(k: K) => matches.map((m) => m[k]);
  await db.query(
    `INSERT INTO matches (id, league_id, home_team_id, away_team_id, home_score, away_score, date,
       is_finished, phase, group_label, knockout_round, knockout_slot, next_match_id, matchday)
     SELECT id, $2, home, away, 0, 0, now(), false, phase, grp, kr, ks, nxt, md
     FROM unnest($1::text[], $3::text[], $4::text[], $5::text[], $6::text[], $7::int[], $8::int[], $9::text[], $10::int[])
       AS t(id, home, away, phase, grp, kr, ks, nxt, md)`,
    [
      col("id"),
      leagueId,
      col("homeTeamId"),
      col("awayTeamId"),
      col("phase"),
      col("groupLabel"),
      col("knockoutRound"),
      col("knockoutSlot"),
      col("nextMatchId"),
      col("matchday"),
    ],
  );
}
