const {onDocumentCreated, onDocumentUpdated, onDocumentWritten} = require("firebase-functions/v2/firestore");

// The Firebase Admin SDK to access Firestore.
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

// logger
const {log, error} = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();
const defaultMessaging = getMessaging();

// Firestore trigger for when a user is added to an esports group
exports.createEsportGroupNotification = onDocumentUpdated("esports_groups/{groupId}", async (event) => {
  const newValue = event.data.after.data();
  const previousValue = event.data.before.data();

  // Check if a new member was added to the group
  const newMembers = newValue.members || [];
  const oldMembers = previousValue.members || [];

  // Find the newly added members
  const addedMembers = newMembers.filter((member) => !oldMembers.includes(member));

  const groupId = event.params.groupId;
  const groupName = newValue.groupName;

  const promises = addedMembers.map((memberId) => {
    const notification = {
      title: "Nhóm mới",
      message: `Bạn đã được thêm vào nhóm ${groupName}`,
      type: "esport_group",
      relatedId: groupId,
      timestamp: FieldValue.serverTimestamp(),
      isRead: false,
      userId: memberId,
    };
    // Add notification to the user's subcollection
    return db
        .collection("users")
        .doc(memberId)
        .collection("notifications")
        .add(notification);
  });
  return Promise.all(promises);
});

// // Firestore trigger for when a user is added to an esports league
exports.createEsportLeagueNotification = onDocumentUpdated("esports_leagues/{leagueId}", async (event) => {
  const newValue = event.data.after.data();
  const previousValue = event.data.before.data();

  // Check if a new participant was added to the league
  const newParticipants = newValue.participants || [];
  const oldParticipants = previousValue.participants || [];

  // Find the newly added participants
  const addedParticipants = newParticipants.filter((participant) => !oldParticipants.includes(participant));

  const leagueId = event.params.leagueId;
  const leagueName = newValue.name;

  const promises = addedParticipants.map((participantId) => {
    const notification = {
      title: "Giải đấu mới",
      message: `Bạn đã được thêm vào giải đấu ${leagueName}`,
      type: "esport_league",
      relatedId: leagueId,
      timestamp: FieldValue.serverTimestamp(),
      isRead: false,
      userId: participantId,
    };

    // Add notification to the user's subcollection
    return db
        .collection("users")
        .doc(participantId)
        .collection("notifications")
        .add(notification);
  });

  return Promise.all(promises);
});

// Firestore trigger for when a notification is created in the user's subcollection
exports.sendPushNotification = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
  const notificationData = event.data.data();
  const userId = event.params.userId;
  const notificationId = event.params.notificationId;

  log(`Sending push notification to user ${userId}`);

  // Fetch the user's FCM token from Firestore
  const userDoc = await db.collection("users").doc(userId).get();
  const fcmToken = userDoc.data().fcmToken; // Use optional chaining to avoid errors

  log(`User ${userId} has FCM token: ${fcmToken}`);

  if (fcmToken && fcmToken.trim() !== "") {
    const message = {
      notification: {
        title: notificationData.title,
        body: notificationData.message,
      },
      token: fcmToken,
      data: {
        // Add any additional data you want to send
        id: notificationId,
        type: notificationData.type,
        relatedId: notificationData.relatedId,
        timestamp: notificationData.timestamp.toString(),
        isRead: notificationData.isRead.toString(),
      },
    };

    // Send the push notification via FCM
    return defaultMessaging.send(message)
        .then((response) => {
          log("Successfully sent push notification:", response);
          return null;
        })
        .catch((err) => {
          error("Error sending push notification:", err);
        });
  }
  return null;
});

// =====================================================================
// Per-user lifetime stats (dashboard)
//
// Single source of truth: `users/{uid}/stats/summary` and
// `users/{uid}/h2h/{opponentUid}`. Maintained incrementally by the
// `onLeagueMatchWritten` trigger, with `onLeagueStatusChanged` handling
// championCount when a league finishes.
//
// Rebuild path: clients write `users/{uid}/stats/_recompute_request` to
// ask for a backfill (used for users who joined before this feature
// shipped); `onRecomputeUserSummaryRequest` consumes the request, folds
// every finished match for that user, and overwrites the summary.
// =====================================================================

