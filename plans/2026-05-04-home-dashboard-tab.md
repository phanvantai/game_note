# Plan: Tab Home với Dashboard cá nhân + Nhóm

**Ngày:** 2026-05-04
**Trạng thái:** Chưa triển khai
**Phụ thuộc:** Plan `2026-05-04-remove-esport-game-selection.md` (nên xong trước, không bắt buộc).
**Người thực hiện dự kiến:** codex / deepseek / sonnet agent

---

## 1. Mục tiêu

Đổi cấu trúc tab gốc từ `[Giải đấu, Nhóm, Cá nhân]` thành `[Home, Giải đấu, Cá nhân]`, trong đó **Home** là một page có 2 sub-tab:

1. **Dashboard** — thống kê thành tích cá nhân của user, tổng hợp từ tất cả group + league user tham gia.
2. **Nhóm** — reuse `GroupsView` hiện tại.

Tab "Giải đấu" (top-level) và "Cá nhân" giữ nguyên.

## 2. Yêu cầu UI/UX của Dashboard

### 2.1 Layout (top → bottom)

```
┌─────────────────────────────────────────┐
│ AppBar: "Trang chủ"  [🔔 notif badge]   │
├─────────────────────────────────────────┤
│ TabBar: [Dashboard] [Nhóm]              │
├─────────────────────────────────────────┤
│ ── Dashboard tab ──                     │
│                                         │
│ ┌──────────┬──────────┐                 │
│ │ Giải đã  │ Tỉ lệ    │                 │
│ │ tham gia │ vô địch  │                 │
│ │   12     │  25%     │                 │
│ ├──────────┼──────────┤                 │
│ │ Tỉ lệ về │ Vô địch  │                 │
│ │ nhì      │ gần nhất │                 │
│ │  17%     │ 3 ngày   │                 │
│ └──────────┴──────────┘                 │
│                                         │
│ "Phong độ 10 trận gần nhất"             │
│  ● ● ● ● ● ● ● ● ● ●  (W=xanh,         │
│   D=vàng, L=đỏ; trái = mới nhất)        │
│                                         │
│ "Trận gần đây"                          │
│ ┌─────────────────────────────────────┐ │
│ │ 03/05 · Champions Cup               │ │
│ │ Bạn 3 - 1 NamPhan      ✅          │ │
│ ├─────────────────────────────────────┤ │
│ │ ...                                 │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### 2.2 Stat cards (4 ô)

| Tên | Giá trị | Cách tính |
|---|---|---|
| Giải tham gia | int | `count(league)` user là participant (`league.participants.contains(uid)`). |
| Tỉ lệ vô địch | `championCount / finishedCount * 100%` | `finishedCount` = số league `status == finished` user tham gia. `championCount` = số league trong đó user xếp #1 ở standings. |
| Tỉ lệ á quân | `runnerUpCount / finishedCount * 100%` | #2 ở standings. |
| Vô địch gần nhất | "X ngày trước" hoặc dd/MM/yyyy | `max(league.endDate ?? league.updatedAt)` của các league user vô địch; null → hiển thị "—". |

**Sort standings** dùng đúng logic hiện hành ở `tournament_detail_bloc.dart:162-164`: `points DESC → goalDifference DESC → goals DESC`.

Edge cases:
- `finishedCount == 0` → tỉ lệ hiển thị "—" (tránh chia 0).
- Khi vẫn loading → skeleton/shimmer cho từng card.

### 2.3 "Phong độ 10 trận"

- Lấy **10 match gần nhất** mà:
  - `match.isFinished == true`
  - User là 1 trong 2 player (`homeTeamId == uid || awayTeamId == uid`)
- Sort by `match.date DESC` (nếu thiếu date, dùng `updatedAt`).
- Mỗi match → 1 dot:
  - **W (xanh)**: side của user score > đối thủ
  - **D (vàng)**: bằng nhau
  - **L (đỏ)**: thua
- Hiển thị 10 dot ngang, leftmost = mới nhất. Nếu < 10 trận → chỉ render đúng số có.
- Empty state: "Chưa có trận nào".

### 2.4 List 10 trận gần nhất

- Cùng dataset với 2.3.
- Mỗi item:
  - Ngày `dd/MM`
  - Tên league
  - "Bạn N - M Đối-thủ" (với "Bạn" thay cho display name của uid)
  - Icon W/D/L (màu giống dot)
- Tap item → push `Routing.tournamentDetailPath(match.leagueId)`.

## 3. Cấu trúc code

### 3.1 File mới

```
lib/presentation/home/
├── home_page.dart                         # AppBar + TabBar(Dashboard|Nhóm)
├── dashboard/
│   ├── dashboard_view.dart                # widget tree
│   ├── bloc/
│   │   ├── dashboard_bloc.dart
│   │   ├── dashboard_event.dart
│   │   └── dashboard_state.dart
│   ├── models/
│   │   ├── dashboard_stats.dart           # value object
│   │   └── recent_match_summary.dart      # match + result enum
│   └── widgets/
│       ├── stat_card_grid.dart
│       ├── form_dots_row.dart
│       └── recent_matches_list.dart
```

### 3.2 File sửa

- `lib/presentation/main/main_view.dart`: 3 tab mới `[Home, Giải đấu, Cá nhân]`.
- `lib/injection_container.dart`: register `DashboardBloc`.
- `lib/app.dart` hoặc nơi `MultiBlocProvider` cấp app: provide `DashboardBloc`.
- `lib/presentation/esport/groups/groups_view.dart`: hiện tại có AppBar + 2 inner tab + FAB "Tạo nhóm". Khi nhúng vào Home, AppBar **không cần** (Home đã có rồi). Tách thành:
  - `GroupsView` (hiện tại) — vẫn standalone-able.
  - Thêm constructor `GroupsView({this.embedded = false})`. Khi `embedded=true` → bỏ Scaffold/AppBar bên ngoài, chỉ render body + FAB. (Hoặc chia thành `GroupsBody` + `GroupsScaffold`; xem 5.2.)

## 4. Data layer — không thêm repo mới

Tận dụng method có sẵn:

- `EsportLeagueRepository.getMyLeagues()` (`lib/domain/repositories/esport/esport_league_repository.dart:24`) → trả về `List<GNEsportLeague>` user owns hoặc participants.
- Với mỗi league: `getLeagueStats(leagueId)` + `getMatches(leagueId)`. Dùng `getParticipantsAndMatches(leagueId)` để load song song.
- **Cảnh báo cost**: nếu user có 50 league, đây là 50 round-trip song song. Phase 1 chấp nhận; theo dõi performance, optimize sau (ví dụ: lưu cache `championUserId` vào league doc — phase sau).

### 4.1 DashboardBloc

**Event:**
```dart
class LoadDashboard extends DashboardEvent {}
class RefreshDashboard extends DashboardEvent {}
```

**State (`Equatable`):**
```dart
class DashboardState {
  final ViewStatus viewStatus;            // initial/loading/success/failure
  final DashboardStats? stats;            // null khi chưa load
  final String? errorMessage;
}
```

**`DashboardStats`:**
```dart
class DashboardStats {
  final int tournamentsJoined;            // tổng league user là participant
  final int finishedTournaments;          // league đã finish
  final int championCount;
  final int runnerUpCount;
  final DateTime? lastChampionAt;
  final List<RecentMatchSummary> recentMatches; // length ≤ 10, sort desc by date
}

