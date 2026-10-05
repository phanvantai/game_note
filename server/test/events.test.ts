import { afterEach, describe, expect, it } from "vitest";
import { ok, seedGroup, seedLeague, seedUser, useTestApp } from "./helpers.js";

const ctx = useTestApp();
let base = "";
let controllers: AbortController[] = [];

afterEach(() => {
  for (const c of controllers) c.abort();
  controllers = [];
});

/** Opens the SSE stream over real HTTP and yields parsed snapshots. */
async function open(leagueId: string, uid = "a") {
  if (!base) base = await ctx.app.listen({ port: 0, host: "127.0.0.1" });
  const controller = new AbortController();
  controllers.push(controller);
  const res = await fetch(`${base}/v1/leagues/${leagueId}/events`, {
    headers: { authorization: `Bearer uid:${uid}` },
    signal: controller.signal,
  });
  expect(res.headers.get("content-type")).toContain("text/event-stream");
  const reader = res.body!.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  return {
    async next(): Promise<any> {
      for (;;) {
        const end = buffer.indexOf("\n\n");
        if (end !== -1) {
          const frame = buffer.slice(0, end);
          buffer = buffer.slice(end + 2);
          const data = frame.split("\n").find((l) => l.startsWith("data: "));
          if (frame.startsWith("event: snapshot") && data) return JSON.parse(data.slice(6));
          continue;
        }
        const { value, done } = await reader.read();
        if (done) throw new Error("stream closed");
        buffer += decoder.decode(value, { stream: true });
      }
    },
  };
}

describe("league events", () => {
  it("sends a snapshot on connect and after every change", async () => {
    for (const u of ["a", "b"]) await seedUser(ctx, u);
    const g = await seedGroup(ctx, "a", ["b"]);
    const l = await seedLeague(ctx, "a", g, { participants: ["a", "b"] });
    const stream = await open(l);

    const first = await stream.next();
    expect(first.league).toMatchObject({ id: l, name: "Season" });
    expect(first.matches).toEqual([]);

    await ok(ctx, "a", "POST", `/v1/leagues/${l}/rounds`, { teamIds: ["a", "b"] });
    const second = await stream.next();
    expect(second.matches).toHaveLength(1);
    expect(second.stats).toHaveLength(2);

    await ok(ctx, "a", "DELETE", `/v1/leagues/${l}`);
    expect(await stream.next()).toEqual({ league: null, matches: [], stats: [] });
  });

  it("requires auth", async () => {
    if (!base) base = await ctx.app.listen({ port: 0, host: "127.0.0.1" });
    const res = await fetch(`${base}/v1/leagues/x/events`);
    expect(res.status).toBe(401);
  });
});
