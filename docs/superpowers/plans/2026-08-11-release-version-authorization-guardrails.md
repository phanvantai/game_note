# Release Version and Authorization Guardrails Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the already-deployed online-league work as mobile release `3.6.0+48` and prevent future missed release metadata or unauthorized remote actions.

**Architecture:** This is a release-metadata and contributor-guidance repair only: `pubspec.yaml` holds Flutter's semantic version and Android version code, `CHANGELOG.md` records the user-visible scope, and `AGENTS.md` becomes the concise operational source for release and authorization boundaries. The three files are deliberately independent, with no changes to online-league runtime code, Firebase data, SQLite schema, or offline features.

**Tech Stack:** Flutter/Dart, YAML, Markdown, Git, GitHub pull requests, GitHub Actions.

## Global Constraints

- Start from the latest `main` on a short-lived branch; never work, commit, or push directly on `main`.
- This repair modifies only `pubspec.yaml`, `CHANGELOG.md`, and `AGENTS.md`; it must not modify online-league runtime behavior, Firebase data, SQLite schema, or offline features.
- Set the only release version to exactly `3.6.0+48`: it is a user-facing minor release and its build number changes exactly once from `47` to `48`.
- Keep the project dependencies unchanged.
- The changelog must begin this repair's entry with exactly `## [3.6.0+48] - 2026-08-11` and explicitly say offline tournament behavior is unchanged.
- Every merge to `main` is a production release; do not merge this repair until required CI checks pass.
- Authorization to implement or commit does not authorize push, PR creation/update, merge, or any other remote action; each remote action needs an explicit user request.
- For this repair only, the user has explicitly authorized implementation, the necessary branch push, PR creation, and merge.
- If a post-merge regression is found, open a new PR that reverts the faulty commit; never force-push or rewrite `main`.

---

## File Map

- `pubspec.yaml` — Flutter application version consumed by Android/iOS release builds.
- `CHANGELOG.md` — dated release notes describing the already-shipped user-visible online-league behavior.
- `AGENTS.md` — repository workflow guidance, expanded with production-release and remote-action authorization rules.

### Task 1: Set the Flutter release version

**Files:**
- Modify: `pubspec.yaml:5`

**Interfaces:**
- Consumes: the current single YAML key `version: 3.5.0+47`.
- Produces: the single YAML key `version: 3.6.0+48`, which Flutter maps to semantic version `3.6.0` and build number `48`.

- [ ] **Step 1: Write the failing release-version assertion**

Run this before editing to prove the repository still has the pre-repair version:

```bash
rg -n '^version: 3\.5\.0\+47$' pubspec.yaml
```

Expected: one match at line 5; the required `3.6.0+48` value is absent.

- [ ] **Step 2: Apply the minimal YAML change**

Replace the exact line:

```yaml
version: 3.5.0+47
```

with:

```yaml
version: 3.6.0+48
```

- [ ] **Step 3: Run the GREEN version and YAML assertions**

```bash
rg -n '^version: 3\.6\.0\+48$' pubspec.yaml
ruby -e "require 'yaml'; version = YAML.load_file('pubspec.yaml').fetch('version'); abort(\"expected 3.6.0+48, got #{version.inspect}\") unless version == '3.6.0+48'; puts version"
```

Expected: the first command prints exactly one version line and the second prints `3.6.0+48` without a YAML parse error.

- [ ] **Step 4: Inspect the isolated diff**

```bash
git diff --check -- pubspec.yaml
git diff -- pubspec.yaml
```

Expected: no whitespace errors and one-line replacement from `3.5.0+47` to `3.6.0+48`.

### Task 2: Record the 3.6.0+48 release notes

**Files:**
- Modify: `CHANGELOG.md:5`

**Interfaces:**
- Consumes: the current top release heading `## [3.5.0+47] - 2026-08-09`.
- Produces: a new top entry headed `## [3.6.0+48] - 2026-08-11`, using `### Added`, `### Changed`, and `### Fixed` subsections.

- [ ] **Step 1: Write the failing changelog-content assertions**

Run before editing:

```bash
rg -n '^## \[3\.6\.0\+48\] - 2026-08-11$' CHANGELOG.md
rg -n -i 'offline tournament behavior is unchanged' CHANGELOG.md
```

Expected: both commands return exit status 1 because neither required release heading nor explicit offline-behavior statement exists yet.

- [ ] **Step 2: Insert the exact release entry above 3.5.0+47**

Add this Markdown immediately after the introductory paragraph and before `## [3.5.0+47] - 2026-08-09`:

```markdown
## [3.6.0+48] - 2026-08-11

### Added

- Phản hồi tải kịp thời khi tạo giải league online.

### Changed

- Chi tiết giải league cập nhật thời gian thực giữa nhiều thiết bị.
- Cập nhật trận dùng ghi lạc quan nguyên tử để giữ điểm số nhất quán khi có thao tác đồng thời.

### Fixed

- Phản hồi đang chờ và xung đột theo từng hàng giúp hiển thị rõ các cập nhật trận đang xử lý hoặc cạnh tranh.
- Hành vi giải đấu offline không thay đổi.
```

- [ ] **Step 3: Run the GREEN changelog-content assertions**

```bash
rg -n '^## \[3\.6\.0\+48\] - 2026-08-11$' CHANGELOG.md
rg -n -i 'Phản hồi tải kịp thời khi tạo giải league online|Chi tiết giải league cập nhật thời gian thực giữa nhiều thiết bị|ghi lạc quan nguyên tử|Phản hồi đang chờ và xung đột theo từng hàng|Hành vi giải đấu offline không thay đổi' CHANGELOG.md
```