enum MatchResult { win, draw, loss }

class RecentMatchSummary {
  final String matchId;
  final String leagueId;
  final String leagueName;
  final DateTime date;
  final int userScore;
  final int opponentScore;
  final String opponentDisplayName;
  final MatchResult result;
}
```

**Handler `_onLoadDashboard`:**
1. Lấy `uid` từ `GNAuth` (qua getIt).
2. `final leagues = await leagueRepo.getMyLeagues();`
3. Filter các league user là participant: `leagues.where((l) => l.participants.contains(uid))`.
4. `tournamentsJoined = filtered.length`.
5. `Future.wait` cho mỗi league: `getParticipantsAndMatches(league.id)`.
6. Với mỗi `(league, data)`:
   - **Standings rank**: sort `data.participants` theo `points DESC, goalDifference DESC, goals DESC`. Tìm index của stat `userId == uid`.
   - Nếu `league.status == 'finished'`:
     - `finishedCount++`.
     - `rank == 0` → `championCount++`, cập nhật `lastChampionAt = max(lastChampionAt, league.endDate ?? league.updatedAt)`.
     - `rank == 1` → `runnerUpCount++`.
   - **Matches của user**: filter `data.matches.where((m) => m.isFinished && (m.homeTeamId == uid || m.awayTeamId == uid))`. Gắn `leagueName = league.name`.
7. Gộp toàn bộ `userMatches` từ mọi league, sort `date DESC`, `take(10)`.
8. Resolve `opponentDisplayName` qua `getIt<GNFirestoreUser>().getUsersById([...opponentIds])` (batch, đã có sẵn).
9. Build `DashboardStats`, emit `success`.

Failure path: catch exception → emit `failure` với `errorMessage`.

**Handler `_onRefreshDashboard`:** giống `LoadDashboard` nhưng giữ `stats` cũ trong khi loading (state `loading` không clear).

### 4.2 Caching

- Phase 1: không cache. Mỗi lần vào tab Dashboard hoặc pull-to-refresh → load lại.
- Tab `Home` build → `BlocProvider.value` của `DashboardBloc` đã register sẵn ở root; trigger `LoadDashboard` lần đầu trong `initState` của `DashboardView`.

## 5. Triển khai chi tiết

### 5.1 `MainView` — đổi tab structure

`lib/presentation/main/main_view.dart`:

```dart
tabs = {
  const BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home),
    label: 'Trang chủ',
  ): const HomePage(),
  const BottomNavigationBarItem(
    icon: Icon(Icons.emoji_events_outlined),
    activeIcon: Icon(Icons.emoji_events),
    label: 'Giải đấu',
  ): const TournamentView(),
  const BottomNavigationBarItem(
    icon: Icon(Icons.person_outline),
    activeIcon: Icon(Icons.person),
    label: 'Cá nhân',
  ): const ProfileView(),
};
```

- Bỏ tab "Nhóm" cũ (đã chuyển vào Home).
- `context.read<GroupBloc>().add(GetEsportGroups())` ở `initState` → giữ nguyên (Home tab Groups vẫn cần).

### 5.2 `HomePage`

`lib/presentation/home/home_page.dart`:

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trang chủ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bảng điều khiển'),
              Tab(text: 'Nhóm'),
            ],
          ),
          actions: [
            // Reuse notification icon — copy block từ groups_view.dart line 53-77.
            _NotificationBellAction(),
          ],
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            DashboardView(),
            GroupsView(embedded: true), // không tự render Scaffold/AppBar
          ],
        ),
      ),
    );
  }
}
```

