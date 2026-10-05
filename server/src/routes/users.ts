import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { isGroupMember } from "../access.js";
import type { AppDeps } from "../app.js";
import { forbidden, notFound } from "../errors.js";
import { caller, idList, parse } from "../http.js";
import { newId } from "../ids.js";
import { findGroup, userJson, usersByIds, type UserRow } from "../rows.js";
import { groupSummary, userH2H, userSummary } from "../domain/summaries.js";

const optionalText = z.string().nullish();

export function userRoutes({ db }: AppDeps): FastifyPluginAsync {
  return async (app) => {
    const findUser = async (id: string) => {
      const { rows } = await db.query<UserRow>("SELECT * FROM users WHERE id = $1", [id]);
      return rows[0] ?? null;
    };

    // createUserIfNeeded: the first sign-in creates the row from the Firebase
    // profile; later calls return it untouched.
    app.post("/v1/me/bootstrap", async (req) => {
      const { uid, email } = caller(req);
      const body = parse(
        z.object({
          displayName: optionalText,
          email: optionalText,
          phoneNumber: optionalText,
          photoUrl: optionalText,
        }),
        req.body,
      );
      await db.query(
        `INSERT INTO users (id, display_name, email, phone_number, photo_url)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO NOTHING`,
        [uid, body.displayName ?? null, body.email ?? email, body.phoneNumber ?? null, body.photoUrl ?? null],
      );
      return userJson((await findUser(uid))!);
    });

    app.get("/v1/me", async (req) => {
      const user = await findUser(caller(req).uid);
      if (!user) throw notFound("User");
      return userJson(user);
    });

    app.patch("/v1/me", async (req) => {
      const { uid } = caller(req);
      const body = parse(
        z.object({ displayName: optionalText, phoneNumber: optionalText, email: optionalText }),
        req.body,
      );
      // Empty strings mean "leave unchanged", as in the Firestore version.
      const keep = (v: string | null | undefined) => (v ? v : null);
      const { rows } = await db.query<UserRow>(
        `UPDATE users SET
           display_name = coalesce($2, display_name),
           phone_number = coalesce($3, phone_number),
           email = coalesce($4, email),
           updated_at = now()
         WHERE id = $1 RETURNING *`,
        [uid, keep(body.displayName), keep(body.phoneNumber), keep(body.email)],
      );
      if (!rows[0]) throw notFound("User");
      return userJson(rows[0]);
    });

    app.delete("/v1/me", async (req, reply) => {
      const { rowCount } = await db.query(
        `UPDATE users SET deleted = true, deleted_at = now(), email = NULL,
           phone_number = NULL, updated_at = now()
         WHERE id = $1`,
        [caller(req).uid],
      );
      if (!rowCount) throw notFound("User");
      return reply.status(204).send();
    });

    app.post("/v1/users/batch", async (req) => {
      caller(req);
      const { ids } = parse(z.object({ ids: idList.max(500) }), req.body);
      return { users: [...(await usersByIds(db, ids)).values()] };
    });

    app.get("/v1/users/search", async (req) => {
      const { uid } = caller(req);
      const { q, groupId } = parse(
        z.object({ q: z.string().default(""), groupId: z.string().optional() }),
        req.query,
      );
      let memberFilter: { active: Set<string> } | null = null;
      if (groupId) {
        const group = await findGroup(db, groupId);
        if (!group) throw notFound("Group");
        if (!(await isGroupMember(db, groupId, uid))) throw forbidden("User is not a member of the group");
        const deactivated = new Set(group.deactivated_members);
        memberFilter = { active: new Set(group.members.filter((m) => !deactivated.has(m))) };
      }
      const prefix = `${q.toLowerCase().replace(/[\\%_]/g, (c) => `\\${c}`)}%`;
      const { rows } = await db.query<UserRow>(
        `SELECT * FROM users
         WHERE lower(display_name) LIKE $1 OR lower(email) LIKE $1 OR phone_number LIKE $1
         ORDER BY display_name NULLS LAST, id
         LIMIT 100`,
        [prefix],
      );
      return rows.filter((r) => !memberFilter || memberFilter.active.has(r.id)).map(userJson);
    });

    app.post("/v1/users/placeholders", async (req) => {
      caller(req);
      const { displayName } = parse(z.object({ displayName: z.string().trim().min(1) }), req.body);
      const { rows } = await db.query<UserRow>(
        `INSERT INTO users (id, display_name, is_placeholder) VALUES ($1, $2, true) RETURNING *`,
        [`placeholder_${newId()}`, displayName],
      );
      return userJson(rows[0]!);
    });

    app.get<{ Params: { id: string } }>("/v1/users/:id", async (req) => {
      caller(req);
      const user = await findUser(req.params.id);
      if (!user) throw notFound("User");
      return userJson(user);
    });

    app.get<{ Params: { id: string } }>("/v1/users/:id/summary", async (req) => {
      caller(req);
      return userSummary(db, req.params.id);
    });

    app.get<{ Params: { id: string; opponentId: string } }>(
      "/v1/users/:id/h2h/:opponentId",
      async (req) => {
        caller(req);
        const h2h = await userH2H(db, req.params.id, req.params.opponentId);
        if (!h2h) throw notFound("Head-to-head");
        return h2h;
      },
    );

    app.get<{ Params: { id: string } }>("/v1/groups/:id/summary", async (req) => {
      caller(req);
      if (!(await findGroup(db, req.params.id))) throw notFound("Group");
      return groupSummary(db, req.params.id);
    });
  };
}
