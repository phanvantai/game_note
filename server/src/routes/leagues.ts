import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { requireGroupMember, requireLeagueEditor } from "../access.js";
import type { AppDeps } from "../app.js";
import { tx } from "../db.js";
import { notFound, validation } from "../errors.js";
import { caller, idList, isoDate, parse } from "../http.js";
import { newId } from "../ids.js";
import { leaguesWithGroups, type LeagueRow, type MatchRow, type StatRow } from "../rows.js";
import { groupLabel, groupStageMatches, isPowerOfTwo, knockoutMatches, type NewMatch } from "../domain/bracket.js";
import {
  ensureStatRows,
  findLeague,
  insertMatches,
  leagueWithGroup,
  listStats,
} from "../domain/league-data.js";
import { buildRoundRobinSchedule, distinctIds } from "../domain/scheduler.js";

type LeagueParams = { Params: { id: string } };

const mode = z.enum(["league", "cup", "full"]);
const status = z.enum(["upcoming", "ongoing", "finished"]);
const money = z.number().int().min(0);

// Editable league fields, shared by create (POST) and update (PATCH).
const leagueFields = {
  name: z.string(),
  description: z.string(),
  startDate: isoDate,
  endDate: isoDate.nullable(),
  isActive: z.boolean(),
  status: status.nullable(),
  participants: idList,
  rankPayoutEnabled: z.boolean(),
  rankPayouts: z.array(money),
  defaultMatchCost: money,
  defaultPerGoalEnabled: z.boolean(),
  defaultCostPerGoal: money,
  mergeCompleted: z.boolean(),
  mode,
  groupCount: z.number().int().min(1),
  advanceCount: z.number().int().min(1),
  knockoutSeeding: z.array(z.string()),
};

const COLUMNS: Record<keyof typeof leagueFields, string> = {
  name: "name",
  description: "description",
  startDate: "start_date",
  endDate: "end_date",
  isActive: "is_active",
  status: "status",
  participants: "participants",
  rankPayoutEnabled: "rank_payout_enabled",
  rankPayouts: "rank_payouts",
  defaultMatchCost: "default_match_cost",
  defaultPerGoalEnabled: "default_per_goal_enabled",
  defaultCostPerGoal: "default_cost_per_goal",
  mergeCompleted: "merge_completed",
  mode: "mode",
  groupCount: "group_count",
  advanceCount: "advance_count",
  knockoutSeeding: "knockout_seeding",
};

/** Opaque keyset cursor over (start_date desc, id desc). */
const encodeCursor = (l: LeagueRow) =>
  Buffer.from(JSON.stringify([l.start_date.toISOString(), l.id])).toString("base64url");
function decodeCursor(cursor: string): [Date, string] {
  try {
    const [date, id] = JSON.parse(Buffer.from(cursor, "base64url").toString("utf8"));
    if (typeof date !== "string" || typeof id !== "string") throw new Error();
    return [new Date(date), id];
  } catch {
    throw validation("Invalid cursor");
  }
}

