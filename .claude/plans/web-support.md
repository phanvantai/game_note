# Web Support — Spec chốt

Bổ sung Web là platform thứ 3 (cạnh Android & iOS). Mục tiêu: cho phép user truy cập các tính năng online cốt lõi qua trình duyệt, dùng chung backend Firebase hiện tại.

## Scope

Web chỉ phục vụ **online core features**, xoay quanh tournament. Không port các native-only module.

### Có trên web

- Đăng nhập / đăng ký bằng email + password
- Đăng nhập bằng Google
- Verify email
- Tournaments: list, create, detail, matches, table, cost
- Groups: list, create, detail, members, chat
- Profile: xem thông tin
- Profile: cập nhật text fields (display name, bio...)
- Đổi mật khẩu
- Gửi feedback

### Không có trên web (ẩn UI)

- Upload / đổi avatar (và mọi flow upload ảnh khác)
- Share preview tournament dạng image
- Notification (push & in-app)
- Offline mode (toàn bộ local tournament / SQLite)
- Quảng cáo (banner ads)

## UX

- **Không làm responsive desktop**. Web chỉ render giao diện mobile hiện tại.
- Khi browser width > 600px: hiển thị mobile frame (~420px) căn giữa, hai bên là background trống.
- Khi browser width ≤ 600px: fullscreen như mobile bình thường.
- Deep link / URL routing chưa cần — phase này chấp nhận URL luôn ở root.

## Hạ tầng

- **Hosting**: Firebase Hosting (cùng project Firebase hiện tại).
- **Domain**: dùng custom domain user đã có, trỏ DNS sang Firebase Hosting + auto SSL.
- **CI/CD**: deploy bằng `firebase deploy --only hosting`, có thể tích hợp vào GitHub Actions sau.

## Out of scope (phase này)

- Responsive layout cho tablet / desktop
- Deep linking / shareable tournament URLs
- PWA / offline web
- SEO, meta tags, social preview
- Push notification web (FCM service worker)
