# Minimalist Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved Mono Ink minimalist design direction to the shared Flutter theme and main online screens.

**Architecture:** Start with central design tokens and reusable UI primitives, then migrate the online shell and top-level tabs to those primitives. Keep BLoC, routing, repositories, ads, and data flows unchanged.

**Tech Stack:** Flutter, Material 3, flutter_bloc, go_router, existing app theme/helpers.

---

## File Structure

- Modify `lib/core/theme/app_colors.dart`: Mono Ink light/dark palette and semantic colors.
- Modify `lib/core/theme/app_theme.dart`: Material 3 component defaults for minimalist cards, buttons, inputs, navigation, tabs, dialogs, dividers, snackbars.
- Modify `lib/core/widgets/app_ui_helpers.dart`: shared page shell, section surface, compact header/stat/action primitives.
- Modify `lib/presentation/main/main_view.dart`: minimalist navigation styling and badge preservation.
- Modify `lib/presentation/home/home_page.dart`: remove decorative background gradient and use shared page background.
- Modify `lib/presentation/home/dashboard/dashboard_view.dart`: restyle dashboard hero/sections to Mono Ink.
- Modify `lib/presentation/home/dashboard/widgets/stat_card_grid.dart`: align stat cards with shared surface rules.
- Modify `lib/presentation/home/widgets/ongoing_tournaments_banner.dart`: remove heavy decoration while preserving tournament summaries/actions.
- Modify `lib/presentation/esport/groups/groups_view.dart`: restyle top-level groups screen, tab bar, hero, empty states.
- Modify `lib/presentation/esport/groups/widgets/group_item.dart`: align group rows/cards.
- Modify `lib/presentation/esport/tournament/tournament_view.dart`: restyle top-level tournament screen, tab bar, hero, empty states.
- Modify `lib/presentation/esport/tournament/tournament_item.dart`: align tournament cards.
- Modify `lib/presentation/notification/notification_view.dart`: restyle notification shell and summary area.
- Modify `lib/presentation/notification/notification_item.dart`: align notification rows/cards.
- Modify `lib/presentation/profile/profile_view.dart`: restyle profile hero, sections, and action tiles.
- Add or modify widget tests under `test/presentation/...` for navigation and key screen states if existing test harness allows.

## Task 1: Foundation Theme And Helpers

**Files:**
- Modify: `lib/core/theme/app_colors.dart`
- Modify: `lib/core/theme/app_theme.dart`
- Modify: `lib/core/widgets/app_ui_helpers.dart`

- [ ] **Step 1: Inspect current helper usage**

Run:

```bash
rg "AppCard|AppEmptyState|appInputDecoration|showAppConfirmDialog|showAppFormDialog" lib test
```

Expected: list of current call sites so helper changes remain backward compatible.

- [ ] **Step 2: Update palette to Mono Ink**

Implement these token values in `AppColors` while preserving existing public names:

```dart
static const Color lightBackground = Color(0xFFFAFAFA);
static const Color lightSurface = Color(0xFFFFFFFF);
static const Color lightSurfaceVariant = Color(0xFFF4F4F5);
static const Color lightOnBackground = Color(0xFF111827);
static const Color lightOnSurface = Color(0xFF52525B);
static const Color lightOutline = Color(0xFFE4E4E7);
static const Color lightPrimary = Color(0xFF111827);
static const Color lightOnPrimary = Color(0xFFFFFFFF);

static const Color darkBackground = Color(0xFF09090B);
static const Color darkSurface = Color(0xFF18181B);
static const Color darkSurfaceVariant = Color(0xFF27272A);
static const Color darkOnBackground = Color(0xFFFAFAFA);
static const Color darkOnSurface = Color(0xFFD4D4D8);
static const Color darkOutline = Color(0xFF3F3F46);
static const Color darkPrimary = Color(0xFFFAFAFA);
static const Color darkOnPrimary = Color(0xFF111827);

static const Color accent = Color(0xFF111827);
static const Color onAccent = Color(0xFFFFFFFF);
```

Keep semantic success/error/warning colors intact or slightly muted only if contrast remains clear.

- [ ] **Step 3: Update theme defaults**

In `AppTheme._buildTheme`, keep `useMaterial3: true` and adjust component defaults:

```dart
static const double _borderRadius = 8.0;
```

