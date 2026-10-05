import type { Queryable } from "./db.js";

// Row shapes as returned by Postgres, and their JSON (API contract) forms.

export interface UserRow {
  id: string;
  display_name: string | null;
  phone_number: string | null;
  email: string | null;
  photo_url: string | null;
  role: string;
  is_placeholder: boolean;
  deleted: boolean;
  deleted_at: Date | null;
}

export interface GroupRow {
  id: string;
  group_name: string;
  owner_id: string;
  description: string;
  status: string;
  created_at: Date;
  updated_at: Date;
  members: string[];
  deactivated_members: string[];
}

export interface LeagueRow {
  id: string;
  owner_id: string;
  group_id: string;
  name: string;
  description: string;
  start_date: Date;
  end_date: Date | null;
  is_active: boolean;
  status: string;
  participants: string[];
  rank_payout_enabled: boolean;
  rank_payouts: number[];
  default_match_cost: number;
  default_per_goal_enabled: boolean;
  default_cost_per_goal: number;
  merge_completed: boolean;
  mode: string;
  group_count: number;
  advance_count: number;
  knockout_seeding: string[];
  matchday_count: number | null;
}

export interface MatchRow {
  id: string;
  league_id: string;
  home_team_id: string;
  away_team_id: string;
  home_score: number | null;
  away_score: number | null;
  date: Date;
  is_finished: boolean;
  match_cost: number | null;
  cost_per_goal: number | null;
  phase: string | null;
  group_label: string | null;
  knockout_round: number | null;
  knockout_slot: number | null;
  next_match_id: string | null;
  matchday: number | null;
  updated_at: Date | null;
}

export interface StatRow {
  id: string;
  league_id: string;
  user_id: string;
  group_label: string | null;
}

const iso = (d: Date | null) => (d ? d.toISOString() : null);

export function userJson(r: UserRow) {
  return {
    id: r.id,
    displayName: r.display_name,
    phoneNumber: r.phone_number,
    email: r.email,
    photoUrl: r.photo_url,
    role: r.role,
    isPlaceholder: r.is_placeholder,
    deleted: r.deleted,
    deletedAt: iso(r.deleted_at),
  };
}
export type UserJson = ReturnType<typeof userJson>;

export function groupJson(r: GroupRow) {
  return {
    id: r.id,
    groupName: r.group_name,
    ownerId: r.owner_id,
    members: r.members,
    deactivatedMembers: r.deactivated_members,
    description: r.description,
    status: r.status,
    createdAt: iso(r.created_at),
    updatedAt: iso(r.updated_at),
  };
}
export type GroupJson = ReturnType<typeof groupJson>;

export function leagueJson(r: LeagueRow, group: GroupJson | null) {
  return {
    id: r.id,
    ownerId: r.owner_id,
    groupId: r.group_id,
    name: r.name,
    startDate: iso(r.start_date),
    endDate: iso(r.end_date),
    isActive: r.is_active,
    description: r.description,
    participants: r.participants,
    status: r.status,
    rankPayoutEnabled: r.rank_payout_enabled,
    rankPayouts: r.rank_payouts,
    defaultMatchCost: r.default_match_cost,
    defaultPerGoalEnabled: r.default_per_goal_enabled,
    defaultCostPerGoal: r.default_cost_per_goal,
    mergeCompleted: r.merge_completed,
    mode: r.mode,
    groupCount: r.group_count,
    advanceCount: r.advance_count,
    knockoutSeeding: r.knockout_seeding,
    group,
  };
}

export function matchJson(r: MatchRow, users: Map<string, UserJson>) {
  return {
    id: r.id,
    leagueId: r.league_id,
    homeTeamId: r.home_team_id,
    awayTeamId: r.away_team_id,
    homeScore: r.home_score,
    awayScore: r.away_score,
    date: iso(r.date),
    isFinished: r.is_finished,
    matchCost: r.match_cost,
    costPerGoal: r.cost_per_goal,
    updatedAt: iso(r.updated_at),
    phase: r.phase,
    groupId: r.group_label,
    knockoutRound: r.knockout_round,
    knockoutSlot: r.knockout_slot,
    nextMatchId: r.next_match_id,
    matchday: r.matchday,
    homeTeam: users.get(r.home_team_id) ?? null,
    awayTeam: users.get(r.away_team_id) ?? null,
  };
}

// ---------------------------------------------------------------------------
// Shared loaders
// ---------------------------------------------------------------------------

const GROUP_SELECT = `
  SELECT g.*,
    coalesce(array_agg(m.user_id ORDER BY m.position) FILTER (WHERE m.user_id IS NOT NULL), '{}') AS members,
    coalesce(array_agg(m.user_id ORDER BY m.position) FILTER (WHERE m.deactivated), '{}') AS deactivated_members
  FROM groups g
  LEFT JOIN group_members m ON m.group_id = g.id`;

export async function findGroups(
  db: Queryable,
  where: string,
  params: unknown[],
  orderBy = "g.created_at",
): Promise<GroupRow[]> {
  const { rows } = await db.query<GroupRow>(
    `${GROUP_SELECT} WHERE ${where} GROUP BY g.id ORDER BY ${orderBy}`,
    params,
  );
  return rows;
}

export async function findGroup(db: Queryable, id: string): Promise<GroupRow | null> {
  return (await findGroups(db, "g.id = $1", [id]))[0] ?? null;
}

export async function usersByIds(db: Queryable, ids: Iterable<string>): Promise<Map<string, UserJson>> {
  const unique = [...new Set(ids)].filter((id) => id);
  if (unique.length === 0) return new Map();
  const { rows } = await db.query<UserRow>("SELECT * FROM users WHERE id = ANY($1)", [unique]);
  return new Map(rows.map((r) => [r.id, userJson(r)]));
}

/** Attaches each league's group (one query for all of them). */
export async function leaguesWithGroups(db: Queryable, leagues: LeagueRow[]) {
  const groupIds = [...new Set(leagues.map((l) => l.group_id))];
  const groups = groupIds.length
    ? await findGroups(db, "g.id = ANY($1)", [groupIds])
    : [];
  const byId = new Map(groups.map((g) => [g.id, groupJson(g)]));
  return leagues.map((l) => leagueJson(l, byId.get(l.group_id) ?? null));
}
