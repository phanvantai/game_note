const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const source = fs.readFileSync(path.join(__dirname, "index.js"), "utf8");

test("notification exports and messaging are absent", () => {
  for (const name of [
    "createEsportGroupNotification",
    "createEsportLeagueNotification",
    "sendPushNotification",
    "getMessaging",
    "deleteNotificationsFor",
  ]) assert.equal(source.includes(name), false, name);
});

test("retained core exports remain", () => {
  for (const name of [
    "onLeagueMatchWritten",
    "onLeagueStatusChanged",
    "onRecomputeUserSummaryRequest",
    "onGroupDeletionRequestCreated",
    "onEsportLeagueWritten",
    "onRecomputeGroupSummaryRequest",
  ]) assert.equal(source.includes(`exports.${name}`), true, name);
});
