// Guards the JSON contract shared with the Flutter client. Responses from a
// realistic scenario are compared, by shape, to the fixtures the Dart tests
// parse (test/fixtures/api/ at the repo root). Regenerate after an intended
// contract change with: UPDATE_FIXTURES=1 npx vitest run test/contract.test.ts
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { between, ok, score, seedGroup, seedLeague, seedUser, useTestApp } from "./helpers.js";

const ctx = useTestApp();
const FIXTURES = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../test/fixtures/api");

/** Type tree of a JSON value; null matches any type. */
function shape(v: unknown): unknown {
  if (v === null) return null;
  if (Array.isArray(v)) return v.length ? [shape(v[0])] : [];
  if (typeof v === "object") {
    return Object.fromEntries(Object.entries(v as object).sort(([a], [b]) => a.localeCompare(b)).map(([k, x]) => [k, shape(x)]));
  }
  return typeof v;
}

function compatible(actual: unknown, expected: unknown, at = "$"): string[] {
  if (actual === null || expected === null) return [];
  if (Array.isArray(expected)) {
    if (!Array.isArray(actual)) return [`${at}: expected array`];
    if (!expected.length || !actual.length) return [];
    return compatible(actual[0], expected[0], `${at}[0]`);
  }
  if (typeof expected === "object") {
    if (typeof actual !== "object" || Array.isArray(actual)) return [`${at}: expected object`];
    const a = actual as Record<string, unknown>;
    const e = expected as Record<string, unknown>;
    const errors: string[] = [];
    for (const k of new Set([...Object.keys(a), ...Object.keys(e)])) {
      if (!(k in a)) errors.push(`${at}.${k}: missing in response`);
      else if (!(k in e)) errors.push(`${at}.${k}: not in fixture`);
      else errors.push(...compatible(a[k], e[k], `${at}.${k}`));
    }
    return errors;
  }
  return actual === expected ? [] : [`${at}: ${actual} vs fixture ${expected}`];
}

async function check(name: string, body: unknown) {
  const file = path.join(FIXTURES, `${name}.json`);
  if (process.env.UPDATE_FIXTURES) {
    await mkdir(FIXTURES, { recursive: true });
    await writeFile(file, `${JSON.stringify(body, null, 2)}\n`);
    return;
  }
  const fixture = JSON.parse(await readFile(file, "utf8"));
  expect(compatible(shape(body), shape(fixture))).toEqual([]);
}

describe("API contract fixtures", () => {
  it("responses keep the shape the Flutter client parses", async () => {
    for (const u of ["owner", "alice", "bob", "carol"]) await seedUser(ctx, u, u[0]!.toUpperCase() + u.slice(1));
    const g = await seedGroup(ctx, "owner", ["alice", "bob", "carol"]);
    const l = await seedLeague(ctx, "owner", g, {
      name: "Autumn Cup", participants: ["owner", "alice", "bob", "carol"], mode: "full",
      groupCount: 2, advanceCount: 1, rankPayoutEnabled: true, rankPayouts: [50000],
      startDate: "2026-09-01T00:00:00.000Z", endDate: "2026-09-30T00:00:00.000Z",
    });
    await ok(ctx, "owner", "POST", `/v1/leagues/${l}/full-tournament`, {
      groups: [["owner", "alice"], ["bob", "carol"]], advanceCount: 1, knockoutSeeding: ["owner", "bob"],
    });
    const matches = await ok(ctx, "owner", "GET", `/v1/leagues/${l}/matches`);
    await score(ctx, "owner", l, between(matches, "owner", "alice").id, 2, 1);
    await ok(ctx, "owner", "PATCH", `/v1/leagues/${l}`, { status: "finished" });

    await check("user", await ok(ctx, "alice", "GET", "/v1/users/alice"));
    await check("group", await ok(ctx, "alice", "GET", `/v1/groups/${g}`));
    await check("league", await ok(ctx, "alice", "GET", `/v1/leagues/${l}`));
    await check("leagues_page", await ok(ctx, "alice", "GET", "/v1/leagues?scope=mine"));
    await check("matches", await ok(ctx, "alice", "GET", `/v1/leagues/${l}/matches`).then((ms) =>
      // Finished group match first so the fixture's [0] has every field set.
      [...ms].sort((a: any, b: any) => Number(b.isFinished) - Number(a.isFinished))));
    await check("stats", await ok(ctx, "alice", "GET", `/v1/leagues/${l}/stats`));
    await check("user_summary", await ok(ctx, "owner", "GET", "/v1/users/owner/summary"));
    await check("h2h", await ok(ctx, "owner", "GET", "/v1/users/owner/h2h/alice"));
    await check("group_summary", await ok(ctx, "owner", "GET", `/v1/groups/${g}/summary`));
    await check("error", (await ctx.app.inject({ method: "GET", url: "/v1/users/nobody", headers: { authorization: "Bearer uid:alice" } })).json());
  });
});
