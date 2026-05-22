# Group Deletion

## Mục tiêu

Owner của group có thể yêu cầu **xoá vĩnh viễn** group qua dialog confirm-by-typing-name. Server cascade xoá toàn bộ dữ liệu liên quan (leagues, matches, stats, notifications, group doc) rồi rebuild lại user summary cho mọi member bị ảnh hưởng.

Khác với deactivate member (xem `group-member-deactivation.md`) — deletion là **không thể phục hồi** và xoá hẳn lịch sử giải đấu của group.

---

## Cách hoạt động

### Client — request flow

1. Owner mở popup menu trong group detail → "Xoá nhóm".
2. Dialog yêu cầu type chính xác tên group để enable nút confirm.
3. `GroupDetailBloc` dispatch `RequestDeleteGroup` → repository ghi 1 doc vào `group_deletion_requests` collection (create-only, không update).
4. Khi BlocListener nhận `deleteGroupStatus == success`, app refresh group list rồi `context.go('/groups')` (route mới, bounce về Groups tab).

### Server — cascade

Cloud Function `onGroupDeletionRequestCreated` (`functions/index.js:1015`) chạy khi có doc mới trong `group_deletion_requests`:

1. **Idempotency guard** — skip nếu request đã ở trạng thái `processing` / `completed` (chống re-trigger khi Cloud Function retry).
2. **Write tombstones** — với mỗi league của group, ghi 1 doc vào `group_deletion_league_tombstones` để các trigger delta-stat (`onLeagueMatchWritten`, `onEsportLeagueWritten`) skip qua league đang bị xoá. Tránh race condition giữa cascade delete và trigger ghi lại stats.
3. **Cascade delete** — theo thứ tự: matches → league stats → leagues → group stats → notifications liên quan → group doc.
4. **Rebuild user summaries** — với mọi member có league trong group bị xoá, gọi lại `rebuildUserSummary(uid)` để update `tournamentsJoined` + recent matches.
5. Mark request `status: completed`.

### Firestore rules

- `group_deletion_requests/{requestId}`: chỉ `create` bởi user đã sign-in **và** `isGroupOwner(request.resource.data.groupId)`. Không cho update/delete từ client — chỉ Cloud Function ghi lại status.
- `group_deletion_league_tombstones`: chỉ Cloud Function đọc/ghi (admin SDK bypass rules).

### Routing

Route mới `/groups` được khai báo trong `lib/routing.dart` để post-delete navigation có deep-link target ổn định (bounce về `MainPage` với Groups tab active).

---

## Follow-ups đã ghi nhận

Xem `TODOS.md` để biết chi tiết. Tóm tắt:

- **Firestore rules — tighten `esports_groups` write access** (P0): rule `allow read, write: if signedIn()` ở `firestore.rules:99` đang cho phép mọi user gọi `groupRef.delete()` trực tiếp, bypass cascade. Cần field-level rules cho join/leave/transfer.
- **GC `group_deletion_league_tombstones`** (P1): tombstones không bao giờ bị xoá → mỗi `onLeagueMatchWritten` đọc collection này forever. Cần Cloud Scheduler dọn dẹp doc > 24h.
- **Idempotent fan-out cho `rebuildUserSummary`** (P2): group lớn (50+ members) có thể vượt timeout 9 phút. Fan out bằng `_recompute_request` docs thay vì sequential await.
- **Widget tests cho delete dialog + post-delete navigation** (P2): chưa cover typing validation, BlocListener navigation, popup disabled khi loading.

---

## Files liên quan

| File | Vai trò |
|------|---------|
| `functions/index.js` | `onGroupDeletionRequestCreated`, `isGroupDeletionLeague`, cascade + rebuild |
| `firestore.rules` | Rules cho `group_deletion_requests` (create-only, owner-gated) |
| `lib/firebase/firestore/esport/group/gn_firestore_esport_group.dart` | Firestore op — ghi request doc |
| `lib/domain/repositories/esport/esport_group_repository.dart` | Repository interface — `requestDeleteGroup` |
| `lib/data/repositories/esport/esport_group_repository_impl.dart` | Repository impl |
| `lib/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart` | `RequestDeleteGroup` handler, status tracking |
| `lib/presentation/esport/groups/group_detail/bloc/group_detail_event.dart` | `RequestDeleteGroup` event |
| `lib/presentation/esport/groups/group_detail/bloc/group_detail_state.dart` | `deleteGroupStatus`, `deleteGroupErrorMessage` |
| `lib/presentation/esport/groups/group_detail/group_detail_view.dart` | Popup menu + confirm dialog + post-delete BlocListener |
| `lib/routing.dart` | Route `/groups` |
| `lib/presentation/main/main_page.dart`, `main_view.dart` | Bounce target cho `/groups` deep-link |
