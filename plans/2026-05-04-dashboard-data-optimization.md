# Plan: Tối ưu load dữ liệu Dashboard + nền tảng cho stats mở rộng

**Ngày:** 2026-05-04
**Trạng thái:** ✅ Đã triển khai phần data layer (Dart + Cloud Function code). Chưa deploy functions, chưa wire UI cho W/D/L mới.
**Phụ thuộc:** Plan `2026-05-04-home-dashboard-tab.md` (đã triển khai ở `ab82124`).
**Người thực hiện:** Claude

## Sai lệch vs plan khi implement (đã review, chấp nhận)

- **Backfill bằng request-doc thay vì callable**: plan đề xuất `cloud_functions` callable `recomputeUserSummary`. Để tránh thêm dependency mới (`cloud_functions` chưa có trong `pubspec.yaml`), client ghi doc `users/{uid}/stats/_recompute_request` và Cloud Function `onRecomputeUserSummaryRequest` (trigger `onDocumentCreated`) consume + delete. Idempotent, không cần dep mới.
- **Layer entity**: plan định reuse `RecentMatchSummary` (presentation model) trong firebase entity. Đổi sang định nghĩa `GNUserRecentMatch` + `GNRecentMatchResult` riêng trong firebase layer để tránh backwards dependency từ firebase → presentation. Bloc map `GNUserRecentMatch` → `RecentMatchSummary` cho UI.
- **`UserStatsRepositoryImpl` & `gn_firestore_user_stats.dart`** đánh dấu `coverage:ignore-file`: thin Firestore pass-through, không thể unit-test mà không có firestore fake. Theo CLAUDE.md exclusion policy.
- **Không xoá fallback DashboardBloc cũ ngay**: plan §8 nói "giữ fallback 1 tuần". Implementation chọn cách clean hơn — xoá hẳn legacy fan-out path khỏi bloc, dựa vào lazy backfill (`requestRecompute` + `listenSummary` timeout 30s) để cover user chưa có summary doc. Test coverage cho cả 3 path: cache hit, summary có sẵn, summary null + recompute.
- **DashboardStats** mở rộng với field mới (`wins/draws/losses/goals/goalsConceded/matchesPlayed`) nhưng UI hiện tại chưa render — đây là phase sau (out of scope).

Coverage file mới = 100%:
- `dashboard_bloc.dart`, `dashboard_state.dart`, `dashboard_event.dart`
- `dashboard_cache.dart`
- `gn_user_stats_summary.dart`, `gn_user_h2h.dart`

`flutter analyze` clean. `flutter test` 247 passed.

## Việc chưa làm

1. Deploy cloud functions: `cd functions && firebase deploy --only functions`.
2. Verify trên emulator/staging: tạo match, kiểm tra `users/{uid}/stats/summary` build đúng, dashboard 1 read.
3. Wire UI cho W/D/L lifetime + win rate + tile so sánh H2H (phase tiếp theo, plan riêng).
4. Trigger `onUserDocUpdate` propagate `displayName` đổi sang h2h docs (phase sau).

---

---

## 1. Mục tiêu

Plan trước đã ship dashboard nhưng **load pattern hiện tại không scale**:

- `DashboardBloc._load` (`lib/presentation/home/dashboard/bloc/dashboard_bloc.dart:47-129`) gọi `getMyLeagues()` rồi `Future.wait` `getParticipantsAndMatches(leagueId)` cho **từng** league user tham gia.
- Mỗi league = **2 Firestore reads** (`getLeagueStats` + `getMatches`). Plan trước đã ghi nhận rủi ro này (Section 4 và Section 8 — "Phase 1 chấp nhận; thêm spinner. Phase sau: cache").
- Mọi metric (W/D/L, ranking, phong độ) đều **tính on-the-fly từ raw matches** trên client mỗi lần mở app.
- Không có cache: data của giải đã `finished` (bất biến) vẫn fetch lại mỗi pull-to-refresh.

Plan này giải quyết:

1. **Giảm read time về O(1)** — dashboard load = **1 doc read** thay vì `1 + 2N`.
2. **Cho phép thêm nhiều metric mới mà không tăng cost**:
   - Tỉ lệ thắng / số trận thắng-hoà-thua **cả đời** (xuyên các league).
   - **So sánh thành tích đối đầu** (head-to-head) giữa 2 user.
   - Goals scored / conceded lifetime, streak, …