const SUMMARY_DOC_ID = "summary";
const RECOMPUTE_REQ_DOC_ID = "_recompute_request";
const RECENT_MATCHES_CAP = 20;
const LEAGUE_HISTORY_CAP = 20;
const SCHEMA_VERSION = 1;
const EVENT_DEDUPE_CAP = 50;

// Compute one user's contribution from a finished match. `sign` is +1 to
// apply, -1 to undo (used to net out a previously-applied score before
// applying a new one when an admin edits the match).
function statContribution(forScore, againstScore, sign) {
  const won = forScore > againstScore ? 1 : 0;
  const drew = forScore === againstScore ? 1 : 0;
  const lost = forScore < againstScore ? 1 : 0;
  return {
    matchesPlayed: sign * 1,
    wins: sign * won,
    draws: sign * drew,
    losses: sign * lost,
    goals: sign * forScore,
    goalsConceded: sign * againstScore,
  };
}

function zeroDelta() {
  return {
    matchesPlayed: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    goals: 0,
    goalsConceded: 0,
  };
}

function sumDelta(a, b) {
  return {
    matchesPlayed: a.matchesPlayed + b.matchesPlayed,
    wins: a.wins + b.wins,
    draws: a.draws + b.draws,
    losses: a.losses + b.losses,
    goals: a.goals + b.goals,
    goalsConceded: a.goalsConceded + b.goalsConceded,
  };
}

function isZeroDelta(d) {
  return d.matchesPlayed === 0 && d.wins === 0 && d.draws === 0 &&
         d.losses === 0 && d.goals === 0 && d.goalsConceded === 0;
}

// Net delta for a single match-write event, from the perspective of one
// side (home or away). `sideKey` is "home" or "away".
function deltaForSide(before, after, sideKey) {
  let undo = zeroDelta();
  let apply = zeroDelta();
  if (before && before.isFinished) {
    undo = sideKey === "home" ?
      statContribution(before.homeScore, before.awayScore, -1) :
      statContribution(before.awayScore, before.homeScore, -1);
  }
  if (after && after.isFinished) {
    apply = sideKey === "home" ?
      statContribution(after.homeScore, after.awayScore, +1) :
      statContribution(after.awayScore, after.homeScore, +1);
  }
  return sumDelta(undo, apply);
}

function userIdsFor(before, after) {
  const m = after || before;
  if (!m) return null;
  return {home: m.homeTeamId, away: m.awayTeamId};
}

async function fetchUserDisplayName(uid) {
  const snap = await db.collection("users").doc(uid).get();
  return (snap.data() || {}).displayName || "";
}

function summaryRef(uid) {
  return db.collection("users").doc(uid).collection("stats").doc(SUMMARY_DOC_ID);
}

function h2hRef(uid, opponentUid) {
  return db.collection("users").doc(uid).collection("h2h").doc(opponentUid);
}

function emptySummary() {
  return {
    matchesPlayed: 0, wins: 0, draws: 0, losses: 0,
    goals: 0, goalsConceded: 0,
    tournamentsJoined: 0, tournamentsFinished: 0,
    championCount: 0, runnerUpCount: 0,
    lastChampionAt: null,
    recentMatches: [],
    leagueHistory: [],
    h2hSummary: [],
    schemaVersion: SCHEMA_VERSION,
    lastEventIds: [],
  };
}

function emptyLeaguePerf(leagueId, leagueName) {
  return {
    leagueId,
    leagueName: leagueName || "",
    lastPlayedAt: null,
    matchesPlayed: 0, wins: 0, draws: 0, losses: 0,
    goals: 0, goalsConceded: 0,
  };
}

