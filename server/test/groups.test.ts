import { describe, expect, it } from "vitest";
import { call, ok, seedGroup, seedLeague, seedUser, useTestApp } from "./helpers.js";

const ctx = useTestApp();

async function users(...ids: string[]) {
  for (const id of ids) await seedUser(ctx, id);
}

describe("groups", () => {
  it("creates a group with the caller as owner and first member", async () => {
    await users("o");
    const g = await ok(ctx, "o", "POST", "/v1/groups", { groupName: "FC", description: "d" });
    expect(g).toMatchObject({ groupName: "FC", ownerId: "o", members: ["o"], deactivatedMembers: [], status: "active", description: "d" });
    expect(await ok(ctx, "o", "GET", `/v1/groups/${g.id}`)).toEqual(g);
  });

  it("lists active groups, optionally by owner", async () => {
    await users("o", "p");
    const g1 = await seedGroup(ctx, "o");
    const g2 = await seedGroup(ctx, "p");
    await ok(ctx, "p", "POST", `/v1/groups/${g2}/deactivate`);
    expect((await ok(ctx, "o", "GET", "/v1/groups")).map((g: any) => g.id)).toEqual([g1]);
    expect(await ok(ctx, "o", "GET", "/v1/groups?ownerId=p")).toEqual([]);
  });

  it("members are returned in join order", async () => {
    await users("o", "b", "a");
    const g = await seedGroup(ctx, "o", ["b", "a"]);
    expect((await ok(ctx, "o", "GET", `/v1/groups/${g}/members`)).map((u: any) => u.id)).toEqual(["o", "b", "a"]);
  });

  it("only members can add; adding twice is a no-op", async () => {
    await users("o", "m", "x");
    const g = await seedGroup(ctx, "o", ["m"]);
    expect((await call(ctx, "x", "POST", `/v1/groups/${g}/members`, { userId: "x" })).status).toBe(403);
    await ok(ctx, "m", "POST", `/v1/groups/${g}/members`, { userId: "x" });
    await ok(ctx, "m", "POST", `/v1/groups/${g}/members`, { userId: "x" });
    expect((await ok(ctx, "o", "GET", `/v1/groups/${g}`)).members).toEqual(["o", "m", "x"]);
  });

  it("owner removes anyone, members only themselves", async () => {
    await users("o", "a", "b");
    const g = await seedGroup(ctx, "o", ["a", "b"]);
    expect((await call(ctx, "a", "DELETE", `/v1/groups/${g}/members/b`)).status).toBe(403);
    expect((await call(ctx, "a", "DELETE", `/v1/groups/${g}/members/a`)).status).toBe(204);
    expect((await call(ctx, "o", "DELETE", `/v1/groups/${g}/members/b`)).status).toBe(204);
    expect((await ok(ctx, "o", "GET", `/v1/groups/${g}`)).members).toEqual(["o"]);
  });

  it("deactivation is owner-only and reflected in deactivatedMembers", async () => {
    await users("o", "a");
    const g = await seedGroup(ctx, "o", ["a"]);
    expect((await call(ctx, "a", "PUT", `/v1/groups/${g}/members/a/deactivation`, { deactivated: true })).status).toBe(403);
    await ok(ctx, "o", "PUT", `/v1/groups/${g}/members/a/deactivation`, { deactivated: true });
    expect((await ok(ctx, "o", "GET", `/v1/groups/${g}`)).deactivatedMembers).toEqual(["a"]);
    await ok(ctx, "o", "PUT", `/v1/groups/${g}/members/a/deactivation`, { deactivated: false });
    expect((await ok(ctx, "o", "GET", `/v1/groups/${g}`)).deactivatedMembers).toEqual([]);
    expect((await call(ctx, "o", "PUT", `/v1/groups/${g}/members/zz/deactivation`, { deactivated: true })).status).toBe(404);
  });

  it("transfers ownership to a member only", async () => {
    await users("o", "a", "x");
    const g = await seedGroup(ctx, "o", ["a"]);
    expect((await call(ctx, "o", "POST", `/v1/groups/${g}/transfer-ownership`, { newOwnerId: "x" })).status).toBe(400);
    await ok(ctx, "o", "POST", `/v1/groups/${g}/transfer-ownership`, { newOwnerId: "a" });
    expect((await ok(ctx, "o", "GET", `/v1/groups/${g}`)).ownerId).toBe("a");
    expect((await call(ctx, "o", "POST", `/v1/groups/${g}/deactivate`)).status).toBe(403);
  });

  it("app admins act as owners, except for deletion", async () => {
    await users("o", "a");
    await seedUser(ctx, "admin", "Admin", { role: "admin" });
    const g = await seedGroup(ctx, "o", ["a"]);
    await ok(ctx, "admin", "PUT", `/v1/groups/${g}/members/a/deactivation`, { deactivated: true });
    expect((await call(ctx, "admin", "DELETE", `/v1/groups/${g}`)).status).toBe(403);
  });

  it("owner hard-deletes a group with all its leagues", async () => {
    await users("o", "a");
    const g = await seedGroup(ctx, "o", ["a"]);
    const l = await seedLeague(ctx, "o", g, { participants: ["o", "a"] });
    await ok(ctx, "o", "POST", `/v1/leagues/${l}/rounds`, { teamIds: ["o", "a"] });
    expect((await call(ctx, "a", "DELETE", `/v1/groups/${g}`)).status).toBe(403);
    expect((await call(ctx, "o", "DELETE", `/v1/groups/${g}`)).status).toBe(204);
    expect((await call(ctx, "o", "GET", `/v1/groups/${g}`)).status).toBe(404);
    expect((await call(ctx, "o", "GET", `/v1/leagues/${l}`)).status).toBe(404);
    const { rows } = await ctx.db.query("SELECT count(*)::int AS n FROM matches");
    expect(rows[0].n).toBe(0);
  });

  it("lists a group's active leagues newest first with the group embedded", async () => {
    await users("o");
    const g = await seedGroup(ctx, "o");
    const older = await seedLeague(ctx, "o", g, { startDate: "2026-01-01T00:00:00.000Z" });
    const newer = await seedLeague(ctx, "o", g, { startDate: "2026-02-01T00:00:00.000Z" });
    const gone = await seedLeague(ctx, "o", g);
    await ok(ctx, "o", "POST", `/v1/leagues/${gone}/deactivate`);
    const leagues = await ok(ctx, "o", "GET", `/v1/groups/${g}/leagues`);
    expect(leagues.map((l: any) => l.id)).toEqual([newer, older]);
    expect(leagues[0].group.id).toBe(g);
  });

  it("404s for unknown groups", async () => {
    await users("o");
    expect((await call(ctx, "o", "GET", "/v1/groups/nope")).status).toBe(404);
    expect((await call(ctx, "o", "GET", "/v1/groups/nope/members")).status).toBe(404);
    expect((await call(ctx, "o", "POST", "/v1/groups/nope/members", { userId: "o" })).status).toBe(404);
    expect((await call(ctx, "o", "DELETE", "/v1/groups/nope")).status).toBe(404);
  });
});
