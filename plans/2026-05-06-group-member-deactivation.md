# Plan: Group Member Deactivation

**Ngày:** 2026-05-06

## Mục tiêu

Admin của group có thể đánh dấu một thành viên là "không hoạt động" (deactivate). Thành viên đó:
- Không hiện trong bảng xếp hạng và awards của group overview (all-time & year filter)
- Không hiện trong picker khi thêm participant vào giải mới
- Có thể reactivate bất kỳ lúc nào

Lịch sử trận đấu và stats tổng của group **không thay đổi** — deactivate là ẩn khỏi display, không phải xoá dữ liệu.

## Quyết định thiết kế

### Tại sao không xoá stats của active user liên quan đến deactivated user

Mỗi trận đấu là sự kiện có 2 phía. Win của Hùng trước Tuấn là thật — nếu xoá đi khi Tuấn bị deactivate thì stats của Hùng bị corrupt, và `totalGoals` của group mất đối xứng. Deactivate chỉ nghĩa là "không còn thi đua", không phải "chưa từng tồn tại".

### Cách xử lý aggregate numbers

`GroupOverviewCalculator` tính `totalMatchesPlayed` và `totalGoals` bằng cách fold toàn bộ `playerStats`. Cần giữ deactivated user trong fold này, chỉ loại khỏi `playerStats` đầu ra (bảng xếp hạng) và awards.

### Lưu trữ

Thêm field `deactivatedMembers: List<String>` vào `GNEsportGroup` (Firestore array). Mọi group hiện tại tự nhiên có field này là `[]` — không cần migration.

Giữ nguyên `members` — `deactivatedMembers` là overlay "ẩn", không thay thế membership.

**Cleanup rule:** khi admin xoá một member khỏi `members`, đồng thời `arrayRemove` userId đó khỏi `deactivatedMembers` (dùng Firestore batch để atomic).

---

## Phạm vi thay đổi

### 1. Data model — `GNEsportGroup`

**File:** `lib/firebase/firestore/esport/group/gn_esport_group.dart`

Thêm field:
```dart
final List<String> deactivatedMembers;
```

Cập nhật:
- Constructor (default `const []`)
- `copyWith`
- `fromFirestore` / `toFirestore`
- `props`
- Thêm const key: `static const String deactivatedMembersKey = 'deactivatedMembers';`

---

### 2. Firestore — toggle deactivation

**File:** `lib/firebase/firestore/esport/group/gn_firestore_esport_group.dart`

Thêm method:

```dart
Future<void> toggleMemberDeactivation({
  required String groupId,
  required String userId,
  required bool deactivate,
}) async {
  await firestore
      .collection(GNEsportGroup.collectionName)
      .doc(groupId)
      .update({
    GNEsportGroup.deactivatedMembersKey: deactivate
        ? FieldValue.arrayUnion([userId])
        : FieldValue.arrayRemove([userId]),
  });
}
```

Cũng cập nhật method `removeMember` hiện tại để cleanup `deactivatedMembers` đồng thời:

```dart
// Trong removeMember — dùng WriteBatch hoặc Map update:
{
  GNEsportGroup.membersKey: FieldValue.arrayRemove([userId]),
  GNEsportGroup.deactivatedMembersKey: FieldValue.arrayRemove([userId]),
}
```

---

### 3. Repository

**File:** `lib/domain/repositories/esport/esport_group_repository.dart`

Thêm method:
```dart
Future<void> toggleMemberDeactivation({
  required String groupId,
  required String userId,
  required bool deactivate,
});
```

**File:** `lib/data/repositories/esport/esport_group_repository_impl.dart`

Implement: delegate sang `_firestore.toggleMemberDeactivation(...)`.

---

### 4. BLoC

**File:** `lib/presentation/esport/groups/group_detail/bloc/group_detail_event.dart`