// Apply a per-user delta (already net-of-undo) to that user's per-league
// history entry. Stored as an array on the summary doc so reads are free
// — we cap at LEAGUE_HISTORY_CAP entries by lastPlayedAt to bound size.
function applyLeagueHistoryDelta(prev, leagueId, leagueName, delta, after) {
  const arr = [...(prev.leagueHistory || [])];
  let idx = arr.findIndex((e) => e.leagueId === leagueId);
  if (idx === -1) {
    arr.push(emptyLeaguePerf(leagueId, leagueName));
    idx = arr.length - 1;
  }
  const entry = arr[idx];
  const updated = {
    ...entry,
    leagueName: leagueName || entry.leagueName || "",
    matchesPlayed: Math.max(0, (entry.matchesPlayed || 0) + delta.matchesPlayed),
    wins: Math.max(0, (entry.wins || 0) + delta.wins),
    draws: Math.max(0, (entry.draws || 0) + delta.draws),
    losses: Math.max(0, (entry.losses || 0) + delta.losses),
    goals: Math.max(0, (entry.goals || 0) + delta.goals),
    goalsConceded:
      Math.max(0, (entry.goalsConceded || 0) + delta.goalsConceded),
    lastPlayedAt: after && after.isFinished
      ? maxDate(entry.lastPlayedAt, after.date || null)
      : entry.lastPlayedAt,
  };
  arr[idx] = updated;

  // Drop entries that no longer have any matches (an admin un-finished the
  // sole match in that league for this user).
  const cleaned = arr.filter((e) => (e.matchesPlayed || 0) > 0);

  cleaned.sort((a, b) => {
    const am = a.lastPlayedAt && a.lastPlayedAt.toMillis
      ? a.lastPlayedAt.toMillis() : (a.lastPlayedAt
        ? new Date(a.lastPlayedAt).getTime() : 0);
    const bm = b.lastPlayedAt && b.lastPlayedAt.toMillis
      ? b.lastPlayedAt.toMillis() : (b.lastPlayedAt
        ? new Date(b.lastPlayedAt).getTime() : 0);
    return bm - am;
  });
  return cleaned.slice(0, LEAGUE_HISTORY_CAP);
}

function emptyH2H(opponentId, opponentDisplayName) {
  return {
    opponentId,
    opponentDisplayName: opponentDisplayName || "",
    matchesPlayed: 0, wins: 0, draws: 0, losses: 0,
    goals: 0, goalsConceded: 0,
    lastMetAt: null,
  };
}

function applySummaryDelta(prev, delta) {
  return {
    ...prev,
    matchesPlayed: (prev.matchesPlayed || 0) + delta.matchesPlayed,
    wins: (prev.wins || 0) + delta.wins,
    draws: (prev.draws || 0) + delta.draws,
    losses: (prev.losses || 0) + delta.losses,
    goals: (prev.goals || 0) + delta.goals,
    goalsConceded: (prev.goalsConceded || 0) + delta.goalsConceded,
  };
}

function buildRecentEntry(matchAfter, leagueName, uid, opponentDisplayName) {
  const isHome = matchAfter.homeTeamId === uid;
  const userScore = isHome ? matchAfter.homeScore : matchAfter.awayScore;
  const opponentScore = isHome ? matchAfter.awayScore : matchAfter.homeScore;
  const opponentId = isHome ? matchAfter.awayTeamId : matchAfter.homeTeamId;
  let result = "draw";
  if (userScore > opponentScore) result = "win";
  else if (userScore < opponentScore) result = "loss";
  return {
    matchId: matchAfter.id,
    leagueId: matchAfter.leagueId,
    leagueName: leagueName || "",
    date: matchAfter.date || null,
    userScore: userScore || 0,
    opponentScore: opponentScore || 0,
    opponentId: opponentId || "",
    opponentDisplayName: opponentDisplayName || "",
    result,
    // Tracks when the match document was last edited. The dashboard sorts
    // the visible 10 matches by this so an edit to an older fixture
    // bubbles to the top.
    updatedAt: matchAfter.updatedAt || matchAfter.date || null,
  };
}

// Insert a recent-match entry, replacing any existing entry with the same
// matchId, then sort desc by date and cap.
function mergeRecent(existing, entry) {
  if (!entry) return existing || [];
  const filtered = (existing || []).filter((e) => e.matchId !== entry.matchId);
  filtered.push(entry);
  filtered.sort((a, b) => {
    const ad = a.date && a.date.toMillis ? a.date.toMillis() : (a.date ? new Date(a.date).getTime() : 0);
    const bd = b.date && b.date.toMillis ? b.date.toMillis() : (b.date ? new Date(b.date).getTime() : 0);
    return bd - ad;
  });
  return filtered.slice(0, RECENT_MATCHES_CAP);
}

function removeRecent(existing, matchId) {
  return (existing || []).filter((e) => e.matchId !== matchId);
}

