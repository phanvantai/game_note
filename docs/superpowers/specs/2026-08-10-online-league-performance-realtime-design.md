# Thiết kế tối ưu hiệu năng và realtime cho Online League

## Mục tiêu

Làm mượt bốn luồng online quan trọng: tạo league, mở League Detail, cập nhật match và nhận thay đổi realtime từ thiết bị khác. Thiết kế loại bỏ các lần đọc lại toàn bộ dữ liệu không cần thiết, giữ tính nhất quán của match và bảng điểm, đồng thời luôn phân biệt rõ dữ liệu đang chờ với dữ liệu đã được server xác nhận.

## Phạm vi

- Tạo league có loading ngay trên nút, khóa submit lặp/back/form cho đến khi callback hoàn tất.
- Bỏ `addMultipleParticipants` thừa trong create flow và chỉ reload My/Managed Leagues sau khi người dùng rời League Detail.
- Dùng league/stats/matches streams làm nguồn dữ liệu duy nhất của League Detail; không chạy thêm explicit get hoặc full reload song song.
- Cache user theo `userId`, chỉ tải profile mới khi roster thay đổi.
- Cập nhật match, hai stat liên quan và ô đấu knockout tiếp theo trong một Firestore transaction duy nhất đối với các document áp dụng.
- Hiển thị pending theo từng match, hỗ trợ cập nhật từ nhiều thiết bị và xử lý optimistic-lock conflict.
- Giảm rebuild bằng `BlocSelector`/`buildWhen`; chỉ tạo share cards khi người dùng mở chức năng chia sẻ.

## Ngoài phạm vi

- Không đổi schema Firestore và không migration stat document sang deterministic ID trong nhánh này.
- Không thay đổi thuật toán tạo fixtures, cách tính điểm hay giới hạn số người của round robin.
- Không đưa tạo fixtures sang Cloud Functions và không mở detail trước khi quá trình tạo hoàn tất.
- Không thay đổi các flow offline.

## Nguyên nhân hiện tại

- `create_esport_league_page.dart`: `_submit()` await toàn bộ `onAddLeague` nhưng không có submit state, nên nút không phản hồi và vẫn có thể được bấm lại.
- `tournament_view.dart`: `addLeague` đã ghi participants nhưng create callback vẫn gọi `addMultipleParticipants`; sau khi tạo còn dispatch `LoadMyLeagues` và `LoadManagedLeagues` trước khi mở detail.
- `tournament_detail_bloc.dart`: khi mở trang vừa attach ba listeners vừa gọi `getLeague` và `getParticipantsAndMatches`; league/stat snapshot lại kích hoạt `GetParticipantsAndMatches`, gây nhiều lần tải stats, matches và users giống nhau.
- `esport_league_repository_impl.dart`, `gn_firestore_esport_league_stat.dart` và `gn_firestore_esport_league_match.dart`: full fetch stats/matches đều tự enrich users, nên mỗi reactive reload tiếp tục tạo thêm user queries.
- `gn_firestore_esport_league_match.dart`: match và stat delta đang được ghi bằng hai transaction tách rời; trước transaction stat còn phải query hai document có ID ngẫu nhiên. Khoảng giữa hai transaction có thể hiển thị match mới nhưng bảng điểm cũ.
- `tournament_detail_view.dart`: một `BlocBuilder` lớn rebuild theo toàn state và 2–4 `LeagueShareCard` ngoài màn hình luôn được dựng, kể cả khi người dùng không chia sẻ.

## Kiến trúc trạng thái League Detail

`TournamentDetailBloc` sở hữu đúng một subscription cho mỗi stream của league hiện tại:

- League stream cập nhật riêng `state.league`.
- Stats stream sắp xếp và cập nhật riêng `state.participants`.
- Matches stream cập nhật riêng `state.matches`.

Subscription được tạo một lần khi vào detail, hủy khi đổi league hoặc dispose. Initial snapshot của ba stream chính là bootstrap; không gọi thêm `getLeague`, `getParticipantsAndMatches`, `getLeagueStats` hoặc `getMatches`. Khi app resume, tiếp tục dùng/rebind stream nếu subscription đã mất thay vì full reload.

State tách tối thiểu các phần:

- `bootstrapStatus`: chỉ phản ánh việc đã nhận đủ initial league/stats/matches snapshots hay chưa.
- `league`, `participants`, `matches`: ba slice dữ liệu đã xác nhận từ streams.
- `usersById`: cache profile theo ID.
- `pendingMatchIds` hoặc map pending theo match ID: chỉ phản ánh lệnh local đang chờ server.
- lỗi bootstrap và lỗi mutation tách riêng; lỗi một match không chuyển toàn trang sang failure/loading.

