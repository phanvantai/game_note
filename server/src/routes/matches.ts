import type { FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { requireLeagueEditor } from "../access.js";
import type { AppDeps } from "../app.js";
import { tx } from "../db.js";
import { ApiError, notFound } from "../errors.js";
import { caller, isoDate, parse } from "../http.js";
import { newId } from "../ids.js";
import { matchJson, usersByIds, type MatchRow } from "../rows.js";
import { ensureStatRows, findLeague, leagueSnapshot, listMatches } from "../domain/league-data.js";

type LeagueParams = { Params: { id: string } };
type MatchParams = { Params: { id: string; matchId: string } };

const PING_INTERVAL_MS = 25_000;
// Coalesces bursts (e.g. a score save touching match + next knockout slot).
const SNAPSHOT_DEBOUNCE_MS = 30;

const score = z.number().int().min(0);
const money = z.number().int().min(0);

export function matchRoutes({ db, events }: AppDeps): FastifyPluginAsync {
  return async (app) => {
    app.get<LeagueParams>("/v1/leagues/:id/matches", async (req) => {
      caller(req);
      if (!(await findLeague(db, req.params.id))) throw notFound("League");
      return listMatches(db, req.params.id);
    });

    app.post<LeagueParams>("/v1/leagues/:id/matches", async (req) => {
      const { uid } = caller(req);
      const body = parse(
        z.object({
          homeTeamId: z.string(),
          awayTeamId: z.string(),
          homeScore: score.nullable().default(0),
          awayScore: score.nullable().default(0),
          date: isoDate.optional(),
          isFinished: z.boolean().default(false),
          matchCost: money.nullable().default(null),
          costPerGoal: money.nullable().default(null),
          phase: z.enum(["group", "knockout"]).nullable().default(null),
          groupId: z.string().nullable().default(null),
          knockoutRound: z.number().int().nullable().default(null),
          knockoutSlot: z.number().int().nullable().default(null),
          nextMatchId: z.string().nullable().default(null),
          matchday: z.number().int().nullable().default(null),
        }),
        req.body,
      );
      await requireLeagueEditor(db, req.params.id, uid);
      const { rows } = await db.query<MatchRow>(
        `INSERT INTO matches (id, league_id, home_team_id, away_team_id, home_score, away_score, date,
           is_finished, match_cost, cost_per_goal, phase, group_label, knockout_round, knockout_slot,
           next_match_id, matchday, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, coalesce($7, now()), $8, $9, $10, $11, $12, $13, $14, $15, $16,
           date_trunc('milliseconds', clock_timestamp()))
         RETURNING *`,
        [
          newId(), req.params.id, body.homeTeamId, body.awayTeamId, body.homeScore, body.awayScore,
          body.date ?? null, body.isFinished, body.matchCost, body.costPerGoal, body.phase, body.groupId,
          body.knockoutRound, body.knockoutSlot, body.nextMatchId, body.matchday,
        ],
      );
      events.publish(req.params.id);
      const match = rows[0]!;
      return matchJson(match, await usersByIds(db, [match.home_team_id, match.away_team_id]));
    });

    // Score / cost edit. The row lock makes the version check and every
    // derived write (next knockout slot) atomic; standings are derived from
    // matches, so there is nothing else to keep in sync.
    app.patch<MatchParams>("/v1/leagues/:id/matches/:matchId", async (req) => {
      const { uid } = caller(req);
      const body = parse(
        z.object({
          homeScore: score.nullish(),
          awayScore: score.nullish(),
          matchCost: money.nullish(),
          costPerGoal: money.nullish(),
          expectedUpdatedAt: isoDate.nullable(),
        }),
        req.body,
      );
      const updated = await tx(db, async (c) => {
        await requireLeagueEditor(c, req.params.id, uid);
        const { rows } = await c.query<MatchRow>(
          "SELECT * FROM matches WHERE id = $1 AND league_id = $2 FOR UPDATE",
          [req.params.matchId, req.params.id],
        );
        const current = rows[0];
        if (!current) throw notFound("Match");

        const expected = body.expectedUpdatedAt?.getTime() ?? null;
        if ((current.updated_at?.getTime() ?? null) !== expected) {
          throw new ApiError("concurrent_update", `Match ${current.id} was updated by someone else`);
        }

        const homeScore = body.homeScore ?? current.home_score;
        const awayScore = body.awayScore ?? current.away_score;
        const isFinished = body.homeScore != null && body.awayScore != null ? true : current.is_finished;

        if (current.phase === "knockout" && isFinished && current.next_match_id) {
          const winner = (homeScore ?? 0) >= (awayScore ?? 0) ? current.home_team_id : current.away_team_id;
          const column = (current.knockout_slot ?? 0) % 2 === 0 ? "home_team_id" : "away_team_id";
          const { rowCount } = await c.query(
            `UPDATE matches SET ${column} = $3 WHERE id = $1 AND league_id = $2`,
            [current.next_match_id, req.params.id, winner],
          );
          if (!rowCount) throw notFound("Next knockout match");
        }
        if (current.phase !== "knockout") {
          // Score entry used to fail when a side had no standings row; create
          // it instead so the result always counts.
          await ensureStatRows(
            c,
            req.params.id,
            [current.home_team_id, current.away_team_id].map((userId) => ({ userId, groupLabel: current.group_label })),
          );
        }

        const { rows: out } = await c.query<MatchRow>(
          `UPDATE matches SET home_score = $2, away_score = $3, is_finished = $4,
             match_cost = coalesce($5, match_cost), cost_per_goal = coalesce($6, cost_per_goal),
             -- Strictly increasing, so two saves in the same millisecond
             -- still get distinct versions.
             updated_at = greatest(date_trunc('milliseconds', clock_timestamp()),
                                   coalesce(updated_at, '-infinity') + interval '1 millisecond')
           WHERE id = $1 RETURNING *`,
          [current.id, homeScore, awayScore, isFinished, body.matchCost ?? null, body.costPerGoal ?? null],
        );
        return out[0]!;
      });
      events.publish(req.params.id);
      return matchJson(updated, await usersByIds(db, [updated.home_team_id, updated.away_team_id]));
    });

    app.delete<MatchParams>("/v1/leagues/:id/matches/:matchId", async (req, reply) => {
      const { uid } = caller(req);
      await requireLeagueEditor(db, req.params.id, uid);
      await db.query("DELETE FROM matches WHERE id = $1 AND league_id = $2", [req.params.matchId, req.params.id]);
      events.publish(req.params.id);
      return reply.status(204).send();
    });

    // Server-Sent Events: a full snapshot on connect and after every change.
    // Snapshots are small for a friend group, and sending whole state keeps
    // the client trivially consistent (no diff merging, no ordering bugs).
    app.get<LeagueParams>("/v1/leagues/:id/events", async (req, reply) => {
      caller(req);
      const leagueId = req.params.id;
      reply.hijack();
      const res = reply.raw;
      res.writeHead(200, {
        "content-type": "text/event-stream; charset=utf-8",
        "cache-control": "no-cache, no-transform",
        connection: "keep-alive",
        "x-accel-buffering": "no",
      });

      let closed = false;
      let sending = false;
      let dirty = false;
      let timer: NodeJS.Timeout | null = null;

      const send = async () => {
        if (sending) {
          dirty = true;
          return;
        }
        sending = true;
        try {
          do {
            dirty = false;
            const snapshot = await leagueSnapshot(db, leagueId);
            if (closed) return;
            res.write(`event: snapshot\ndata: ${JSON.stringify(snapshot)}\n\n`);
          } while (dirty && !closed);
        } catch (err) {
          req.log.error(err);
          res.end();
        } finally {
          sending = false;
        }
      };
      const schedule = () => {
        if (timer) return;
        timer = setTimeout(() => {
          timer = null;
          void send();
        }, SNAPSHOT_DEBOUNCE_MS);
      };

      const unsubscribe = events.subscribe(leagueId, schedule);
      const ping = setInterval(() => res.write(": ping\n\n"), PING_INTERVAL_MS);
      req.raw.on("close", () => {
        closed = true;
        unsubscribe();
        clearInterval(ping);
        if (timer) clearTimeout(timer);
      });

      await send();
    });
  };
}
