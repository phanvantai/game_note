# TODOs

## Quản lý giải đấu (Profile)

**Context:** Tab giải đấu hiện tại chỉ hiển thị các giải user tham gia với tư cách vận động viên
(`participants array-contains uid`) — khớp với dashboard stat. Các giải user tạo ra nhưng chưa
tham gia không hiển thị ở đây nữa.

**Việc cần làm:** Thêm mục "Giải đấu của tôi" vào Profile view

- [ ] Thêm `getManagedLeagues()` trong `gn_firestore_esport_league.dart` — query `ownerId == uid`
- [ ] Tạo màn hình / bottom sheet "Giải đấu tôi quản lý" trong `lib/presentation/profile/`
- [ ] Hiển thị danh sách với action nhanh: mở detail, đổi trạng thái, xóa
- [ ] Cân nhắc badge "Admin" trên item để phân biệt với giải tham gia thông thường
