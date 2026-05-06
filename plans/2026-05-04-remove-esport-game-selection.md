# Plan: Xoá hoàn toàn khái niệm "chọn môn esport"

**Ngày:** 2026-05-04
**Trạng thái:** ✅ Đã triển khai (commit `d11da22`, develop)
**Người thực hiện:** codex agent

---

## 1. Mục tiêu

App chỉ phục vụ cộng đồng PES. Loại bỏ toàn bộ **flow chọn môn esport** (model `EsportModel`, bloc `EsportBloc`, view `EsportView`, field `esportId` trên group, collection Firestore `esports`, validate "Chưa chọn một môn thể thao điện tử"). Sau plan này:

- Tạo group **không** cần chọn môn.
- Không còn warning "Chưa chọn một môn thể thao điện tử".
- Không còn class/file/import nào liên quan tới `EsportModel` / `EsportBloc` / `EsportView` / `esports` collection / field `esportId`.
- App build & test xanh.

## 2. Phạm vi KHÔNG bao gồm

- **Không** rename các class/file `GNEsportGroup`, `EsportLeague`, `EsportMatch`, `EsportLeagueStat`, `lib/presentation/esport/`, `lib/data/repositories/esport/`, `lib/domain/repositories/esport/`. Giữ nguyên (đã thống nhất với user).
- **Không** đổi tên Firestore collection `esports_groups`, `esports_leagues`, `leagues_matches`, `leagues_stats` (yêu cầu data migration, ngoài scope).
- **Không** thay đổi `GNNotificationType.esportsGroup` / `esportsLeague` trong `lib/firebase/firestore/notification/gn_notification.dart` — chuỗi `"esport_group"` / `"esport_league"` đang là khoá định tuyến notification từ server, đổi sẽ làm vỡ deep-link cho thông báo cũ.
- **Không** chạy migration để xoá field `esportId` trên doc cũ ở Firestore. App ngưng đọc/ghi field này; doc cũ giữ field stale (vô hại).

## 3. Phân tích hiện trạng

### 3.1 Component cần xoá

| File / Symbol | Lý do |
|---|---|
| `lib/firebase/firestore/esport/esport_model.dart` (`EsportModel`) | Model "môn esport"; collection `esports` Firestore. |
| `lib/firebase/firestore/esport/gn_firestore_esport.dart` (`GNFirestoreEsport.getEsports()`) | Đọc list môn esport. |
| `lib/presentation/esport/bloc/esport_bloc.dart` | Bloc chứa `selectedEsportModel`. |
| `lib/presentation/esport/bloc/esport_event.dart` | Events `LoadEsports`, `SelectEsport`. |
| `lib/presentation/esport/bloc/esport_state.dart` | State chứa `esportModel`. |
| `lib/presentation/esport/esport_view.dart` | View bọc các tab, đọc `EsportBloc`. |
| Field `esportId` trong `lib/firebase/firestore/esport/group/gn_esport_group.dart` | Bỏ field hoàn toàn. |
| Param `esportId` trong `addGroup`, `CreateEsportGroup` event, `EsportGroupRepository.addGroup` | Bỏ param. |

### 3.2 Component cần sửa (giữ lại)

- `lib/presentation/main/main_view.dart` — đang `import '../esport/groups/groups_view.dart'`, không phụ thuộc `EsportBloc` trực tiếp. Sẽ bỏ wrapper `EsportView` phía trên (xem 3.3).
- `lib/presentation/esport/groups/groups_view.dart`:
  - Dòng 10 `import '../bloc/esport_bloc.dart';` → xoá.
  - Dòng 158–162: bỏ block `final esportModel = context.read<EsportBloc>...; if (esportModel == null) showToast('Chưa chọn một môn thể thao điện tử'); return;`.
  - Dòng 209–213: `CreateEsportGroup(groupName, esportId: esportModel.id, description)` → bỏ `esportId`.
