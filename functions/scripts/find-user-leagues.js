#!/usr/bin/env node
//
// Ad-hoc query: list every league a user is still a participant of,
// optionally scoped to one group. Uses the Firebase Admin SDK so it
// reads prod data directly — no client build required.
//
// Auth: pick whichever is convenient.
//   1. `gcloud auth application-default login` (one-time, easiest)
//   2. `GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json node ...`
//
// Usage:
//   node functions/scripts/find-user-leagues.js <userId> [groupId]
//
// Examples:
//   node functions/scripts/find-user-leagues.js BRneAq6lUXOFeSaFh20V5M0o6A42
//   node functions/scripts/find-user-leagues.js BRneAq6lUXOFeSaFh20V5M0o6A42 G1abc

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

const PROJECT_ID = "gamenoteapp";

initializeApp({
  credential: applicationDefault(),
  projectId: PROJECT_ID,
});

const db = getFirestore();

async function findLeagues(userId, groupId) {
  let q = db.collection("esports_leagues")
      .where("participants", "array-contains", userId);
  if (groupId) q = q.where("groupId", "==", groupId);
  const snap = await q.get();

  if (snap.empty) {
    console.log(`No leagues found for user=${userId}` +
        (groupId ? ` group=${groupId}` : ""));
    return;
  }

  console.log(`Found ${snap.size} league(s):\n`);
  console.log(
      "leagueId".padEnd(22),
      "isActive".padEnd(9),
      "status".padEnd(10),
      "groupId".padEnd(22),
      "name",
  );
  console.log("-".repeat(100));
  for (const doc of snap.docs) {
    const d = doc.data();
    console.log(
        doc.id.padEnd(22),
        String(d.isActive).padEnd(9),
        String(d.status || "-").padEnd(10),
        String(d.groupId || "-").padEnd(22),
        d.name || "(no name)",
    );
  }
}

async function findGroup(userId) {
  // Quick scan: report which groups this user is a member of, helpful
  // when you don't remember the groupId.
  const snap = await db.collection("esports_groups")
      .where("members", "array-contains", userId).get();
  if (snap.empty) return;
  console.log(`\nGroup memberships for ${userId}:`);
  for (const doc of snap.docs) {
    const d = doc.data();
    console.log(`  ${doc.id} | ${d.groupName || "(no name)"}`);
  }
}

(async () => {
  const [, , userId, groupId] = process.argv;
  if (!userId) {
    console.error("Usage: node find-user-leagues.js <userId> [groupId]");
    process.exit(2);
  }
  await findLeagues(userId, groupId);
  await findGroup(userId);
  process.exit(0);
})().catch((err) => {
  console.error("ERROR:", err.message);
  process.exit(1);
});