League snapshot chỉ patch metadata league, giữ group object đã resolve và không kéo lại stats/matches. Vì stream league document không tự attach group, group được lấy một lần khi `groupId` xuất hiện/thay đổi, ưu tiên cache hiện có và chỉ fallback một repository read; đây không phải một lần đọc lại league.

Stats/matches snapshots chứa domain rows chưa enrich. Bloc lấy tập user ID cần hiển thị từ roster và dữ liệu snapshot, so với `usersById`, rồi chỉ gọi `getUsersByIds` cho các ID còn thiếu. Profile không được tải lại khi chỉ có score, cost, status hoặc thứ hạng thay đổi. Khi roster bỏ thành viên, cache có thể giữ đến lúc dispose để tránh churn; UI chỉ dùng IDs còn hiện diện.

Các snapshot handlers không hiển thị toast. Thay đổi từ thiết bị khác chỉ patch đúng slice và rebuild đúng vùng liên quan.

## Luồng tạo league

`CreateEsportLeaguePage` có `_isSubmitting`, mặc định `false`. Sau khi validation đồng bộ thành công và ngay trước `onAddLeague`, widget bật cờ này. Trong lúc chờ:

- Nút hiển thị spinner nhỏ và label localization **Đang tạo giải…** / **Creating league…**.
- Submit có guard và không thể gọi callback lần hai.
- Nút back, form controls, system back, gesture back và pop từ wizard bị khóa bằng disabled handlers, input blocking và `PopScope`.
- Kích thước nút không thay đổi.

Create callback chỉ gọi `addLeague` một lần rồi tạo fixtures theo mode; bỏ `addMultipleParticipants` vì participants đã có trong document league. Loading bao trùm toàn callback. Thành công giữ loading cho đến khi wizard `pop(leagueId)` và outer flow mở League Detail.

`LoadMyLeagues` và `LoadManagedLeagues` không chạy trong callback tạo. Outer flow `await` route League Detail; sau khi người dùng quay lại, dispatch mỗi event đúng một lần. Có thể đặt reload trong `finally` quanh detail navigation để list vẫn được làm mới nếu detail đóng bằng một đường khác.

Nếu `RoundTooLargeException` hoặc lỗi thường xảy ra, wizard tắt loading, giữ toàn bộ input và dùng toast hiện có. Nếu lỗi xảy ra sau khi league document đã được tạo, callback vẫn gọi rollback hiện có rồi rethrow. Việc xóa đệ quy orphan subcollections không được mở rộng trong scope hiệu năng này và vẫn là residual risk cần theo dõi riêng.

## Luồng cập nhật match nguyên tử

Repository cung cấp một command cập nhật match nguyên tử thay cho chuỗi `updateMatch` rồi `applyMatchStatDelta`:

1. Trước transaction, resolve stat references của home/away bằng query `userId` và `groupId` hiện có. Bước này duy trì tương thích với stat document ID ngẫu nhiên của league cũ.
2. Transaction đọc match hiện tại và kiểm tra `expectedUpdatedAt` như optimistic lock hiện tại.
3. Delta được tính từ match thực tế vừa đọc sang score/cost mới, không tính từ state cũ bên ngoài transaction.
4. Với phase có tính standings, transaction đọc và cập nhật hai stat documents.
5. Với knockout đã hoàn tất, transaction cập nhật ô home/away của next match như hiện tại.
6. Transaction ghi match và `serverTimestamp` trong cùng commit với các document áp dụng.

League phase cần match + hai stats; knockout phase cần match + next slot và không tạo stat delta nếu luật hiện tại không tính standings. Full tournament group phase resolve đúng stat theo `groupId`. Nếu thiếu stat reference hoặc stat document không tồn tại, command thất bại trước/ở transaction và không ghi match một phần.

Firestore tự retry transaction khi hai update khác match nhưng cùng đụng stat document. Mỗi lần retry phải đọc lại match/stats và tính lại delta trong transaction closure; closure không phát toast hoặc thay đổi Bloc state. Nhờ đó hai trận khác nhau của cùng một người có thể commit nối tiếp mà không làm mất điểm.

Không đổi stat IDs trong nhánh này. Sau này deterministic ID có thể bỏ hai query resolve trước transaction, nhưng đó là migration riêng có backfill và kế hoạch xóa compatibility rõ ràng.

## Pending, offline và nhiều thiết bị