- `lib/presentation/esport/groups/bloc/group_event.dart`: `CreateEsportGroup` bỏ `esportId`, sửa `props`.
- `lib/presentation/esport/groups/bloc/group_bloc.dart` (line 46): `addGroup(... esportId: event.esportId ...)` → bỏ.
- `lib/data/repositories/esport/esport_group_repository_impl.dart` (line 19, 24): bỏ param `esportId`.
- `lib/domain/repositories/esport/esport_group_repository.dart` (line 10): bỏ param `esportId`.
- `lib/firebase/firestore/esport/group/gn_firestore_esport_group.dart` (line 21–27): hàm `addGroup` bỏ param `esportId`, không ghi `GNEsportGroup.esportIdKey` vào doc.
- `lib/firebase/firestore/esport/group/gn_esport_group.dart`:
  - Bỏ field `esportId`, constructor param `esportId`, `props`, copy, `toFirestore`, `fromFirestore`, `placeholder`, hằng `esportIdKey`.
- `lib/injection_container.dart`:
  - Dòng 40 `import '...esport_bloc.dart'` → xoá.
  - Phần register `EsportBloc`, `GNFirestoreEsport` (nếu có) → xoá.
- `lib/app.dart` (kiểm tra): nếu đang `MultiBlocProvider` provide `EsportBloc` ở cấp app → xoá entry đó; nếu provide qua `EsportView` (`lib/presentation/esport/esport_view.dart`) thì bỏ wrapper đó luôn.
- `lib/routing.dart`:
  - Line 5 `import 'firebase/firestore/esport/group/gn_esport_group.dart'` — giữ (vẫn dùng `GNEsportGroup` cho route extra).
  - Line 29 comment `// esport — base paths...` → đổi thành `// group / league — base paths...`.

### 3.3 `EsportView` — xác định cách dùng

Trước khi xoá, cần check ở `lib/app.dart` / `main_view.dart` xem `EsportView` có đang là wrapper của 3 tab không. Nếu là:
- Wrapper cấp cao → bỏ wrapper, plug `MainView` thẳng vào router.
- Đã không còn được dùng → xoá thẳng file.

(Search reference `EsportView(` trước khi xoá.)

### 3.4 Test files cần xoá / sửa

```
test/presentation/esport/bloc/esport_bloc_test.dart   (nếu có) → xoá
test/presentation/esport/groups/...                   (nếu có dùng EsportBloc) → bỏ mock EsportBloc
test/firebase/firestore/esport/group/gn_esport_group_test.dart → bỏ field esportId trong fixtures
test/data/repositories/esport/esport_group_repository_impl_test.dart → bỏ param esportId trong call
```

(Bước đầu: `grep -rn "EsportBloc\|EsportModel\|esportId" test/` để liệt kê đầy đủ.)

## 4. Các bước triển khai (theo thứ tự, mỗi bước build xanh trước khi sang bước kế)

### Bước 1 — Loại field `esportId` khỏi domain & data layer

1. `lib/firebase/firestore/esport/group/gn_esport_group.dart`: xoá field `esportId`, `esportIdKey`, sửa constructor / `props` / `copyWith` / `fromFirestore` / `toFirestore` / `placeholder`.
2. `lib/firebase/firestore/esport/group/gn_firestore_esport_group.dart`: hàm `addGroup` bỏ param `esportId` và bỏ key trong map ghi Firestore.
3. `lib/domain/repositories/esport/esport_group_repository.dart`: bỏ param `esportId` trong `addGroup`.
4. `lib/data/repositories/esport/esport_group_repository_impl.dart`: bỏ param `esportId` ở implementation.
5. Build local (`flutter analyze`) — sửa toàn bộ call site đỏ.

### Bước 2 — Loại `esportId` khỏi BLoC group

1. `group_event.dart`: `CreateEsportGroup` bỏ `esportId`, cập nhật `props`.
2. `group_bloc.dart`: handler `_onCreateEsportGroup` bỏ `esportId`.
3. `groups_view.dart`:
   - Bỏ import `esport_bloc.dart`.
   - Bỏ block check `esportModel == null` + toast warning.
   - Sửa `CreateEsportGroup(groupName: ..., description: ...)` (bỏ `esportId`).
4. Build & smoke test tạo group.

