#!/usr/bin/env node
//
// Comprehensive scan: where is this user still referenced?
// Checks leagues.participants, leagues_stats, leagues_matches,
// group memberships, group summary playerStats, user summary doc.
//
// Usage: node functions/scripts/scan-user-data.js <userId> [groupId]

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp({credential: applicationDefault(), projectId: "gamenoteapp"});
const db = getFirestore();

async function main(userId, groupIdFilter) {
  console.log(`\n=== Scanning user ${userId}${
    groupIdFilter ? ` (group=${groupIdFilter})` : ""} ===\n`);

  // 1. Leagues with user in participants
  let leagueQuery = db.collection("esports_leagues")
      .where("participants", "array-contains", userId);
  if (groupIdFilter) {
    leagueQuery = leagueQuery.where("groupId", "==", groupIdFilter);
  }
  const leagues = await leagueQuery.get();
  console.log(`[participants] ${leagues.size} league(s)`);
  for (const d of leagues.docs) {
    const x = d.data();
    console.log(`  ${d.id} active=${x.isActive} status=${x.status} ` +
        `group=${x.groupId} name="${x.name}"`);
  }

  // 2. Group memberships
  const groups = await db.collection("esports_groups")
      .where("members", "array-contains", userId).get();
  console.log(`\n[group.members] ${groups.size} group(s)`);
  for (const d of groups.docs) {
    console.log(`  ${d.id} name="${d.data().groupName}"`);
  }

  // 3+4. Per-league scan — works without collectionGroup indexes.
  // Determine which leagues to scan: scoped to group (if filter set) or
  // all leagues in groups the user is a member of.
  const targetGroupIds = groupIdFilter ? [groupIdFilter] :
    groups.docs.map((d) => d.id);
  const allLeaguesInGroups = [];
  for (const gid of targetGroupIds) {
    const ls = await db.collection("esports_leagues")
        .where("groupId", "==", gid).get();
    for (const d of ls.docs) allLeaguesInGroups.push(d);
  }
  console.log(`\n[per-league scan] checking ` +
      `${allLeaguesInGroups.length} league(s) across ` +
      `${targetGroupIds.length} group(s)`);

  let staleStats = 0;
  let staleMatches = 0;
  for (const leagueDoc of allLeaguesInGroups) {
    const leagueId = leagueDoc.id;
    const leagueData = leagueDoc.data();
    // Stats subcollection
    const stats = await db.collection("esports_leagues").doc(leagueId)
        .collection("leagues_stats")
        .where("userId", "==", userId).get();
    for (const d of stats.docs) {
      const x = d.data();
      console.log(`  [stats] league=${leagueId} ` +
          `(active=${leagueData.isActive} status=${leagueData.status}) ` +
          `statId=${d.id} M${x.matchesPlayed} W${x.wins}D${x.draws}L${x.losses}`);
      staleStats += 1;
    }
    // Matches: home + away
    const homes = await db.collection("esports_leagues").doc(leagueId)
        .collection("leagues_matches")
        .where("homeTeamId", "==", userId).get();
    const aways = await db.collection("esports_leagues").doc(leagueId)
        .collection("leagues_matches")
        .where("awayTeamId", "==", userId).get();
    for (const d of [...homes.docs, ...aways.docs]) {
      const x = d.data();
      console.log(`  [match] league=${leagueId} matchId=${d.id} ` +
          `${x.homeTeamId}(${x.homeScore}) vs ${x.awayTeamId}(${x.awayScore}) ` +
          `finished=${x.isFinished}`);
      staleMatches += 1;
    }
  }
  console.log(`  → total stale stats=${staleStats} matches=${staleMatches}`);

  // 5. Group summary playerStats — scan known group(s)
  const groupsToCheck = groupIdFilter ? [groupIdFilter] :
    Array.from(new Set(groups.docs.map((d) => d.id)));
  console.log(`\n[group_summary.playerStats] checking ` +
      `${groupsToCheck.length} group(s)`);
  for (const gid of groupsToCheck) {
    const summarySnap = await db.collection("esports_groups")
        .doc(gid).collection("stats").doc("summary").get();
    if (!summarySnap.exists) {
      console.log(`  group=${gid}: no summary doc`);
      continue;
    }
    const players = summarySnap.data().playerStats || [];
    const found = players.find((p) => p.userId === userId);
    if (found) {
      console.log(`  group=${gid}: ❌ STILL PRESENT — ` +
          `M${found.matches} W${found.wins}/D${found.draws}/L${found.losses} ` +
          `champ=${found.championships} runnerUp=${found.runnerUps} ` +
          `finishedJoined=${found.finishedLeaguesJoined}`);
    } else {
      console.log(`  group=${gid}: ✅ not in playerStats ` +
          `(total=${players.length} players)`);
    }
  }

  // 6. User summary doc
  const userSummary = await db.collection("users").doc(userId)
      .collection("stats").doc("summary").get();
  console.log(`\n[users/{uid}/stats/summary] exists=${userSummary.exists}`);
  if (userSummary.exists) {
    const x = userSummary.data();
    console.log(`  M${x.matchesPlayed} W${x.wins}/D${x.draws}/L${x.losses} ` +
        `champ=${x.championCount} runnerUp=${x.runnerUpCount} ` +
        `tournamentsJoined=${x.tournamentsJoined} ` +
        `finished=${x.tournamentsFinished} ` +
        `recentMatches=${(x.recentMatches || []).length} ` +
        `leagueHistory=${(x.leagueHistory || []).length}`);
  }

  console.log("\n=== Done ===");
}

const [, , uid, gid] = process.argv;
if (!uid) {
  console.error("Usage: scan-user-data.js <userId> [groupId]");
  process.exit(2);
}
main(uid, gid).then(() => process.exit(0)).catch((e) => {
  console.error("ERROR:", e.message);
  process.exit(1);
});
