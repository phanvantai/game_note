# TODOS

Project follow-ups, organized by component. Priority scale: P0 (security / data
loss) → P4 (nice-to-have). Items move to `## Completed` at the bottom on ship.

## Firestore rules

### Tighten `esports_groups` write access (field-level rules)

**Priority:** P0
**Noticed on:** v3.3.0+42 group-deletion review (2026-05-22)

`firestore.rules:99` currently has `allow read, write: if signedIn();` which
makes the whole `esports_groups` document writable by any signed-in user. The
new owner-only `update, delete` clause on line 100 is OR'd on top, so it adds
nothing — any logged-in client can call `groupRef.delete()` directly and bypass
the new `group_deletion_requests` cascade flow entirely.

A naive tightening to `allow create: if signedIn();` breaks legitimate
non-owner writes:

- `addMemberToGroup` — non-owner member joining (`arrayUnion(members)`)
- `removeMemberFromGroup` — non-owner leaving (`arrayRemove(members)`)
- `toggleMemberDeactivation` — owner-only in practice but currently runs as
  any-signed-in

The proper fix is field-level rules: which fields can which role
(owner / member / non-member) mutate? Sketch:

```
allow update: if signedIn() && (
  request.auth.uid == resource.data.ownerId ||
  // member self-leave: only allowed to remove themselves
  (request.auth.uid in resource.data.members
    && onlyTouches(['members','deactivatedMembers','updatedAt'])
    && !(request.auth.uid in request.resource.data.members))
  || // member self-join via invite ... etc.
);
allow delete: if signedIn() && request.auth.uid == resource.data.ownerId;
```

Needs careful per-flow analysis + emulator tests for join/leave/transfer.

## Cloud functions

### GC `group_deletion_league_tombstones`

**Priority:** P1
**Noticed on:** v3.3.0+42 group-deletion review (2026-05-22)

`functions/index.js:957` writes tombstones to `group_deletion_league_tombstones`
to suppress delta-stat triggers during cascade, but they are never deleted.
The collection grows unboundedly, and every `onLeagueMatchWritten` /
`onEsportLeagueWritten` invocation reads it (`isGroupDeletionLeague` at
`functions/index.js:391`) — a per-write read tax forever.

End-of-cascade cleanup races with late-firing triggers for the deleted league,
so the safer fix is a scheduled sweep (daily Cloud Scheduler function deletes
tombstones whose `createdAt` is > 24h old).

### Idempotent fan-out for `rebuildUserSummary`

**Priority:** P2
**Noticed on:** v3.3.0+42 group-deletion review (2026-05-22)

`functions/index.js:1077` sequentially awaits `rebuildUserSummary(uid)` for
every affected user. For groups with 50+ members and many cross-group leagues,
this can blow past Cloud Functions' 9-minute timeout — leaving the cascade in
`processing` with partial summary updates.

Fan out by writing per-user `_recompute_request` docs and letting the existing
`onRecomputeUserSummaryRequest` trigger pick them up in parallel.

## Group detail

### Widget tests for the delete confirmation dialog and post-delete navigation

**Priority:** P2
**Noticed on:** v3.3.0+42 coverage audit (2026-05-22)

`lib/presentation/esport/groups/group_detail/group_detail_view.dart` has no
widget tests for:

- `_deleteGroup` confirmation dialog: typing wrong name keeps the button
  disabled, typing the exact group name enables it, dismissing the dialog
  does not dispatch.
- BlocListener: `deleteGroupStatus == success` → `GroupBloc.add(GetEsportGroups)`
  + `context.go('/groups')`.
- BlocListener: `deleteGroupErrorMessage.isNotEmpty` → toast.
- PopupMenuButton disabled while `deleteGroupStatus == loading`.

## Completed
