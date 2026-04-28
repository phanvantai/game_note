# TODOs

Pending work items, captured across sessions. Update / remove as items land.

## App refactor: data loading & auth gating

**Status:** planned for a dedicated session.

**Goal:** rework the data-loading flow so Firestore subscriptions don't fire
before the user is authenticated, and centralise the auth-gated bootstrap.

### Bug that motivates it: Firestore `permission-denied` when unauthenticated

Repro: open app while signed out (or right after sign-out).

```
I/flutter: Auth state changed: null
W/Firestore: Listen for QueryWrapper(query=Query(target=Query(esports_leagues
            order by __name__);limitType=LIMIT_TO_FIRST)) failed:
            Status{code=PERMISSION_DENIED, description=Missing or insufficient
            permissions., cause=null}
E/flutter: Unhandled Exception: [cloud_firestore/permission-denied] The caller
           does not have permission to execute the specified operation.
```

The app starts a Firestore listener on `esports_leagues` before there's an
authenticated user. Firestore security rules reject it (correctly), and the
exception bubbles up unhandled.

**Likely root cause** (to confirm during refactor): a top-level bloc /
repository subscribes in its constructor or in `initState`, not gated on
`AppStatus.authenticated`. Candidate: `TournamentBloc._leaguesSubscription`
(see [tournament_bloc.dart](lib/presentation/esport/tournament/bloc/tournament_bloc.dart))
— it calls `listenForLeagues()` in the constructor.

**Fix direction (preferred):** start league/group/chat listeners only after
`AppBloc` emits `AppStatus.authenticated`. Tear them down on sign-out.

**Alternative (not preferred):** loosen Firestore rules — would mask the bug
and leak collection structure to unauthenticated callers.

### Scope for refactor session

- Audit every long-lived Firestore listener and identify which need auth.
- Introduce a single auth-gated entry point that fans out subscriptions.
- Make sure listeners cancel on sign-out (avoid the next sign-in seeing stale
  state).
- Add a regression test: bloc with no current user should not call the repo's
  listen* methods. Use `mocktail` repo + verify nothing called.

## Xcode Cloud build failure (xcfilelist)

**Status:** parked — likely a cache-invalidation artefact, will recheck on the
next Xcode Cloud run.

**Symptom:** build fails with

```
Unable to load contents of file list:
'/Target Support Files/Pods-Runner/Pods-Runner-resources-Release-input-files.xcfilelist'
```

The leading `/` means `${PODS_ROOT}` resolved empty — the Pods xcconfig wasn't
included, which usually means `pod install` didn't complete on CI.

**Investigation done so far:**

- Code changes between last-good (`814e3dd`) and broken (`a27972e`) are pure
  Dart + dev-only test deps (`bloc_test`, `mocktail`). No iOS plugin list
  changes (`.flutter-plugins-dependencies` identical: 17 plugins).
- `ci_post_clone.sh` runs `flutter pub get` + `pod install` but has no
  `set -e`, so a silent `pod install` failure would let the build proceed
  with no Pods xcconfigs.
- Local `Pods/` is fully populated; project file references are correct.

**Next steps when revisiting:**

1. Re-run Xcode Cloud — if it now passes, it was cache invalidation when
   pubspec.lock changed. Done.
2. If still failing, capture the **full** `ci_post_clone.sh` log from the
   Xcode Cloud build report to see what `pod install` actually does.
3. Add `set -e` to `ci_post_clone.sh` so silent failures surface.
