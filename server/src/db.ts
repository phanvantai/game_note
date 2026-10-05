import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";

// COUNT(*) and other int8 results come back as strings by default.
pg.types.setTypeParser(pg.types.builtins.INT8, (v) => Number(v));

export type Db = pg.Pool;
export type Queryable = pg.Pool | pg.PoolClient;

export function createPool(connectionString: string): Db {
  return new pg.Pool({ connectionString, max: 10 });
}

/** Runs [fn] inside a transaction, rolling back on any thrown error. */
export async function tx<T>(db: Db, fn: (client: pg.PoolClient) => Promise<T>): Promise<T> {
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

const migrationsDir = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  // src/ in dev and tests, dist/src/ once compiled.
  import.meta.url.includes("/dist/") ? "../../migrations" : "../migrations",
);

/** Applies every migrations/*.sql file not yet recorded, in name order. */
export async function migrate(db: Db): Promise<void> {
  await db.query(
    "CREATE TABLE IF NOT EXISTS schema_migrations (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())",
  );
  const files = (await readdir(migrationsDir)).filter((f) => f.endsWith(".sql")).sort();
  for (const name of files) {
    const { rowCount } = await db.query("SELECT 1 FROM schema_migrations WHERE name = $1", [name]);
    if (rowCount) continue;
    const sql = await readFile(path.join(migrationsDir, name), "utf8");
    await tx(db, async (c) => {
      await c.query(sql);
      await c.query("INSERT INTO schema_migrations (name) VALUES ($1)", [name]);
    });
  }
}
