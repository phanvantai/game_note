// One-shot Firestore → Postgres import. Replaces everything in the target
// database with the current Firestore data, in one transaction.
//
//   GOOGLE_APPLICATION_CREDENTIALS=./gamenoteapp.service-account.json \
//   DATABASE_URL=postgres://… \
//   PUBLIC_BASE_URL=https://gamenote-api.taiphanvan.dev \
//   npm run import:firestore -- [--dry-run] [--avatars-dir ./avatars]
//
// --avatars-dir downloads every Firebase Storage avatar into that folder and
// rewrites photoUrl to PUBLIC_BASE_URL/avatars/<file>; copy the folder into
// the API's avatar volume afterwards (see deploy/README.md).
// Reads Firestore only; never writes to it.

import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { parseArgs } from "node:util";
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import pg from "pg";
import { migrate, tx } from "../src/db.js";
import { transform, type FirestoreDoc, type FirestoreDump, type ImportRows } from "./transform.js";

const { values: args } = parseArgs({
  options: {
    "dry-run": { type: "boolean", default: false },
    "avatars-dir": { type: "string" },
  },
});

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl && !args["dry-run"]) throw new Error("DATABASE_URL is required (or pass --dry-run)");

initializeApp({ credential: applicationDefault(), projectId: process.env.FIREBASE_PROJECT_ID ?? "gamenoteapp" });
const firestore = getFirestore();

async function docs(ref: FirebaseFirestore.CollectionReference): Promise<FirestoreDoc[]> {
  const snap = await ref.get();
  return snap.docs.map((d) => ({ id: d.id, data: d.data() }));
}

async function dump(): Promise<FirestoreDump> {
  const [users, groups, leagueDocs] = await Promise.all([
    docs(firestore.collection("users")),
    docs(firestore.collection("esports_groups")),
    docs(firestore.collection("esports_leagues")),
  ]);
  const leagues = await Promise.all(
    leagueDocs.map(async (l) => {
      const ref = firestore.collection("esports_leagues").doc(l.id);
      const [matches, stats] = await Promise.all([
        docs(ref.collection("leagues_matches")),
        docs(ref.collection("leagues_stats")),
      ]);
      return { ...l, matches, stats };
    }),
  );
  return { users, groups, leagues };
}

/** Downloads Firebase-hosted avatars and points users at the API copies. */
async function rehostAvatars(rows: ImportRows, dir: string, publicBaseUrl: string) {
  await mkdir(dir, { recursive: true });
  for (const user of rows.users) {
    const [id, , , , photoUrl] = user as [string, unknown, unknown, unknown, string | null];
    if (!photoUrl?.includes("firebasestorage.googleapis.com")) continue;
    try {
      const res = await fetch(photoUrl);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const type = res.headers.get("content-type") ?? "";
      const ext = { "image/png": "png", "image/webp": "webp", "image/gif": "gif", "image/heic": "heic" }[type] ?? "jpg";
      const file = `${id.replace(/[^A-Za-z0-9_-]/g, "_")}-imported.${ext}`;
      await writeFile(path.join(dir, file), Buffer.from(await res.arrayBuffer()));
      user[4] = `${publicBaseUrl}/avatars/${file}`;
    } catch (err) {
      rows.warnings.push(`avatar for ${id} kept as-is: ${(err as Error).message}`);
    }
  }
}

async function insert(client: pg.PoolClient, table: string, columns: string[], rows: unknown[][]) {
  const chunk = 500;
  for (let i = 0; i < rows.length; i += chunk) {
    const part = rows.slice(i, i + chunk);
    const params: unknown[] = [];
    const tuples = part.map((row) => `(${row.map((v) => `$${params.push(v)}`).join(", ")})`);
    await client.query(`INSERT INTO ${table} (${columns.join(", ")}) VALUES ${tuples.join(", ")}`, params);
  }
}

const started = Date.now();
const rows = transform(await dump());
if (args["avatars-dir"]) {
  const base = process.env.PUBLIC_BASE_URL;
  if (!base) throw new Error("PUBLIC_BASE_URL is required with --avatars-dir");
  await rehostAvatars(rows, args["avatars-dir"], base.replace(/\/$/, ""));
}

console.log(
  `users=${rows.users.length} groups=${rows.groups.length} members=${rows.members.length} ` +
    `leagues=${rows.leagues.length} standingsRows=${rows.statRows.length} matches=${rows.matches.length}`,
);
for (const w of rows.warnings) console.warn(`warning: ${w}`);

if (args["dry-run"]) {
  console.log("dry run: nothing written");
} else {
  const db = new pg.Pool({ connectionString: databaseUrl });
  await migrate(db);
  await tx(db, async (c) => {
    await c.query("TRUNCATE users, groups, group_members, leagues, league_stat_rows, matches CASCADE");
    await insert(c, "users", ["id", "display_name", "phone_number", "email", "photo_url", "role", "is_placeholder", "deleted", "deleted_at", "created_at", "updated_at"], rows.users);
    await insert(c, "groups", ["id", "group_name", "owner_id", "description", "status", "created_at", "updated_at"], rows.groups);
    await insert(c, "group_members", ["group_id", "user_id", "position", "deactivated"], rows.members);
    await insert(c, "leagues", ["id", "owner_id", "group_id", "name", "description", "start_date", "end_date", "is_active", "status", "participants", "rank_payout_enabled", "rank_payouts", "default_match_cost", "default_per_goal_enabled", "default_cost_per_goal", "merge_completed", "mode", "group_count", "advance_count", "knockout_seeding", "matchday_count"], rows.leagues);
    await insert(c, "league_stat_rows", ["id", "league_id", "user_id", "group_label"], rows.statRows);
    await insert(c, "matches", ["id", "league_id", "home_team_id", "away_team_id", "home_score", "away_score", "date", "is_finished", "match_cost", "cost_per_goal", "phase", "group_label", "knockout_round", "knockout_slot", "next_match_id", "matchday", "updated_at"], rows.matches);
  });
  await db.end();
  console.log(`imported in ${((Date.now() - started) / 1000).toFixed(1)}s`);
}
