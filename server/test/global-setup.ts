import pg from "pg";
import { migrate } from "../src/db.js";

export const TEST_DATABASE_URL =
  process.env.TEST_DATABASE_URL ?? "postgres://postgres:test@localhost:54329/game_note_test";

/** Fresh schema once per run; individual tests truncate (see helpers.ts). */
export default async function setup() {
  const pool = new pg.Pool({ connectionString: TEST_DATABASE_URL });
  try {
    await pool.query("DROP SCHEMA public CASCADE; CREATE SCHEMA public;");
    await migrate(pool);
  } finally {
    await pool.end();
  }
}