export function leagueRoutes({ db, events }: AppDeps): FastifyPluginAsync {
  return async (app) => {
    app.get("/v1/leagues", async (req) => {
      const { uid } = caller(req);
      const q = parse(
        z.object({
          scope: z.enum(["mine", "managed", "others"]).optional(),
          cursor: z.string().optional(),
          limit: z.coerce.number().int().min(1).max(100).default(20),
          ownerId: z.string().optional(),
          groupIds: z.string().optional(),
        }),
        req.query,
      );

      if (q.ownerId !== undefined) {
        const { rows } = await db.query<LeagueRow>(
          "SELECT * FROM leagues WHERE is_active AND owner_id = $1 ORDER BY start_date DESC, id DESC",
          [q.ownerId],
        );
        return leaguesWithGroups(db, rows);
      }
      if (q.groupIds !== undefined) {
        const ids = q.groupIds.split(",").filter(Boolean);
        if (ids.length === 0) return [];
        const { rows } = await db.query<LeagueRow>(
          "SELECT * FROM leagues WHERE is_active AND group_id = ANY($1) ORDER BY start_date DESC, id DESC",
          [ids],
        );
        return leaguesWithGroups(db, rows);
      }
      if (!q.scope) throw validation("One of scope, ownerId or groupIds is required");

      const scopeFilter = {
        mine: "$1 = ANY(participants)",
        managed: "owner_id = $1",
        others: "owner_id <> $1 AND NOT ($1 = ANY(participants))",
      }[q.scope];
      const params: unknown[] = [uid, q.limit + 1];
      let after = "";
      if (q.cursor) {
        const [date, id] = decodeCursor(q.cursor);
        params.push(date, id);
        after = "AND (start_date, id) < ($3, $4)";
      }
      const { rows } = await db.query<LeagueRow>(
        `SELECT * FROM leagues WHERE is_active AND ${scopeFilter} ${after}
         ORDER BY start_date DESC, id DESC LIMIT $2`,
        params,
      );
      const hasMore = rows.length > q.limit;
      const page = rows.slice(0, q.limit);
      return {
        items: await leaguesWithGroups(db, page),
        nextCursor: hasMore ? encodeCursor(page[page.length - 1]!) : null,
        hasMore,
      };
    });

    app.post("/v1/leagues", async (req) => {
      const { uid } = caller(req);
      const body = parse(
        z.object({
          groupId: z.string().min(1),
          name: z.string().min(1),
          description: leagueFields.description.default(""),
          startDate: leagueFields.startDate.optional(),
          endDate: leagueFields.endDate.optional(),
          status: leagueFields.status.optional(),
          participants: leagueFields.participants.default([]),
          rankPayoutEnabled: leagueFields.rankPayoutEnabled.default(false),
          rankPayouts: leagueFields.rankPayouts.default([]),
          defaultMatchCost: leagueFields.defaultMatchCost.default(50000),
          defaultPerGoalEnabled: leagueFields.defaultPerGoalEnabled.default(false),
          defaultCostPerGoal: leagueFields.defaultCostPerGoal.default(50000),
          mode: mode.default("league"),
          groupCount: leagueFields.groupCount.default(1),
          advanceCount: leagueFields.advanceCount.default(2),
          knockoutSeeding: leagueFields.knockoutSeeding.default([]),
        }),
        req.body,
      );
      await requireGroupMember(db, body.groupId, uid);
      const id = newId();
      await db.query(
        `INSERT INTO leagues (id, owner_id, group_id, name, description, start_date, end_date, status,
           participants, rank_payout_enabled, rank_payouts, default_match_cost, default_per_goal_enabled,
           default_cost_per_goal, mode, group_count, advance_count, knockout_seeding)
         VALUES ($1, $2, $3, $4, $5, coalesce($6, now()), $7, coalesce($8, 'upcoming'), $9, $10, $11, $12,
           $13, $14, $15, $16, $17, $18)`,
        [
          id, uid, body.groupId, body.name, body.description, body.startDate ?? null, body.endDate ?? null,
          body.status ?? null, distinctIds(body.participants), body.rankPayoutEnabled, body.rankPayouts,
          body.defaultMatchCost, body.defaultPerGoalEnabled, body.defaultCostPerGoal, body.mode,
          body.groupCount, body.advanceCount, body.knockoutSeeding,
        ],
      );
      return { id };
    });

    app.get<LeagueParams>("/v1/leagues/:id", async (req) => {
      caller(req);
      const league = await findLeague(db, req.params.id);
      if (!league) throw notFound("League");
      return leagueWithGroup(db, league);
    });

    app.patch<LeagueParams>("/v1/leagues/:id", async (req) => {
      const { uid } = caller(req);
      const body = parse(z.object(leagueFields).partial().strip(), req.body);
      await requireLeagueEditor(db, req.params.id, uid);
      const entries = Object.entries(body).filter(([, v]) => v !== undefined) as [keyof typeof COLUMNS, unknown][];
      if (entries.length > 0) {
        const sets = entries.map(([k], i) =>
          k === "status" ? `status = coalesce($${i + 2}, 'upcoming')` : `${COLUMNS[k]} = $${i + 2}`,
        );
        const values = entries.map(([k, v]) => (k === "participants" ? distinctIds(v as string[]) : v));
        await db.query(`UPDATE leagues SET ${sets.join(", ")}, updated_at = now() WHERE id = $1`, [
          req.params.id,
          ...values,
        ]);
        events.publish(req.params.id);
      }
      return leagueWithGroup(db, (await findLeague(db, req.params.id))!);
    });

    app.post<LeagueParams>("/v1/leagues/:id/deactivate", async (req, reply) => {
      const { uid } = caller(req);
      await requireLeagueEditor(db, req.params.id, uid);
      await db.query("UPDATE leagues SET is_active = false, updated_at = now() WHERE id = $1", [req.params.id]);
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    app.delete<LeagueParams>("/v1/leagues/:id", async (req, reply) => {
      const { uid } = caller(req);
      await requireLeagueEditor(db, req.params.id, uid);
      await db.query("DELETE FROM leagues WHERE id = $1", [req.params.id]);
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    app.post<LeagueParams>("/v1/leagues/:id/transfer-ownership", async (req, reply) => {
      const { uid } = caller(req);
      const { newOwnerId } = parse(z.object({ newOwnerId: z.string().min(1) }), req.body);
      await requireLeagueEditor(db, req.params.id, uid);
      await db.query("UPDATE leagues SET owner_id = $2, updated_at = now() WHERE id = $1", [
        req.params.id,
        newOwnerId,
      ]);
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    app.put<LeagueParams>("/v1/leagues/:id/merge-completed", async (req, reply) => {
      const { uid } = caller(req);
      const { completed } = parse(z.object({ completed: z.boolean() }), req.body);
      await requireLeagueEditor(db, req.params.id, uid);
      await db.query("UPDATE leagues SET merge_completed = $2, updated_at = now() WHERE id = $1", [
        req.params.id,
        completed,
      ]);
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    app.post<LeagueParams>("/v1/leagues/:id/participants", async (req, reply) => {
      const { uid } = caller(req);
      const { userIds } = parse(z.object({ userIds: idList }), req.body);
      await tx(db, async (c) => {
        const league = await requireLeagueEditor(c, req.params.id, uid, { forUpdate: true });
        const added = distinctIds(userIds).filter((u) => !league.participants.includes(u));
        await c.query("UPDATE leagues SET participants = participants || $2::text[], updated_at = now() WHERE id = $1", [
          league.id,
          added,
        ]);
        await ensureStatRows(c, league.id, distinctIds(userIds).map((userId) => ({ userId, groupLabel: null })));
      });
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    // Swap a player for another everywhere in the league (e.g. a placeholder
    // for the real account). Standings follow the matches automatically; a
    // row the new user already has in the same group absorbs the old one.
    app.post<LeagueParams>("/v1/leagues/:id/replace-participant", async (req, reply) => {
      const { uid } = caller(req);
      const { oldUserId, newUserId } = parse(
        z.object({ oldUserId: z.string().min(1), newUserId: z.string().min(1) }),
        req.body,
      );
      await tx(db, async (c) => {
        const league = await requireLeagueEditor(c, req.params.id, uid, { forUpdate: true });
        const { rows } = await c.query<StatRow>(
          "SELECT * FROM league_stat_rows WHERE league_id = $1 AND user_id = ANY($2)",
          [league.id, [oldUserId, newUserId]],
        );
        const oldRows = rows.filter((r) => r.user_id === oldUserId);
        if (oldRows.length === 0) throw notFound(`User ${oldUserId} in league`);
        const newGroups = new Set(rows.filter((r) => r.user_id === newUserId).map((r) => r.group_label));
        for (const row of oldRows) {
          if (newGroups.has(row.group_label)) {
            await c.query("DELETE FROM league_stat_rows WHERE id = $1", [row.id]);
          } else {
            await c.query("UPDATE league_stat_rows SET user_id = $2 WHERE id = $1", [row.id, newUserId]);
          }
        }
        const participants = league.participants.filter((p) => p !== oldUserId);
        if (!participants.includes(newUserId)) participants.push(newUserId);
        await c.query("UPDATE leagues SET participants = $2, updated_at = now() WHERE id = $1", [
          league.id,
          participants,
        ]);
        await c.query(
          `UPDATE matches SET
             home_team_id = CASE WHEN home_team_id = $2 THEN $3 ELSE home_team_id END,
             away_team_id = CASE WHEN away_team_id = $2 THEN $3 ELSE away_team_id END
           WHERE league_id = $1 AND (home_team_id = $2 OR away_team_id = $2)`,
          [league.id, oldUserId, newUserId],
        );
      });
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    // One round-robin leg. The league row lock serialises concurrent
    // generations, so matchday ranges never overlap and orientation is
    // always computed from the latest fixtures.
    app.post<LeagueParams>("/v1/leagues/:id/rounds", async (req, reply) => {
      const { uid } = caller(req);
      const { teamIds } = parse(z.object({ teamIds: idList }), req.body);
      await tx(db, async (c) => {
        const league = await requireLeagueEditor(c, req.params.id, uid, { forUpdate: true });
        const teams = distinctIds(teamIds);
        await ensureStatRows(c, league.id, teams.map((userId) => ({ userId, groupLabel: null })));
        const { rows: existing } = await c.query<MatchRow>(
          "SELECT home_team_id, away_team_id, matchday FROM matches WHERE league_id = $1",
          [league.id],
        );
        const schedule = buildRoundRobinSchedule(
          teams,
          existing.map((m) => ({ homeId: m.home_team_id, awayId: m.away_team_id })),
        );
        if (schedule.length === 0) return;
        const allocated =
          league.matchday_count ?? existing.reduce((max, m) => Math.max(max, m.matchday ?? 0), 0);
        const matchdaysInLeg = Math.max(...schedule.map((p) => p.matchday));
        const fixtures: NewMatch[] = schedule.map((p) => ({
          id: newId(),
          homeTeamId: p.homeId,
          awayTeamId: p.awayId,
          phase: null,
          groupLabel: null,
          knockoutRound: null,
          knockoutSlot: null,
          nextMatchId: null,
          matchday: allocated + p.matchday,
        }));
        await insertMatches(c, league.id, fixtures);
        await c.query("UPDATE leagues SET matchday_count = $2 WHERE id = $1", [league.id, allocated + matchdaysInLeg]);
      });
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    app.post<LeagueParams>("/v1/leagues/:id/group-rounds", async (req, reply) => {
      const { uid } = caller(req);
      const { groupId, teamIds } = parse(z.object({ groupId: z.string().min(1), teamIds: idList }), req.body);
      await requireLeagueEditor(db, req.params.id, uid);
      await insertMatches(db, req.params.id, groupStageMatches(groupId, teamIds));
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    app.post<LeagueParams>("/v1/leagues/:id/cup-bracket", async (req, reply) => {
      const { uid } = caller(req);
      const { seededTeamIds } = parse(z.object({ seededTeamIds: idList }), req.body);
      if (!isPowerOfTwo(seededTeamIds.length)) {
        throw validation(`Cup bracket requires a power-of-2 participant count, got ${seededTeamIds.length}`);
      }
      await requireLeagueEditor(db, req.params.id, uid);
      await insertMatches(db, req.params.id, knockoutMatches(seededTeamIds.length, seededTeamIds));
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    app.post<LeagueParams>("/v1/leagues/:id/full-tournament", async (req, reply) => {
      const { uid } = caller(req);
      const body = parse(
        z.object({
          groups: z.array(idList).min(1),
          advanceCount: z.number().int().min(1),
          knockoutSeeding: z.array(z.string()).default([]),
        }),
        req.body,
      );
      const size = body.groups.length * body.advanceCount;
      if (!isPowerOfTwo(size)) {
        throw validation(`Knockout size (groupCount × advanceCount = ${size}) must be a power of 2`);
      }
      await tx(db, async (c) => {
        const league = await requireLeagueEditor(c, req.params.id, uid, { forUpdate: true });
        const groupMatches = body.groups.flatMap((members, g) => groupStageMatches(groupLabel(g), members));
        await ensureStatRows(
          c,
          league.id,
          body.groups.flatMap((members, g) => members.map((userId) => ({ userId, groupLabel: groupLabel(g) }))),
        );
        const seeding = body.knockoutSeeding.length === size ? body.knockoutSeeding : null;
        await insertMatches(c, league.id, [...groupMatches, ...knockoutMatches(size, seeding)]);
      });
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    app.get<LeagueParams>("/v1/leagues/:id/stats", async (req) => {
      caller(req);
      if (!(await findLeague(db, req.params.id))) throw notFound("League");
      return listStats(db, req.params.id);
    });

    // Rebuilds which standings rows exist, with the rules of the old
    // recomputeLeagueStats: league/cup ⇒ participants ∪ every match side;
    // full ⇒ (user, group) from group-phase matches, falling back to the
    // user's existing group row. Numbers are always derived, so only the
    // row set needs repairing.
    app.post<LeagueParams>("/v1/leagues/:id/stats/recompute", async (req, reply) => {
      const { uid } = caller(req);
      await tx(db, async (c) => {
        const league = await requireLeagueEditor(c, req.params.id, uid, { forUpdate: true });
        const [{ rows: matches }, { rows: existing }] = [
          await c.query<MatchRow>("SELECT * FROM matches WHERE league_id = $1 ORDER BY id", [league.id]),
          await c.query<StatRow>("SELECT * FROM league_stat_rows WHERE league_id = $1 ORDER BY id", [league.id]),
        ];
        const desired = new Map<string, { userId: string; groupLabel: string | null }>();
        const key = (u: string, g: string | null) => `${u}\u0000${g ?? ""}`;
        if (league.mode === "full") {
          const groupOf = new Map<string, string>();
          for (const m of matches) {
            if (m.phase !== "group" || !m.group_label) continue;
            if (m.home_team_id) groupOf.set(m.home_team_id, m.group_label);
            if (m.away_team_id) groupOf.set(m.away_team_id, m.group_label);
          }
          for (const r of existing) {
            if (r.group_label && !groupOf.has(r.user_id)) groupOf.set(r.user_id, r.group_label);
          }
          for (const [userId, g] of groupOf) desired.set(key(userId, g), { userId, groupLabel: g });
        } else {
          const users = new Set([...league.participants, ...matches.flatMap((m) => [m.home_team_id, m.away_team_id])]);
          users.delete("");
          for (const userId of users) desired.set(key(userId, null), { userId, groupLabel: null });
        }
        const stale = existing.filter((r) => !desired.has(key(r.user_id, r.group_label))).map((r) => r.id);
        if (stale.length) await c.query("DELETE FROM league_stat_rows WHERE id = ANY($1)", [stale]);
        await ensureStatRows(c, league.id, [...desired.values()]);
      });
      events.publish(req.params.id);
      return reply.status(204).send();
    });
  };
}