// Idempotency: keep a small ring of recently-applied event ids on the
// summary doc. If a Cloud Function retry fires the same event, we'll see
// the id and bail out before double-applying the delta.
function bumpEventLog(prev, eventId) {
  const log = (prev.lastEventIds || []).filter((id) => id !== eventId);
  log.push(eventId);
  return log.slice(-EVENT_DEDUPE_CAP);
}

function alreadyProcessed(prev, eventId) {
  return (prev.lastEventIds || []).includes(eventId);
}

// ---------------------------------------------------------------------
// Trigger: a match write fans out to summary + h2h for both players.
// ---------------------------------------------------------------------
exports.onLeagueMatchWritten = onDocumentWritten(
    "esports_leagues/{leagueId}/leagues_matches/{matchId}",
    async (event) => {
      const before = event.data.before.exists ? event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;

      const ids = userIdsFor(before, after);
      if (!ids) return null;
      const {home, away} = ids;

      const homeDelta = deltaForSide(before, after, "home");
      const awayDelta = deltaForSide(before, after, "away");

      if (isZeroDelta(homeDelta) && isZeroDelta(awayDelta) &&
        // Even a status flip without a stats delta should still keep the
        // recentMatches list in sync (e.g. an unfinished match shouldn't
        // appear there). Treat as a no-op only when nothing meaningful
        // changed.
        !(after && after.isFinished) && !(before && before.isFinished)) {
        return null;
      }

      const leagueId = event.params.leagueId;
      const leagueDoc = await db.collection("esports_leagues").doc(leagueId).get();
      const leagueName = (leagueDoc.data() || {}).name || "";

      const [homeName, awayName] = await Promise.all([
        fetchUserDisplayName(home),
        fetchUserDisplayName(away),
      ]);

      const eventId = event.id;
      const matchId = event.params.matchId;
      const matchAfterWithIds = after ? {...after, id: matchId, leagueId} : null;

      await Promise.all([
        applyToSummary({
          uid: home, opponentUid: away, opponentName: awayName,
          delta: homeDelta, after: matchAfterWithIds, before,
          leagueId, leagueName, eventId,
        }),
        applyToSummary({
          uid: away, opponentUid: home, opponentName: homeName,
          delta: awayDelta, after: matchAfterWithIds, before,
          leagueId, leagueName, eventId,
        }),
        applyToH2H({
          uid: home, opponentUid: away, opponentName: awayName,
          delta: homeDelta, matchAfter: matchAfterWithIds, eventId,
        }),
        applyToH2H({
          uid: away, opponentUid: home, opponentName: homeName,
          delta: awayDelta, matchAfter: matchAfterWithIds, eventId,
        }),
      ]);

      return null;
    },
);

async function applyToSummary({uid, delta, after, before, leagueId, leagueName, opponentName, eventId}) {
  const ref = summaryRef(uid);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptySummary();

    if (alreadyProcessed(prev, eventId)) return;

    const next = applySummaryDelta(prev, delta);

    let recent = prev.recentMatches || [];
    if (after && after.isFinished) {
      const entry = buildRecentEntry(after, leagueName, uid, opponentName);
      recent = mergeRecent(recent, entry);
    } else if (before) {
      // Match was un-finished or deleted — remove the corresponding entry.
      recent = removeRecent(recent, after ? after.id : (before.id || ""));
    }
    next.recentMatches = recent;

    if (leagueId) {
      next.leagueHistory = applyLeagueHistoryDelta(
          prev, leagueId, leagueName, delta, after,
      );
    } else {
      next.leagueHistory = prev.leagueHistory || [];
    }

    next.schemaVersion = SCHEMA_VERSION;
    next.lastEventIds = bumpEventLog(prev, eventId);
    next.updatedAt = FieldValue.serverTimestamp();

    txn.set(ref, next, {merge: true});
  });
}

