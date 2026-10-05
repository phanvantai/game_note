import { describe, expect, it } from "vitest";
import { between, call, ok, score, seedGroup, seedLeague, seedUser, useTestApp } from "./helpers.js";

const ctx = useTestApp();

async function leagueWithRound(players = ["a", "b"]) {
  await seedUser(ctx, "o");
  for (const p of players) await seedUser(ctx, p);
  const g = await seedGroup(ctx, "o", players);
  const id = await seedLeague(ctx, "o", g, { participants: players });
  await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: players });
  return { g, id, matches: await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`) };
}

describe("score updates", () => {
  it("finishes the match, bumps the version and updates standings", async () => {
    const { id, matches } = await leagueWithRound();
    const m = matches[0];
    const saved = await ok(ctx, "a", "PATCH", `/v1/leagues/${id}/matches/${m.id}`, {
      homeScore: 3, awayScore: 1, matchCost: 20000, expectedUpdatedAt: null,
    });
    expect(saved).toMatchObject({ homeScore: 3, awayScore: 1, isFinished: true, matchCost: 20000, costPerGoal: null });
    expect(saved.updatedAt).toMatch(/\.\d{3}Z$/);
    const stats = await ok(ctx, "a", "GET", `/v1/leagues/${id}/stats`);
    const home = stats.find((s: any) => s.userId === m.homeTeamId);
    const away = stats.find((s: any) => s.userId === m.awayTeamId);
    expect(home).toMatchObject({ matchesPlayed: 1, wins: 1, goals: 3, goalsConceded: 1 });
    expect(away).toMatchObject({ matchesPlayed: 1, losses: 1, goals: 1, goalsConceded: 3 });

    // Editing the score replaces the old result instead of adding to it.
    await ok(ctx, "a", "PATCH", `/v1/leagues/${id}/matches/${m.id}`, {
      homeScore: 1, awayScore: 1, expectedUpdatedAt: saved.updatedAt,
    });
    const after = await ok(ctx, "a", "GET", `/v1/leagues/${id}/stats`);
    expect(after.find((s: any) => s.userId === m.homeTeamId)).toMatchObject({ matchesPlayed: 1, draws: 1, wins: 0 });
    expect((await ok(ctx, "a", "GET", `/v1/leagues/${id}/matches`))[0].matchCost).toBe(20000);
  });

  it("rejects a stale version with 409 concurrent_update and writes nothing", async () => {
    const { id, matches } = await leagueWithRound();
    const m = matches[0];
    await score(ctx, "a", id, m.id, 1, 0);
    const res = await call(ctx, "b", "PATCH", `/v1/leagues/${id}/matches/${m.id}`, {
      homeScore: 0, awayScore: 5, expectedUpdatedAt: null,
    });
    expect(res.status).toBe(409);
    expect(res.body.error).toBe("concurrent_update");
    expect((await ok(ctx, "a", "GET", `/v1/leagues/${id}/matches`))[0]).toMatchObject({ homeScore: 1, awayScore: 0 });
  });

  it("two simultaneous saves with the same version: exactly one wins", async () => {
    const { id, matches } = await leagueWithRound();
    const m = matches[0];
    const results = await Promise.all(
      [[1, 0], [0, 1]].map(([h, a]) =>
        call(ctx, "a", "PATCH", `/v1/leagues/${id}/matches/${m.id}`, { homeScore: h, awayScore: a, expectedUpdatedAt: null }),
      ),
    );
    expect(results.map((r) => r.status).sort()).toEqual([200, 409]);
  });

  it("rapid sequential saves get strictly increasing versions", async () => {
    const { id, matches } = await leagueWithRound();
    let version: string | null = null;
    const seen = new Set<string>();
    for (let i = 0; i < 5; i++) {
      const saved: any = await ok(ctx, "a", "PATCH", `/v1/leagues/${id}/matches/${matches[0].id}`, {
        homeScore: i, awayScore: 0, expectedUpdatedAt: version,
      });
      expect(seen.has(saved.updatedAt)).toBe(false);
      seen.add(saved.updatedAt);
      version = saved.updatedAt;
    }
  });

  it("non-members cannot edit; unknown matches 404", async () => {
    const { id, matches } = await leagueWithRound();
    await seedUser(ctx, "x");
    expect((await call(ctx, "x", "PATCH", `/v1/leagues/${id}/matches/${matches[0].id}`, { homeScore: 1, awayScore: 0, expectedUpdatedAt: null })).status).toBe(403);
    expect((await call(ctx, "a", "PATCH", `/v1/leagues/${id}/matches/nope`, { homeScore: 1, awayScore: 0, expectedUpdatedAt: null })).status).toBe(404);
    expect((await call(ctx, "a", "PATCH", `/v1/leagues/${id}/matches/${matches[0].id}`, { homeScore: -1, awayScore: 0, expectedUpdatedAt: null })).status).toBe(400);
  });

  it("a scored match with a missing standings row creates it", async () => {
    const { id, matches } = await leagueWithRound();
    await ctx.db.query("DELETE FROM league_stat_rows WHERE league_id = $1", [id]);
    await score(ctx, "a", id, matches[0].id, 2, 2);
    const stats = await ok(ctx, "a", "GET", `/v1/leagues/${id}/stats`);
    expect(stats.map((s: any) => s.draws)).toEqual([1, 1]);
  });
});

describe("knockout progression", () => {
  it("winner fills the next slot: even slot → home, odd → away; home wins ties", async () => {
    await seedUser(ctx, "o");
    for (const p of ["a", "b", "c", "d"]) await seedUser(ctx, p);
    const g = await seedGroup(ctx, "o", ["a", "b", "c", "d"]);
    const id = await seedLeague(ctx, "o", g, { mode: "cup" });
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/cup-bracket`, { seededTeamIds: ["a", "b", "c", "d"] });
    const ms = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    const slot = (s: number) => ms.find((m: any) => m.knockoutRound === 0 && m.knockoutSlot === s);
    await score(ctx, "o", id, slot(0).id, 0, 2); // a vs d → d
    await score(ctx, "o", id, slot(1).id, 1, 1); // b vs c → b (tie → home)
    const final = (await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`)).find((m: any) => m.knockoutRound === 1);
    expect([final.homeTeamId, final.awayTeamId]).toEqual(["d", "b"]);
    expect(final.homeTeam.id).toBe("d");
    // Knockout results never touch standings.
    expect(await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`)).toEqual([]);
  });
});

