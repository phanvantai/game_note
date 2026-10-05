import multipart from "@fastify/multipart";
import Fastify, { type FastifyInstance } from "fastify";
import type { TokenVerifier } from "./auth.js";
import type { Config } from "./config.js";
import type { Db } from "./db.js";
import { ApiError } from "./errors.js";
import type { LeagueEvents } from "./events.js";
import { avatarRoutes } from "./routes/avatars.js";
import { groupRoutes } from "./routes/groups.js";
import { leagueRoutes } from "./routes/leagues.js";
import { matchRoutes } from "./routes/matches.js";
import { userRoutes } from "./routes/users.js";

export interface AppDeps {
  db: Db;
  verifyToken: TokenVerifier;
  config: Pick<Config, "publicBaseUrl" | "avatarDir">;
  events: LeagueEvents;
  logger?: boolean;
}

export async function buildApp(deps: AppDeps): Promise<FastifyInstance> {
  const app = Fastify({ logger: deps.logger ?? false, bodyLimit: 1024 * 1024 });

  app.decorateRequest("auth", null);
  await app.register(multipart, { limits: { fileSize: 5 * 1024 * 1024, files: 1 } });

  app.addHook("onRequest", async (req) => {
    if (!req.url.startsWith("/v1/")) return;
    const header = req.headers.authorization;
    if (!header?.startsWith("Bearer ")) throw new ApiError("unauthenticated", "Missing bearer token");
    req.auth = await deps.verifyToken(header.slice("Bearer ".length));
  });

  app.setErrorHandler((err, req, reply) => {
    if (err instanceof ApiError) {
      return reply.status(err.statusCode).send({ error: err.code, message: err.message });
    }
    const status = (err as { statusCode?: number }).statusCode;
    if (status && status >= 400 && status < 500) {
      return reply.status(status).send({ error: "validation", message: (err as Error).message });
    }
    req.log.error(err);
    return reply.status(500).send({ error: "internal", message: "Internal server error" });
  });

  app.get("/health", async () => {
    await deps.db.query("SELECT 1");
    return { ok: true };
  });

  await app.register(userRoutes(deps));
  await app.register(avatarRoutes(deps));
  await app.register(groupRoutes(deps));
  await app.register(leagueRoutes(deps));
  await app.register(matchRoutes(deps));

  return app;
}
