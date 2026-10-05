import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import type { FastifyInstance } from "fastify";
import { afterAll, beforeAll, beforeEach } from "vitest";
import { buildApp } from "../src/app.js";
import type { TokenVerifier } from "../src/auth.js";
import { createPool, type Db } from "../src/db.js";
import { ApiError } from "../src/errors.js";
import { LeagueEvents } from "../src/events.js";
import { TEST_DATABASE_URL } from "./global-setup.js";

/** Test tokens are just `uid:<uid>`. */
const fakeVerifier: TokenVerifier = async (token) => {
  if (!token.startsWith("uid:")) throw new ApiError("unauthenticated", "bad token");
  return { uid: token.slice(4), email: `${token.slice(4)}@test.dev` };
};

export interface TestContext {
  app: FastifyInstance;
  db: Db;
  events: LeagueEvents;
  baseUrl: string;
}

export function useTestApp(): TestContext {
  const ctx = {} as TestContext;
  beforeAll(async () => {
    ctx.db = createPool(TEST_DATABASE_URL);
    ctx.events = new LeagueEvents();
    ctx.baseUrl = "http://api.test";
    ctx.app = await buildApp({
      db: ctx.db,
      verifyToken: fakeVerifier,
      events: ctx.events,
      config: {
        publicBaseUrl: ctx.baseUrl,
        avatarDir: await mkdtemp(path.join(tmpdir(), "gn-avatars-")),
      },
    });
  });
  beforeEach(async () => {
    await ctx.db.query("TRUNCATE users, groups, group_members, leagues, league_stat_rows, matches CASCADE");
  });
  afterAll(async () => {
    await ctx.app.close();
    await ctx.db.end();
  });
  return ctx;
}

type Method = "GET" | "POST" | "PATCH" | "PUT" | "DELETE";

/** Calls the API as [uid] and returns { status, body }. */
export async function call(
  ctx: TestContext,
  uid: string | null,
  method: Method,
  url: string,
  payload?: unknown,
): Promise<{ status: number; body: any }> {
  const res = await ctx.app.inject({
    method,
    url,
    headers: uid ? { authorization: `Bearer uid:${uid}` } : {},
    ...(payload !== undefined ? { payload: payload as object } : {}),
  });
  return { status: res.statusCode, body: res.body ? JSON.parse(res.body) : null };
}

/** Like [call] but throws unless the status is 2xx. */
export async function ok(ctx: TestContext, uid: string, method: Method, url: string, payload?: unknown) {
  const res = await call(ctx, uid, method, url, payload);
  if (res.status >= 300) throw new Error(`${method} ${url} → ${res.status} ${JSON.stringify(res.body)}`);
  return res.body;
}

export async function seedUser(ctx: TestContext, id: string, displayName = id, extra: Record<string, unknown> = {}) {
  await ok(ctx, id, "POST", "/v1/me/bootstrap", { displayName });
  if (extra.role) await ctx.db.query("UPDATE users SET role = $2 WHERE id = $1", [id, extra.role]);
}

/** Owner creates a group and adds [members]. Returns the group id. */
export async function seedGroup(ctx: TestContext, owner: string, members: string[] = []): Promise<string> {
  const group = await ok(ctx, owner, "POST", "/v1/groups", { groupName: "Friends" });
  for (const m of members) await ok(ctx, owner, "POST", `/v1/groups/${group.id}/members`, { userId: m });
  return group.id;
}

export async function seedLeague(
  ctx: TestContext,
  owner: string,
  groupId: string,
  fields: Record<string, unknown> = {},
): Promise<string> {
  const { id } = await ok(ctx, owner, "POST", "/v1/leagues", { name: "Season", groupId, ...fields });
  return id;
}

/** Saves a final score with the current version. Returns the updated match. */
export async function score(ctx: TestContext, uid: string, leagueId: string, matchId: string, home: number, away: number) {
  const matches = await ok(ctx, uid, "GET", `/v1/leagues/${leagueId}/matches`);
  const match = matches.find((m: any) => m.id === matchId);
  return ok(ctx, uid, "PATCH", `/v1/leagues/${leagueId}/matches/${matchId}`, {
    homeScore: home,
    awayScore: away,
    expectedUpdatedAt: match.updatedAt,
  });
}

/** Finds the match between two players (either orientation). */
export function between(matches: any[], a: string, b: string) {
  const m = matches.find(
    (x) => (x.homeTeamId === a && x.awayTeamId === b) || (x.homeTeamId === b && x.awayTeamId === a),
  );
  if (!m) throw new Error(`no match ${a} vs ${b}`);
  return m;
}