describe("custom and deleted matches", () => {
  it("creates a custom match with a version", async () => {
    const { id } = await leagueWithRound();
    const m = await ok(ctx, "a", "POST", `/v1/leagues/${id}/matches`, {
      homeTeamId: "a", awayTeamId: "b", date: "2026-05-01T12:00:00.000Z", matchCost: 0,
    });
    expect(m).toMatchObject({ homeTeamId: "a", awayTeamId: "b", homeScore: 0, isFinished: false, matchCost: 0, date: "2026-05-01T12:00:00.000Z" });
    expect(m.updatedAt).not.toBeNull();
    expect(m.id).toMatch(/^[A-Za-z0-9]{20}$/);
  });

  it("deleting a finished match removes its result from standings; idempotent", async () => {
    const { id, matches } = await leagueWithRound();
    const m = between(matches, "a", "b");
    await score(ctx, "a", id, m.id, 4, 0);
    expect((await call(ctx, "a", "DELETE", `/v1/leagues/${id}/matches/${m.id}`)).status).toBe(204);
    expect((await call(ctx, "a", "DELETE", `/v1/leagues/${id}/matches/${m.id}`)).status).toBe(204);
    const stats = await ok(ctx, "a", "GET", `/v1/leagues/${id}/stats`);
    expect(stats.every((s: any) => s.matchesPlayed === 0)).toBe(true);
  });

  it("404s for unknown leagues", async () => {
    await seedUser(ctx, "a");
    expect((await call(ctx, "a", "GET", "/v1/leagues/nope/matches")).status).toBe(404);
    expect((await call(ctx, "a", "GET", "/v1/leagues/nope/stats")).status).toBe(404);
  });
});
