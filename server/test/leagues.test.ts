import { describe, expect, it } from "vitest";
import { between, call, ok, score, seedGroup, seedLeague, seedUser, useTestApp } from "./helpers.js";

const ctx = useTestApp();

async function setup(members = ["a", "b", "c", "d"]) {
  await seedUser(ctx, "o");
  for (const m of members) await seedUser(ctx, m);
  const g = await seedGroup(ctx, "o", members);
  return g;
}

describe("league CRUD", () => {
  it("creates with defaults and returns the group embedded", async () => {
    const g = await setup();
    const { id } = await ok(ctx, "o", "POST", "/v1/leagues", { name: "S1", groupId: g });
    const league = await ok(ctx, "a", "GET", `/v1/leagues/${id}`);
    expect(league).toMatchObject({
      id, ownerId: "o", groupId: g, name: "S1", isActive: true, status: "upcoming", participants: [],
      defaultMatchCost: 50000, defaultCostPerGoal: 50000, mode: "league", groupCount: 1, advanceCount: 2,
      knockoutSeeding: [], endDate: null, mergeCompleted: false, rankPayouts: [],
    });
    expect(league.group).toMatchObject({ id: g, groupName: "Friends" });
  });

  it("only group members can create or edit", async () => {
    const g = await setup();
    await seedUser(ctx, "x");
    expect((await call(ctx, "x", "POST", "/v1/leagues", { name: "S", groupId: g })).status).toBe(403);
    const id = await seedLeague(ctx, "o", g);
    expect((await call(ctx, "x", "PATCH", `/v1/leagues/${id}`, { name: "hack" })).status).toBe(403);
  });

  it("PATCH updates given fields only and ignores ownerId/groupId", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { description: "keep" });
    const updated = await ok(ctx, "a", "PATCH", `/v1/leagues/${id}`, {
      name: "New", status: "finished", endDate: "2026-03-01T00:00:00.000Z", participants: ["a", "b", "a"],
      rankPayouts: [10000, 5000], ownerId: "a", groupId: "other",
    });
    expect(updated).toMatchObject({
      name: "New", description: "keep", status: "finished", endDate: "2026-03-01T00:00:00.000Z",
      participants: ["a", "b"], rankPayouts: [10000, 5000], ownerId: "o", groupId: g,
    });
    expect((await call(ctx, "a", "PATCH", `/v1/leagues/${id}`, { mode: "bogus" })).status).toBe(400);
  });

  it("deactivate hides from lists; delete removes", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { participants: ["a"] });
    await ok(ctx, "a", "POST", `/v1/leagues/${id}/deactivate`);
    expect((await ok(ctx, "a", "GET", "/v1/leagues?scope=mine")).items).toEqual([]);
    expect((await ok(ctx, "a", "GET", `/v1/leagues/${id}`)).isActive).toBe(false);
    await ok(ctx, "a", "DELETE", `/v1/leagues/${id}`);
    expect((await call(ctx, "a", "GET", `/v1/leagues/${id}`)).status).toBe(404);
  });

  it("transfers ownership and toggles mergeCompleted", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g);
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/transfer-ownership`, { newOwnerId: "a" });
    await ok(ctx, "o", "PUT", `/v1/leagues/${id}/merge-completed`, { completed: true });
    expect(await ok(ctx, "o", "GET", `/v1/leagues/${id}`)).toMatchObject({ ownerId: "a", mergeCompleted: true });
  });
});

describe("league lists", () => {
  it("paginates mine/managed/others by startDate desc", async () => {
    const g = await setup();
    const ids: string[] = [];
    for (let i = 1; i <= 5; i++) {
      ids.push(await seedLeague(ctx, "o", g, { startDate: `2026-0${i}-01T00:00:00.000Z`, participants: ["a"] }));
    }
    const p1 = await ok(ctx, "a", "GET", "/v1/leagues?scope=mine&limit=2");
    expect(p1.items.map((l: any) => l.id)).toEqual([ids[4], ids[3]]);
    expect(p1.hasMore).toBe(true);
    const p2 = await ok(ctx, "a", "GET", `/v1/leagues?scope=mine&limit=2&cursor=${p1.nextCursor}`);
    expect(p2.items.map((l: any) => l.id)).toEqual([ids[2], ids[1]]);
    const p3 = await ok(ctx, "a", "GET", `/v1/leagues?scope=mine&limit=2&cursor=${p2.nextCursor}`);
    expect(p3).toMatchObject({ hasMore: false, nextCursor: null });
    expect(p3.items.map((l: any) => l.id)).toEqual([ids[0]]);

    expect((await ok(ctx, "o", "GET", "/v1/leagues?scope=managed")).items).toHaveLength(5);
    expect((await ok(ctx, "a", "GET", "/v1/leagues?scope=managed")).items).toHaveLength(0);
    expect((await ok(ctx, "b", "GET", "/v1/leagues?scope=others")).items).toHaveLength(5);
    expect((await ok(ctx, "a", "GET", "/v1/leagues?scope=others")).items).toHaveLength(0);
    expect((await call(ctx, "a", "GET", "/v1/leagues?scope=mine&cursor=garbage")).status).toBe(400);
    expect((await call(ctx, "a", "GET", "/v1/leagues")).status).toBe(400);
  });

  it("filters by owner and by group ids", async () => {
    const g1 = await setup();
    const g2 = await seedGroup(ctx, "a");
    const l1 = await seedLeague(ctx, "o", g1);
    const l2 = await seedLeague(ctx, "a", g2);
    expect((await ok(ctx, "a", "GET", "/v1/leagues?ownerId=a")).map((l: any) => l.id)).toEqual([l2]);
    const both = await ok(ctx, "a", "GET", `/v1/leagues?groupIds=${g1},${g2}`);
    expect(both.map((l: any) => l.id).sort()).toEqual([l1, l2].sort());
    expect(await ok(ctx, "a", "GET", "/v1/leagues?groupIds=")).toEqual([]);
  });
});

describe("participants", () => {
  it("adds unique participants and their standings rows", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { participants: ["a"] });
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/participants`, { userIds: ["a", "b", "b", "c"] });
    expect((await ok(ctx, "o", "GET", `/v1/leagues/${id}`)).participants).toEqual(["a", "b", "c"]);
    const stats = await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`);
    expect(stats.map((s: any) => s.userId).sort()).toEqual(["a", "b", "c"]);
    expect(stats[0]).toMatchObject({ matchesPlayed: 0, groupId: null, leagueId: id });
    expect(stats.find((s: any) => s.userId === "a").user.id).toBe("a");
  });

  it("replaces a participant in matches, participants and standings", async () => {
    const g = await setup();
    await ok(ctx, "o", "POST", `/v1/groups/${g}/members`, { userId: "p" });
    const id = await seedLeague(ctx, "o", g, { participants: ["p", "b"] });
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["p", "b"] });
    const [m] = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    await score(ctx, "o", id, m.id, m.homeTeamId === "p" ? 2 : 0, m.homeTeamId === "p" ? 0 : 2);

    await ok(ctx, "o", "POST", `/v1/leagues/${id}/replace-participant`, { oldUserId: "p", newUserId: "a" });
    expect((await ok(ctx, "o", "GET", `/v1/leagues/${id}`)).participants).toEqual(["b", "a"]);
    const stats = await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`);
    expect(stats.map((s: any) => s.userId).sort()).toEqual(["a", "b"]);
    expect(stats.find((s: any) => s.userId === "a")).toMatchObject({ wins: 1, goals: 2 });
    const [after] = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    expect([after.homeTeamId, after.awayTeamId].sort()).toEqual(["a", "b"]);
  });

  it("replacing into an existing player merges their rows", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { participants: ["a", "b", "c"] });
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b", "c"] });
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/replace-participant`, { oldUserId: "c", newUserId: "a" });
    const stats = await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`);
    expect(stats.map((s: any) => s.userId).sort()).toEqual(["a", "b"]);
    expect((await call(ctx, "o", "POST", `/v1/leagues/${id}/replace-participant`, { oldUserId: "zz", newUserId: "a" })).status).toBe(404);
  });
});