async function applyToH2H({uid, opponentUid, opponentName, delta, matchAfter, eventId}) {
  if (!opponentUid) return;
  const ref = h2hRef(uid, opponentUid);
  let nextH2H = null;
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptyH2H(opponentUid, opponentName);

    if (alreadyProcessed(prev, eventId)) return;

    nextH2H = {
      ...prev,
      opponentId: opponentUid,
      opponentDisplayName: opponentName || prev.opponentDisplayName || "",
      matchesPlayed: (prev.matchesPlayed || 0) + delta.matchesPlayed,
      wins: (prev.wins || 0) + delta.wins,
      draws: (prev.draws || 0) + delta.draws,
      losses: (prev.losses || 0) + delta.losses,
      goals: (prev.goals || 0) + delta.goals,
      goalsConceded: (prev.goalsConceded || 0) + delta.goalsConceded,
      lastMetAt: matchAfter && matchAfter.isFinished ?
        (matchAfter.date || prev.lastMetAt) :
        prev.lastMetAt,
      lastEventIds: bumpEventLog(prev, eventId),
      updatedAt: FieldValue.serverTimestamp(),
    };
    txn.set(ref, nextH2H, {merge: true});
  });

  // Mirror the new h2h aggregate into the summary doc's embedded list so
  // the dashboard can render the "đối đầu" section with one read.
  if (nextH2H !== null) {
    await mirrorH2HToSummary(uid, opponentUid, nextH2H);
  }
}

async function mirrorH2HToSummary(uid, opponentUid, h2h) {
  const ref = summaryRef(uid);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptySummary();
    const list = [...(prev.h2hSummary || [])];
    const idx = list.findIndex((e) => e.opponentId === opponentUid);
    const entry = {
      opponentId: opponentUid,
      opponentDisplayName: h2h.opponentDisplayName || "",
      matchesPlayed: h2h.matchesPlayed || 0,
      wins: h2h.wins || 0,
      draws: h2h.draws || 0,
      losses: h2h.losses || 0,
    };
    if (entry.matchesPlayed <= 0) {
      // Drop entries that no longer have any matches (admin un-finished
      // the only fixture between the two players).
      if (idx !== -1) list.splice(idx, 1);
    } else if (idx === -1) {
      list.push(entry);
    } else {
      list[idx] = entry;
    }
    txn.set(ref, {h2hSummary: list}, {merge: true});
  });
}

// ---------------------------------------------------------------------
// Trigger: league status changes — bump championCount/runnerUpCount.
// ---------------------------------------------------------------------
exports.onLeagueStatusChanged = onDocumentUpdated(
    "esports_leagues/{leagueId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before || !after) return null;
      if (before.status === after.status) return null;

      const leagueId = event.params.leagueId;
      const eventId = event.id;

      if (after.status === "finished" && before.status !== "finished") {
        await applyChampionRunnerUp(leagueId, after, eventId, +1);
      } else if (before.status === "finished" && after.status !== "finished") {
        await applyChampionRunnerUp(leagueId, before, eventId, -1);
      }

      return null;
    },
);

async function applyChampionRunnerUp(leagueId, leagueData, eventId, sign) {
  const statsSnap = await db
      .collection("esports_leagues")
      .doc(leagueId)
      .collection("leagues_stats")
      .get();
  if (statsSnap.empty) return;

  const stats = statsSnap.docs.map((d) => d.data());
  stats.sort((a, b) => {
    const ap = (a.wins || 0) * 3 + (a.draws || 0);
    const bp = (b.wins || 0) * 3 + (b.draws || 0);
    if (ap !== bp) return bp - ap;
    const agd = (a.goals || 0) - (a.goalsConceded || 0);
    const bgd = (b.goals || 0) - (b.goalsConceded || 0);
    if (agd !== bgd) return bgd - agd;
    return (b.goals || 0) - (a.goals || 0);
  });

  const champion = stats[0];
  const runnerUp = stats[1];

  const championAt = leagueData.endDate || leagueData.startDate || null;

  await Promise.all([
    champion ? bumpTournamentCounts({
      uid: champion.userId,
      championDelta: sign,
      finishedDelta: sign,
      championAt,
      eventId,
    }) : Promise.resolve(),
    runnerUp ? bumpTournamentCounts({
      uid: runnerUp.userId,
      runnerUpDelta: sign,
      finishedDelta: 0, // counted by champion path; avoid double
      eventId,
    }) : Promise.resolve(),
  ].concat(
      stats.slice(2).map((s) => bumpTournamentCounts({
        uid: s.userId,
        finishedDelta: 0, // see comment below
        eventId,
      })),
  ));
}

