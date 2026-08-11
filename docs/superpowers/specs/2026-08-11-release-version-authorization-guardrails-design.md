# Release version and authorization guardrails

## Purpose

PR #62 merged shippable online-league changes without a release version or
changelog update. This repair ships the already-deployed web changes with a
valid mobile release version and makes the missed release and authorization
rules explicit for future work.

## Release change

- Change `pubspec.yaml` from `3.5.0+47` to `3.6.0+48`.
- `3.6.0` is a minor release because the merged work is user-facing. The
  build number increases exactly once, from `47` to `48`, so Google Play sees
  a new version code.
- Add `CHANGELOG.md` entry `## [3.6.0+48] - 2026-08-11`. It records responsive
  create-league loading feedback, real-time league-detail updates across
  multiple clients, atomic optimistic match updates, and per-row
  pending/conflict feedback. It explicitly states that offline tournament
  behavior is unchanged.

## Repository guardrails

`AGENTS.md` will incorporate the production-release rules from `CLAUDE.md`:

- Every merge to `main` is a production release because the Android release
  workflow publishes from each push to `main`.
- Any PR touching `lib/`, `android/`, or `ios/` must update `pubspec.yaml` in
  that PR. Increase `+N` by exactly one; use a minor semantic bump for a
  user-facing feature and a patch bump for fixes or internal work.
- Add a corresponding, dated `[X.Y.Z+N]` entry to `CHANGELOG.md`. Docs-only and
  test-only PRs are exempt because they do not ship app behavior.

The same section will state the authorization boundary: authorization to
implement or commit never authorizes pushing, opening/updating a PR, merging,
or any other remote action. Each remote action requires an explicit user
request. For this repair only, the user has explicitly authorized
implementation, the necessary branch push, PR creation, and merge.

## Verification and rollback

Verify the changed YAML and Markdown with `git diff --check`, then run the
relevant Flutter analysis and tests before the PR is opened or updated. Review
the final diff to confirm the version, build number, changelog scope, and
authorization wording agree. If a regression is found after merge, open a new
PR that reverts the faulty commit; do not force-push or rewrite `main`.

This repair changes release metadata and contributor guidance only. It does
not modify online-league runtime behavior, Firebase data, SQLite schema, or
offline features.
