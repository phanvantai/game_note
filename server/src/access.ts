import type { Queryable } from "./db.js";
import { forbidden, notFound } from "./errors.js";
import type { LeagueRow } from "./rows.js";

async function isAppAdmin(db: Queryable, uid: string): Promise<boolean> {
  const { rows } = await db.query<{ role: string }>("SELECT role FROM users WHERE id = $1", [uid]);
  return rows[0]?.role === "admin";
}

export async function isGroupMember(db: Queryable, groupId: string, uid: string): Promise<boolean> {
  const { rowCount } = await db.query(
    "SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2",
    [groupId, uid],
  );
  return (rowCount ?? 0) > 0;
}

/** Throws unless [uid] is a member of [groupId] (or an app admin). */
export async function requireGroupMember(db: Queryable, groupId: string, uid: string): Promise<void> {
  const { rowCount } = await db.query("SELECT 1 FROM groups WHERE id = $1", [groupId]);
  if (!rowCount) throw notFound("Group");
  if (await isGroupMember(db, groupId, uid)) return;
  if (await isAppAdmin(db, uid)) return;
  throw forbidden("Only group members can do this");
}

/** Throws unless [uid] owns [groupId] (or is an app admin). */
export async function requireGroupOwner(db: Queryable, groupId: string, uid: string): Promise<void> {
  const { rows } = await db.query<{ owner_id: string }>("SELECT owner_id FROM groups WHERE id = $1", [groupId]);
  if (!rows[0]) throw notFound("Group");
  if (rows[0].owner_id === uid) return;
  if (await isAppAdmin(db, uid)) return;
  throw forbidden("Only the group owner can do this");
}

/**
 * Loads a league and checks the caller may change it (member of its group).
 * Pass `forUpdate` inside a transaction to lock the row.
 */
export async function requireLeagueEditor(
  db: Queryable,
  leagueId: string,
  uid: string,
  { forUpdate = false } = {},
): Promise<LeagueRow> {
  const { rows } = await db.query<LeagueRow>(
    `SELECT * FROM leagues WHERE id = $1${forUpdate ? " FOR UPDATE" : ""}`,
    [leagueId],
  );
  const league = rows[0];
  if (!league) throw notFound("League");
  await requireGroupMember(db, league.group_id, uid);
  return league;
}
