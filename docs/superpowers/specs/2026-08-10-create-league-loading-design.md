# Thiết kế trạng thái loading khi tạo league

## Mục tiêu

Khi người dùng bấm **Tạo giải đấu**, wizard phải phản hồi ngay bằng spinner và nhãn đã dịch **Đang tạo giải…** trên chính nút submit. Trạng thái này tồn tại trong toàn bộ callback `onAddLeague`, bao gồm tạo league, thêm participants và tạo fixtures, để người dùng biết ứng dụng vẫn đang xử lý.

Trong lúc submit, wizard không cho gửi lặp, quay lại bước trước, đóng route hoặc kích hoạt điều hướng khác. Khi thành công, loading được giữ đến lúc wizard trả `leagueId`; flow bên ngoài tiếp tục mở League Detail như hiện tại. Khi thất bại, form được mở khóa và giữ nguyên dữ liệu để thử lại.

## Phạm vi

- Thêm trạng thái submit cục bộ cho `CreateEsportLeaguePage`.
- Thay nội dung nút submit bằng spinner nhỏ và chuỗi localization `Đang tạo giải…` khi đang xử lý.
- Chặn submit lặp, nút quay lại và thao tác system back/pop trong lúc xử lý.
- Khôi phục trạng thái tương tác sau `RoundTooLargeException` hoặc lỗi thông thường.
- Bổ sung localization key và widget tests cho các trạng thái trên.

## Ngoài phạm vi

- Không thay đổi repository, cấu trúc Firestore hoặc cách tạo league/participants/fixtures.
- Không tối ưu thời gian thực thi backend trong thay đổi này.
- Không chuyển sang overlay toàn màn hình và không mở League Detail trước khi fixtures hoàn tất.
- Không thay đổi toast thành công hoặc toast lỗi hiện có.

## Nguyên nhân hiện tại

`_submit()` chờ `widget.onAddLeague(...)` hoàn tất nhưng không lưu trạng thái đang submit. Callback bên ngoài thực hiện nối tiếp nhiều thao tác mạng trước khi trả `leagueId`, trong khi nút vẫn hiển thị **Tạo giải đấu** và vẫn có thể được bấm. Vì không có phản hồi tức thời, khoảng chờ này trông giống như ứng dụng bị lag.

## Thiết kế trạng thái và giao diện

`_CreateEsportLeaguePageState` có một cờ `_isSubmitting`, mặc định `false`. Chỉ đặt cờ thành `true` sau khi toàn bộ validation đồng bộ đã thành công và ngay trước khi gọi `onAddLeague`. Nhờ vậy lỗi validation không làm nút rơi vào loading.

Khi `_isSubmitting == true`:

- Nút submit bị vô hiệu hóa về tương tác, icon được thay bằng `CircularProgressIndicator` kích thước cố định và label dùng localization key cho **Đang tạo giải…**.
- Nút quay lại bị vô hiệu hóa.
- Nội dung form không nhận thao tác chỉnh sửa.
- Route được bọc bằng `PopScope(canPop: false)` để chặn system back, gesture back và các yêu cầu pop khác từ wizard.
- Mọi đường gọi `_submit()` đều có guard đầu hàm để không thể gọi `onAddLeague` lần thứ hai.

Kích thước nút không đổi khi chuyển trạng thái để tránh layout shift. Spinner dùng màu tương phản với nền nút và có semantics label cùng ý nghĩa với chuỗi loading. Nhãn phải lấy từ `context.l10n`, không hard-code trong widget; ít nhất bản dịch tiếng Việt là **Đang tạo giải…** và tiếng Anh là **Creating league…**.

## Luồng dữ liệu

1. Người dùng bấm **Tạo giải đấu**.
2. `_submit()` bỏ qua yêu cầu nếu `_isSubmitting` đã bật, sau đó chạy validation hiện có.
3. Validation thành công thì `setState` bật `_isSubmitting` và giao diện phản hồi ở frame kế tiếp.
4. `onAddLeague` chạy toàn bộ flow tạo league, participants và fixtures trong `tournament_view.dart`.
5. Nếu callback trả `leagueId`, wizard giữ nguyên loading và gọi `Navigator.pop(leagueId)`; không đặt `_isSubmitting` về `false` trước khi pop.
6. `openCreateTournament` nhận ID và mở route League Detail như hiện tại.
7. Nếu callback ném lỗi, wizard tắt `_isSubmitting` khi widget còn mounted, giữ nguyên controller và lựa chọn hiện tại, rồi cho phép người dùng thử lại.

Chỉ `_submit()` sở hữu việc chuyển trạng thái. Không thêm timer hoặc loading state vào `TournamentBloc`, vì trạng thái này chỉ thuộc vòng đời của wizard và callback hiện tại đã biểu diễn đầy đủ thời gian chờ cần hiển thị.

## Xử lý lỗi

- `RoundTooLargeException`: giữ toast đã dịch hiện tại, tắt loading, giữ nguyên tên league, participants và cấu hình để người dùng điều chỉnh rồi thử lại.
- Lỗi thông thường: giữ toast lỗi hiện tại, tắt loading và giữ nguyên toàn bộ form.
- Widget bị unmount bởi tác nhân bên ngoài: không gọi `setState` hoặc `Navigator` sau `await` khi `mounted == false`.
- Nếu thành công: không chạy nhánh reset loading, tránh nháy lại nút **Tạo giải đấu** trước khi chuyển trang.

## Khả năng tiếp cận

- Trạng thái đang xử lý có nhãn văn bản, không truyền đạt chỉ bằng animation.
- Spinner có semantics label đã dịch và không làm mất nhãn trạng thái của nút.
- Các control bị khóa không còn nhận tap hoặc keyboard activation.
- Giữ kích thước nút và vùng chạm hiện tại để giao diện không dịch chuyển khi loading.

## Kế hoạch kiểm thử TDD

Các test mới dùng `Completer<String>` để giữ `onAddLeague` ở trạng thái pending và quan sát UI trước khi callback hoàn tất:

1. **Hiển thị tức thời:** sau một `pump` kể từ tap, tìm thấy spinner và nhãn **Đang tạo giải…**, không còn trạng thái submit bình thường.
2. **Không submit lặp:** tap nhiều lần trong khi `Completer` chưa hoàn tất chỉ gọi `onAddLeague` đúng một lần.
3. **Khóa điều hướng:** nút quay lại bị disable và system back/pop không đóng wizard khi đang submit.
4. **Giữ loading đến thành công:** wizard vẫn loading khi future pending; sau khi complete, route pop đúng `leagueId` và outer flow có thể tiếp tục điều hướng.
5. **Khôi phục sau lỗi thường:** callback ném lỗi thì spinner biến mất, nút tạo được bật lại, toast hiện một lần và tên đã nhập vẫn còn.
6. **Khôi phục sau giới hạn vòng đấu:** `RoundTooLargeException` tắt loading, hiển thị toast đã dịch hiện tại và giữ wizard/form để retry.
7. **Validation không bật loading:** tên trống, ngày không hợp lệ hoặc cost form không hợp lệ không gọi callback và không chuyển nút sang loading.
8. **Semantics:** trạng thái pending cung cấp nhãn loading đã dịch và các nút bị khóa không còn action tap.

Các test lỗi hiện có tiếp tục đứng gác toast và việc wizard không đóng. Chạy targeted test cho `create_esport_league_page_test.dart` trước, sau đó `flutter analyze` và full `flutter test` khi thực tế cho phép.