Use `colorScheme.primary` for primary filled actions, `colorScheme.outline` for borders, `surfaceContainerHighest` for subtle fills, and remove elevated/decorative effects by default.

- [ ] **Step 4: Add backward-compatible helper primitives**

In `app_ui_helpers.dart`, add new widgets without removing existing exports:

```dart
class AppPageBackground extends StatelessWidget {
  final Widget child;
  const AppPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

class AppSectionSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const AppSectionSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: child,
    );
  }
}
```

Add only the helper widgets actually used by migrated screens.

- [ ] **Step 5: Verify foundation**

Run:

```bash
dart format lib/core/theme/app_colors.dart lib/core/theme/app_theme.dart lib/core/widgets/app_ui_helpers.dart
flutter analyze
```

Expected: formatting succeeds and analyze has no new issues.

## Task 2: Main Shell And Home Dashboard

**Files:**
- Modify: `lib/presentation/main/main_view.dart`
- Modify: `lib/presentation/home/home_page.dart`
- Modify: `lib/presentation/home/dashboard/dashboard_view.dart`
- Modify: `lib/presentation/home/dashboard/widgets/stat_card_grid.dart`
- Modify: `lib/presentation/home/widgets/ongoing_tournaments_banner.dart`

- [ ] **Step 1: Preserve behavior before visual edits**

Inspect existing tests:

```bash
rg "MainView|HomePage|DashboardView|OngoingTournamentsBanner|StatCardGrid" test lib/presentation/home
```

Expected: identify whether tests already cover these widgets.

- [ ] **Step 2: Remove home gradient shell**

Replace the decorative `Container(decoration: BoxDecoration(...gradient...))` in `HomePage` with `AppPageBackground`, keeping `SafeArea`, `OngoingTournamentsBanner`, and `DashboardView` unchanged structurally.

- [ ] **Step 3: Restyle main navigation**

Keep `TabController`, unread badge, ad banner, and tab list unchanged. Rely on theme-level `NavigationBarThemeData` where possible; only add local styling if needed to maintain selected indicator clarity.

- [ ] **Step 4: Restyle dashboard hero and sections**

Replace local hero/section `BoxDecoration` patterns with `AppSectionSurface`. Use plain icon buttons or small outline icon marks instead of saturated icon containers. Preserve:

```dart
context.push(Routing.dashboardDetail)
FormDotsRow(matches: stats.recentMatches)
RecentMatchesList(matches: stats.recentMatches)
```

- [ ] **Step 5: Restyle stat cards and banner**

Remove gradients/shadows from stat cards and ongoing tournament banner. Keep all current text, callbacks, list rendering, and loading/empty handling.

- [ ] **Step 6: Verify shell/home**

Run:

```bash
dart format lib/presentation/main/main_view.dart lib/presentation/home/home_page.dart lib/presentation/home/dashboard/dashboard_view.dart lib/presentation/home/dashboard/widgets/stat_card_grid.dart lib/presentation/home/widgets/ongoing_tournaments_banner.dart
flutter analyze
```

Expected: formatting succeeds and analyze has no new issues.

## Task 3: Groups And Tournaments Top-Level Screens

**Files:**
- Modify: `lib/presentation/esport/groups/groups_view.dart`
- Modify: `lib/presentation/esport/groups/widgets/group_item.dart`
- Modify: `lib/presentation/esport/tournament/tournament_view.dart`
- Modify: `lib/presentation/esport/tournament/tournament_item.dart`

- [ ] **Step 1: Inspect current repeated patterns**

Run:

```bash
rg "LinearGradient|BoxShadow|BorderRadius.circular\\(18|BorderRadius.circular\\(20|_HeroStat|TabBar" lib/presentation/esport/groups lib/presentation/esport/tournament
```

Expected: list of local decorations to simplify.

- [ ] **Step 2: Migrate page backgrounds**

Use `AppPageBackground` for groups and tournaments body containers. Preserve `DefaultTabController`, `TabBarView`, loading indicator, create dialogs, create tournament navigation, and BLoC listeners.

- [ ] **Step 3: Migrate hero sections**

Use `AppSectionSurface` for `_GroupsHero` and `_TournamentHero`. Keep metric counts and create buttons. Replace large filled icon boxes with compact outline icons or remove them if the title/action already gives enough context.

- [ ] **Step 4: Migrate tab bars**

Make tab containers monochrome:

```dart
indicatorColor: colorScheme.primary
labelColor: colorScheme.onSurface
unselectedLabelColor: colorScheme.onSurfaceVariant
```

Avoid saturated selected backgrounds unless needed for contrast.

- [ ] **Step 5: Migrate item cards**

Update `GroupItem` and `TournamentItem` to use white/dark surfaces, 8px radius, outline borders, compact spacing, and no decorative shadows. Preserve `onTap`, status chips, member/participant counts, and admin affordances.

- [ ] **Step 6: Verify groups/tournaments**

Run:

```bash
dart format lib/presentation/esport/groups/groups_view.dart lib/presentation/esport/groups/widgets/group_item.dart lib/presentation/esport/tournament/tournament_view.dart lib/presentation/esport/tournament/tournament_item.dart
flutter analyze
```

Expected: formatting succeeds and analyze has no new issues.

## Task 4: Notifications And Profile

**Files:**
- Modify: `lib/presentation/notification/notification_view.dart`
- Modify: `lib/presentation/notification/notification_item.dart`
- Modify: `lib/presentation/profile/profile_view.dart`

- [ ] **Step 1: Inspect current local sections**

Run:

```bash
rg "LinearGradient|BoxShadow|BorderRadius.circular\\(18|BorderRadius.circular\\(20|_ProfileSection|Notification" lib/presentation/notification lib/presentation/profile/profile_view.dart
```

Expected: list of local presentation decorations and private helper widgets.

- [ ] **Step 2: Migrate notification page**

Use `AppPageBackground` and `AppSectionSurface`. Preserve unread count logic, loading indicator, empty state, and notification tap behavior.

- [ ] **Step 3: Migrate notification items**

Use compact row/card style with outline border and monochrome icon treatment. Keep read/unread distinction visible through font weight, small dot, or left border rather than saturated fills.

- [ ] **Step 4: Migrate profile page**

Use `AppPageBackground` for the page. Restyle `_ProfileHero`, `_ProfileSection`, `_ProfileActionTile`, and sheet actions with monochrome surfaces and borders. Preserve avatar change/delete behavior, offline switch, sync route, settings route, feedback route, rate app links, feature toggle counter, and sign out confirmation.

- [ ] **Step 5: Verify notifications/profile**

Run:

```bash
dart format lib/presentation/notification/notification_view.dart lib/presentation/notification/notification_item.dart lib/presentation/profile/profile_view.dart
flutter analyze
```

Expected: formatting succeeds and analyze has no new issues.

## Task 5: Targeted Tests And Final Verification

**Files:**
- Add or modify: `test/presentation/main/main_view_test.dart`
- Add or modify: `test/presentation/home/dashboard/dashboard_view_test.dart`
- Add or modify: `test/presentation/esport/groups/groups_view_test.dart`
- Add or modify: `test/presentation/esport/tournament/tournament_view_test.dart`

- [ ] **Step 1: Inspect test setup**

Run:

```bash
rg "MaterialApp|BlocProvider|Mock|pumpWidget|GoRouter|AppTheme" test
```

Expected: identify existing widget test harness patterns and mocks.

- [ ] **Step 2: Add focused tests only where setup is practical**

Use existing project test helpers if present. Cover behavior that visual refactors can break: tab switching, empty states, loading states, and primary action visibility. Do not overbuild mocks for Firebase-heavy screens if the repo lacks a stable harness.

- [ ] **Step 3: Run targeted tests**

Run commands for the test files that exist after Step 2, for example:

```bash
flutter test test/presentation/main/main_view_test.dart
flutter test test/presentation/home/dashboard/dashboard_view_test.dart
```

Expected: targeted widget tests pass.

- [ ] **Step 4: Run final verification**

Run:

```bash
flutter analyze
flutter test
```

Expected: analyze clean and tests pass. If full `flutter test` is blocked by environment/Firebase setup, record the failure reason and the targeted tests that did pass.

## Self-Review

- Spec coverage: phase 1 theme/helpers maps to Task 1; phase 2 main online screens maps to Tasks 2-4; verification maps to Task 5.
- Scope check: offline screens, detail flows, create wizard, and sync flow are intentionally excluded from this plan.
- Placeholder scan: no unresolved placeholder language remains in executable task steps.
- Type consistency: helper names are introduced in Task 1 before screen migration tasks use them.
