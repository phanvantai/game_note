import { buildApp } from "./app.js";
import { firebaseVerifier } from "./auth.js";
import { loadConfig } from "./config.js";
import { createPool, migrate } from "./db.js";
import { LeagueEvents } from "./events.js";

const config = loadConfig();
const db = createPool(config.databaseUrl);
await migrate(db);

const app = await buildApp({
  db,
  verifyToken: firebaseVerifier(config.firebaseProjectId),
  config,
  events: new LeagueEvents(),
  logger: true,
});

const shutdown = async () => {
  await app.close();
  await db.end();
  process.exit(0);
};
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

await app.listen({ host: "0.0.0.0", port: config.port });