```dart
class ToggleMemberDeactivation extends GroupDetailEvent {
  const ToggleMemberDeactivation({
    required this.groupId,
    required this.userId,
    required this.deactivate,
  });
  final String groupId;
  final String userId;
  final bool deactivate;
}
```

**File:** `lib/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart`

Handler `_onToggleMemberDeactivation`:
1. Optimistic update: emit `state.copyWith(group: state.group.copyWith(deactivatedMembers: ...))` ngay lập tức
2. Gọi `_groupRepository.toggleMemberDeactivation(...)`
3. Nếu lỗi: rollback về state cũ, emit error message

Không cần field mới trong `GroupDetailState` — `state.group.deactivatedMembers` là đủ.

---

### 5. Stats filtering — `GroupOverviewCalculator`

**File:** `lib/presentation/esport/groups/group_detail/services/group_overview_calculator.dart`

Thêm tham số `Set<String> deactivatedIds = const {}` vào `compute()`.

Tách logic:

```dart
final allPlayers = summary.playerStats;
final activePlayers = allPlayers
    .where((e) => !deactivatedIds.contains(e.userId))
    .toList();

// Aggregate từ ALL players — giữ đúng lịch sử group
final totalPlayerMatches = allPlayers.fold<int>(0, (acc, e) => acc + e.matches);
final totalGoals = allPlayers.fold<int>(0, (acc, e) => acc + e.goals);

// Ranking và awards chỉ từ active players
final playerStats = activePlayers.map(...).toList();
// _bestRate, _drawKing, _ironDefense, _master — truyền activePlayers
```

Tất cả private helpers (`_bestRate`, `_drawKing`, `_ironDefense`, `_master`) nhận `activePlayers` thay vì `allPlayers` — không cần thay đổi signature các helper này.

---

### 6. Stats filtering — `GroupOverviewYearFilter`

**File:** `lib/presentation/esport/groups/group_detail/services/group_overview_year_filter.dart`

Thêm tham số `Set<String> deactivatedIds = const {}` vào `aggregate()`.

Trong vòng lặp accumulation, giữ nguyên (acc vẫn tích lũy cho deactivated user vì cần cho consistency). Nhưng khi build `playerEntries` cuối cùng, filter ra:

```dart
final playerEntries = acc.values
    .where((e) => !deactivatedIds.contains(e.userId))  // thêm dòng này
    .map((e) => GNEsportGroupPlayerEntry(...))
    .toList();
```

Tuy nhiên `totalMatchesPlayed` / `totalGoals` trong `GroupOverview` được tính từ `playerEntries` trong `GroupOverviewCalculator` — vì đã patch ở bước 5 để tính từ `allPlayers` trước khi filter, nên không bị ảnh hưởng.

> **Lưu ý:** Với year filter, `GroupOverviewYearFilter` tạo `GNEsportGroupStatsSummary` synthetic rồi truyền vào `GroupOverviewCalculator`. Cách đơn giản nhất là filter trong `GroupOverviewCalculator` (bước 5) — không cần filter trong `GroupOverviewYearFilter`, vì `GroupOverviewCalculator` đã nhận `deactivatedIds` và xử lý cả hai case.

---

### 7. Bloc — truyền `deactivatedIds` xuống calculator

**File:** `lib/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart`

Hai chỗ gọi `GroupOverviewCalculator.compute(...)`:
- `_onLoadGroupOverview` (all-time)
- `_onFilterGroupOverviewByYear` (year filter)

Thêm:
```dart
deactivatedIds: Set<String>.from(state.group.deactivatedMembers),
```

---

### 8. Participant picker — `searchUserByGroup`

**File:** `lib/firebase/firestore/user/gn_firestore_user.dart`

Method này đã fetch `group` doc để kiểm tra membership. Chỉ cần thêm một filter:

```dart
return uniqueDocs.values
    .map((doc) => GNUser.fromFireStore(doc))
    .where((user) =>
        group.members.contains(user.id) &&
        !group.deactivatedMembers.contains(user.id))  // thêm dòng này
    .toList();
```