**`GroupsView` cập nhật:**
- Thêm tham số `final bool embedded;` (default false).
- Khi `embedded == true`:
  - Không bọc `Scaffold` ngoài.
  - Không render `AppBar` (TabBar "Nhóm của tôi" / "Nhóm khác" giữ lại — render thẳng trong body).
  - FAB "Tạo nhóm" giữ — wrap bằng `Stack` hoặc dùng `Scaffold` không có AppBar tuỳ design.
- Khi `embedded == false`: behavior cũ (giữ để fallback / dev tools).

Refactor đơn giản nhất: tách body của `GroupsView` thành `_GroupsBody` private widget, `GroupsView.build` tuỳ `embedded` chọn:
- `embedded=true`: `return Scaffold(body: _GroupsBody(), floatingActionButton: ...);` (không AppBar, không inner DefaultTabController nữa nếu Home đã có TabController? — **không**, Home tab "Nhóm" vẫn cần inner tab "Của tôi"/"Khác" → giữ inner DefaultTabController length=2 trong body của GroupsView).

> Edge case: Home đang dùng `DefaultTabController(length: 2)` ở ngoài, GroupsView dùng `DefaultTabController(length: 2)` ở trong → 2 controller riêng, không xung đột. Xác nhận rồi triển khai.

### 5.3 `DashboardView`

```dart
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});
  ...
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.viewStatus == ViewStatus.loading && state.stats == null) {
          return const _DashboardSkeleton();
        }
        if (state.viewStatus == ViewStatus.failure) {
          return _DashboardError(message: state.errorMessage ?? 'Lỗi tải dữ liệu');
        }
        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: () async {
            context.read<DashboardBloc>().add(RefreshDashboard());
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatCardGrid(stats: stats),
              const SizedBox(height: 24),
              Text('Phong độ 10 trận gần nhất', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FormDotsRow(matches: stats.recentMatches),
              const SizedBox(height: 24),
              Text('Trận gần đây', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              RecentMatchesList(matches: stats.recentMatches),
            ],
          ),
        );
      },
    );
  }
}
```

### 5.4 Widgets

- `StatCardGrid`: `GridView.count(crossAxisCount: 2)` 4 card. Mỗi card: title + value lớn. Dùng theme colors.
- `FormDotsRow`: `Row` 10 `Container` 12x12 borderRadius full, color theo `MatchResult`. Padding giữa.
- `RecentMatchesList`: `Column` các `ListTile` (KHÔNG `ListView` lồng `ListView`). Card hoặc `Material` wrapper.

### 5.5 DI

`lib/injection_container.dart`:

```dart
sl.registerFactory(() => DashboardBloc(
  leagueRepository: sl(),
  authProvider: sl<GNAuth>(),
  userFirestore: sl(),
));
```

