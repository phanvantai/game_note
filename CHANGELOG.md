# Changelog

All notable changes to PES Arena are documented here.

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
