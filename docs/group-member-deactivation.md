# Group Member Deactivation

## Mục tiêu

Admin của group có thể đánh dấu một thành viên là "không hoạt động" (deactivate). Thành viên đó:

- Không hiện trong bảng xếp hạng và awards của group overview (all-time & year filter)
- Không hiện trong picker khi thêm participant vào giải mới
- Có thể reactivate bất kỳ lúc nào

Lịch sử giải đấu **không bị xoá** — deactivate chỉ ảnh hưởng đến display.

---

## Cách hoạt động

### Lưu trữ

Field `deactivatedMembers: List<String>` trong Firestore doc `esports_groups/{groupId}`.

- Mặc định `[]` — không cần migration cho group cũ.
- `members` vẫn giữ nguyên — `deactivatedMembers` là overlay "ẩn", không thay thế membership.
- Khi xoá member khỏi group, đồng thời `arrayRemove` khỏi `deactivatedMembers` (atomic trong cùng 1 Firestore update).

### Stats filtering

**Year-filter overview** (client-side từ per-league stats):
- Các giải đấu nào có deactivated user trong `participants` bị **bỏ qua hoàn toàn** trước khi tính stats.
- Logic: `GroupOverviewYearFilter.aggregate(deactivatedIds: ...)` + bloc filter trước khi fetch stats.
- Collateral: các active player cũng mất stats từ các giải bị loại. Chấp nhận được vì deactivated user thường ít tham gia.

**All-time overview** (server-maintained summary doc):
- Cloud Function vẫn ghi deactivated user vào summary doc như bình thường.
- Client filter tại `GroupOverviewCalculator.compute(deactivatedIds: ...)` — ẩn deactivated user khỏi `playerStats`, rankings, và awards.
- Aggregate counts (`totalMatchesPlayed`, `totalGoals`) tính từ tất cả players kể cả deactivated — giữ tính consistency với lịch sử group.

> **Tại sao all-time và year-filter có cách tiếp cận khác nhau?**
> Year-filter có dữ liệu per-league → có thể lọc ở tầng league (sạch hơn).
> All-time dùng pre-aggregated summary doc → không có per-league breakdown, chỉ lọc được ở tầng player.
> Nếu muốn all-time cũng theo cách league-level, cần backfill summary doc sau khi deactivate (Cloud Function).

**Participant picker** (`searchUserByGroup`):
- Filter `!group.deactivatedMembers.contains(user.id)` khi trả kết quả tìm kiếm.

### Optimistic update

Khi toggle deactivation:
1. Cập nhật `state.group.deactivatedMembers` ngay lập tức (không chờ Firestore).
2. Xoá `yearlyOverviews` cache để buộc tính lại lần sau.
3. Mark overview stale (`overviewIsStale: true`).
4. Nếu Firestore call lỗi → rollback về state trước.

---

## Backfill

Stats là derived data — Cloud Function tính lại từ match records bất cứ lúc nào.
Xoá giải đấu mới mất data. Chỉ cần giải còn tồn tại thì backfill lại được.

Nếu muốn all-time overview phản ánh đúng "league-level exclusion" như year-filter:
1. Deactivate user trên UI.
2. Trigger `requestRecompute(groupId)` → Cloud Function rebuild summary doc.
3. (Tương lai) Cloud Function có thể đọc `deactivatedMembers` và exclude leagues có user đó.

---

## Files liên quan

| File | Vai trò |
|------|---------|
| `lib/firebase/firestore/esport/group/gn_esport_group.dart` | Model — field `deactivatedMembers` |
| `lib/firebase/firestore/esport/group/gn_firestore_esport_group.dart` | Firestore ops — `toggleMemberDeactivation`, `removeMemberFromGroup` |
| `lib/domain/repositories/esport/esport_group_repository.dart` | Repository interface |
| `lib/data/repositories/esport/esport_group_repository_impl.dart` | Repository impl |
| `lib/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart` | Optimistic update, deactivatedIds pass-through |
| `lib/presentation/esport/groups/group_detail/bloc/group_detail_event.dart` | `ToggleMemberDeactivation` event |
| `lib/presentation/esport/groups/group_detail/services/group_overview_calculator.dart` | `deactivatedIds` filter cho all-time |
| `lib/presentation/esport/groups/group_detail/services/group_overview_year_filter.dart` | League-level filter cho year overview |
| `lib/firebase/firestore/user/gn_firestore_user.dart` | `searchUserByGroup` — loại deactivated member khỏi picker |
| `lib/presentation/esport/groups/group_detail/group_detail_view.dart` | UI — badge + popup menu |
