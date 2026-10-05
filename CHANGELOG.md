# Changelog

All notable changes to PES Arena are documented here.

## [5.0.0+50] - 2026-10-05

### Changed

- **Backend riêng thay cho Firestore**: dữ liệu nhóm, giải, trận, bảng xếp hạng và thống kê giờ nằm trên server Postgres tại Hà Nội thay vì Firestore ở Mỹ, nên mở app, mở giải và lưu tỉ số nhanh hơn rõ rệt. Firebase chỉ còn dùng để đăng nhập.
- Bảng xếp hạng, dashboard cá nhân, đối đầu và tổng quan nhóm được tính trực tiếp từ kết quả trận mỗi lần mở, không còn phải chờ "tính lại" hay thấy số liệu cũ.
- Màn hình giải dùng một kết nối realtime duy nhất thay cho ba listener; cập nhật tỉ số đồng thời vẫn được chặn xung đột như trước.
- Ảnh đại diện chuyển từ Firebase Storage sang server.
- Dashboard ở tab Arena hỗ trợ kéo để làm mới và tự tải lại khi quay về tab, không cần mở lại app mới thấy trận vừa đá.

### Breaking

- Bản 4.x không còn đồng bộ với dữ liệu mới sau khi chuyển; mọi người cần cập nhật lên 5.0.0.

## [4.0.0+49] - 2026-08-12

### Changed

- Giữ nguyên nhóm online và các luồng giải League/Cup/Full, gồm cập nhật trận đa thiết bị theo thời gian thực cùng bảng xếp hạng và kết quả.
- Loại bỏ thông báo/push, dữ liệu offline cùng UI migration/đồng bộ, quảng cáo di động, ứng dụng Flutter Web (không ảnh hưởng landing site), phản hồi/đánh giá và các chỉ số dashboard cá nhân dư thừa.
- Dashboard cá nhân giữ phong độ gần đây, lần vô địch gần nhất, tỷ lệ vô địch/á quân và đối đầu/khắc tinh/mồi ngon.

## [3.6.0+48] - 2026-08-11

### Added

- Phản hồi tải kịp thời khi tạo giải league online.

### Changed

- Chi tiết giải league cập nhật thời gian thực giữa nhiều thiết bị.
- Cập nhật trận dùng ghi lạc quan nguyên tử để giữ điểm số nhất quán khi có thao tác đồng thời.

### Fixed

- Phản hồi đang chờ và xung đột theo từng hàng giúp hiển thị rõ các cập nhật trận đang xử lý hoặc cạnh tranh.
- Hành vi giải đấu offline không thay đổi.

## [3.5.0+47] - 2026-08-09

### Added

- **Vòng đấu cho giải league online**: lịch thi đấu giờ được chia theo vòng thay vì đổ ra một danh sách phẳng. Giải 6 người sinh 5 vòng, mỗi người đá đúng một trận mỗi vòng; số vòng chạy liên tục qua các lượt (lượt đi 1–5, lượt về 6–10). Trận của giải cũ và trận tự tạo gom vào mục "Trận khác" ở cuối, không cần migration.

### Changed

- **Lượt về giờ đảo sân thật**: trước đây tạo lượt mới sinh lại y hệt chiều sân nhà/sân khách của lượt đi — lượt về chỉ là bản sao. Chiều sân giờ quyết định theo lịch sử đối đầu của từng cặp nên vẫn đúng khi có người rời hoặc vào giải giữa các lượt.
- **Một lượt được ghi nguyên tử**: số vòng được đặt trước từ counter trên document giải trong cùng transaction ghi các trận, nên hai người bấm tạo lượt cùng lúc không nhận trùng số vòng, và xoá hết trận của vòng cuối không giải phóng số vòng đó. Giải quá 32 người bị từ chối ngay kèm thông báo thay vì ghi dở dang.
- **Đổi thuật ngữ**: nút "Thêm vòng" đổi thành "Thêm lượt đấu" cho khỏi nhầm với vòng đấu thật; các thông báo liên quan đổi theo.

### Fixed

- Màn tạo giải nuốt lỗi im lặng: `_submit` await callback tạo giải mà không bắt exception, nên mọi lỗi đều thoát ra async handler và wizard đứng im không báo gì. Giờ hiện thông báo và giữ wizard mở để người dùng sửa rồi thử lại.

## [3.3.0+42] - 2026-05-22

### Added

- **Xoá nhóm (owner-initiated group deletion)**: the group owner can now permanently delete a group from the group detail menu after typing the group name to confirm. Server cascades the cleanup — every league, match, stat row, group-level stats doc, and related notification is removed, and every affected member's all-time summary is rebuilt so `tournamentsJoined` and recent matches stay honest.
- **`/groups` deep link**: explicit route mounts the Groups tab directly so the post-deletion bounce (and future deep links) lands on the right tab.

## [3.2.0+41] - 2026-05-16

### Added

- **Web auth guard**: deep linking now waits for Firebase to restore the session on a splash screen, then either renders the requested route (if signed in) or bounces to `/login?next=...` and returns the user to the original URL after sign-in
- **Smart back button**: every secondary screen ships a back arrow that works even on cold deep-link visits — pops the previous route when there is one, otherwise goes home

### Changed

- **Update match score is now latency-decoupled from stats**: writing the match doc is a fast standalone transaction; player stat deltas reconcile via a separate event so the score-entry dialog dismisses immediately on web
- **"Đồng bộ điểm số" is now delete-and-recreate**: nukes existing stat rows and rebuilds them from `league.participants` ∪ match teams, fixing legacy leagues that ended up with duplicate or missing stat docs
- **Home banner "đang diễn ra"** now filters by `status == ongoing` (the field admins actually toggle) instead of date range
- **Create-league wizard**: Cup and Full modes temporarily marked "Sắp ra mắt" and disabled while their stat/bracket flows are stabilised — only League mode can be created
- **Cost panel formatting**: amounts now round half-up to the nearest thousand (e.g. 49,500 → `50k`) so individual rows add up to the displayed net; the "Theo trận" section is only shown when at least one finished match has a non-zero cost

### Fixed

- League-mode tournaments now initialise per-player stat rows when matches are generated, so score entry no longer throws "No stats found"
- `_statRefForUser` query filters `groupId` in code instead of relying on Firestore's `isNull: true` predicate, which silently missed stat docs whose field was omitted by `toMap` when null

## [3.1.0+40] - 2026-05-08

### Added
- **Full tournament mode**: create tournaments with group stage + knockout bracket in a single flow — set number of groups, advancement count, and let the app generate everything
- **Bracket view**: visual knockout bracket tab on tournament detail, showing round labels (Tứ kết / Bán kết / Chung kết) and real-time scores
- **Group standings view**: per-group tables for full-mode tournaments with group selector tab bar
- **Create-league wizard overhaul**: mode selector (league / cup / full), participant count, group configuration, and collapsible cost setup all in one guided flow
- **Collapsible cost config**: cost settings panel that starts collapsed to reduce visual noise, expands on tap with subtitle showing current config
- **Match score dialog**: extracted update-score dialog with cost-per-match toggle and default prefill from league settings

### Changed
- Cost calculator now handles knockout bracket payout distribution
- Cost split view updated for group + knockout phase breakdown
- Matches view supports phase filtering and improved search
- Group detail view updated for multi-mode tournaments
- App icons and screenshots refreshed

### Fixed
- Profile view cleanup, removed stale widgets
- GNCircleAvatar handles null photo URL gracefully
- Firebase Auth error handling improvements