### Bước 3 — Xoá `EsportBloc` / `EsportView` / `EsportModel`

1. Xoá thư mục `lib/presentation/esport/bloc/` (3 files: `esport_bloc.dart`, `esport_event.dart`, `esport_state.dart`).
2. Xoá file `lib/presentation/esport/esport_view.dart`. Trước đó, search `EsportView(` toàn repo:
   - Nếu được dùng ở `app.dart` hoặc router → thay thế bằng `MainView` trực tiếp.
3. Xoá `lib/firebase/firestore/esport/esport_model.dart` và `lib/firebase/firestore/esport/gn_firestore_esport.dart`.
4. Cập nhật `lib/firebase/firestore/gn_firestore.dart` (nếu compose `GNFirestoreEsport`): xoá mixin/inheritance/getter liên quan.
5. `lib/injection_container.dart`: xoá register `EsportBloc`, `GNFirestoreEsport` (nếu có).
6. Build & analyze sạch.

### Bước 4 — Dọn import & comment

1. `routing.dart` line 29: đổi comment `esport` → `group / league`.
2. `grep -rn "EsportModel\|EsportBloc\|esportId" lib/` phải trả về 0 dòng.
3. `grep -rn "Chưa chọn.*esport\|chưa chọn.*môn" lib/` phải trả về 0 dòng.

### Bước 5 — Test

1. Chạy `flutter test --coverage`.
2. Sửa/xoá test fixtures dùng `esportId` hoặc mock `EsportBloc`.
3. Thêm test mới cho `GNEsportGroup.fromFirestore` đảm bảo doc cũ có field `esportId` thừa **vẫn parse được** (forward-compat với data cũ): test data có key `esportId` → `fromFirestore` không throw, không lưu.
4. Test BLoC `GroupBloc` cho `CreateEsportGroup` event sau khi bỏ param: assert call repo với đúng args mới.
5. Smoke test thủ công: build APK, login, vào tab Nhóm, bấm "Tạo nhóm" → KHÔNG thấy toast "Chưa chọn..." nữa, group tạo thành công với data tối thiểu.

### Bước 6 — Backwards-compat doc cũ trên Firestore (verify)

Doc cũ trên Firestore vẫn có `esportId: '<id>'` thừa. Verify:
- Đọc 1 group cũ ở prod (qua Firestore Console hoặc test account).
- Đảm bảo app render ổn (parse không crash, các tab Group hoạt động).

(Field thừa sẽ tự nhạt đi theo thời gian; không cần migration script.)

## 5. Acceptance criteria

- [ ] `grep -rn "EsportModel\|EsportBloc\|esportId\|esports'\|getEsports" lib/` → empty.
- [ ] `grep -rn "Chưa chọn một môn thể thao điện tử" lib/` → empty.
- [ ] Tạo group thành công không cần chọn môn, không hiện cảnh báo.
- [ ] `flutter analyze` clean.
- [ ] `flutter test` xanh, coverage `lib/` không tụt vs trước plan.
- [ ] Doc group cũ trên Firestore (có field `esportId`) vẫn được app load đúng.

## 6. Rủi ro & cách xử lý

| Rủi ro | Xử lý |
|---|---|
| Có route/page khác dùng `EsportBloc.esportModel` chưa thấy | Bước 3 chạy `grep -rn "EsportBloc\|esportModel" lib/` trước khi xoá. |
| Build deep-link notification cũ vẫn dùng key `esport_group` | Plan này KHÔNG đổi `GNNotificationType` constants — vẫn tương thích. |
| `EsportView` từng cung cấp `EsportBloc` cho descendants | Bước 3 đảm bảo các descendant không còn `context.read<EsportBloc>()` (đã xử lý ở Bước 2 cho `groups_view.dart`; cần grep thêm). |
| Group cũ bị parse sai do thiếu xử lý field thừa | Test forward-compat ở Bước 5.3. |

## 7. Ước lượng

- ~30 file đụng (xoá ~7, sửa ~20+).
- Effort: 0.5–1 ngày dev + test.

## 8. Rollback

Plan thuần code-side, không migrate Firestore → revert PR là đủ.