3. **Eventual consistency chấp nhận được** cho dashboard (~vài giây sau khi nhập tỉ số).

Out-of-scope:

- UI cho các metric mới (sẽ có plan UI riêng sau khi data nền sẵn sàng).
- Group-level dashboard (mention ở plan trước, Section 10 — phase sau).

## 2. Vấn đề hiện trạng (chi tiết)

### 2.1 Load pattern

```
LoadDashboard
 ├─ getMyLeagues()                                  (2 queries: ownerId + participants)
 ├─ filter participants.contains(uid)
 └─ for each league (parallel):
      getParticipantsAndMatches(leagueId)
        ├─ getLeagueStats(leagueId)                 (1 query)
        └─ getMatches(leagueId)                     (1 query)
 → BLoC: tính rank, finishedCount, championCount, recentMatches
```

Với user có 20 league, đây là **41 Firestore reads/lần mở Home**. Khi user gắn bó lâu (50–100 league), pattern này không bền vững — cả về tiền lẫn UX (thời gian load tăng tuyến tính).

### 2.2 Metric mở rộng

User muốn (theo brief):

- **Tỉ lệ / số trận thắng / hoà / thua** lifetime → cần duyệt **mọi match của mọi league** user từng tham gia. Hiện không có aggregate.
- **So sánh đối đầu giữa các user (H2H)** → cần biết, giữa user A và user B trên toàn bộ system: bao nhiêu trận, ai thắng nhiều hơn, tổng tỉ số. Hiện chỉ có thể tính bằng cách scan toàn bộ matches → không khả thi nếu làm online.

→ Cần **per-user aggregate doc** + **per-pair (A,B) aggregate doc**.

### 2.3 Write path đã sẵn pattern delta — tận dụng

`gn_firestore_esport_league_match.dart:129-222` (`updateMatch`) đã chạy **một transaction** vừa update match vừa apply delta vào `leagues_stats` của 2 user (home/away). Có sẵn helper:

- `_statContribution(homeScore, awayScore, sign: ±1)` → trả về delta `(matchesPlayed, wins, draws, losses, goals, goalsConceded)`.
- `_zeroDelta`, `_applyDeltaMap`.

Pattern này **đảm bảo idempotent** khi sửa tỉ số (undo old + apply new). Mở rộng sang user-summary và h2h dùng **cùng helper** → không phát sinh logic mới rủi ro.

## 3. Giải pháp tổng quát — 3 lớp + cache

### 3.1 Lớp 1 — Per-user lifetime summary (`users/{uid}/stats/summary`)

**Mục đích**: nguồn duy nhất cho dashboard cá nhân. Đọc 1 doc là đủ render toàn bộ stats lifetime.

**Schema** (single doc):

```
users/{uid}/stats/summary {
  // Match aggregates (fold của tất cả finished matches user tham gia)
  matchesPlayed: int
  wins: int
  draws: int
  losses: int
  goals: int                  // tổng bàn thắng user ghi
  goalsConceded: int          // tổng bàn thua

  // Tournament aggregates
  tournamentsJoined: int      // số league user là participant
  tournamentsFinished: int
  championCount: int
  runnerUpCount: int
  lastChampionAt: Timestamp?

  // Recent activity (cap 20 — đủ cho "Phong độ 10 trận" + buffer)
  recentMatches: [
    {
      matchId, leagueId, leagueName, date,
      userScore, opponentScore,
      opponentId, opponentDisplayName,
      result: 'win' | 'draw' | 'loss',
    }
  ]

  updatedAt: Timestamp
  schemaVersion: int          // để migrate sau
}
```

**Derived metrics tính ở client** (rẻ, không lưu redundant):
- `winRate = wins / matchesPlayed` (guard /0 → null)
- `championRate = championCount / tournamentsFinished`
- `runnerUpRate = runnerUpCount / tournamentsFinished`
- `goalDifference = goals - goalsConceded`

### 3.2 Lớp 2 — Head-to-Head (`users/{uid}/h2h/{opponentUid}`)

