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

      const leagueData = leagueDoc.data() || {};
      const groupId = leagueData.groupId || null;
      // Soft-deleted leagues don't contribute to group summary so the
      // Tổng quan tab matches user dashboard's `isActive == true` rule.
      // (User-level summary still updates — that path filters separately
      // via the `isActive` check in `onRecomputeUserSummaryRequest`.)
      const groupActive = groupId && leagueData.isActive !== false;
      const deactivatedIds = groupActive ?
        await fetchDeactivatedIds(groupId) : new Set();
      const leagueExcluded = groupActive &&
        hasDeactivatedParticipant(leagueData, deactivatedIds);

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
        (groupActive && !leagueExcluded) ? applyMatchDeltaToGroupSummary({
          groupId, uid: home, displayName: homeName, delta: homeDelta, eventId,
        }) : Promise.resolve(),
        (groupActive && !leagueExcluded) ? applyMatchDeltaToGroupSummary({
          groupId, uid: away, displayName: awayName, delta: awayDelta, eventId,
        }) : Promise.resolve(),
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

      let sign = 0;
      let leagueData = null;
      if (after.status === "finished" && before.status !== "finished") {
        sign = +1;
        leagueData = after;
      } else if (before.status === "finished" && after.status !== "finished") {
        sign = -1;
        leagueData = before;
      }

      if (sign !== 0 && leagueData) {
        await Promise.all([
          applyChampionRunnerUp(leagueId, leagueData, eventId, sign),
          applyLeagueFinishedToGroupSummary(
              leagueId, leagueData, eventId, sign,
          ),
        ]);
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

// Fetch the deactivatedMembers set for a group. Returns empty Set when the
// group doc doesn't exist or the field is absent (backward compat).
async function fetchDeactivatedIds(groupId) {
  if (!groupId) return new Set();
  const snap = await db.collection("esports_groups").doc(groupId).get();
  return new Set((snap.data() || {}).deactivatedMembers || []);
}

// Returns true if any of the league's participants is in deactivatedIds.
// When true the entire league is excluded from the group summary.
function hasDeactivatedParticipant(leagueData, deactivatedIds) {
  if (!deactivatedIds.size) return false;
  return (leagueData.participants || []).some((p) => deactivatedIds.has(p));
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

// =====================================================================
// Per-group lifetime stats (group overview tab)
//
// Single source of truth: `esports_groups/{groupId}/stats/summary`.
// Maintained incrementally by `onLeagueMatchWritten`,
// `onLeagueStatusChanged`, and `onEsportLeagueWritten`. Awards
// (vô đối / kẻ về nhì / hoà vương / cao thủ / hàng thủ thép) are
// computed client-side from the playerStats array — keeps the schema
// minimal and lets thresholds change without redeploying functions.
//
// Rebuild path: clients write
// `esports_groups/{groupId}/stats/_recompute_request` — handled by
// `onRecomputeGroupSummaryRequest` below.
// =====================================================================

const GROUP_RECOMPUTE_REQ_DOC_ID = "_recompute_request";

function groupSummaryRef(groupId) {
  return db.collection("esports_groups").doc(groupId)
      .collection("stats").doc(SUMMARY_DOC_ID);
}

function emptyGroupSummary() {
  return {
    totalLeagues: 0,
    finishedLeagues: 0,
    playerStats: [],
    schemaVersion: SCHEMA_VERSION,
    lastEventIds: [],
  };
}

function emptyGroupPlayerEntry(uid, displayName) {
  return {
    userId: uid,
    displayName: displayName || "",
    photoUrl: null,
    matches: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    goals: 0,
    goalsConceded: 0,
    championships: 0,
    runnerUps: 0,
    finishedLeaguesJoined: 0,
  };
}

// Find or create a player entry, applying mutator and clamping at zero.
function upsertPlayer(playerStats, uid, displayName, mutator) {
  const arr = [...(playerStats || [])];
  let idx = arr.findIndex((e) => e.userId === uid);
  let entry;
  if (idx === -1) {
    entry = emptyGroupPlayerEntry(uid, displayName);
    arr.push(entry);
    idx = arr.length - 1;
  } else {
    entry = {...arr[idx]};
    if (displayName && !entry.displayName) entry.displayName = displayName;
  }
  mutator(entry);
  entry.matches = Math.max(0, entry.matches);
  entry.wins = Math.max(0, entry.wins);
  entry.draws = Math.max(0, entry.draws);
  entry.losses = Math.max(0, entry.losses);
  entry.goals = Math.max(0, entry.goals);
  entry.goalsConceded = Math.max(0, entry.goalsConceded);
  entry.championships = Math.max(0, entry.championships);
  entry.runnerUps = Math.max(0, entry.runnerUps);
  entry.finishedLeaguesJoined = Math.max(0, entry.finishedLeaguesJoined);
  arr[idx] = entry;
  // Drop empty rows so the array doesn't accumulate ghosts when a single
  // match is un-finished by an admin and was the only contribution.
  return arr.filter((e) =>
    (e.matches || 0) > 0 ||
    (e.championships || 0) > 0 ||
    (e.runnerUps || 0) > 0 ||
    (e.finishedLeaguesJoined || 0) > 0);
}

async function applyMatchDeltaToGroupSummary(
    {groupId, uid, displayName, delta, eventId},
) {
  if (!groupId || !uid) return;
  if (isZeroDelta(delta)) return;
  const ref = groupSummaryRef(groupId);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptyGroupSummary();
    if (alreadyProcessed(prev, eventId)) return;
    const playerStats = upsertPlayer(prev.playerStats, uid, displayName, (e) => {
      e.matches += delta.matchesPlayed;
      e.wins += delta.wins;
      e.draws += delta.draws;
      e.losses += delta.losses;
      e.goals += delta.goals;
      e.goalsConceded += delta.goalsConceded;
    });
    txn.set(ref, {
      ...prev,
      totalLeagues: prev.totalLeagues || 0,
      finishedLeagues: prev.finishedLeagues || 0,
      playerStats,
      schemaVersion: SCHEMA_VERSION,
      lastEventIds: bumpEventLog(prev, eventId),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

async function applyLeagueFinishedToGroupSummary(
    leagueId, leagueData, eventId, sign,
) {
  const groupId = leagueData.groupId;
  if (!groupId) return;
  // Soft-deleted leagues should not contribute to the group summary,
  // even if their status flips. The isActive transition trigger
  // (`onEsportLeagueWritten`) is responsible for rolling back any
  // championship counts that were applied while the league was active.
  if (leagueData.isActive === false) return;
  const deactivatedIds = await fetchDeactivatedIds(groupId);
  if (hasDeactivatedParticipant(leagueData, deactivatedIds)) return;
  const statsSnap = await db
      .collection("esports_leagues").doc(leagueId)
      .collection("leagues_stats").get();
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
  const championUid = stats[0] ? stats[0].userId : null;
  const runnerUpUid = stats[1] ? stats[1].userId : null;

  // Resolve display names so first-time entries aren't blank.
  const namePromises = {};
  for (const s of stats) {
    if (s.userId && !namePromises[s.userId]) {
      namePromises[s.userId] = fetchUserDisplayName(s.userId);
    }
  }
  const names = {};
  for (const uid of Object.keys(namePromises)) {
    names[uid] = await namePromises[uid];
  }

  const ref = groupSummaryRef(groupId);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptyGroupSummary();
    if (alreadyProcessed(prev, eventId)) return;

    let playerStats = prev.playerStats || [];
    for (const s of stats) {
      const uid = s.userId;
      if (!uid) continue;
      playerStats = upsertPlayer(playerStats, uid, names[uid] || "", (e) => {
        e.finishedLeaguesJoined += sign;
        if (uid === championUid) e.championships += sign;
        if (uid === runnerUpUid) e.runnerUps += sign;
      });
    }

    txn.set(ref, {
      ...prev,
      totalLeagues: prev.totalLeagues || 0,
      finishedLeagues: Math.max(0, (prev.finishedLeagues || 0) + sign),
      playerStats,
      schemaVersion: SCHEMA_VERSION,
      lastEventIds: bumpEventLog(prev, eventId),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

// ---------------------------------------------------------------------
// Trigger: league created or deleted — bump totalLeagues counter on the
// group summary. Status flips finished/!finished are handled separately
// by `onLeagueStatusChanged` so we don't double-count.
// ---------------------------------------------------------------------
exports.onEsportLeagueWritten = onDocumentWritten(
    "esports_leagues/{leagueId}",
    async (event) => {
      const before = event.data.before.exists ? event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;
      const eventId = event.id;
      const leagueId = event.params.leagueId;

      // Created — only count active leagues without deactivated members.
      if (!before && after) {
        if (!after.groupId || after.isActive === false) return null;
        const deactivatedIds = await fetchDeactivatedIds(after.groupId);
        if (hasDeactivatedParticipant(after, deactivatedIds)) return null;
        await bumpGroupTotalLeagues(after.groupId, +1, eventId);
        if (after.status === "finished") {
          // Rare: league created already finished. Mirror finishedLeagues
          // — the championship/runner-up bump is the responsibility of
          // onLeagueStatusChanged, which won't fire on create. Most flows
          // create as 'upcoming' first, so this branch is a safety net.
          await bumpGroupFinishedLeagues(after.groupId, +1, eventId + ":fin");
        }
        return null;
      }

      // Deleted (hard delete) — only decrement if the league was active
      // when it disappeared. Inactive leagues weren't counted anyway.
      if (before && !after) {
        if (!before.groupId || before.isActive === false) return null;
        const deactivatedIds = await fetchDeactivatedIds(before.groupId);
        if (hasDeactivatedParticipant(before, deactivatedIds)) return null;
        await bumpGroupTotalLeagues(before.groupId, -1, eventId);
        if (before.status === "finished") {
          await bumpGroupFinishedLeagues(before.groupId, -1, eventId + ":fin");
        }
        return null;
      }

      if (before && after) {
        // Soft-delete / un-delete transition. Treated like a delete or
        // create from the group summary's perspective: roll back (or
        // re-add) the league's match contributions, championship counts,
        // and counters atomically.
        const wasActive = before.isActive !== false;
        const isActive = after.isActive !== false;
        if (wasActive && !isActive) {
          const deactivatedIds = await fetchDeactivatedIds(before.groupId);
          if (!hasDeactivatedParticipant(before, deactivatedIds)) {
            await applyLeagueActiveTransition(
                leagueId, before, eventId + ":soft-del", -1);
          }
          return null;
        }
        if (!wasActive && isActive) {
          const deactivatedIds = await fetchDeactivatedIds(after.groupId);
          if (!hasDeactivatedParticipant(after, deactivatedIds)) {
            await applyLeagueActiveTransition(
                leagueId, after, eventId + ":undel", +1);
          }
          return null;
        }

        // groupId change — extremely rare, treat as delete + add.
        if (before.groupId !== after.groupId) {
          if (before.groupId && wasActive) {
            const deactivatedIdsBefore =
              await fetchDeactivatedIds(before.groupId);
            if (!hasDeactivatedParticipant(before, deactivatedIdsBefore)) {
              await applyLeagueActiveTransition(
                  leagueId, before, eventId + ":out", -1);
            }
          }
          if (after.groupId && isActive) {
            const deactivatedIdsAfter =
              await fetchDeactivatedIds(after.groupId);
            if (!hasDeactivatedParticipant(after, deactivatedIdsAfter)) {
              await applyLeagueActiveTransition(
                  leagueId, after, eventId + ":in", +1);
            }
          }
        }
      }
      return null;
    },
);

// Soft-delete / un-delete transition for a league. Folds every finished
// match in/out of the group summary's per-player aggregates, then bumps
// totalLeagues and (if applicable) the finished-league counters and
// championships. `sign` is +1 to apply (un-delete), -1 to undo (soft-
// delete). Idempotent via the eventId ring stored on the summary doc.
async function applyLeagueActiveTransition(
    leagueId, leagueData, eventId, sign,
) {
  const groupId = leagueData.groupId;
  if (!groupId) return;

  // 1. Aggregate per-player delta from every finished match.
  const matchesSnap = await db.collection("esports_leagues")
      .doc(leagueId).collection("leagues_matches")
      .where("isFinished", "==", true).get();

  // Map<uid, {displayName, delta}> — built once, applied in one txn.
  const playerDeltas = new Map();
  const ensure = (uid) => {
    if (!playerDeltas.has(uid)) {
      playerDeltas.set(uid, {displayName: "", delta: zeroDelta()});
    }
    return playerDeltas.get(uid);
  };
  for (const matchDoc of matchesSnap.docs) {
    const m = matchDoc.data();
    if (!m.homeTeamId || !m.awayTeamId) continue;
    const homeContrib = statContribution(
        m.homeScore || 0, m.awayScore || 0, sign);
    const awayContrib = statContribution(
        m.awayScore || 0, m.homeScore || 0, sign);
    const homeEntry = ensure(m.homeTeamId);
    homeEntry.delta = sumDelta(homeEntry.delta, homeContrib);
    const awayEntry = ensure(m.awayTeamId);
    awayEntry.delta = sumDelta(awayEntry.delta, awayContrib);
  }

  // Resolve display names so freshly-added rows aren't blank.
  for (const uid of Array.from(playerDeltas.keys())) {
    playerDeltas.get(uid).displayName = await fetchUserDisplayName(uid);
  }

  // 2. Apply player deltas + totalLeagues bump in one transaction.
  const ref = groupSummaryRef(groupId);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptyGroupSummary();
    if (alreadyProcessed(prev, eventId)) return;

    let playerStats = prev.playerStats || [];
    for (const [uid, info] of playerDeltas.entries()) {
      const d = info.delta;
      if (isZeroDelta(d)) continue;
      playerStats = upsertPlayer(playerStats, uid, info.displayName, (e) => {
        e.matches += d.matchesPlayed;
        e.wins += d.wins;
        e.draws += d.draws;
        e.losses += d.losses;
        e.goals += d.goals;
        e.goalsConceded += d.goalsConceded;
      });
    }

    txn.set(ref, {
      ...prev,
      totalLeagues: Math.max(0, (prev.totalLeagues || 0) + sign),
      finishedLeagues: prev.finishedLeagues || 0,
      playerStats,
      schemaVersion: SCHEMA_VERSION,
      lastEventIds: bumpEventLog(prev, eventId),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  // 3. If the league was finished, also adjust championship/runner-up
  // counts and the finishedLeagues counter. We sidestep the
  // `isActive === false` guard in `applyLeagueFinishedToGroupSummary`
  // by passing a synthesized leagueData with isActive forced true —
  // the transition itself is what decides whether to apply.
  if (leagueData.status === "finished") {
    await applyLeagueFinishedToGroupSummary(
        leagueId, {...leagueData, isActive: true}, eventId + ":fin", sign);
  }
}

async function bumpGroupTotalLeagues(groupId, delta, eventId) {
  const ref = groupSummaryRef(groupId);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptyGroupSummary();
    if (alreadyProcessed(prev, eventId)) return;
    txn.set(ref, {
      ...prev,
      totalLeagues: Math.max(0, (prev.totalLeagues || 0) + delta),
      finishedLeagues: prev.finishedLeagues || 0,
      playerStats: prev.playerStats || [],
      schemaVersion: SCHEMA_VERSION,
      lastEventIds: bumpEventLog(prev, eventId),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

async function bumpGroupFinishedLeagues(groupId, delta, eventId) {
  const ref = groupSummaryRef(groupId);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    const prev = snap.exists ? snap.data() : emptyGroupSummary();
    if (alreadyProcessed(prev, eventId)) return;
    txn.set(ref, {
      ...prev,
      totalLeagues: prev.totalLeagues || 0,
      finishedLeagues: Math.max(0, (prev.finishedLeagues || 0) + delta),
      playerStats: prev.playerStats || [],
      schemaVersion: SCHEMA_VERSION,
      lastEventIds: bumpEventLog(prev, eventId),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

// ---------------------------------------------------------------------
// Trigger: client requests a backfill via
// `esports_groups/{groupId}/stats/_recompute_request`. Folds every
// finished match in every league of the group into a fresh summary doc.
// ---------------------------------------------------------------------
exports.onRecomputeGroupSummaryRequest = onDocumentCreated(
    "esports_groups/{groupId}/stats/_recompute_request",
    async (event) => {
      const groupId = event.params.groupId;
      log(`recomputeGroupSummary: start groupId=${groupId}`);

      try {
        const summary = emptyGroupSummary();
        const players = new Map(); // userId -> entry

        const ensure = (uid, displayName) => {
          if (!players.has(uid)) {
            players.set(uid, emptyGroupPlayerEntry(uid, displayName));
          } else if (displayName) {
            const e = players.get(uid);
            if (!e.displayName) e.displayName = displayName;
          }
          return players.get(uid);
        };

        // Mirror user dashboard backfill: only count active leagues. Soft-
        // deleted leagues (isActive: false) are excluded so the Tổng quan
        // tab doesn't count history that the group has explicitly removed.
        const leaguesSnap = await db.collection("esports_leagues")
            .where("groupId", "==", groupId)
            .where("isActive", "==", true)
            .get();

        // Leagues containing a deactivated member are excluded entirely —
        // consistent with the client-side year-filter league-level exclusion.
        const deactivatedIds = await fetchDeactivatedIds(groupId);

        for (const leagueDoc of leaguesSnap.docs) {
          const league = leagueDoc.data();
          const leagueId = leagueDoc.id;

          if (hasDeactivatedParticipant(league, deactivatedIds)) continue;
          summary.totalLeagues += 1;

          const matchesSnap = await db.collection("esports_leagues")
              .doc(leagueId).collection("leagues_matches")
              .where("isFinished", "==", true).get();

          // Cache display names per league to avoid re-fetching the same
          // user N times when they're in many matches.
          const localNames = {};
          const nameOf = async (uid) => {
            if (!uid) return "";
            if (localNames[uid] !== undefined) return localNames[uid];
            localNames[uid] = await fetchUserDisplayName(uid);
            return localNames[uid];
          };

          for (const matchDoc of matchesSnap.docs) {
            const m = matchDoc.data();
            const homeUid = m.homeTeamId;
            const awayUid = m.awayTeamId;
            if (!homeUid || !awayUid) continue;
            const homeName = await nameOf(homeUid);
            const awayName = await nameOf(awayUid);
            const homeContrib = statContribution(
                m.homeScore || 0, m.awayScore || 0, +1);
            const awayContrib = statContribution(
                m.awayScore || 0, m.homeScore || 0, +1);
            const homeEntry = ensure(homeUid, homeName);
            const awayEntry = ensure(awayUid, awayName);
            applyContribInPlace(homeEntry, homeContrib);
            applyContribInPlace(awayEntry, awayContrib);
          }

          if (league.status === "finished") {
            summary.finishedLeagues += 1;
            const statsSnap = await db.collection("esports_leagues")
                .doc(leagueId).collection("leagues_stats").get();
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
            for (let i = 0; i < stats.length; i += 1) {
              const uid = stats[i].userId;
              if (!uid) continue;
              const name = await nameOf(uid);
              const entry = ensure(uid, name);
              entry.finishedLeaguesJoined += 1;
              if (i === 0) entry.championships += 1;
              if (i === 1) entry.runnerUps += 1;
            }
          }
        }

        summary.playerStats = Array.from(players.values()).filter((e) =>
          (e.matches || 0) > 0 ||
          (e.championships || 0) > 0 ||
          (e.runnerUps || 0) > 0 ||
          (e.finishedLeaguesJoined || 0) > 0);
        summary.schemaVersion = SCHEMA_VERSION;
        summary.updatedAt = FieldValue.serverTimestamp();
        // lastEventIds intentionally reset — a backfill is the new ground
        // truth, so we don't need to remember partial trigger state.
        summary.lastEventIds = [];

        const batch = db.batch();
        batch.set(groupSummaryRef(groupId), summary);
        batch.delete(db.collection("esports_groups").doc(groupId)
            .collection("stats").doc(GROUP_RECOMPUTE_REQ_DOC_ID));
        await batch.commit();
        log(`recomputeGroupSummary: done groupId=${groupId} ` +
            `players=${summary.playerStats.length}`);
      } catch (err) {
        error(`recomputeGroupSummary failed for groupId=${groupId}`, err);
      }
      return null;
    },
);

function applyContribInPlace(entry, contrib) {
  entry.matches += contrib.matchesPlayed;
  entry.wins += contrib.wins;
  entry.draws += contrib.draws;
  entry.losses += contrib.losses;
  entry.goals += contrib.goals;
  entry.goalsConceded += contrib.goalsConceded;
}