Khi người dùng lưu một match, Bloc thêm đúng match ID vào pending và có thể overlay giá trị vừa nhập lên row đó. Các match khác vẫn tương tác bình thường; không dùng `viewStatus.loading` toàn trang và không gọi full reload sau mutation.

Pending không đồng nghĩa server-confirmed. Chỉ khi transaction Future hoàn tất thành công mới xóa pending và hiển thị toast thành công local; stream tiếp tục là nguồn xác nhận cuối cùng. Nếu thiết bị offline hoặc transaction lỗi, không hiển thị thành công, xóa pending, giữ dữ liệu stream đã xác nhận và đưa lỗi đã dịch tại đúng match hoặc toast hiện có.

Hai thiết bị sửa cùng một match từ cùng version:

- Commit đầu tiên thành công.
- Commit sau đọc `updatedAt` mới, không khớp `expectedUpdatedAt`, ném `ConcurrentMatchUpdateException`.
- Thiết bị stale xóa pending, hiển thị conflict đã dịch và không ghi đè dữ liệu; match listener reconcile row theo server snapshot.

Hai thiết bị sửa hai match khác nhau nhưng chung người chơi được phép cùng gửi. Transaction contention trên stat docs được Firestore retry, và kết quả cuối phải chứa tổng delta của cả hai trận.

Remote match/stat/league snapshots không tạo success toast, error toast hoặc global loading trên thiết bị chỉ đang xem. Chỉ command do chính thiết bị khởi tạo mới sở hữu pending và feedback của command đó.

## Render và chia sẻ

Chia view thành các vùng chọn state nhỏ:

- Header/actions chọn league metadata.
- Standings chọn participants.
- Fixtures/results/bracket chọn matches và pending IDs cần thiết.
- Cost view chọn cost config, stats và matches liên quan.

Dùng `BlocSelector` hoặc `buildWhen` để score update không rebuild header, tab shell hay vùng không phụ thuộc. Collection snapshots vẫn có thể trả list đầy đủ, nhưng Bloc chuẩn hóa theo ID và chỉ phát state slice khi nội dung tương ứng thực sự đổi.

Không dựng sẵn các `LeagueShareCard` ngoài màn hình. Khi người dùng chọn share, view bật trạng thái render tạm thời, dựng các variant cần cho preview trong `RepaintBoundary`, đợi frame capture, mở preview rồi dispose các card tạm. Realtime update thông thường vì thế không còn rebuild 2–4 bảng share lớn.

## Failure, rollback và lifecycle

- Lỗi bootstrap của một stream hiển thị retry cho slice cần thiết hoặc trạng thái trang nếu chưa có league; dữ liệu từ các slice đã tải không bị xóa.
- Lỗi match transaction chỉ gỡ pending của match đó; không làm mất snapshot hiện tại và không chuyển toàn trang sang failure.
- Stream error có thể re-subscribe với backoff hữu hạn; không dùng vòng full fetch. Subscription luôn được hủy khi Bloc đóng.
- League bị xóa/inactive được biểu diễn thành event rõ ràng để đóng detail an toàn; mapper không được giả định snapshot luôn tồn tại.
- Create rollback giữ hành vi xóa league document hiện tại. Nếu rollback cũng lỗi, log cả rollback failure nhưng trả lỗi tạo ban đầu cho UI; không báo thành công.

## Tương thích ngược

- Tiếp tục resolve legacy stat documents theo `userId` + `groupId`; không yêu cầu người dùng migration dữ liệu để dùng bản phát hành này.
- Giữ `expectedUpdatedAt` và `ConcurrentMatchUpdateException`. Match legacy chưa có timestamp được phép nhận lần update đầu theo hành vi hiện tại; các update sau có server timestamp và được bảo vệ đầy đủ.
- Giữ cách tính điểm, knockout advancement, toast và navigation result hiện tại, ngoại trừ thời điểm reload list được dời đến sau khi rời detail.
- Các API cũ `applyMatchStatDelta` chỉ được xóa sau khi mọi caller đã chuyển sang command nguyên tử; không giữ hai đường ghi hoạt động song song.

## Khả năng tiếp cận

- Nút tạo có label loading bằng localization, spinner tương phản và kích thước/vùng chạm ổn định.
- Khi tạo, control bị khóa không còn tap/keyboard action; focus không tự nhảy khỏi trường hiện tại.
- Match pending có text/semantics như **Đang lưu kết quả**, không chỉ đổi màu hoặc chỉ hiện animation; chỉ khóa row/action của match đó.
- Conflict và lỗi có thông báo đã dịch, đủ nghĩa khi đọc bằng screen reader.
- Remote realtime updates không liên tục phát live announcements gây nhiễu; dữ liệu mới có thể được đọc khi người dùng focus lại vùng liên quan.