---

### 9. UI — Members tab

**File:** `lib/presentation/esport/groups/group_detail/group_detail_view.dart` (widget `_MembersTab`)

Thay đổi trong `_MembersTab.build`:

- Đọc `deactivatedMembers = state.group.deactivatedMembers`
- Với mỗi member tile: nếu `deactivatedMembers.contains(user.id)` → hiện badge "Không hoạt động" (chip nhỏ màu surface variant)
- Owner: thay nút xoá bằng `PopupMenuButton` với 2 option:
  - Nếu user đang active: "Ngừng hoạt động" + icon `person_off_outlined`
  - Nếu user đang deactivated: "Kích hoạt lại" + icon `person_outlined`
  - "Xoá khỏi nhóm" (destructive, giữ nguyên behavior cũ)

Dispatch `ToggleMemberDeactivation` khi chọn.

**Không cần** confirm dialog cho toggle deactivation — action có thể undo ngay. Chỉ giữ confirm dialog cho "Xoá khỏi nhóm".

---

## Tests cần viết

### Unit tests

| File | Nội dung |
|------|---------|
| `test/firebase/firestore/esport/group/gn_esport_group_test.dart` | `fromFirestore` với `deactivatedMembers` có giá trị; với field vắng mặt → default `[]` |
| `test/firebase/firestore/esport/group/gn_firestore_esport_group_test.dart` | `toggleMemberDeactivation` gọi đúng `arrayUnion`/`arrayRemove`; `removeMember` cleanup cả `members` và `deactivatedMembers` |
| `test/presentation/esport/groups/group_detail/services/group_overview_calculator_test.dart` | Deactivated user: không trong `playerStats`, không nhận award; aggregate `totalMatchesPlayed` và `totalGoals` vẫn tính đủ kể cả deactivated |
| `test/presentation/esport/groups/group_detail/services/group_overview_year_filter_test.dart` | Deactivated user bị loại khỏi `playerStats` của synthetic summary |
| `test/presentation/esport/groups/group_detail/bloc/group_detail_bloc_test.dart` | `ToggleMemberDeactivation` success → optimistic update đúng; failure → rollback |
| `test/firebase/firestore/user/gn_firestore_user_test.dart` | `searchUserByGroup` loại deactivated members khỏi kết quả |

### Widget tests

| File | Nội dung |
|------|---------|
| `test/presentation/esport/groups/group_detail/group_detail_view_test.dart` | Badge "Không hoạt động" hiện khi member trong `deactivatedMembers`; popup menu owner có đủ 3 option |

---

## Thứ tự implement

1. `GNEsportGroup` model (data foundation cho mọi bước sau)
2. Firestore methods (`toggleMemberDeactivation`, update `removeMember`)
3. Repository interface + impl
4. BLoC event + handler
5. `GroupOverviewCalculator` — thêm `deactivatedIds` param
6. BLoC — truyền `deactivatedIds` vào calculator calls
7. `searchUserByGroup` — filter participant picker
8. UI — Members tab badge + popup menu
9. Viết toàn bộ tests

---

## Rủi ro & lưu ý

- **`deactivatedMembers` chứa userId không còn trong `members`**: xảy ra nếu cleanup `removeMember` fail một nửa. Không gây crash (filter là `contains` — thêm entry thừa chỉ là no-op), nhưng nên cleanup trong `removeMember` để tránh data noise.
- **Overview cache**: `yearlyOverviews` trong bloc state được cache theo năm. Khi toggle deactivation xong, cần invalidate cache này để tính lại. Thêm `clearYearlyOverviewCache: true` vào `copyWith` state, tương tự pattern `clearSelectedYear` hiện có.
- **Cloud Function `summary` doc**: doc all-time vẫn chứa deactivated user trong `playerStats` — nhưng `GroupOverviewCalculator` đã filter client-side nên UI luôn đúng mà không cần redeploy function.