describe("round generation", () => {
  it("creates one leg with continuous matchdays and standings rows", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g);
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b", "c", "d", "a"] });
    let matches = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    expect(matches).toHaveLength(6);
    expect([...new Set(matches.map((m: any) => m.matchday))].sort()).toEqual([1, 2, 3]);
    expect(matches[0]).toMatchObject({ homeScore: 0, awayScore: 0, isFinished: false, updatedAt: null, phase: null });
    expect(matches[0].homeTeam).toMatchObject({ id: matches[0].homeTeamId });

    await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b", "c", "d"] });
    matches = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    expect(matches).toHaveLength(12);
    expect(Math.max(...matches.map((m: any) => m.matchday))).toBe(6);
    // Second leg flips every pairing.
    const legOf = (m: any) => (m.matchday <= 3 ? 1 : 2);
    for (const m of matches.filter((x: any) => legOf(x) === 2)) {
      expect(matches.some((x: any) => legOf(x) === 1 && x.homeTeamId === m.awayTeamId && x.awayTeamId === m.homeTeamId)).toBe(true);
    }
    expect(await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`)).toHaveLength(4);
  });

  it("deleting the last matchday never frees its number", async () => {
    const g = await setup(["a", "b"]);
    const id = await seedLeague(ctx, "o", g);
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b"] });
    const [m] = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    await ok(ctx, "o", "DELETE", `/v1/leagues/${id}/matches/${m.id}`);
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b"] });
    const [again] = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    expect(again.matchday).toBe(2);
  });

  it("legacy leagues without a counter continue from the highest matchday", async () => {
    const g = await setup(["a", "b"]);
    const id = await seedLeague(ctx, "o", g);
    await ctx.db.query(
      "INSERT INTO matches (id, league_id, home_team_id, away_team_id, date, matchday) VALUES ('legacy', $1, 'a', 'b', now(), 7)",
      [id],
    );
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b"] });
    const created = (await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`)).find((m: any) => m.id !== "legacy");
    expect(created).toMatchObject({ matchday: 8, homeTeamId: "b" });
  });

  it("concurrent generations get disjoint matchday ranges", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g);
    await Promise.all([
      ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b", "c", "d"] }),
      ok(ctx, "a", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["a", "b", "c", "d"] }),
    ]);
    const matches = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    expect(matches.map((m: any) => m.matchday).sort((x: number, y: number) => x - y)).toEqual(
      [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6],
    );
  });

  it("group rounds create group matches only", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { mode: "full" });
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/group-rounds`, { groupId: "B", teamIds: ["a", "b", "c"] });
    const matches = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    expect(matches).toHaveLength(3);
    expect(matches.every((m: any) => m.phase === "group" && m.groupId === "B" && m.matchday === null)).toBe(true);
    expect(await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`)).toEqual([]);
  });
});