## Triển khai theo pha trong cùng nhánh

1. **Create UX:** thêm localization, submit state và widget tests; bỏ participant write thừa; dời list reload sau detail.
2. **Realtime bootstrap:** tách state slices, user cache và ba snapshot handlers; xóa explicit bootstrap/full refresh, kể cả refresh khi resume.
3. **Atomic match:** viết repository tests trước, gộp match/stat/next-slot vào transaction, sau đó chuyển Bloc sang per-match pending và bỏ split delta/full reload.
4. **Render:** thêm selectors/build filters và lazy share cards; chạy widget regression tests.
5. Chạy targeted tests sau từng pha, rồi `flutter analyze` và full `flutter test` trước khi mở PR.

Mỗi pha phải giữ app build/test được để dễ cô lập regression, nhưng toàn bộ scope được hoàn thành trên nhánh hiện tại trước khi bàn giao.

## TDD và tiêu chí chấp nhận

### Create flow

- Future pending làm nút đổi sang spinner + label sau một `pump`; form/back/pop bị khóa.
- Tap nhiều lần gọi `onAddLeague` đúng 1 lần.
- Success trả đúng `leagueId` và không nháy lại nút thường trước khi pop.
- Lỗi thường và `RoundTooLargeException` mở khóa, giữ input và toast đúng một lần.
- Repository call counts: `addLeague == 1`, `addMultipleParticipants == 0`, generator đúng mode `== 1`.
- Trước khi vào detail: `LoadMyLeagues == 0`, `LoadManagedLeagues == 0`; sau khi detail pop: mỗi event `== 1`.

### Detail bootstrap và realtime

- Mở detail subscribe league/stats/matches đúng 1 lần mỗi stream.
- Explicit call counts trong bootstrap: `getLeague == 0`, `getParticipantsAndMatches == 0`, `getLeagueStats == 0`, `getMatches == 0`.
- Initial roster chỉ gọi `getUsersByIds` cho IDs thiếu; score-only, cost-only và league metadata snapshots giữ call count user không đổi.
- League snapshot không gọi stats/matches; stats snapshot không gọi league/matches; match snapshot không gọi league/stats.
- Resume không tạo full read và không nhân đôi active subscriptions.
- Một remote snapshot cập nhật đúng widget slice; header không rebuild khi chỉ score đổi và standings không rebuild khi chỉ league name đổi.

### Match transaction

- Một score update gọi atomic repository command đúng 1 lần; `applyMatchStatDelta`, `GetParticipantStats`, `GetMatches` và `GetParticipantsAndMatches` đều có call count 0.
- Transaction cập nhật match và hai stat rows trong một commit; knockout cập nhật match + next slot và không thay standings ngoài luật hiện tại.
- Sửa lại match đã hoàn tất undo contribution cũ rồi apply contribution mới đúng một lần.
- Thiếu stat hoặc transaction failure không để match/stat/next-slot ở trạng thái một phần.
- `expectedUpdatedAt` không khớp ném conflict đã định danh; không ghi document nào.

### Nhiều thiết bị và offline

- Hai Bloc/repository clients dùng cùng fake Firestore: client A cập nhật match, client B nhận match và stats snapshots mà không có toast/global loading.
- Hai clients giữ cùng version: A commit thành công, B submit stale nhận localized conflict và sau listener có state giống server.
- Hai clients cập nhật hai match khác nhau có chung player: sau cả hai transaction, fake Firestore chứa tổng stats chính xác, không mất delta.
- Future transaction pending giữ duy nhất row local ở pending và không phát success; offline/error gỡ pending, giữ confirmed snapshot và cho retry.
- Nếu fake Firestore không mô phỏng đầy đủ transaction contention retry của SDK, dùng transaction harness có kiểm soát cho retry ordering và giữ shared-fake test cho propagation; Firebase Emulator là bước integration xác nhận cuối cùng.

### Render và accessibility

- Khi chưa bấm share không tồn tại `LeagueShareCard`; mở share mới dựng variant cần thiết và đóng preview thì dispose.
- Score snapshot không rebuild các selector không phụ thuộc.
- Semantics tests xác nhận loading create, pending match và disabled actions có label/trạng thái đúng.

Targeted suites cần bao phủ `test/presentation/esport/tournament/` và `test/firebase/firestore/esport/league/`; full suite và analyzer là gate cuối, nhưng không thay thế QA thật trên hai thiết bị hoặc Firebase Emulator.
