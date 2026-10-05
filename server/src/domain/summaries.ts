// User / head-to-head / group summaries, computed on read. These reproduce
// the "rebuild" paths of the old Cloud Functions (rebuildUserSummary and
// onRecomputeGroupSummaryRequest), which were the ground truth that the
// incremental triggers approximated.

import type { Queryable } from "../db.js";
import type { LeagueRow, MatchRow, StatRow, UserJson } from "../rows.js";
import { usersByIds } from "../rows.js";
import {
  addResult,
  foldStandings,
  isScored,
  rankStandings,
  zeroTotals,
  type Totals,
} from "./standings.js";

export const RECENT_MATCHES_CAP = 20;
export const LEAGUE_HISTORY_CAP = 20;
const SCHEMA_VERSION = 1;

const iso = (d: Date | null) => (d ? d.toISOString() : null);
const maxDate = (a: Date | null, b: Date | null) => (!a ? b : !b ? a : a >= b ? a : b);
const time = (d: Date | null) => (d ? d.getTime() : 0);

interface LeagueData {
  leagues: LeagueRow[];
  matchesByLeague: Map<string, MatchRow[]>;
  rowsByLeague: Map<string, StatRow[]>;
}

async function loadLeagueData(db: Queryable, leagues: LeagueRow[]): Promise<LeagueData> {
  const ids = leagues.map((l) => l.id);
  const [matches, rows] = await Promise.all([
    db.query<MatchRow>(
      "SELECT * FROM matches WHERE league_id = ANY($1) AND is_finished ORDER BY league_id, id",
      [ids],
    ),
    db.query<StatRow>(
      "SELECT * FROM league_stat_rows WHERE league_id = ANY($1) ORDER BY id",
      [ids],
    ),
  ]);
  const group = <T extends { league_id: string }>(items: T[]) => {
    const map = new Map<string, T[]>();
    for (const item of items) {
      const list = map.get(item.league_id) ?? [];
      list.push(item);
      map.set(item.league_id, list);
    }
    return map;
  };
  return { leagues, matchesByLeague: group(matches.rows), rowsByLeague: group(rows.rows) };
}

/** Final ranking of a finished league: user ids, best first. */
function finalRanking(data: LeagueData, leagueId: string): string[] {
  const standings = foldStandings(
    data.rowsByLeague.get(leagueId) ?? [],
    data.matchesByLeague.get(leagueId) ?? [],
  );
  return rankStandings(standings).map((s) => s.row.user_id);
}

interface H2HAggregate extends Totals {
  opponentId: string;
  lastMetAt: Date | null;
}

async function activeLeaguesOf(db: Queryable, uid: string): Promise<LeagueRow[]> {
  const { rows } = await db.query<LeagueRow>(
    "SELECT * FROM leagues WHERE is_active AND $1 = ANY(participants) ORDER BY id",
    [uid],
  );
  return rows;
}