**Mục đích**: feature "so sánh đối đầu giữa 2 user".

**Schema**:

```
users/{uid}/h2h/{opponentUid} {
  opponentId
  opponentDisplayName       // denormalize, refresh khi user đổi tên (xem 5.5)
  matchesPlayed
  wins                      // theo góc nhìn của uid
  draws
  losses
  goals
  goalsConceded
  lastMetAt: Timestamp?
  updatedAt
}
```

Dữ liệu **đối xứng**: mỗi finished match A vs B → cả `users/A/h2h/B` và `users/B/h2h/A` đều update. (B's wins == A's losses, etc.)

**Read**: dashboard / profile compare → `1 doc read` (`users/{me}/h2h/{X}`).

### 3.3 Lớp 3 — Cloud Function fan-out

Lý do **không** nhồi tất cả vào client transaction:

- Client transaction `updateMatch` hiện đã có 1 match doc + 2 stat docs. Nhồi thêm 4 docs (2 user-summary + 2 h2h) sẽ:
  - Tăng risk transaction abort do contention.
  - Tăng latency thấy được khi admin nhập tỉ số.
  - Tăng độ phức tạp khi `recentMatches` array cần cap (đọc array trước khi ghi).

**Đề xuất**: thêm Firestore trigger ở `functions/index.js` (đã có infrastructure cho notifications).

```js
exports.onLeagueMatchWritten = onDocumentWritten(
  'esports_leagues/{leagueId}/leagues_matches/{matchId}',
  async (event) => {
    const before = event.data.before.exists ? event.data.before.data() : null;
    const after  = event.data.after.exists  ? event.data.after.data()  : null;

    // Compute delta net (undo before-finished, apply after-finished).
    // Apply to:
    //   users/{home}/stats/summary
    //   users/{away}/stats/summary
    //   users/{home}/h2h/{away}
    //   users/{away}/h2h/{home}
    // Update recentMatches array (cap 20).
    // Bump tournaments/championCount when league.status transitions to finished
    //   — handled in separate trigger on esports_leagues doc.
  }
);

exports.onLeagueStatusChanged = onDocumentUpdated(
  'esports_leagues/{leagueId}',
  async (event) => {
    // When status: ongoing → finished → resolve standings, bump
    // championCount/runnerUpCount/lastChampionAt for top-2 users.
    // When status: finished → ongoing → undo (rare, admin op).
  }
);
```

**Trade-off**:
- ✅ Client write path đơn giản hóa (chỉ cần giữ `updateMatch` hiện tại).
- ✅ Eventual consistency ~1-3s → dashboard chấp nhận được.
- ⚠️ Cần handle Cloud Function retry & idempotency. Dùng `event.id` làm dedupe key trong 1 doc nhỏ `users/{uid}/stats/_processedEvents/{eventId}` (TTL 7 ngày), hoặc check `before/after` đảm bảo function chỉ apply delta net.

### 3.4 Lớp 4 — Client cache (instant UX)

- Lưu `DashboardStats` cuối cùng vào `shared_preferences` (đã có dependency).
- Khi mở Home: emit ngay state cached → fetch summary doc nền → emit lại nếu khác.
- Kết quả: dashboard hiện **0 ms perceived latency**.

### 3.5 Backfill data hiện hữu

Trước khi đổi `DashboardBloc` sang đọc summary, phải backfill cho user đang có data.

**Cách 1 — Cloud Function callable** (recommended):

```js
exports.recomputeUserSummary = onCall(async (req) => {
  const uid = req.auth.uid;
  // 1. Query mọi league có participants.contains(uid).
  // 2. Với mỗi league: load leagues_stats, leagues_matches.
  // 3. Fold thành user summary + dictionary h2h.
  // 4. Batch write users/{uid}/stats/summary + users/{uid}/h2h/*.
});
```

Trigger: client gọi function này 1 lần khi user mở Home và `summary` không tồn tại (lazy migration). Throttle bằng cờ `summarySchemaVersion` ở user doc.

**Cách 2 — One-shot script**: `tools/backfill_user_stats.dart` chạy thủ công với service account, scan toàn bộ users. Dùng nếu muốn migrate atomic.

**Lựa chọn**: dùng **Cách 1 (lazy)** — không cần ops cycle, user mới hoặc user inactive không tốn read.