// `finishedDelta` is conceptually "did this league count as finished for
// the user?" — here we count it once for the champion to keep the
// numerator/denominator math simple in `championRate`. Other participants
// already see the league reflected in `tournamentsFinished` because the
// summary is built from raw matches: the recompute path counts every
// participant in every finished league. For the incremental trigger we
// approximate by bumping for everyone in the standings.
async function bumpTournamentCounts({
  uid, championDelta = 0, runnerUpDelta = 0, finishedDelta = 0, championAt = null, eventId,
}) {
  if (!uid) return;
  const ref = summaryRef(uid);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptySummary();
    if (alreadyProcessed(prev, eventId)) return;

    const next = {
      ...prev,
      championCount: Math.max(0, (prev.championCount || 0) + championDelta),
      runnerUpCount: Math.max(0, (prev.runnerUpCount || 0) + runnerUpDelta),
      tournamentsFinished: Math.max(0, (prev.tournamentsFinished || 0) + finishedDelta),
      lastChampionAt: championDelta > 0 && championAt ?
        maxDate(prev.lastChampionAt, championAt) :
        prev.lastChampionAt,
      lastEventIds: bumpEventLog(prev, eventId),
      updatedAt: FieldValue.serverTimestamp(),
    };
    txn.set(ref, next, {merge: true});
  });
}

function maxDate(a, b) {
  if (!a) return b;
  if (!b) return a;
  const am = a.toMillis ? a.toMillis() : new Date(a).getTime();
  const bm = b.toMillis ? b.toMillis() : new Date(b).getTime();
  return am >= bm ? a : b;
}