describe("brackets", () => {
  it("cup bracket rejects non-power-of-two and links rounds", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { mode: "cup" });
    expect((await call(ctx, "o", "POST", `/v1/leagues/${id}/cup-bracket`, { seededTeamIds: ["a", "b", "c"] })).status).toBe(400);
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/cup-bracket`, { seededTeamIds: ["a", "b", "c", "d"] });
    const ms = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    expect(ms).toHaveLength(3);
    const final = ms.find((m: any) => m.knockoutRound === 1);
    expect(ms.filter((m: any) => m.nextMatchId === final.id)).toHaveLength(2);
    expect(final).toMatchObject({ homeTeamId: "", awayTeamId: "", homeTeam: null });
  });

  it("full tournament: group stage, group rows, seeded knockout", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { mode: "full", groupCount: 2 });
    expect((await call(ctx, "o", "POST", `/v1/leagues/${id}/full-tournament`, { groups: [["a", "b"], ["c", "d"], ["o"]], advanceCount: 1 })).status).toBe(400);
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/full-tournament`, {
      groups: [["a", "b"], ["c", "d"]], advanceCount: 2, knockoutSeeding: ["A1", "B1", "A2", "B2"],
    });
    const ms = await ok(ctx, "o", "GET", `/v1/leagues/${id}/matches`);
    expect(ms.filter((m: any) => m.phase === "group").map((m: any) => m.groupId).sort()).toEqual(["A", "B"]);
    const r0 = ms.filter((m: any) => m.phase === "knockout" && m.knockoutRound === 0);
    expect(r0.map((m: any) => `${m.homeTeamId}-${m.awayTeamId}`).sort()).toEqual(["A1-B2", "B1-A2"]);
    const stats = await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`);
    expect(stats.map((s: any) => `${s.userId}${s.groupId}`).sort()).toEqual(["aA", "bA", "cB", "dB"]);
  });
});

describe("recompute standings rows", () => {
  it("league mode: participants ∪ match sides; drops orphans", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { participants: ["a"] });
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/rounds`, { teamIds: ["b", "c"] });
    await ctx.db.query("INSERT INTO league_stat_rows VALUES ('orphan', $1, 'zz', 'A')", [id]);
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/stats/recompute`);
    const stats = await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`);
    expect(stats.map((s: any) => s.userId).sort()).toEqual(["a", "b", "c"]);
  });

  it("full mode: group from group matches, else existing row", async () => {
    const g = await setup();
    const id = await seedLeague(ctx, "o", g, { mode: "full" });
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/group-rounds`, { groupId: "A", teamIds: ["a", "b"] });
    await ctx.db.query("INSERT INTO league_stat_rows VALUES ('r1', $1, 'c', 'B'), ('r2', $1, 'a', NULL)", [id]);
    await ok(ctx, "o", "POST", `/v1/leagues/${id}/stats/recompute`);
    const stats = await ok(ctx, "o", "GET", `/v1/leagues/${id}/stats`);
    expect(stats.map((s: any) => `${s.userId}${s.groupId}`).sort()).toEqual(["aA", "bA", "cB"]);
  });
});
