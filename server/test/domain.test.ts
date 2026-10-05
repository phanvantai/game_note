import { describe, expect, it } from "vitest";
import { groupStageMatches, isPowerOfTwo, knockoutMatches } from "../src/domain/bracket.js";
import { buildRoundRobinSchedule, type Pairing } from "../src/domain/scheduler.js";
import { foldStandings, rankStandings, zeroTotals } from "../src/domain/standings.js";
import type { MatchRow, StatRow } from "../src/rows.js";

const ids = (n: number) => Array.from({ length: n }, (_, i) => `u${i + 1}`);
const byMatchday = (s: Pairing[]) => {
  const map = new Map<number, Pairing[]>();
  for (const p of s) map.set(p.matchday, [...(map.get(p.matchday) ?? []), p]);
  return map;
};

describe("buildRoundRobinSchedule", () => {
  it("6 players → 5 matchdays of 3", () => {
    const s = buildRoundRobinSchedule(ids(6), []);
    expect(s).toHaveLength(15);
    const days = byMatchday(s);
    expect([...days.keys()].sort()).toEqual([1, 2, 3, 4, 5]);
    for (const day of days.values()) expect(day).toHaveLength(3);
  });

  it("every pair meets exactly once and nobody plays twice a matchday", () => {
    const s = buildRoundRobinSchedule(ids(6), []);
    expect(new Set(s.map((p) => [p.homeId, p.awayId].sort().join("|"))).size).toBe(15);
    for (const day of byMatchday(s).values()) {
      const players = day.flatMap((p) => [p.homeId, p.awayId]);
      expect(new Set(players).size).toBe(players.length);
    }
  });

  it("5 players → 5 matchdays with one resting", () => {
    const s = buildRoundRobinSchedule(ids(5), []);
    expect(s).toHaveLength(10);
    for (const day of byMatchday(s).values()) expect(day).toHaveLength(2);
  });

  it("second leg mirrors home/away, third leg restores the first", () => {
    const first = buildRoundRobinSchedule(ids(4), []);
    const asFixtures = (s: Pairing[]) => s.map((p) => ({ homeId: p.homeId, awayId: p.awayId }));
    const second = buildRoundRobinSchedule(ids(4), asFixtures(first));
    const third = buildRoundRobinSchedule(ids(4), [...asFixtures(first), ...asFixtures(second)]);
    const key = (p: Pairing) => `${p.homeId}>${p.awayId}`;
    const firstHomes = new Set(first.map(key));
    for (const p of second) expect(firstHomes.has(`${p.awayId}>${p.homeId}`)).toBe(true);
    expect(new Set(third.map(key))).toEqual(firstHomes);
  });

  it("only the pair's own history decides its orientation", () => {
    const s = buildRoundRobinSchedule(["u1", "u2"], [{ homeId: "u1", awayId: "u3" }]);
    expect(s).toEqual([{ homeId: "u1", awayId: "u2", matchday: 1 }]);
  });

  it("drops duplicate and empty ids; < 2 teams → []", () => {
    expect(buildRoundRobinSchedule(["u1", "u1", "", "u2"], [])).toHaveLength(1);
    expect(buildRoundRobinSchedule(["u1"], [])).toEqual([]);
    expect(buildRoundRobinSchedule([], [])).toEqual([]);
  });
});

describe("brackets", () => {
  it("isPowerOfTwo", () => {
    expect([1, 2, 3, 4, 6, 8, 16].map(isPowerOfTwo)).toEqual([false, true, false, true, false, true, true]);
  });

  it("knockout skeleton links rounds and seeds round 0 as s vs n-1-s", () => {
    const ms = knockoutMatches(4, ["a", "b", "c", "d"]);
    expect(ms).toHaveLength(3);
    const [r0s0, r0s1, final] = ms;
    expect([r0s0!.homeTeamId, r0s0!.awayTeamId]).toEqual(["a", "d"]);
    expect([r0s1!.homeTeamId, r0s1!.awayTeamId]).toEqual(["b", "c"]);
    expect(r0s0!.nextMatchId).toBe(final!.id);
    expect(r0s1!.nextMatchId).toBe(final!.id);
    expect(final).toMatchObject({ knockoutRound: 1, knockoutSlot: 0, nextMatchId: null, homeTeamId: "" });
  });

  it("unseeded knockout starts empty", () => {
    expect(knockoutMatches(2, null)[0]).toMatchObject({ homeTeamId: "", awayTeamId: "", phase: "knockout" });
  });

  it("group stage pairs everyone once with the group label", () => {
    const ms = groupStageMatches("B", ["a", "b", "c"]);
    expect(ms.map((m) => `${m.homeTeamId}${m.awayTeamId}`)).toEqual(["ab", "ac", "bc"]);
    expect(ms.every((m) => m.phase === "group" && m.groupLabel === "B")).toBe(true);
  });
});

const row = (id: string, user: string, group: string | null = null): StatRow => ({
  id, league_id: "l", user_id: user, group_label: group,
});
const match = (home: string, away: string, hs: number | null, as: number | null, extra: Partial<MatchRow> = {}): MatchRow => ({
  id: `${home}-${away}`, league_id: "l", home_team_id: home, away_team_id: away,
  home_score: hs, away_score: as, date: new Date(0), is_finished: true, match_cost: null,
  cost_per_goal: null, phase: null, group_label: null, knockout_round: null, knockout_slot: null,
  next_match_id: null, matchday: null, updated_at: null, ...extra,
});

describe("standings", () => {
  it("folds finished non-knockout matches into the matching group row", () => {
    const s = foldStandings(
      [row("1", "a"), row("2", "b"), row("3", "a", "A")],
      [
        match("a", "b", 2, 1),
        match("b", "a", 1, 1),
        match("a", "b", 3, 0, { phase: "knockout" }),
        match("a", "b", 5, 0, { is_finished: false }),
        match("a", "x", 1, 0, { phase: "group", group_label: "A" }),
      ],
    );
    expect(s.map(({ row: _r, ...t }) => t)).toEqual([
      { matchesPlayed: 2, goals: 3, goalsConceded: 2, wins: 1, draws: 1, losses: 0 },
      { matchesPlayed: 2, goals: 2, goalsConceded: 3, wins: 0, draws: 1, losses: 1 },
      { matchesPlayed: 1, goals: 1, goalsConceded: 0, wins: 1, draws: 0, losses: 0 },
    ]);
  });

  it("ranks by points, goal difference, goals, then input order", () => {
    const t = (id: string, wins: number, draws: number, goals: number, against: number) => ({
      id, ...zeroTotals(), wins, draws, goals, goalsConceded: against,
    });
    const ranked = rankStandings([t("a", 1, 0, 1, 0), t("b", 1, 0, 3, 0), t("c", 1, 0, 4, 1), t("d", 1, 0, 1, 0), t("e", 2, 0, 0, 0)]);
    expect(ranked.map((x) => x.id)).toEqual(["e", "c", "b", "a", "d"]);
  });
});