// ---------------------------------------------------------------------
// Trigger: client requests a backfill via `users/{uid}/stats/_recompute_request`.
// Folds every finished match in every league the user has joined into a
// fresh summary doc + h2h docs. Used for users created before this feature
// shipped, or after a schema bump.
// ---------------------------------------------------------------------
exports.onRecomputeUserSummaryRequest = onDocumentCreated(
    "users/{uid}/stats/_recompute_request",
    async (event) => {
      const uid = event.params.uid;
      log(`recomputeUserSummary: start uid=${uid}`);

      try {
        const summary = emptySummary();
        const h2hMap = new Map(); // opponentUid -> aggregate

        // Find leagues this user participates in. Mirror the client-side
        // `getMyLeagues()` filter: only count active leagues — a
        // soft-deleted league shouldn't show up in tournamentsJoined.
        const leaguesSnap = await db
            .collection("esports_leagues")
            .where("isActive", "==", true)
            .where("participants", "array-contains", uid)
            .get();

        summary.tournamentsJoined = leaguesSnap.size;

        for (const leagueDoc of leaguesSnap.docs) {
          const league = leagueDoc.data();
          const leagueId = leagueDoc.id;
          const leagueName = league.name || "";
          const leaguePerf = emptyLeaguePerf(leagueId, leagueName);

          const matchesSnap = await db
              .collection("esports_leagues").doc(leagueId)
              .collection("leagues_matches")
              .where("isFinished", "==", true)
              .get();

          for (const matchDoc of matchesSnap.docs) {
            const m = matchDoc.data();
            const isHome = m.homeTeamId === uid;
            if (!isHome && m.awayTeamId !== uid) continue;
            const opponentUid = isHome ? m.awayTeamId : m.homeTeamId;
            const userScore = isHome ? m.homeScore : m.awayScore;
            const oppScore = isHome ? m.awayScore : m.homeScore;
            const contrib = statContribution(userScore, oppScore, +1);
            summary.matchesPlayed += contrib.matchesPlayed;
            summary.wins += contrib.wins;
            summary.draws += contrib.draws;
            summary.losses += contrib.losses;
            summary.goals += contrib.goals;
            summary.goalsConceded += contrib.goalsConceded;

            leaguePerf.matchesPlayed += contrib.matchesPlayed;
            leaguePerf.wins += contrib.wins;
            leaguePerf.draws += contrib.draws;
            leaguePerf.losses += contrib.losses;
            leaguePerf.goals += contrib.goals;
            leaguePerf.goalsConceded += contrib.goalsConceded;
            leaguePerf.lastPlayedAt =
              maxDate(leaguePerf.lastPlayedAt, m.date || null);

            const opponentName = await fetchUserDisplayName(opponentUid);
            const entry = buildRecentEntry(
                {...m, id: matchDoc.id, leagueId},
                leagueName, uid, opponentName,
            );
            summary.recentMatches = mergeRecent(summary.recentMatches, entry);

            const h2h = h2hMap.get(opponentUid) || emptyH2H(opponentUid, opponentName);
            h2h.matchesPlayed += contrib.matchesPlayed;
            h2h.wins += contrib.wins;
            h2h.draws += contrib.draws;
            h2h.losses += contrib.losses;
            h2h.goals += contrib.goals;
            h2h.goalsConceded += contrib.goalsConceded;
            h2h.lastMetAt = maxDate(h2h.lastMetAt, m.date || null);
            h2h.opponentDisplayName = opponentName || h2h.opponentDisplayName;
            h2hMap.set(opponentUid, h2h);
          }

          // Standings → champion / runner-up
          if (league.status === "finished") {
            const statsSnap = await db
                .collection("esports_leagues").doc(leagueId)
                .collection("leagues_stats")
                .get();
            const stats = statsSnap.docs.map((d) => d.data());
            stats.sort((a, b) => {
              const ap = (a.wins || 0) * 3 + (a.draws || 0);
              const bp = (b.wins || 0) * 3 + (b.draws || 0);
              if (ap !== bp) return bp - ap;
              const agd = (a.goals || 0) - (a.goalsConceded || 0);
              const bgd = (b.goals || 0) - (b.goalsConceded || 0);
              if (agd !== bgd) return bgd - agd;
              return (b.goals || 0) - (a.goals || 0);
            });
            const rank = stats.findIndex((s) => s.userId === uid);
            if (rank !== -1) {
              summary.tournamentsFinished += 1;
              if (rank === 0) {
                summary.championCount += 1;
                summary.lastChampionAt = maxDate(
                    summary.lastChampionAt,
                    league.endDate || league.startDate || null,
                );
              } else if (rank === 1) {
                summary.runnerUpCount += 1;
              }
            }
          }

          if (leaguePerf.matchesPlayed > 0) {
            summary.leagueHistory.push(leaguePerf);
          }
        }

        // Sort by lastPlayedAt desc + cap.
        summary.leagueHistory.sort((a, b) => {
          const am = a.lastPlayedAt && a.lastPlayedAt.toMillis
            ? a.lastPlayedAt.toMillis()
            : (a.lastPlayedAt ? new Date(a.lastPlayedAt).getTime() : 0);
          const bm = b.lastPlayedAt && b.lastPlayedAt.toMillis
            ? b.lastPlayedAt.toMillis()
            : (b.lastPlayedAt ? new Date(b.lastPlayedAt).getTime() : 0);
          return bm - am;
        });
        summary.leagueHistory =
          summary.leagueHistory.slice(0, LEAGUE_HISTORY_CAP);

        // Embedded compact h2h list for the dashboard "đối đầu" section.
        summary.h2hSummary = [];
        for (const [opponentUid, agg] of h2hMap.entries()) {
          if ((agg.matchesPlayed || 0) <= 0) continue;
          summary.h2hSummary.push({
            opponentId: opponentUid,
            opponentDisplayName: agg.opponentDisplayName || "",
            matchesPlayed: agg.matchesPlayed || 0,
            wins: agg.wins || 0,
            draws: agg.draws || 0,
            losses: agg.losses || 0,
          });
        }

        summary.updatedAt = FieldValue.serverTimestamp();
        summary.schemaVersion = SCHEMA_VERSION;

        const batch = db.batch();
        batch.set(summaryRef(uid), summary);
        for (const [opponentUid, agg] of h2hMap.entries()) {
          agg.updatedAt = FieldValue.serverTimestamp();
          batch.set(h2hRef(uid, opponentUid), agg);
        }
        // Consume the request.
        batch.delete(
            db.collection("users").doc(uid).collection("stats").doc(RECOMPUTE_REQ_DOC_ID),
        );
        await batch.commit();
        log(`recomputeUserSummary: done uid=${uid} matches=${summary.matchesPlayed}`);
      } catch (err) {
        error(`recomputeUserSummary failed for uid=${uid}`, err);
      // Leave the request doc in place so a retry / manual re-run can pick it up.
      }
      return null;
    },
);