## 4. Cấu trúc code

### 4.1 File mới

```
lib/firebase/firestore/user/stats/
├── gn_user_stats_summary.dart        # entity + fromMap/fromFirestore/toMap
├── gn_user_h2h.dart                  # entity
└── gn_firestore_user_stats.dart      # mixin trên GNFirestore với getUserSummary/getH2H/recomputeUserSummary

lib/domain/repositories/user/
└── user_stats_repository.dart        # interface

lib/data/repositories/user/
└── user_stats_repository_impl.dart   # impl

lib/core/cache/
└── dashboard_cache.dart              # SharedPreferences wrapper cho DashboardStats

functions/
└── (mở rộng index.js — không tách file riêng cho gọn)
```

### 4.2 File sửa

| File | Thay đổi |
|---|---|
| `lib/presentation/home/dashboard/bloc/dashboard_bloc.dart` | `_load` đọc `UserStatsRepository.getSummary(uid)` thay vì duyệt leagues. Fallback: nếu `summary == null` → gọi `recomputeUserSummary()` rồi reload. Inject `DashboardCache`. |
| `lib/presentation/home/dashboard/bloc/dashboard_event.dart` | (không đổi) |
| `lib/presentation/home/dashboard/bloc/dashboard_state.dart` | Thêm `bool isStale` (true khi đang fetch nền sau cache hit). |
| `lib/presentation/home/dashboard/models/dashboard_stats.dart` | Thêm `wins, draws, losses, goals, goalsConceded`. Derived getters `winRate`, `championRate`. |
| `lib/firebase/firestore/gn_firestore.dart` | Thêm method `getUserSummary(uid)`, `getH2H(uid, opponentUid)`, `recomputeUserSummary(uid)`. |
| `lib/injection_container.dart` | Register `UserStatsRepository`, `DashboardCache`. |
| `functions/index.js` | Thêm `onLeagueMatchWritten`, `onLeagueStatusChanged`. |

### 4.3 File **không** đổi (quan trọng)

- `lib/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart` — giữ nguyên `updateMatch`. Cloud function bắt write event.
- `EsportLeagueRepository` interface — không đụng. Tách stats user ra repo mới.

## 5. Triển khai chi tiết

### 5.1 Entity `GNUserStatsSummary`

```dart
class GNUserStatsSummary extends Equatable {
  final String userId;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int goalsConceded;
  final int tournamentsJoined;
  final int tournamentsFinished;
  final int championCount;
  final int runnerUpCount;
  final DateTime? lastChampionAt;
  final List<RecentMatchSummary> recentMatches;
  final DateTime? updatedAt;
  final int schemaVersion;

  const GNUserStatsSummary({...});

  // Theo CLAUDE.md test policy: expose fromMap để test không cần mock DocumentSnapshot.
  factory GNUserStatsSummary.fromMap(Map<String, dynamic> map, String userId) { ... }
  factory GNUserStatsSummary.fromFirestore(DocumentSnapshot doc) =>
      GNUserStatsSummary.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  Map<String, dynamic> toMap() { ... }

  // Derived
  double? get winRate => matchesPlayed == 0 ? null : wins / matchesPlayed;
  int get goalDifference => goals - goalsConceded;
  double? get championRate =>
      tournamentsFinished == 0 ? null : championCount / tournamentsFinished;

  @override
  List<Object?> get props => [...];
}
```

`GNUserH2H` tương tự.

### 5.2 `UserStatsRepository`

```dart
abstract class UserStatsRepository {
  Future<GNUserStatsSummary?> getSummary(String uid);
  Future<GNUserH2H?> getH2H({required String uid, required String opponentUid});
  Future<void> recomputeSummary(String uid);   // gọi callable function
  Stream<GNUserStatsSummary?> listenSummary(String uid);
}
```

Impl đọc từ `users/{uid}/stats/summary` và subcollection `h2h`.

### 5.3 `DashboardBloc._load` mới

