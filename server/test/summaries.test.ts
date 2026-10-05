import { describe, expect, it } from "vitest";
import { between, call, ok, score, seedGroup, seedLeague, seedUser, useTestApp } from "./helpers.js";

const ctx = useTestApp();

/** a beats b 2-0, a draws c 1-1, c beats b 2-1 → a champion (GD +2), c runner-up (GD +1). */
async function finishedLeague(groupId: string, name = "S1", startDate = "2026-01-01T00:00:00.000Z") {
  const id = await seedLeague(ctx, "a", groupId, { name, participants: ["a", "b", "c"], startDate });
  await ok(ctx, "a", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b", "c"] });
  const ms = await ok(ctx, "a", "GET", `/v1/leagues/${id}/matches`);
  const play = async (x: string, y: string, gx: number, gy: number) => {
    const m = between(ms, x, y);
    const [h, aw] = m.homeTeamId === x ? [gx, gy] : [gy, gx];
    await score(ctx, "a", id, m.id, h, aw);
  };
  await play("a", "b", 2, 0);
  await play("a", "c", 1, 1);
  await play("c", "b", 2, 1);
  await ok(ctx, "a", "PATCH", `/v1/leagues/${id}`, { status: "finished", endDate: "2026-02-01T00:00:00.000Z" });
  return id;
}

async function setup() {
  for (const u of ["a", "b", "c"]) await seedUser(ctx, u, u.toUpperCase());
  return seedGroup(ctx, "a", ["b", "c"]);
}

describe("user summary", () => {
  it("is all zeros for a new user", async () => {
    await seedUser(ctx, "a");
    expect(await ok(ctx, "a", "GET", "/v1/users/a/summary")).toMatchObject({
      userId: "a", matchesPlayed: 0, tournamentsJoined: 0, championCount: 0,
      recentMatches: [], leagueHistory: [], h2hSummary: [], lastChampionAt: null, schemaVersion: 1,
    });
  });

  it("totals, champion, history, recent matches and h2h list", async () => {
    const g = await setup();
    const l = await finishedLeague(g);
    const s = await ok(ctx, "a", "GET", "/v1/users/a/summary");
    expect(s).toMatchObject({
      matchesPlayed: 2, wins: 1, draws: 1, losses: 0, goals: 3, goalsConceded: 1,
      tournamentsJoined: 1, tournamentsFinished: 1, championCount: 1, runnerUpCount: 0,
      lastChampionAt: "2026-02-01T00:00:00.000Z",
    });
    expect(s.leagueHistory).toEqual([
      expect.objectContaining({ leagueId: l, leagueName: "S1", matchesPlayed: 2, wins: 1, draws: 1 }),
    ]);
    expect(s.recentMatches).toHaveLength(2);
    expect(s.recentMatches.find((r: any) => r.opponentId === "b")).toMatchObject({
      leagueId: l, userScore: 2, opponentScore: 0, result: "win", opponentDisplayName: "B",
    });
    expect(s.h2hSummary.map((h: any) => h.opponentId).sort()).toEqual(["b", "c"]);

    const c = await ok(ctx, "a", "GET", "/v1/users/c/summary");
    expect(c).toMatchObject({ runnerUpCount: 1, championCount: 0, tournamentsFinished: 1 });
  });

  it("ignores inactive leagues and leagues the user is not a participant of", async () => {
    const g = await setup();
    const l = await finishedLeague(g);
    await ok(ctx, "a", "POST", `/v1/leagues/${l}/deactivate`);
    expect((await ok(ctx, "a", "GET", "/v1/users/a/summary")).matchesPlayed).toBe(0);
  });

  it("includes knockout results", async () => {
    const g = await setup();
    const l = await seedLeague(ctx, "a", g, { mode: "cup", participants: ["a", "b"] });
    await ok(ctx, "a", "POST", `/v1/leagues/${l}/cup-bracket`, { seededTeamIds: ["a", "b"] });
    const [m] = await ok(ctx, "a", "GET", `/v1/leagues/${l}/matches`);
    await score(ctx, "a", l, m.id, 1, 0);
    expect((await ok(ctx, "a", "GET", "/v1/users/a/summary")).wins).toBe(1);
  });

  it("caps recent matches at 20, newest first", async () => {
    const g = await setup();
    const l = await seedLeague(ctx, "a", g, { participants: ["a", "b"] });
    for (let i = 0; i < 22; i++) {
      await ok(ctx, "a", "POST", `/v1/leagues/${l}/matches`, {
        homeTeamId: "a", awayTeamId: "b", homeScore: i, awayScore: 0, isFinished: true,
        date: new Date(Date.UTC(2026, 0, 1 + i)).toISOString(),
      });
    }
    const s = await ok(ctx, "a", "GET", "/v1/users/a/summary");
    expect(s.matchesPlayed).toBe(22);
    expect(s.recentMatches).toHaveLength(20);
    expect(s.recentMatches[0].userScore).toBe(21);
  });
});

describe("h2h", () => {
  it("returns the record against one opponent, 404 if they never met", async () => {
    const g = await setup();
    await finishedLeague(g);
    expect(await ok(ctx, "b", "GET", "/v1/users/b/h2h/c")).toMatchObject({
      userId: "b", opponentId: "c", opponentDisplayName: "C", matchesPlayed: 1, losses: 1, goals: 1, goalsConceded: 2,
    });
    await seedUser(ctx, "z");
    expect((await call(ctx, "a", "GET", "/v1/users/a/h2h/z")).status).toBe(404);
    expect((await call(ctx, "z", "GET", "/v1/users/z/h2h/a")).status).toBe(404);
  });
});

describe("group summary", () => {
  it("aggregates players across active leagues with titles", async () => {
    const g = await setup();
    await finishedLeague(g);
    const s = await ok(ctx, "a", "GET", `/v1/groups/${g}/summary`);
    expect(s).toMatchObject({ groupId: g, totalLeagues: 1, finishedLeagues: 1, schemaVersion: 1 });
    const a = s.playerStats.find((p: any) => p.userId === "a");
    expect(a).toMatchObject({ displayName: "A", matches: 2, wins: 1, championships: 1, finishedLeaguesJoined: 1 });
    expect(s.playerStats.find((p: any) => p.userId === "c")).toMatchObject({ runnerUps: 1 });
  });

  it("excludes leagues with a deactivated participant", async () => {
    const g = await setup();
    await finishedLeague(g);
    await ok(ctx, "a", "PUT", `/v1/groups/${g}/members/b/deactivation`, { deactivated: true });
    expect(await ok(ctx, "a", "GET", `/v1/groups/${g}/summary`)).toMatchObject({ totalLeagues: 0, playerStats: [] });
  });

  it("404s for unknown groups", async () => {
    await seedUser(ctx, "a");
    expect((await call(ctx, "a", "GET", "/v1/groups/nope/summary")).status).toBe(404);
  });
});