export async function userSummary(db: Queryable, uid: string) {
  const leagues = await activeLeaguesOf(db, uid);
  const data = await loadLeagueData(db, leagues);

  const totals = zeroTotals();
  let tournamentsFinished = 0;
  let championCount = 0;
  let runnerUpCount = 0;
  let lastChampionAt: Date | null = null;
  const recent: { m: MatchRow; league: LeagueRow }[] = [];
  const history: { league: LeagueRow; totals: Totals; lastPlayedAt: Date | null }[] = [];
  const h2h = new Map<string, H2HAggregate>();

  for (const league of leagues) {
    const perf = zeroTotals();
    let lastPlayedAt: Date | null = null;
    for (const m of data.matchesByLeague.get(league.id) ?? []) {
      if (!isScored(m)) continue;
      const isHome = m.home_team_id === uid;
      if (!isHome && m.away_team_id !== uid) continue;
      const [mine, theirs] = isHome ? [m.home_score, m.away_score] : [m.away_score, m.home_score];
      addResult(totals, mine, theirs);
      addResult(perf, mine, theirs);
      lastPlayedAt = maxDate(lastPlayedAt, m.date);
      recent.push({ m, league });

      const opponentId = isHome ? m.away_team_id : m.home_team_id;
      const agg = h2h.get(opponentId) ?? { opponentId, lastMetAt: null, ...zeroTotals() };
      addResult(agg, mine, theirs);
      agg.lastMetAt = maxDate(agg.lastMetAt, m.date);
      h2h.set(opponentId, agg);
    }
    if (perf.matchesPlayed > 0) history.push({ league, totals: perf, lastPlayedAt });

    if (league.status === "finished") {
      const rank = finalRanking(data, league.id).indexOf(uid);
      if (rank !== -1) {
        tournamentsFinished += 1;
        if (rank === 0) {
          championCount += 1;
          lastChampionAt = maxDate(lastChampionAt, league.end_date ?? league.start_date);
        } else if (rank === 1) {
          runnerUpCount += 1;
        }
      }
    }
  }

  const names = await usersByIds(db, h2h.keys());
  const nameOf = (id: string) => names.get(id)?.displayName ?? "";

  recent.sort((a, b) => time(b.m.date) - time(a.m.date));
  history.sort((a, b) => time(b.lastPlayedAt) - time(a.lastPlayedAt));

  return {
    userId: uid,
    ...totals,
    tournamentsJoined: leagues.length,
    tournamentsFinished,
    championCount,
    runnerUpCount,
    lastChampionAt: iso(lastChampionAt),
    recentMatches: recent.slice(0, RECENT_MATCHES_CAP).map(({ m, league }) => {
      const isHome = m.home_team_id === uid;
      const userScore = isHome ? m.home_score! : m.away_score!;
      const opponentScore = isHome ? m.away_score! : m.home_score!;
      const opponentId = isHome ? m.away_team_id : m.home_team_id;
      return {
        matchId: m.id,
        leagueId: league.id,
        leagueName: league.name,
        date: iso(m.date),
        userScore,
        opponentScore,
        opponentId,
        opponentDisplayName: nameOf(opponentId),
        result: userScore > opponentScore ? "win" : userScore < opponentScore ? "loss" : "draw",
        updatedAt: iso(m.updated_at ?? m.date),
      };
    }),
    leagueHistory: history.slice(0, LEAGUE_HISTORY_CAP).map(({ league, totals: t, lastPlayedAt }) => ({
      leagueId: league.id,
      leagueName: league.name,
      lastPlayedAt: iso(lastPlayedAt),
      ...t,
    })),
    h2hSummary: [...h2h.values()].map((agg) => ({
      opponentId: agg.opponentId,
      opponentDisplayName: nameOf(agg.opponentId),
      matchesPlayed: agg.matchesPlayed,
      wins: agg.wins,
      draws: agg.draws,
      losses: agg.losses,
    })),
    updatedAt: new Date().toISOString(),
    schemaVersion: SCHEMA_VERSION,
  };
}

/** Head-to-head of [uid] against [opponentId], or null if they never met. */
export async function userH2H(db: Queryable, uid: string, opponentId: string) {
  const leagues = await activeLeaguesOf(db, uid);
  if (leagues.length === 0) return null;
  const { rows } = await db.query<MatchRow>(
    `SELECT * FROM matches
     WHERE league_id = ANY($1) AND is_finished
       AND ((home_team_id = $2 AND away_team_id = $3) OR (home_team_id = $3 AND away_team_id = $2))`,
    [leagues.map((l) => l.id), uid, opponentId],
  );
  const totals = zeroTotals();
  let lastMetAt: Date | null = null;
  for (const m of rows) {
    if (!isScored(m)) continue;
    const isHome = m.home_team_id === uid;
    addResult(totals, isHome ? m.home_score : m.away_score, isHome ? m.away_score : m.home_score);
    lastMetAt = maxDate(lastMetAt, m.date);
  }
  if (totals.matchesPlayed === 0) return null;
  const names = await usersByIds(db, [opponentId]);
  return {
    userId: uid,
    opponentId,
    opponentDisplayName: names.get(opponentId)?.displayName ?? "",
    ...totals,
    lastMetAt: iso(lastMetAt),
    updatedAt: new Date().toISOString(),
  };
}