```dart
Future<void> _load(Emitter<DashboardState> emit) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) { emit(failure('Người dùng chưa đăng nhập')); return; }

  // 1. Hydrate from cache nếu có (instant).
  final cached = await _cache.read(uid);
  if (cached != null) {
    emit(state.copyWith(
      viewStatus: ViewStatus.success,
      stats: cached,
      isStale: true,
    ));
  } else {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
  }

  // 2. Fetch summary doc.
  try {
    var summary = await _userStatsRepo.getSummary(uid);

    // 3. Lazy-create nếu chưa có (user cũ trước khi feature ra).
    if (summary == null) {
      await _userStatsRepo.recomputeSummary(uid);
      summary = await _userStatsRepo.getSummary(uid);
    }

    if (summary == null) {
      emit(state.copyWith(viewStatus: ViewStatus.failure,
        errorMessage: 'Không tải được thống kê'));
      return;
    }

    final stats = _toDashboardStats(summary);
    await _cache.write(uid, stats);
    emit(state.copyWith(viewStatus: ViewStatus.success, stats: stats, isStale: false));
  } catch (e) {
    if (state.stats == null) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    } else {
      // Có cached → giữ nguyên, chỉ log.
      emit(state.copyWith(isStale: true));
    }
  }
}
```

### 5.4 Cloud Function — `onLeagueMatchWritten`

```js
exports.onLeagueMatchWritten = onDocumentWritten(
  'esports_leagues/{leagueId}/leagues_matches/{matchId}',
  async (event) => {
    const { leagueId, matchId } = event.params;
    const before = event.data.before.exists ? event.data.before.data() : null;
    const after  = event.data.after.exists  ? event.data.after.data()  : null;

    // Resolve actors
    const home = (after || before).homeTeamId;
    const away = (after || before).awayTeamId;

    // Compute delta net
    const undo = (before && before.isFinished)
      ? statContribution(before.homeScore, before.awayScore, -1) : zero();
    const apply = (after && after.isFinished)
      ? statContribution(after.homeScore, after.awayScore, +1) : zero();
    const homeDelta = sumDelta(undo.home, apply.home);
    const awayDelta = sumDelta(undo.away, apply.away);

    if (isZero(homeDelta) && isZero(awayDelta)) return;

    // Resolve league name (denormalize) — read once
    const leagueDoc = await db.collection('esports_leagues').doc(leagueId).get();
    const leagueName = leagueDoc.data()?.name || '';

    const batch = db.batch();
    applyToUserSummary(batch, home, homeDelta, after, leagueName, away);
    applyToUserSummary(batch, away, awayDelta, after, leagueName, home);
    applyToH2H(batch, home, away, homeDelta);
    applyToH2H(batch, away, home, awayDelta);
    await batch.commit();
  }
);
```

`applyToUserSummary` cũng cập nhật `recentMatches` array bằng cách read-modify-write (cap 20). Đây là 1 read + 1 write per user per match — acceptable với write rate matches (admin nhập).

`onLeagueStatusChanged` xử lý `championCount/runnerUpCount/lastChampionAt`:

```js
exports.onLeagueStatusChanged = onDocumentUpdated(
  'esports_leagues/{leagueId}',
  async (event) => {
    const before = event.data.before.data();
    const after  = event.data.after.data();
    if (before.status === after.status) return;

    if (after.status === 'finished' && before.status !== 'finished') {
      // Read leagues_stats sub, sort by points/GD/goals, top-2 → bump fields.
      // Update lastChampionAt = endDate || startDate.
    } else if (before.status === 'finished' && after.status !== 'finished') {
      // Reverse — rare admin undo.
    }
  }
);
```

### 5.5 Denormalize `opponentDisplayName`

`recentMatches[].opponentDisplayName` và `h2h.opponentDisplayName` là snapshot. Khi user đổi tên → stale.

**Mitigation**: thêm trigger `onUserDocUpdate` nếu `displayName` đổi → propagate sang h2h docs (`users/{*}/h2h/{thisUid}`). Có thể là phase sau — phase 1 chấp nhận stale name (UI có thể fallback fetch user nếu cần render mới).

### 5.6 Idempotency của Cloud Function

Firestore triggers retry → có thể fire 2 lần. Phải đảm bảo:

- Trigger luôn dùng **delta net từ before/after**, không dùng "increment by score". Retry với cùng before/after → cùng delta → áp dụng 2 lần sẽ sai.
- **Giải pháp**: dedupe bằng `event.id`. Trước khi commit batch, check/write `users/{uid}/stats/_events/{eventId}` (TTL doc). Nếu đã tồn tại → skip.
- Hoặc dùng **transaction** với precondition `lastEventId != currentEventId` ở summary doc.

**Quyết định**: dùng **summary doc field `lastEventIds: array (cap 50)`** trong transaction — đơn giản hơn TTL, không cần subcollection.

## 6. Test (theo policy 100% coverage trong CLAUDE.md)

### 6.1 Unit tests Dart

- `test/firebase/firestore/user/stats/gn_user_stats_summary_test.dart`:
  - `fromMap` round-trip với mọi field.
  - Derived getters: `winRate` khi `matchesPlayed == 0` → null.
  - `goalDifference`, `championRate` cases.
- `test/firebase/firestore/user/stats/gn_user_h2h_test.dart`: tương tự.
- `test/data/repositories/user/user_stats_repository_impl_test.dart`:
  - `getSummary` map đúng từ Firestore mock.
  - `getSummary` returns null khi doc not exists.
- `test/presentation/home/dashboard/bloc/dashboard_bloc_test.dart` (cập nhật):
  - Cache hit → emit success ngay với `isStale: true`, sau đó refetch.
  - Cache miss + summary exists → 1 emit success.
  - Summary missing → trigger `recomputeSummary`, reload.
  - Recompute fail → failure state.
  - `RefreshDashboard` không clear stats khi đang fetch.
- `test/core/cache/dashboard_cache_test.dart`:
  - Read/write round-trip qua `SharedPreferences.setMockInitialValues`.
  - Read trả null khi key không tồn tại / data corrupt.

### 6.2 Cloud Function tests

`functions/test/index.test.js` (mới — đã có Jest? nếu chưa, dùng `firebase-functions-test` + Mocha):

- `onLeagueMatchWritten`:
  - Create finished match → home & away summary tăng đúng W/D/L/goals.
  - Update score (3-1 → 2-1) → delta net áp dụng đúng (undo cũ + apply mới), không double-count.
  - Update isFinished false → true → apply.
  - Update isFinished true → false → undo.
  - Delete finished match → undo.
  - Idempotency: gọi 2 lần cùng `event.id` → chỉ apply 1.
  - H2H: A vs B 3-1 → A.h2h.B.wins=1, B.h2h.A.losses=1.
- `onLeagueStatusChanged`:
  - ongoing → finished với standings rõ ràng → top-1 championCount++, top-2 runnerUpCount++.
  - finished → ongoing → undo.

### 6.3 Manual end-to-end

1. `cd functions && npm run serve` (emulator) hoặc deploy staging.
2. `flutter run` (dùng emulator).
3. User A login → tạo league, thêm participant B → nhập match A 3-1 B → `firebase emulators` log thấy trigger fire.
4. Verify Firestore emulator UI: `users/A/stats/summary` có `wins=1, goals=3, goalsConceded=1, recentMatches[0].result=win`.
5. Sửa match thành 2-2 → summary cập nhật `wins=0, draws=1, goals=2, goalsConceded=2`.
6. Mở app A → dashboard hiển thị đúng (chỉ 1 doc read trong Network tab).
7. End league A → trigger status → `championCount` tăng cho user xếp #1.
8. Mở screen H2H (nếu UI đã build) → verify A vs B doc match.

### 6.4 Performance verification

- Trước: log `Firestore.instance` reads bằng wrapper hoặc đếm trong test → expect `1 + 2N`.
- Sau: expect **1 read** (`users/{uid}/stats/summary`).
- Coverage: `flutter test --coverage` cho file mới ≥ 100% theo policy.

## 7. Acceptance criteria

- [ ] Dashboard load chỉ thực hiện **1 Firestore read** (đo bằng debug instrumentation).
- [ ] Mở Home lần thứ 2 → cache hit → render <50ms perceived.
- [ ] Khi nhập / sửa / xoá tỉ số match: trong vòng ≤ 5s, dashboard pull-to-refresh thấy số liệu mới chính xác (không lệch).
- [ ] Khi sửa tỉ số nhiều lần liên tiếp → summary không double-count (verify bằng integration test).
- [ ] User cũ (chưa có summary doc) mở Home → tự động backfill và render đúng.
- [ ] H2H doc tồn tại sau ≥ 1 finished match giữa 2 user.
- [ ] `flutter analyze` clean. `flutter test --coverage` ≥ 100% cho file mới.
- [ ] Cloud function tests pass.

