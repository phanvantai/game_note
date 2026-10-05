import type { MatchRow, StatRow } from "../rows.js";

export interface Totals {
  matchesPlayed: number;
  goals: number;
  goalsConceded: number;
  wins: number;
  draws: number;
  losses: number;
}

export const zeroTotals = (): Totals => ({
  matchesPlayed: 0,
  goals: 0,
  goalsConceded: 0,
  wins: 0,
  draws: 0,
  losses: 0,
});

/** Adds one result, seen from the side that scored [scoredFor]. */
export function addResult(t: Totals, scoredFor: number, scoredAgainst: number): void {
  t.matchesPlayed += 1;
  t.goals += scoredFor;
  t.goalsConceded += scoredAgainst;
  if (scoredFor > scoredAgainst) t.wins += 1;
  else if (scoredFor === scoredAgainst) t.draws += 1;
  else t.losses += 1;
}

/** A finished match with both scores. Knockout matches included. */
export function isScored(m: MatchRow): m is MatchRow & { home_score: number; away_score: number } {
  return m.is_finished && m.home_score !== null && m.away_score !== null;
}

export interface Standing extends Totals {
  row: StatRow;
}

/**
 * Folds finished, non-knockout matches into each standings row. A match
 * counts for the row whose group equals the match's group (null for
 * league-wide play), exactly like the old per-match stat updates.
 */
export function foldStandings(rows: StatRow[], matches: MatchRow[]): Standing[] {
  const key = (userId: string, group: string | null) => `${userId}\u0000${group ?? ""}`;
  const byKey = new Map<string, Standing>();
  const standings = rows.map((row) => {
    const s: Standing = { row, ...zeroTotals() };
    byKey.set(key(row.user_id, row.group_label), s);
    return s;
  });
  for (const m of matches) {
    if (!isScored(m) || m.phase === "knockout") continue;
    const home = byKey.get(key(m.home_team_id, m.group_label));
    const away = byKey.get(key(m.away_team_id, m.group_label));
    if (home) addResult(home, m.home_score, m.away_score);
    if (away) addResult(away, m.away_score, m.home_score);
  }
  return standings;
}

/**
 * Champion ordering used by the old Cloud Functions: points, then goal
 * difference, then goals. Array.sort is stable, so ties keep input order.
 */
export function rankStandings<T extends Totals>(standings: T[]): T[] {
  const points = (t: Totals) => t.wins * 3 + t.draws;
  return [...standings].sort(
    (a, b) =>
      points(b) - points(a) ||
      b.goals - b.goalsConceded - (a.goals - a.goalsConceded) ||
      b.goals - a.goals,
  );
}