interface PlayerEntry {
  userId: string;
  matches: number;
  wins: number;
  draws: number;
  losses: number;
  goals: number;
  goalsConceded: number;
  championships: number;
  runnerUps: number;
  finishedLeaguesJoined: number;
}

export async function groupSummary(db: Queryable, groupId: string) {
  const [{ rows: leagues }, { rows: deactivated }] = await Promise.all([
    db.query<LeagueRow>("SELECT * FROM leagues WHERE group_id = $1 AND is_active ORDER BY id", [groupId]),
    db.query<{ user_id: string }>(
      "SELECT user_id FROM group_members WHERE group_id = $1 AND deactivated",
      [groupId],
    ),
  ]);
  const deactivatedIds = new Set(deactivated.map((r) => r.user_id));
  // A league with any deactivated participant is excluded entirely.
  const counted = leagues.filter((l) => !l.participants.some((p) => deactivatedIds.has(p)));
  const data = await loadLeagueData(db, counted);

  const players = new Map<string, PlayerEntry>();
  const entry = (userId: string) => {
    let e = players.get(userId);
    if (!e) {
      e = {
        userId,
        matches: 0, wins: 0, draws: 0, losses: 0, goals: 0, goalsConceded: 0,
        championships: 0, runnerUps: 0, finishedLeaguesJoined: 0,
      };
      players.set(userId, e);
    }
    return e;
  };
  const apply = (e: PlayerEntry, scoredFor: number, scoredAgainst: number) => {
    const t = zeroTotals();
    addResult(t, scoredFor, scoredAgainst);
    e.matches += 1;
    e.wins += t.wins;
    e.draws += t.draws;
    e.losses += t.losses;
    e.goals += t.goals;
    e.goalsConceded += t.goalsConceded;
  };

  let finishedLeagues = 0;
  for (const league of counted) {
    for (const m of data.matchesByLeague.get(league.id) ?? []) {
      if (!isScored(m) || !m.home_team_id || !m.away_team_id) continue;
      apply(entry(m.home_team_id), m.home_score, m.away_score);
      apply(entry(m.away_team_id), m.away_score, m.home_score);
    }
    if (league.status === "finished") {
      finishedLeagues += 1;
      finalRanking(data, league.id).forEach((uid, i) => {
        const e = entry(uid);
        e.finishedLeaguesJoined += 1;
        if (i === 0) e.championships += 1;
        if (i === 1) e.runnerUps += 1;
      });
    }
  }

  const kept = [...players.values()].filter(
    (e) => e.matches > 0 || e.championships > 0 || e.runnerUps > 0 || e.finishedLeaguesJoined > 0,
  );
  const users = await usersByIds(db, kept.map((e) => e.userId));
  const info = (id: string): Pick<UserJson, "displayName" | "photoUrl"> =>
    users.get(id) ?? { displayName: "", photoUrl: null };

  return {
    groupId,
    totalLeagues: counted.length,
    finishedLeagues,
    playerStats: kept.map((e) => ({
      userId: e.userId,
      displayName: info(e.userId).displayName ?? "",
      photoUrl: info(e.userId).photoUrl,
      matches: e.matches,
      wins: e.wins,
      draws: e.draws,
      losses: e.losses,
      goals: e.goals,
      goalsConceded: e.goalsConceded,
      championships: e.championships,
      runnerUps: e.runnerUps,
      finishedLeaguesJoined: e.finishedLeaguesJoined,
    })),
    updatedAt: new Date().toISOString(),
    schemaVersion: SCHEMA_VERSION,
  };
}
