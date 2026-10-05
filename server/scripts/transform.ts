// Pure Firestore → Postgres row mapping for the one-shot import. Kept free
// of I/O so it can be unit-tested (test/transform.test.ts).

export interface FirestoreDoc {
  id: string;
  data: Record<string, unknown>;
}

export interface FirestoreDump {
  users: FirestoreDoc[];
  groups: FirestoreDoc[];
  leagues: (FirestoreDoc & { matches: FirestoreDoc[]; stats: FirestoreDoc[] })[];
}

/** Anything with toDate() (Firestore Timestamp), a Date, or nothing. */
function toDate(v: unknown): Date | null {
  if (v instanceof Date) return v;
  if (v && typeof (v as { toDate?: unknown }).toDate === "function") {
    return (v as { toDate(): Date }).toDate();
  }
  return null;
}
/** Versions are compared at millisecond precision by the API. */
const toMs = (d: Date | null) => (d ? new Date(Math.floor(d.getTime())) : null);
const str = (v: unknown): string | null => (typeof v === "string" ? v : null);
const int = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : null);
const bool = (v: unknown, fallback: boolean) => (typeof v === "boolean" ? v : fallback);
const strings = (v: unknown) => (Array.isArray(v) ? v.filter((x): x is string => typeof x === "string") : []);
const unique = (xs: string[]) => [...new Set(xs.filter(Boolean))];

export interface ImportRows {
  users: unknown[][];
  groups: unknown[][];
  members: unknown[][];
  leagues: unknown[][];
  statRows: unknown[][];
  matches: unknown[][];
  warnings: string[];
}

export function transform(dump: FirestoreDump, now = new Date()): ImportRows {
  const warnings: string[] = [];
  const out: ImportRows = { users: [], groups: [], members: [], leagues: [], statRows: [], matches: [], warnings };

  for (const { id, data: d } of dump.users) {
    out.users.push([
      id, str(d.displayName), str(d.phoneNumber), str(d.email), str(d.photoUrl), str(d.role) ?? "user",
      bool(d.isPlaceholder, false), bool(d.deleted, false), toDate(d.deletedAt),
      toDate(d.createdAt) ?? now, toDate(d.updatedAt) ?? now,
    ]);
  }

  const groupIds = new Set<string>();
  for (const { id, data: d } of dump.groups) {
    groupIds.add(id);
    out.groups.push([
      id, str(d.groupName) ?? "", str(d.ownerId) ?? "", str(d.description) ?? "", str(d.status) ?? "active",
      toDate(d.createdAt) ?? now, toDate(d.updatedAt) ?? now,
    ]);
    const deactivated = new Set(strings(d.deactivatedMembers));
    unique(strings(d.members)).forEach((userId, position) => {
      out.members.push([id, userId, position, deactivated.has(userId)]);
    });
  }

  for (const league of dump.leagues) {
    const d = league.data;
    const groupId = str(d.groupId);
    if (!groupId || !groupIds.has(groupId)) {
      warnings.push(`league ${league.id} skipped: group ${groupId ?? "(none)"} does not exist`);
      continue;
    }
    out.leagues.push([
      league.id, str(d.ownerId) ?? "", groupId, str(d.name) ?? "", str(d.description) ?? "",
      toDate(d.startDate) ?? now, toDate(d.endDate), bool(d.isActive, true), str(d.status) ?? "upcoming",
      unique(strings(d.participants)), bool(d.rankPayoutEnabled, false),
      (Array.isArray(d.rankPayouts) ? d.rankPayouts : []).map(int).filter((x): x is number => x !== null),
      int(d.defaultMatchCost) ?? 50000, bool(d.defaultPerGoalEnabled, false), int(d.defaultCostPerGoal) ?? 50000,
      bool(d.mergeCompleted, false), str(d.mode) ?? "league", int(d.groupCount) ?? 1, int(d.advanceCount) ?? 2,
      strings(d.knockoutSeeding), int(d.matchdayCount),
    ]);

    // Legacy bugs left duplicate stat docs per (user, group); keep the first
    // by document id, which is also Firestore's default order.
    const seen = new Set<string>();
    for (const s of [...league.stats].sort((a, b) => (a.id < b.id ? -1 : 1))) {
      const userId = str(s.data.userId);
      if (!userId) continue;
      const group = str(s.data.groupId);
      const key = `${userId}\u0000${group ?? ""}`;
      if (seen.has(key)) {
        warnings.push(`league ${league.id}: dropped duplicate standings row ${s.id} for ${userId}`);
        continue;
      }
      seen.add(key);
      out.statRows.push([s.id, league.id, userId, group]);
    }

    for (const { id, data: m } of league.matches) {
      out.matches.push([
        id, league.id, str(m.homeTeamId) ?? "", str(m.awayTeamId) ?? "",
        // GNEsportMatch.fromMap treats missing scores as 0.
        int(m.homeScore) ?? 0, int(m.awayScore) ?? 0, toDate(m.date) ?? now, bool(m.isFinished, false),
        int(m.matchCost), int(m.costPerGoal), str(m.phase), str(m.groupId), int(m.knockoutRound),
        int(m.knockoutSlot), str(m.nextMatchId), int(m.matchday), toMs(toDate(m.updatedAt)),
      ]);
    }
  }
  return out;
}
