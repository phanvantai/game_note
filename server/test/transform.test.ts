import { describe, expect, it } from "vitest";
import { transform } from "../scripts/transform.js";

const ts = (iso: string) => ({ toDate: () => new Date(iso) });
const now = new Date("2026-10-05T00:00:00.000Z");

describe("firestore import transform", () => {
  it("maps users, groups and members with defaults", () => {
    const rows = transform(
      {
        users: [{ id: "u1", data: { displayName: "Tai", isPlaceholder: true, deletedAt: ts("2026-01-01T00:00:00Z") } }],
        groups: [{ id: "g1", data: { groupName: "FC", ownerId: "u1", members: ["u1", "u2", "u1"], deactivatedMembers: ["u2", "ghost"] } }],
        leagues: [],
      },
      now,
    );
    expect(rows.users[0]).toEqual(["u1", "Tai", null, null, null, "user", true, false, new Date("2026-01-01T00:00:00Z"), now, now]);
    expect(rows.groups[0]).toEqual(["g1", "FC", "u1", "", "active", now, now]);
    expect(rows.members).toEqual([["g1", "u1", 0, false], ["g1", "u2", 1, true]]);
  });

  it("maps leagues, dedupes standings rows and defaults match scores", () => {
    const rows = transform(
      {
        users: [],
        groups: [{ id: "g1", data: {} }],
        leagues: [
          {
            id: "l1",
            data: { groupId: "g1", name: "S", startDate: ts("2026-02-01T00:00:00Z"), participants: ["a", "b"], matchdayCount: 3, rankPayouts: [10000, "x"] },
            stats: [
              { id: "s2", data: { userId: "a" } },
              { id: "s1", data: { userId: "a" } },
              { id: "s3", data: { userId: "a", groupId: "A" } },
            ],
            matches: [{ id: "m1", data: { homeTeamId: "a", awayTeamId: "b", isFinished: true, updatedAt: ts("2026-02-02T00:00:00.123Z") } }],
          },
          { id: "orphan", data: { groupId: "missing" }, stats: [], matches: [] },
        ],
      },
      now,
    );
    expect(rows.leagues).toHaveLength(1);
    expect(rows.leagues[0]!.slice(0, 12)).toEqual(["l1", "", "g1", "S", "", new Date("2026-02-01T00:00:00Z"), null, true, "upcoming", ["a", "b"], false, [10000]]);
    expect(rows.leagues[0]!.at(-1)).toBe(3);
    expect(rows.statRows).toEqual([["s1", "l1", "a", null], ["s3", "l1", "a", "A"]]);
    expect(rows.matches[0]!.slice(0, 8)).toEqual(["m1", "l1", "a", "b", 0, 0, now, true]);
    expect(rows.matches[0]!.at(-1)).toEqual(new Date("2026-02-02T00:00:00.123Z"));
    expect(rows.warnings).toEqual([
      "league l1: dropped duplicate standings row s2 for a",
      "league orphan skipped: group missing does not exist",
    ]);
  });
});