Provide ở root (cùng chỗ provide các bloc khác — kiểm tra `lib/app.dart` để thống nhất pattern).

## 6. Test (theo policy 100% coverage)

### 6.1 Unit test `DashboardBloc`

`test/presentation/home/dashboard/bloc/dashboard_bloc_test.dart`:

- Mock `EsportLeagueRepository`, `GNAuth`, `GNFirestoreUser` (mocktail).
- `bloc_test`:
  - `LoadDashboard` thành công với 3 league (1 finished/champion, 1 finished/runner-up, 1 ongoing) → assert `tournamentsJoined=3`, `championCount=1`, `runnerUpCount=1`, `finishedTournaments=2`, `lastChampionAt` đúng.
  - `LoadDashboard` với 0 league → `tournamentsJoined=0`, `recentMatches=[]`, tỉ lệ "—" (logic hiển thị thì widget test).
  - Sort recentMatches: 15 trận từ 3 league → `recentMatches.length == 10`, sort `date DESC`.
  - Tie-break standings: 2 user cùng points, khác goalDifference → user nào có GD cao xếp #1.
  - Failure path: `getMyLeagues` throw → state `failure`.
  - `RefreshDashboard`: giữ `stats` cũ trong khi loading.

### 6.2 Widget test

- `dashboard_view_test.dart`:
  - State loading → render skeleton.
  - State success với stats có 3 trận W/D/L → render 3 dot đúng màu, list 3 item.
  - State success với 0 trận → render empty state cho dots & list.
  - State failure → render error widget với message.
  - Pull-to-refresh dispatch `RefreshDashboard`.
- `stat_card_grid_test.dart`: hiển thị "—" khi `finishedTournaments == 0`.
- `form_dots_row_test.dart`: render đúng số dot, đúng color theo result.
- `recent_matches_list_test.dart`: tap item → navigate đúng route.
- `home_page_test.dart`: 2 sub-tab, switch tab thấy đúng widget.
- `groups_view_embedded_test.dart`: `embedded=true` không render AppBar.

### 6.3 Test factories cần

- `RecentMatchSummary` test factory.
- `GNEsportLeagueStat`, `GNEsportMatch`, `GNEsportLeague` đã có `fromMap` pure factory → dùng tốt.

## 7. Acceptance criteria

- [ ] BottomNav có đúng 3 tab `[Trang chủ, Giải đấu, Cá nhân]`.
- [ ] Tab "Trang chủ" có 2 sub-tab `[Bảng điều khiển, Nhóm]`.
- [ ] Sub-tab "Nhóm" hiển thị giống `GroupsView` cũ (2 inner tab + FAB), không có AppBar trùng lặp.
- [ ] Sub-tab "Bảng điều khiển":
  - 4 stat card đúng số liệu (verify thủ công với 1 league đã finished thử nghiệm).
  - Hàng dot phong độ render đúng W/D/L.
  - List 10 match render, tap → vào league detail.
  - Pull-to-refresh hoạt động.
  - Empty/loading/failure đều có UI rõ ràng.
- [ ] `flutter analyze` clean.
- [ ] `flutter test --coverage`: `lib/presentation/home/**` ≥ 90% line coverage.

## 8. Rủi ro & cách xử lý

| Rủi ro | Xử lý |
|---|---|
| User có nhiều league → load chậm | Phase 1 chấp nhận; thêm spinner. Phase sau: cache `championUserId` vào league doc. |
| `league.endDate` null → không xác định "vô địch gần nhất" | Fallback `league.updatedAt`. |
| Dữ liệu standings rỗng (league mới, chưa có stat) | Skip league đó (không tính vào finished/champion). |
| `recentMatches` mixed timezone | Tất cả đều `Timestamp.toDate()` → UTC offset thống nhất; sort tin. |
| Conflict `DefaultTabController` Home và GroupsView nội tại | Mỗi `DefaultTabController` tự bind controller con, không đụng. |
| Notification icon trong Home + GroupsView trùng | Khi `embedded=true` GroupsView không render AppBar → không trùng. |

## 9. Ước lượng

- File mới: ~10.
- File sửa: 3 (`main_view.dart`, `groups_view.dart`, `injection_container.dart`).
- Test: ~8 file.
- Effort: 1.5–2 ngày dev + test.

## 10. Phase tiếp theo (out of scope)

- Dashboard cấp **group** (vô địch theo từng group, head-to-head, biểu đồ phong độ theo thời gian).
- Cache server-side `championUserId` để tránh load matches/stats để xác định ngôi vô địch.
- Filter dashboard theo group / theo khoảng thời gian.