Expected: one dated heading and five Vietnamese matching lines covering loading feedback, multi-client real time, atomic optimistic updates, per-row feedback, and unchanged offline behavior.

- [ ] **Step 4: Inspect the isolated diff**

```bash
git diff --check -- CHANGELOG.md
git diff -- CHANGELOG.md
```

Expected: no whitespace errors and only the new dated release entry above `3.5.0+47`.

### Task 3: Add production-release and authorization guardrails

**Files:**
- Modify: `AGENTS.md:110-116`

**Interfaces:**
- Consumes: the existing `## Release / PR Guardrails` section.
- Produces: enforceable written rules that merge-to-`main` ships production, define exact version/changelog conditions and exemptions, and prohibit remote actions without explicit user authorization.

- [ ] **Step 1: Write the failing guardrail assertions**

Run before editing:

```bash
rg -n -i 'every merge to `main` is a production release' AGENTS.md
rg -n -i 'authorization to implement or commit does not authorize pushing, opening or updating a PR, merging, or any other remote action' AGENTS.md
rg -n -i 'each remote action requires an explicit user request' AGENTS.md
```

Expected: all three commands return exit status 1 because the exact production and authorization concepts are not yet documented.

- [ ] **Step 2: Extend `## Release / PR Guardrails` with the required rules**

Add concise bullets that state all of the following facts:

```markdown
- Every merge to `main` is a production release: `.github/workflows/android-release.yml` publishes every push to `main` to Google Play production.
- A PR touching `lib/`, `android/`, or `ios/` must update `pubspec.yaml` and add a dated `[X.Y.Z+N]` entry to `CHANGELOG.md`; docs-only and test-only PRs are exempt.
- Increase `+N` by exactly one. Use a minor semantic bump for user-facing features and a patch bump for fixes or internal work.
- Authorization to implement or commit does not authorize pushing, opening or updating a PR, merging, or any other remote action. Each remote action requires an explicit user request.
- Do not merge until required CI checks pass. If a merged change regresses, open a new revert PR; do not force-push or rewrite `main`.
```

- [ ] **Step 3: Run the GREEN guardrail assertions**

```bash
rg -n -i 'every merge to `main` is a production release|publishes every push to `main` to Google Play production' AGENTS.md
rg -n -i 'touching `lib/`, `android/`, or `ios/`|dated `\[X\.Y\.Z\+N\]` entry|docs-only and test-only PRs are exempt|Increase `\+N` by exactly one' AGENTS.md
rg -n -i 'authorization to implement or commit does not authorize pushing, opening or updating a PR, merging, or any other remote action|Each remote action requires an explicit user request|Do not merge until required CI checks pass' AGENTS.md
```

Expected: the output confirms the release trigger, version/changelog rule and exemption, exact remote-action authorization boundary, and CI gate.

- [ ] **Step 4: Inspect the isolated diff**

```bash
git diff --check -- AGENTS.md
git diff -- AGENTS.md
```

Expected: no whitespace errors and all new guidance is confined to `## Release / PR Guardrails`.

### Task 4: Main-agent integration, release verification, and authorized delivery

**Files:**
- Modify: `pubspec.yaml`, `CHANGELOG.md`, `AGENTS.md` from Tasks 1–3 only

**Interfaces:**
- Consumes: the exact version, changelog entry, and guardrail wording produced by Tasks 1–3.
- Produces: one reviewed commit and, because this repair has explicit authorization, a merged PR to `main` after CI passes.

- [ ] **Step 1: Review ownership and final content**

```bash
git status --short
git diff --name-only
git diff --check
git diff -- pubspec.yaml CHANGELOG.md AGENTS.md
```

Expected: only `pubspec.yaml`, `CHANGELOG.md`, and `AGENTS.md` are changed; the diff has no whitespace errors; the version is `3.6.0+48`; the changelog has its `2026-08-11` entry; and the authorization language is complete.

- [ ] **Step 2: Run the full relevant Flutter verification**

```bash
flutter analyze
flutter test
```

Expected: analysis exits 0 with no diagnostics, and the full Flutter test suite exits 0. These metadata and documentation changes require no runtime behavior changes or database migration checks.

- [ ] **Step 3: Commit the reviewed repair on the short-lived branch**

```bash
git add pubspec.yaml CHANGELOG.md AGENTS.md
git commit -m "chore: release 3.6.0+48"
```

Expected: one commit contains only the three reviewed files.

- [ ] **Step 4: Use the repair-specific explicit authorization to push and open the PR**

```bash
git push -u origin HEAD
gh pr create --base main --title "chore: release 3.6.0+48" --body "Ships the missing release metadata and contributor guardrails for the already-deployed online-league work. Includes version 3.6.0+48, dated changelog notes, and explicit remote-action authorization rules."
```

Expected: the branch is pushed and a PR targeting `main` is created. This remote work is permitted only because the user explicitly authorized implementation, the necessary branch push, PR creation, and merge for this repair.

- [ ] **Step 5: Verify PR checks, merge only after they pass, and clean up**

```bash
gh pr checks --watch
gh pr merge --merge --delete-branch
git switch main
git pull --ff-only origin main
git status --short
```

Expected: all required CI checks pass before merge; the PR is merged; its remote branch is deleted; local `main` fast-forwards to the merged release and has no tracked or untracked changes. If CI fails, diagnose and repair in a new commit on the PR branch instead of merging.