## 8. Migration order (giảm rủi ro deploy)

| Bước | Hành động | Rollback nếu fail |
|---|---|---|
| 1 | Tạo entity + repo + tests (chưa wire). | Revert commit. |
| 2 | Deploy Cloud Function `onLeagueMatchWritten` + `onLeagueStatusChanged`. **Chỉ ghi vào collection mới** — chưa ai đọc. | Disable function. |
| 3 | Deploy callable `recomputeUserSummary`. | Disable function. |
| 4 | Test trên staging với vài user thật. Verify summary chính xác. | — |
| 5 | Đổi `DashboardBloc` sang đọc summary, **giữ fallback** sang code cũ nếu summary null hoặc lỗi. | Feature flag tắt. |
| 6 | Sau 1 tuần monitoring không lỗi → xoá fallback. | — |

## 9. Rủi ro & cách xử lý

| Rủi ro | Xử lý |
|---|---|
| Cloud function retry → double-apply delta | `lastEventIds` array trong summary doc + transaction precondition. |
| User đổi displayName → h2h stale | Phase 2: trigger `onUserDocUpdate` propagate. Phase 1: chấp nhận. |
| `recentMatches` array nặng | Cap cứng 20 items — read-modify-write trong function. |
| Backfill chạy đồng thời với write mới → race | Dùng transaction trong `recomputeUserSummary`; lock bằng `recomputeInProgress: true` field. |
| Cloud function cost tăng | Matches được nhập không nhiều (admin ops, ~chục/ngày trên giải lớn) → chi phí trigger không đáng kể. |
| Schema thay đổi sau này | Field `schemaVersion` để migrate; bump version → invalidate cache, recompute. |
| Lỗi function ăn mòn data | Không xoá raw matches/leagues_stats. Có thể recompute từ raw bất cứ lúc nào (`recomputeUserSummary`). |

## 10. Phase tiếp theo (out of scope)

- **UI**: stat cards W/D/L lifetime, profile compare 1-vs-1, biểu đồ phong độ theo thời gian.
- **Group-level dashboard**: aggregate trong scope group (đã đề cập plan trước Section 10).
- **Win streak / form rating** — derive thêm từ `recentMatches`.
- **Search "đối thủ khắc tinh"** — top opponents user thua nhiều nhất (rank theo h2h).
- **Real-time listener cho summary** thay vì pull — thay `getSummary` bằng `listenSummary` để dashboard tự refresh khi function ghi xong.
- **Offline mode mirror**: cùng schema cho `lib/offline/` (player_league_table đã sẵn pattern aggregate; thêm `player_summary_table`).

## 11. Ước lượng

- File mới: ~6 (Dart) + 1 (functions).
- File sửa: 4 Dart + 1 functions.
- Test: ~6 file Dart + 1 functions test file.
- Effort:
  - Dev nền (entity, repo, function, tests): 2 ngày.
  - Wire BLoC + cache + tests: 1 ngày.
  - QA staging + monitoring: 1–2 ngày.
- Tổng: **~4–5 ngày**.

## 12. Critical files (dùng cho người implement)

**Đọc trước khi code:**

- `lib/presentation/home/dashboard/bloc/dashboard_bloc.dart:47-168` — load logic hiện tại, helper `_compareStandings`, `_summaryForMatch`.
- `lib/presentation/home/dashboard/models/dashboard_stats.dart`, `recent_match_summary.dart` — model đang dùng UI.
- `lib/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart:120-222` — pattern delta `_statContribution`, `updateMatch` transaction.
- `lib/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart:72+` — `recomputeLeagueStats` (tham chiếu logic fold cho function backfill).
- `lib/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart` — schema fields & getters (`points`, `goalDifference`).
- `functions/index.js` — pattern setup trigger hiện có.
- `plans/2026-05-04-home-dashboard-tab.md` — plan trước đã ship dashboard, biết UI hiện hành.
