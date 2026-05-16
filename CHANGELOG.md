# Changelog

All notable changes to PES Arena are documented here.

## [3.2.0+41] - 2026-05-16

### Added

- **Web auth guard**: deep linking now waits for Firebase to restore the session on a splash screen, then either renders the requested route (if signed in) or bounces to `/login?next=...` and returns the user to the original URL after sign-in
- **Smart back button**: every secondary screen ships a back arrow that works even on cold deep-link visits — pops the previous route when there is one, otherwise goes home

### Changed

- **Update match score is now latency-decoupled from stats**: writing the match doc is a fast standalone transaction; player stat deltas reconcile via a separate event so the score-entry dialog dismisses immediately on web
- **"Đồng bộ điểm số" is now delete-and-recreate**: nukes existing stat rows and rebuilds them from `league.participants` ∪ match teams, fixing legacy leagues that ended up with duplicate or missing stat docs
- **Home banner "đang diễn ra"** now filters by `status == ongoing` (the field admins actually toggle) instead of date range
- **Create-league wizard**: Cup and Full modes temporarily marked "Sắp ra mắt" and disabled while their stat/bracket flows are stabilised — only League mode can be created
- **Cost panel formatting**: amounts now round half-up to the nearest thousand (e.g. 49,500 → `50k`) so individual rows add up to the displayed net; the "Theo trận" section is only shown when at least one finished match has a non-zero cost

### Fixed

- League-mode tournaments now initialise per-player stat rows when matches are generated, so score entry no longer throws "No stats found"
- `_statRefForUser` query filters `groupId` in code instead of relying on Firestore's `isNull: true` predicate, which silently missed stat docs whose field was omitted by `toMap` when null

## [3.1.0+40] - 2026-05-08

### Added
- **Full tournament mode**: create tournaments with group stage + knockout bracket in a single flow — set number of groups, advancement count, and let the app generate everything
- **Bracket view**: visual knockout bracket tab on tournament detail, showing round labels (Tứ kết / Bán kết / Chung kết) and real-time scores
- **Group standings view**: per-group tables for full-mode tournaments with group selector tab bar
- **Create-league wizard overhaul**: mode selector (league / cup / full), participant count, group configuration, and collapsible cost setup all in one guided flow
- **Collapsible cost config**: cost settings panel that starts collapsed to reduce visual noise, expands on tap with subtitle showing current config
- **Match score dialog**: extracted update-score dialog with cost-per-match toggle and default prefill from league settings

### Changed
- Cost calculator now handles knockout bracket payout distribution
- Cost split view updated for group + knockout phase breakdown
- Matches view supports phase filtering and improved search
- Group detail view updated for multi-mode tournaments
- App icons and screenshots refreshed

### Fixed
- Profile view cleanup, removed stale widgets
- GNCircleAvatar handles null photo URL gracefully
- Firebase Auth error handling improvements
