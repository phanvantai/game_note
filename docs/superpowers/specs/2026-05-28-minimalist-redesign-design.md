# Minimalist Redesign Design

## Context

PES Arena is a Flutter mobile app for online esports groups/tournaments and offline tournament management. The current UI already has a centralized theme, but many presentation screens override it with gradients, large rounded hero cards, shadows, and duplicated local tab/stat/card styles.

The approved visual direction is **Mono Ink**: a minimalist, utility-first interface with white/near-black surfaces, restrained borders, low or no shadows, compact data rows, and clear typography. This pass covers phase 1 and phase 2 only.

## Goals

- Make the app feel lighter, calmer, and more consistent.
- Remove decorative gradients and heavy glow/shadow treatments from the main online experience.
- Centralize reusable minimalist surfaces in theme/helper widgets so later offline/detail passes can reuse them.
- Preserve existing navigation, BLoC behavior, routing, localization, ads, and data loading logic.

## Non-Goals

- Do not redesign offline screens in this pass.
- Do not redesign high-risk detail/wizard flows in this pass, including tournament detail, group detail, create tournament wizard, sync flow, or share-capture layouts.
- Do not introduce a new state management approach or new package dependency.
- Do not change business logic, repositories, routes, or Firebase/SQLite behavior.

## Scope

### Phase 1: Design Foundation

- Update `lib/core/theme/app_colors.dart` to a Mono Ink palette.
- Update `lib/core/theme/app_theme.dart` so Material components use minimalist defaults:
  - white/off-white background in light mode
  - near-black text and action color
  - subtle gray borders
  - 8px component radius where practical
  - no decorative elevation by default
- Expand `lib/core/widgets/app_ui_helpers.dart` with reusable primitives:
  - minimal page background
  - app section/card shell
  - compact stat tile
  - page header
  - minimal segmented tab container if useful

### Phase 2: Main Online Screens

Apply the shared visual system to:

- `lib/presentation/main/main_view.dart`
- `lib/presentation/home/home_page.dart`
- `lib/presentation/home/dashboard/dashboard_view.dart`
- `lib/presentation/home/dashboard/widgets/stat_card_grid.dart`
- `lib/presentation/home/widgets/ongoing_tournaments_banner.dart`
- `lib/presentation/esport/groups/groups_view.dart`
- `lib/presentation/esport/groups/widgets/group_item.dart`
- `lib/presentation/esport/tournament/tournament_view.dart`
- `lib/presentation/esport/tournament/tournament_item.dart`
- `lib/presentation/notification/notification_view.dart`
- `lib/presentation/notification/notification_item.dart`
- `lib/presentation/profile/profile_view.dart`

## Visual Rules

- Use mostly `ColorScheme.surface`, `scaffoldBackgroundColor`, `outline`, `onSurface`, and `primary`.
- Use black/white/gray as the base system, with semantic colors only for success/error/warning/status.
- Use compact rows and bordered cards for data-heavy screens.
- Keep touch targets at least 44px high.
- Keep tab and navigation affordances clear without saturated backgrounds.
- Prefer dividers and 1px borders over shadows.
- Avoid gradients, neon accents, large soft shadows, oversized cards, and decorative icon containers.

## UX Rules

- Preserve the current bottom navigation structure and labels.
- Preserve existing loading, error, and empty states, but restyle them to match Mono Ink.
- Keep action buttons obvious through contrast rather than color saturation.
- Keep screen-reader semantics and Material button/input affordances intact by using Flutter Material widgets.
- Do not reduce information density in tables/lists; minimalist here means less decoration, not fewer useful fields.

## Testing And Verification

- Add focused widget tests where visual refactors risk behavior:
  - main navigation tab switching and notification badge visibility
  - dashboard loading/error/loaded rendering
  - groups empty/list rendering
  - tournaments empty/list rendering
- Run `flutter analyze`.
- Run targeted widget tests for touched presentation areas.
- Run broader `flutter test` when practical after phase 1+2 integration.

## Risks

- Some screens duplicate private helper widgets, so visual consistency can drift unless shared primitives are introduced first.
- Main navigation includes an ad banner on mobile; bottom spacing and `SafeArea` must be preserved.
- Dashboard/group/tournament hero sections currently combine summary metrics and actions; redesign should simplify visuals without hiding key actions.
- Existing hardcoded localized text in some presentation files is out of scope unless a touched widget needs a small safe fix.

## Approved Direction

The user selected **B: Mono Ink** from the visual companion mockup on 2026-05-28.
