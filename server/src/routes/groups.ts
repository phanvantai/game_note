import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { isGroupMember, requireGroupMember, requireGroupOwner } from "../access.js";
import type { AppDeps } from "../app.js";
import { tx } from "../db.js";
import { ApiError, forbidden, notFound, validation } from "../errors.js";
import { caller, parse } from "../http.js";
import { newId } from "../ids.js";
import { findGroup, findGroups, groupJson, leaguesWithGroups, userJson, type LeagueRow, type UserRow } from "../rows.js";

type GroupParams = { Params: { id: string } };
type MemberParams = { Params: { id: string; userId: string } };

export function groupRoutes({ db, events }: AppDeps): FastifyPluginAsync {
  return async (app) => {
    app.get("/v1/groups", async (req) => {
      caller(req);
      const { ownerId } = parse(z.object({ ownerId: z.string().optional() }), req.query);
      const groups = ownerId
        ? await findGroups(db, "g.status = 'active' AND g.owner_id = $1", [ownerId])
        : await findGroups(db, "g.status = 'active'", []);
      return groups.map(groupJson);
    });

    app.post("/v1/groups", async (req) => {
      const { uid } = caller(req);
      const body = parse(
        z.object({ groupName: z.string().trim().min(1), description: z.string().default("") }),
        req.body,
      );
      const id = newId();
      await tx(db, async (c) => {
        await c.query(
          "INSERT INTO groups (id, group_name, owner_id, description) VALUES ($1, $2, $3, $4)",
          [id, body.groupName, uid, body.description],
        );
        await c.query("INSERT INTO group_members (group_id, user_id, position) VALUES ($1, $2, 0)", [id, uid]);
      });
      return groupJson((await findGroup(db, id))!);
    });

    app.get<GroupParams>("/v1/groups/:id", async (req) => {
      caller(req);
      const group = await findGroup(db, req.params.id);
      if (!group) throw notFound("Group");
      return groupJson(group);
    });

    app.get<GroupParams>("/v1/groups/:id/members", async (req) => {
      caller(req);
      if (!(await findGroup(db, req.params.id))) throw notFound("Group");
      const { rows } = await db.query<UserRow>(
        `SELECT u.* FROM group_members m JOIN users u ON u.id = m.user_id
         WHERE m.group_id = $1 ORDER BY m.position`,
        [req.params.id],
      );
      return rows.map(userJson);
    });

    app.post<GroupParams>("/v1/groups/:id/members", async (req, reply) => {
      const { uid } = caller(req);
      const { userId } = parse(z.object({ userId: z.string().min(1) }), req.body);
      await requireGroupMember(db, req.params.id, uid);
      await db.query(
        `INSERT INTO group_members (group_id, user_id, position)
         SELECT $1, $2, coalesce(max(position) + 1, 0) FROM group_members WHERE group_id = $1
         ON CONFLICT DO NOTHING`,
        [req.params.id, userId],
      );
      await touch(req.params.id);
      return reply.status(204).send();
    });

    app.delete<MemberParams>("/v1/groups/:id/members/:userId", async (req, reply) => {
      const { uid } = caller(req);
      const { id, userId } = req.params;
      if (userId === uid) {
        if (!(await findGroup(db, id))) throw notFound("Group");
      } else {
        await requireGroupOwner(db, id, uid);
      }
      await db.query("DELETE FROM group_members WHERE group_id = $1 AND user_id = $2", [id, userId]);
      await touch(id);
      return reply.status(204).send();
    });

    app.put<MemberParams>("/v1/groups/:id/members/:userId/deactivation", async (req, reply) => {
      const { uid } = caller(req);
      const { deactivated } = parse(z.object({ deactivated: z.boolean() }), req.body);
      await requireGroupOwner(db, req.params.id, uid);
      const { rowCount } = await db.query(
        "UPDATE group_members SET deactivated = $3 WHERE group_id = $1 AND user_id = $2",
        [req.params.id, req.params.userId, deactivated],
      );
      if (!rowCount) throw notFound("Member");
      return reply.status(204).send();
    });

    app.post<GroupParams>("/v1/groups/:id/transfer-ownership", async (req, reply) => {
      const { uid } = caller(req);
      const { newOwnerId } = parse(z.object({ newOwnerId: z.string().min(1) }), req.body);
      await requireGroupOwner(db, req.params.id, uid);
      if (!(await isGroupMember(db, req.params.id, newOwnerId))) {
        throw validation("New owner must be a group member");
      }
      await db.query("UPDATE groups SET owner_id = $2, updated_at = now() WHERE id = $1", [
        req.params.id,
        newOwnerId,
      ]);
      return reply.status(204).send();
    });

    app.post<GroupParams>("/v1/groups/:id/deactivate", async (req, reply) => {
      const { uid } = caller(req);
      await requireGroupOwner(db, req.params.id, uid);
      await db.query("UPDATE groups SET status = 'inactive', updated_at = now() WHERE id = $1", [req.params.id]);
      return reply.status(204).send();
    });

    // Hard delete. Leagues, matches, standings rows and memberships go with
    // it through ON DELETE CASCADE, in one statement.
    app.delete<GroupParams>("/v1/groups/:id", async (req, reply) => {
      const { uid } = caller(req);
      const { rows } = await db.query<{ owner_id: string }>("SELECT owner_id FROM groups WHERE id = $1", [
        req.params.id,
      ]);
      if (!rows[0]) throw notFound("Group");
      // Unlike other owner actions, app admins cannot delete someone's group.
      if (rows[0].owner_id !== uid) throw forbidden("Only the group owner can delete this group");
      const { rows: leagues } = await db.query<{ id: string }>(
        "DELETE FROM leagues WHERE group_id = $1 RETURNING id",
        [req.params.id],
      );
      await db.query("DELETE FROM groups WHERE id = $1", [req.params.id]);
      for (const l of leagues) events.publish(l.id);
      return reply.status(204).send();
    });

    app.get<GroupParams>("/v1/groups/:id/leagues", async (req) => {
      caller(req);
      const { rows } = await db.query<LeagueRow>(
        "SELECT * FROM leagues WHERE group_id = $1 AND is_active ORDER BY start_date DESC, id DESC",
        [req.params.id],
      );
      return leaguesWithGroups(db, rows);
    });

    async function touch(groupId: string) {
      const { rowCount } = await db.query("UPDATE groups SET updated_at = now() WHERE id = $1", [groupId]);
      if (!rowCount) throw new ApiError("not_found", "Group not found");
    }
  };
}
