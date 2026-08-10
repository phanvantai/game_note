// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'PES Arena';

  @override
  String get mainTabArena => 'Arena';

  @override
  String get mainTabGroups => 'Nhóm';

  @override
  String get mainTabTournaments => 'Giải đấu';

  @override
  String get mainTabNotifications => 'Thông báo';

  @override
  String get mainTabProfile => 'Cá nhân';

  @override
  String get languageTitle => 'Chọn ngôn ngữ';

  @override
  String get languageSubtitle => 'Bạn có thể thay đổi sau trong phần cài đặt.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageSystemMatch => 'Đề xuất theo thiết bị của bạn';

  @override
  String get continueButton => 'Tiếp tục';

  @override
  String get settingsTitle => 'Tuỳ chọn khác';

  @override
  String get settingsHeroEyebrow => 'Preferences';

  @override
  String get settingsHeroSubtitle => 'Bảo mật, giao diện và tài khoản.';

  @override
  String get settingsUpdateProfile => 'Cập nhật thông tin';

  @override
  String get settingsChangePassword => 'Đổi mật khẩu';

  @override
  String get settingsDarkMode => 'Chế độ tối';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsDeleteAccount => 'Xoá tài khoản';

  @override
  String get settingsDeleteConfirmTitle => 'Xác nhận';

  @override
  String get settingsDeleteConfirmMessage =>
      'Bạn có chắc chắn muốn xoá tài khoản không?\n\nTất cả dữ liệu cá nhân của bạn sẽ bị xoá và không thể khôi phục. Một số dữ liệu liên quan đến nhóm và các người chơi khác sẽ vẫn được giữ lại.';

  @override
  String get cancel => 'Huỷ';

  @override
  String ownershipCheckFailed(String error) {
    return 'Không thể kiểm tra quyền sở hữu: $error';
  }

  @override
  String get authContinue => 'Đăng nhập để tiếp tục';

  @override
  String get authSignIn => 'Đăng nhập';

  @override
  String get authRegister => 'Đăng ký';

  @override
  String get authForgotPassword => 'Quên mật khẩu';

  @override
  String get authResetPasswordSubmit => 'Gửi email đặt lại mật khẩu';

  @override
  String get authResetPasswordSent => 'Đã gửi email đặt lại mật khẩu';

  @override
  String get authSignInSuccess => 'Đăng nhập thành công';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Mật khẩu';

  @override
  String get authContinueWithGoogle => 'Tiếp tục với Google';

  @override
  String get authContinueWithApple => 'Tiếp tục với Apple';

  @override
  String get authVerifyAccountTitle => 'Xác thực tài khoản';

  @override
  String get authVerificationSent =>
      'Mã xác thực đã được gửi đến số điện thoại của bạn';

  @override
  String get authVerificationCode => 'Mã xác thực';

  @override
  String get authVerify => 'Xác thực';

  @override
  String get profileChangePasswordTitle => 'Đổi mật khẩu';

  @override
  String get profileCurrentPasswordHint => 'Mật khẩu hiện tại';

  @override
  String get profileNewPasswordHint => 'Mật khẩu mới';

  @override
  String get profileConfirmNewPasswordHint => 'Xác nhận mật khẩu mới';

  @override
  String get profileChangePasswordSuccess => 'Đổi mật khẩu thành công';

  @override
  String get profileSecurityEyebrow => 'Security';

  @override
  String get profileSecuritySubtitle =>
      'Cập nhật mật khẩu để bảo vệ tài khoản.';

  @override
  String get or => 'Hoặc';

  @override
  String get pageNotFound => 'Không tìm thấy trang';

  @override
  String get backHome => 'Về trang chủ';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonCreate => 'Tạo';

  @override
  String get commonAdd => 'Thêm';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonSend => 'Gửi';

  @override
  String get commonDelete => 'Xoá';

  @override
  String get commonUpdate => 'Cập nhật';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonErrorTitle => 'Đã xảy ra lỗi';

  @override
  String get commonRetryLater => 'Vui lòng thử lại sau';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSearchByName => 'Tìm theo tên';

  @override
  String get appOnline => 'Online';

  @override
  String get appOffline => 'Offline';

  @override
  String get offlineLeagueTitle => 'Giải đấu';

  @override
  String get offlinePlayersTitle => 'Người chơi';

  @override
  String get offlineStatisticsTitle => 'Thống kê';

  @override
  String get offlineCreateLeagueTitle => 'Tạo giải đấu';

  @override
  String get offlineLeagueNameHint => 'Tên giải đấu';

  @override
  String get offlineAddLeagueTooltip => 'Thêm giải đấu mới';

  @override
  String get offlineNoLeaguesTitle => 'Chưa có giải đấu nào được tạo.';

  @override
  String get offlineNoLeaguesSubtitle =>
      'Bấm nút + bên dưới để tạo một giải đấu';

  @override
  String get offlineDeleteLeagueTitle => 'Xoá giải đấu';

  @override
  String offlineDeleteLeagueMessage(String name) {
    return 'Bạn có chắc muốn xoá giải đấu $name?';
  }

  @override
  String offlineShareStandingsTitle(String name) {
    return 'Bảng xếp hạng - $name';
  }

  @override
  String get offlineLeagueNotSetupTitle => 'Giải đấu chưa được thiết lập.';

  @override
  String get offlineLeagueNotSetupSubtitle =>
      'Bấm nút + bên dưới để thêm người chơi và bắt đầu giải đấu';

  @override
  String get offlineLoadLeagueFailed => 'Không thể tải dữ liệu giải đấu';

  @override
  String get offlineShareStandings => 'Chia sẻ BXH';

  @override
  String get offlineSchedule => 'Lịch thi đấu';

  @override
  String get offlineResults => 'Kết quả';

  @override
  String get offlineAddPlayerTitle => 'Thêm người chơi';

  @override
  String get offlinePlayerNameHint => 'Tên người chơi';

  @override
  String get offlineNoPlayersTitle => 'Chưa có người chơi nào.';

  @override
  String get offlineNoPlayersSubtitle =>
      'Bấm nút + bên dưới để thêm người chơi.';

  @override
  String get offlineAddPlayerTooltip => 'Thêm người chơi';

  @override
  String offlinePlayerDeleted(String name) {
    return 'Đã xóa $name';
  }

  @override
  String get offlineUpdateScoreTitle => 'Cập nhật tỉ số';

  @override
  String get offlineAddRoundTooltip => 'Thêm vòng đấu';

  @override
  String offlineSelectingPlayers(int count) {
    return 'Selecting 2 player. Selected: $count';
  }

  @override
  String offlineSelectedPlayers(int count) {
    return 'Selected: $count';
  }

  @override
  String get offlineDataTitle => 'DỮ LIỆU';

  @override
  String get offlineImportData => 'Nhập dữ liệu';

  @override
  String get offlineExportData => 'Xuất dữ liệu';

  @override
  String get offlineInvalidImportFile =>
      'Tệp tin không đúng.\nVui lòng sử dụng 1 tệp tin database game_note_database.db';

  @override
  String get offlineImportSuccess => 'Dữ liệu đã được nhập thành công';

  @override
  String get offlineStatPointsGoalDiff => 'Điểm/Hiệu số';

  @override
  String get offlineStatChampionRunnerUp => 'Vô địch/Á quân';

  @override
  String get offlineStatWinDrawLoss => 'Thắng/Hoà/Thua';

  @override
  String get syncNoOfflineLeague => 'Không có league offline nào để đồng bộ';

  @override
  String get syncNoGroup => 'Bạn chưa tham gia group nào';

  @override
  String get syncNoLeagueSelected => 'Chưa chọn league';

  @override
  String get syncChoose => 'Chọn';

  @override
  String get syncNoGroupMembers => 'Group chưa có thành viên nào';

  @override
  String get syncCreatePlaceholderUser => 'Tạo user mới (placeholder)';

  @override
  String get syncNewPlayerName => 'Tên người chơi mới';

  @override
  String get syncDisplayNameHint => 'Tên hiển thị';

  @override
  String get syncMissingData => 'Thiếu dữ liệu';

  @override
  String syncDateLabel(String date) {
    return 'Ngày: $date';
  }

  @override
  String syncTargetGroupLabel(String group) {
    return 'Group đích: $group';
  }

  @override
  String get syncNoPlayedMatches => 'Không có trận nào đã đấu';

  @override
  String get syncSuccess => 'Đồng bộ thành công';

  @override
  String get syncRetry => 'Thử lại';

  @override
  String get syncBack => 'Quay lại';

  @override
  String get syncExit => 'Thoát';

  @override
  String get syncContinue => 'Tiếp tục';

  @override
  String get syncOfflineLeagueSection => 'League offline';

  @override
  String get syncOnlineGroupSection => 'Group online';

  @override
  String syncLeagueDescription(int players, String date) {
    return '$players người chơi · $date';
  }

  @override
  String get syncPreview => 'Xem trước';

  @override
  String get syncDuplicateMapping => 'Lỗi: 2 người chơi cùng map vào 1 user';

  @override
  String get syncNotMapped => 'Chưa map';

  @override
  String get syncNewTargetSuffix => 'mới';

  @override
  String syncMapPlayerTitle(String name) {
    return 'Map \"$name\"';
  }

  @override
  String get syncWritingData => 'Đang ghi dữ liệu lên server...';

  @override
  String get syncDoNotClose => 'Vui lòng không đóng app cho đến khi hoàn tất';

  @override
  String get syncSelectSourceTitle => 'Chọn league & group';

  @override
  String get syncMapPlayersTitle => 'Map người chơi';

  @override
  String get syncConfirmTitle => 'Xác nhận';

  @override
  String get syncExecutingTitle => 'Đang đồng bộ';

  @override
  String get syncOriginalOfflineTab => 'Offline (gốc)';

  @override
  String get syncOnlineWillCreateTab => 'Online (sẽ tạo)';

  @override
  String get syncRun => 'Đồng bộ';

  @override
  String get syncNewSuffix => 'mới';

  @override
  String syncWritesCount(int count) {
    return 'Sẽ ghi $count bản ghi lên server';
  }

  @override
  String get syncStandingsTitle => 'Bảng xếp hạng';

  @override
  String syncMatchResultsTitle(int count) {
    return 'Kết quả trận đấu ($count)';
  }

  @override
  String syncNewPlayersWillBeCreated(int count) {
    return 'Người chơi mới sẽ được tạo ($count)';
  }

  @override
  String get tablePlayer => 'Người chơi';

  @override
  String get tableMatchesPlayedShort => 'MP';

  @override
  String get tableWinsShort => 'W';

  @override
  String get tableDrawsShort => 'D';

  @override
  String get tableLossesShort => 'L';

  @override
  String get tableGoalsForShort => 'GF';

  @override
  String get tableGoalsAgainstShort => 'GA';

  @override
  String get tableGoalDifferenceShort => 'GD';

  @override
  String get tablePointsShort => 'Pts';

  @override
  String get groupCreateSuccess => 'Tạo nhóm thành công';

  @override
  String get groupCreateTitle => 'Tạo nhóm mới';

  @override
  String get groupNameHint => 'Tên nhóm';

  @override
  String get groupDescriptionHint => 'Mô tả nhóm';

  @override
  String get groupNameRequired => 'Tên nhóm không được để trống';

  @override
  String get groupCreateButton => 'Tạo nhóm';

  @override
  String get groupEmptyTitle => 'Không có nhóm nào';

  @override
  String get groupEmptySubtitle => 'Tạo nhóm mới để bắt đầu';

  @override
  String get groupHeroEyebrow => 'Community hub';

  @override
  String get groupHeroTitle => 'Quản lý đội nhóm PES';

  @override
  String get groupCreateNew => 'Tạo mới';

  @override
  String get groupMineStat => 'Của tôi';

  @override
  String get groupDiscoverStat => 'Khám phá';

  @override
  String get groupMembersStat => 'Member';

  @override
  String groupMemberCount(int count) {
    return '$count thành viên';
  }

  @override
  String get groupMyGroupsTab => 'Nhóm của tôi';

  @override
  String get groupOtherGroupsTab => 'Nhóm khác';

  @override
  String get groupAddMemberTitle => 'Thêm thành viên';

  @override
  String get groupCreatePlaceholderPlayer => 'Tạo người chơi mới (placeholder)';

  @override
  String get groupCreateNewPlayer => 'Tạo người chơi mới';

  @override
  String get groupDeleteWarning =>
      'Thao tác này sẽ xoá vĩnh viễn nhóm, toàn bộ giải đấu, trận đấu, bảng điểm và thống kê liên quan. Dữ liệu không thể khôi phục.';

  @override
  String get groupSearchByNameHint => 'Tìm kiếm theo tên';

  @override
  String get groupPlayerNameHint => 'Tên người chơi';

  @override
  String get groupAddMemberSuccess => 'Thêm thành viên thành công';

  @override
  String get groupPlayerAddedSuccess => 'Đã thêm người chơi mới';

  @override
  String get groupUpdateStatusFailed => 'Không thể cập nhật trạng thái';

  @override
  String get groupDeleteRequestSent => 'Đã gửi yêu cầu xoá nhóm';

  @override
  String get groupDeleteTitle => 'Xoá nhóm';

  @override
  String get groupOverviewTab => 'Tổng quan';

  @override
  String get groupMembersTab => 'Thành viên';

  @override
  String get groupInactive => 'Không hoạt động';

  @override
  String get groupDescriptionTitle => 'Mô tả';

  @override
  String get groupNoOverview => 'Chưa có dữ liệu tổng quan';

  @override
  String get groupRefreshStatsTitle => 'Cập nhật thống kê?';

  @override
  String get groupRefreshStatsTooltip => 'Cập nhật thống kê';

  @override
  String get groupOverviewTitle => 'Tổng quan group';

  @override
  String get groupYearFilterAll => 'Tất cả';

  @override
  String get groupRefreshStatsMessage =>
      'Hệ thống sẽ tải lại toàn bộ giải đấu và tính lại thống kê group. Thao tác này có thể mất vài giây.';

  @override
  String get groupOverviewLoadFailed => 'Không thể tải dữ liệu tổng quan.';

  @override
  String groupOverviewLoadError(String message) {
    return 'Lỗi tải dữ liệu: $message';
  }

  @override
  String get groupLegendChampion => 'Vô đối';

  @override
  String get groupLegendRunnerUp => 'Kẻ về nhì vĩ đại';

  @override
  String get groupLegendPro => 'Cao thủ';

  @override
  String get groupLegendDefense => 'Hàng thủ thép';

  @override
  String get groupTitles => 'Danh hiệu';

  @override
  String get groupMemberStats => 'Thống kê thành viên';

  @override
  String get groupNotEnoughAwardsData =>
      'Chưa đủ dữ liệu để trao danh hiệu (cần ít nhất 5 giải finished hoặc 5 trận đấu).';

  @override
  String get groupNoMemberStats => 'Chưa có dữ liệu thành viên.';

  @override
  String get groupReplaceSuccess => 'Đã thay thế thành công';

  @override
  String get groupReplaceError => 'Có lỗi xảy ra, vui lòng thử lại';

  @override
  String get groupReplaceSelectOld => 'Chọn người cần thay';

  @override
  String get groupReplaceSelectNew => 'Chọn người thay thế';

  @override
  String get groupReplaceConfirm => 'Xác nhận thay thế';

  @override
  String get groupNoSearchResults => 'Không tìm thấy';

  @override
  String get groupReplaceOldLabel => 'Thay';

  @override
  String get groupReplaceNewLabel => 'Bằng';

  @override
  String get groupReplaceMergeWarning =>
      'Người này đã có trong giải. Thống kê của 2 người sẽ được cộng gộp lại.';

  @override
  String get groupActionIrreversible => 'Hành động này không thể hoàn tác.';

  @override
  String get groupClose => 'Đóng';

  @override
  String get groupPlaceholder => 'Placeholder';

  @override
  String get costRankPayoutRequired =>
      'Nhập số tiền theo thứ hạng (VD: 50, 100)';

  @override
  String get costBracketPayoutTitle => 'Tính tiền theo bracket';

  @override
  String get costRankPayoutTitle => 'Tính tiền theo thứ hạng';

  @override
  String get costBracketPayoutSubtitle =>
      'Champion nhận tiền từ runner-up và người bị loại sớm';

  @override
  String get costRankPayoutSubtitle =>
      'Hạng dưới góp tiền cho hạng nhất theo cấu hình';

  @override
  String get costPayoutHint => 'VD: 50, 100, 150 (k VND)';

  @override
  String get costBracketPayoutOrder =>
      'Lần lượt: runner-up, mỗi người thua bán kết, mỗi người thua tứ kết...';

  @override
  String get costRankPayoutOrder =>
      'Lần lượt: hạng 2, hạng 3, hạng 4... đóng cho hạng 1.';

  @override
  String get costDefaultMatchCostHint => 'Tiền mặc định mỗi trận (k VND)';

  @override
  String get costDefaultMatchCostHelp =>
      'Số này sẽ được điền sẵn khi bật cost cho từng trận lúc nhập kết quả.';

  @override
  String get costDefaultPerGoalTitle =>
      'Mặc định bật tiền theo hiệu số bàn thắng';

  @override
  String get costDefaultPerGoalSubtitle =>
      'Người thua trả thêm theo hiệu số bàn thắng (VD: 3-1 cộng 2 lần số này).';

  @override
  String get costPerGoalHint => 'Tiền mỗi bàn (k VND)';

  @override
  String get costPerGoalHelp =>
      'Cộng vào tiền per-match khi trận đó cũng bật tính tiền.';

  @override
  String get costSuggestions => 'Gợi ý:';

  @override
  String costPresetAmountLabel(String amounts) {
    return '$amounts k';
  }

  @override
  String get tournamentSelectGroupRequired => 'Bạn cần chọn nhóm';

  @override
  String get tournamentParticipantsMinimum =>
      'Cần chọn ít nhất 2 người tham gia';

  @override
  String get tournamentCupPowerOfTwoRequired =>
      'Cup cần số người là lũy thừa của 2 (2, 4, 8, 16...)';

  @override
  String get tournamentFullKnockoutPowerOfTwoRequired =>
      'Số bảng x số lên knockout phải là lũy thừa của 2';

  @override
  String get tournamentNameRequired => 'Bạn cần nhập tên giải đấu';

  @override
  String get tournamentStartBeforeEndRequired =>
      'Ngày bắt đầu phải trước ngày kết thúc';

  @override
  String get tournamentEndAfterStartRequired =>
      'Ngày kết thúc phải sau ngày bắt đầu';

  @override
  String get tournamentNoGroupsTitle => 'Bạn chưa tham gia nhóm nào';

  @override
  String get tournamentNoGroupsSubtitle =>
      'Hãy tạo hoặc tham gia một nhóm trước khi tạo giải đấu';

  @override
  String get tournamentSelectGroupTitle => 'Chọn nhóm';

  @override
  String get tournamentSelectGroupSubtitle => 'Giải đấu sẽ thuộc về nhóm này';

  @override
  String tournamentMembersCount(int count) {
    return '$count thành viên';
  }

  @override
  String get tournamentAddPlayersTitle => 'Thêm người chơi';

  @override
  String tournamentAddPlayersSubtitle(int count) {
    return 'Chọn ít nhất 2 người ($count đã chọn)';
  }

  @override
  String get tournamentModeTitle => 'Chế độ giải đấu';

  @override
  String get tournamentModeSubtitle => 'Chọn kiểu thi đấu';

  @override
  String get tournamentModeLeague => 'League';

  @override
  String get tournamentModeLeagueSubtitle =>
      'Đấu vòng tròn, mọi người gặp nhau';

  @override
  String get tournamentModeCup => 'Cup';

  @override
  String get tournamentModeCupSubtitle => 'Loại trực tiếp, thua là out';

  @override
  String get tournamentModeFull => 'Full';

  @override
  String get tournamentModeFullSubtitle => 'Đá bảng đến knockout';

  @override
  String get tournamentConfigPreviewTitle => 'Cấu hình & Xem trước';

  @override
  String get tournamentConfigPreviewSubtitle => 'Tuỳ chỉnh trước khi tạo giải';

  @override
  String get tournamentInfoTitle => 'Thông tin giải';

  @override
  String get tournamentInfoSubtitle => 'Đặt tên và thời gian';

  @override
  String get tournamentNameDescriptionTitle => 'Tên & mô tả';

  @override
  String get tournamentNameHint => 'Tên giải đấu';

  @override
  String get tournamentDescriptionHint => 'Mô tả (tuỳ chọn)';

  @override
  String get tournamentTimeTitle => 'Thời gian';

  @override
  String get tournamentStartDateHint => 'Ngày bắt đầu';

  @override
  String get tournamentEndDateHint => 'Ngày kết thúc';

  @override
  String get tournamentCostSubtitle => 'Có thể cấu hình sau';

  @override
  String get tournamentStatsSynced => 'Đã đồng bộ lại điểm số';

  @override
  String get tournamentCostUpdated => 'Đã cập nhật chi phí giải đấu';

  @override
  String get tournamentCustomMatchCreated => 'Tạo trận đấu thành công';

  @override
  String get tournamentCreateMatchTitle => 'Tạo trận đấu';

  @override
  String get tournamentMatchDeleted => 'Xoá trận đấu thành công';

  @override
  String get tournamentDeleted => 'Đã xoá giải đấu';

  @override
  String get tournamentStatusUpdated =>
      'Cập nhật trạng thái giải đấu thành công';

  @override
  String get tournamentPlayerAdded => 'Thêm người chơi thành công';

  @override
  String tournamentPlayersAdded(int count) {
    return 'Thêm $count người chơi thành công';
  }

  @override
  String get tournamentGroupRoundMinimum =>
      'Bảng cần ít nhất 2 người chơi để tạo lượt đấu';

  @override
  String get tournamentRoundCreated => 'Tạo lượt đấu thành công';

  @override
  String get tournamentMatchUpdated => 'Cập nhật trận đấu thành công';

  @override
  String get tournamentMatchConcurrentUpdate =>
      'Trận này vừa được người khác cập nhật. Vui lòng kiểm tra lại.';

  @override
  String get tournamentBracketCreated => 'Tạo bracket thành công';

  @override
  String get tournamentFullCreated => 'Tạo giải Full thành công';

  @override
  String tournamentSelectedPlayersCount(int count) {
    return 'Đã chọn $count người:';
  }

  @override
  String tournamentAddPlayersCount(int count) {
    return 'Thêm $count người';
  }

  @override
  String get tournamentLoadingCost => 'Đang tải chi phí';

  @override
  String get tournamentNoCostTitle => 'Chưa có chi phí';

  @override
  String get tournamentNoCostSubtitle =>
      'Bật cấu hình chi phí hoặc nhập tiền trong từng trận';

  @override
  String get tournamentHomeTeamHint => 'Đội nhà';

  @override
  String get tournamentAwayTeamHint => 'Đội khách';

  @override
  String get tournamentSelectTeamRequired => 'Vui lòng chọn đội';

  @override
  String get tournamentDistinctTeamsRequired => 'Vui lòng chọn 2 đội khác nhau';

  @override
  String get tournamentUpdateResultTitle => 'Cập nhật kết quả';

  @override
  String get tournamentMatchHasCost => 'Có tiền cho trận này';

  @override
  String get tournamentMatchCostLabel => 'Số tiền (k VND)';

  @override
  String get tournamentAddGoalDifferenceCost =>
      'Thêm tiền theo hiệu số bàn thắng';

  @override
  String get tournamentGoalDifferenceCostHelp => 'VD: 3-1 cộng x2 vào tiền.';

  @override
  String get tournamentScoreRequired => 'Nhập kết quả trận đấu';

  @override
  String get tournamentTabBracket => 'Bracket';

  @override
  String get tournamentTabResults => 'Kết quả';

  @override
  String get tournamentTabCost => 'Chi phí';

  @override
  String get tournamentTabGroups => 'Bảng';

  @override
  String tournamentGroupLabel(String groupId) {
    return 'Bảng $groupId';
  }

  @override
  String get tournamentTabStandings => 'BXH';

  @override
  String get tournamentTabFixtures => 'Lịch';

  @override
  String get tournamentStatusTitle => 'Trạng thái giải đấu';

  @override
  String get tournamentRecomputeStatsTitle => 'Đồng bộ điểm số';

  @override
  String get tournamentRecomputeStatsMessage =>
      'Tính lại toàn bộ điểm số từ kết quả các trận đã đấu? Dùng khi điểm bị lệch do dữ liệu cũ.';

  @override
  String get tournamentRecomputeStatsConfirm => 'Đồng bộ';

  @override
  String get tournamentDeleteTitle => 'Xóa giải đấu';

  @override
  String get tournamentDeleteMessage =>
      'Bạn có chắc chắn muốn xóa giải đấu này không?';

  @override
  String get tournamentEnded => 'Giải đấu đã kết thúc';

  @override
  String get tournamentLoadingTitle => 'Đang tải giải đấu';

  @override
  String get tournamentBackTooltip => 'Quay lại';

  @override
  String get tournamentOptionsTooltip => 'Tuỳ chọn giải đấu';

  @override
  String get tournamentShareStandings => 'Chia sẻ BXH';

  @override
  String get tournamentStatusMenu => 'Trạng thái';

  @override
  String get tournamentGroupMatchesTitle => 'Trận đấu bảng';

  @override
  String get tournamentAddRound => 'Thêm lượt đấu';

  @override
  String get tournamentScheduleTitle => 'Lịch thi đấu';

  @override
  String get tournamentCreateCustomMatchTooltip => 'Tạo trận tùy chỉnh';

  @override
  String get tournamentSearchPlayerHint => 'Tìm theo tên người chơi (vd: A B)';

  @override
  String get tournamentNoMatchesFound => 'Không tìm thấy trận nào';

  @override
  String get tournamentNoFixtures => 'Chưa có lịch thi đấu';

  @override
  String get tournamentNoResults => 'Chưa có kết quả';

  @override
  String tournamentGenerateRoundWithExisting(int count) {
    return 'Hiện có $count trận trong lịch. Tạo thêm một lượt mới, chia theo vòng?';
  }

  @override
  String tournamentMatchdayLabel(int n) {
    return 'Vòng $n';
  }

  @override
  String tournamentMatchdayBadge(int n) {
    return 'V$n';
  }

  @override
  String get tournamentOtherMatches => 'Trận khác';

  @override
  String tournamentRoundTooLarge(int max) {
    return 'Giải có quá nhiều người chơi để tạo một lượt (tối đa $max).';
  }

  @override
  String get tournamentGenerateRoundMessage =>
      'Tạo lượt đấu mới? Các trận sẽ được chia theo vòng.';

  @override
  String get tournamentNoPlayersTitle => 'Chưa có người chơi nào';

  @override
  String get tournamentNoPlayersSubtitle =>
      'Thêm người chơi để bắt đầu giải đấu';

  @override
  String tournamentShareStandingsTitle(String leagueName) {
    return 'Bảng xếp hạng - $leagueName';
  }

  @override
  String get tournamentShareStandingsSheetTitle => 'Chia sẻ bảng xếp hạng';

  @override
  String get tournamentPreparingShare => 'Đang chuẩn bị...';

  @override
  String get tournamentShareNow => 'Chia sẻ ngay';

  @override
  String get tournamentShareIncludeRankCost => 'Kèm chi phí';

  @override
  String get tournamentLightTheme => 'Sáng';

  @override
  String get tournamentDarkTheme => 'Tối';

  @override
  String get tournamentHeroEyebrow => 'Tournament arena';

  @override
  String get tournamentHeroTitle => 'Quản lý giải đấu PES';

  @override
  String get tournamentMyStat => 'Của tôi';

  @override
  String get tournamentLiveStat => 'Live';

  @override
  String get tournamentPlayersStat => 'Player';

  @override
  String get tournamentJoinedTab => 'Tham gia';

  @override
  String get tournamentManagedTab => 'Quản lý';

  @override
  String get tournamentOtherTab => 'Khác';

  @override
  String get tournamentJoinGroupFirst =>
      'Bạn chưa tham gia nhóm nào. Hãy tham gia nhóm trước';

  @override
  String get tournamentCreatingLeague => 'Đang tạo giải…';

  @override
  String get tournamentSavingMatch => 'Đang lưu kết quả';

  @override
  String get tournamentCreateSuccess => 'Tạo giải đấu thành công';

  @override
  String get tournamentCreateButton => 'Tạo giải đấu';

  @override
  String get tournamentEmptyTitle => 'Không có giải đấu nào';

  @override
  String get tournamentEmptySubtitle => 'Tạo giải đấu mới để bắt đầu';

  @override
  String get tournamentManagedEmptySubtitle =>
      'Tạo giải đấu mới để bắt đầu quản lý';

  @override
  String get commonListEnd => 'Đã hết';

  @override
  String get dashboardLoadError => 'Lỗi tải dữ liệu';

  @override
  String get homeOngoingTournamentsTitle => 'Giải đấu đang diễn ra';

  @override
  String get dashboardSignInRequired => 'Người dùng chưa đăng nhập';

  @override
  String get dashboardRecentForm10 => 'Phong độ 10 trận gần nhất';

  @override
  String get dashboardRecentMatches => 'Trận gần đây';

  @override
  String get dashboardNoMatches => 'Chưa có trận nào';

  @override
  String get dashboardHeroEyebrow => 'Control room';

  @override
  String get dashboardHeroTitle => 'Theo dõi phong độ thi đấu';

  @override
  String get dashboardViewDetail => 'Xem chi tiết';

  @override
  String get dashboardWinRate => 'Tỉ lệ thắng';

  @override
  String get dashboardGoalDifference => 'Hiệu số';

  @override
  String get dashboardMatches => 'Trận';

  @override
  String dashboardMatchesCount(int count) {
    return '$count trận';
  }

  @override
  String get dashboardNoValue => '—';

  @override
  String get dashboardNoData => 'Chưa có';

  @override
  String get dashboardTournamentsJoined => 'Giải đã tham gia';

  @override
  String get dashboardChampionRate => 'Tỉ lệ vô địch';

  @override
  String get dashboardRunnerUpRate => 'Tỉ lệ á quân';

  @override
  String get dashboardLatestChampion => 'Vô địch gần nhất';

  @override
  String get dashboardToday => 'Hôm nay';

  @override
  String dashboardDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get dashboardInsufficientChartData => 'Chưa đủ dữ liệu để vẽ biểu đồ';

  @override
  String get dashboardPointsPerMatch => 'Điểm / trận';

  @override
  String get dashboardGoalDifferencePerMatch => 'Hiệu số / trận';

  @override
  String get dashboardH2HTitle => 'Lịch sử đối đầu';

  @override
  String get dashboardNoH2HData => 'Chưa có dữ liệu đối đầu';

  @override
  String get dashboardStatsTitle => 'Bảng thống kê';

  @override
  String get dashboardDetailEyebrow => 'Chi tiết dashboard';

  @override
  String get dashboardDetailSubtitle => 'Toàn cảnh thành tích thi đấu';

  @override
  String get dashboardRefreshTooltip => 'Cập nhật từ máy chủ';

  @override
  String get dashboardOverview => 'Tổng quan';

  @override
  String get dashboardMetricTournamentsJoined => 'Số giải tham gia';

  @override
  String get dashboardMetricMatches => 'Số trận';

  @override
  String get dashboardMetricLatestChampion => 'Vô địch gần nhất';

  @override
  String get dashboardMetricWdlCount => 'Thắng / Hoà / Thua';

  @override
  String get dashboardMetricWdlRate => 'Tỉ lệ T / H / T';

  @override
  String get dashboardMetricGoals => 'BT / BB / Hiệu số';

  @override
  String get dashboardMetricChampion => 'Vô địch';

  @override
  String get dashboardMetricRunnerUp => 'Á quân';

  @override
  String get dashboardRecentLeagueForm5 => 'Phong độ 5 giải gần nhất';

  @override
  String get dashboardRefreshTitle => 'Cập nhật thống kê?';

  @override
  String get dashboardRefreshMessage =>
      'Hệ thống sẽ tính lại toàn bộ thống kê từ dữ liệu trận đấu. Thao tác này có thể mất vài giây.';

  @override
  String get dashboardH2HSectionTitle => 'Đối đầu';

  @override
  String get dashboardH2HSectionSubtitle =>
      'Khắc tinh và mồi ngon theo lịch sử gặp nhau';

  @override
  String get dashboardH2HSortMostMatches => 'Nhiều trận';

  @override
  String get dashboardH2HSortWins => 'Thắng nhiều';

  @override
  String get dashboardH2HSortLosses => 'Thua nhiều';

  @override
  String get dashboardNemesis => 'Khắc tinh';

  @override
  String get dashboardFavorableOpponent => 'Mồi ngon';

  @override
  String get dashboardLossMetric => 'thua';

  @override
  String get dashboardWinMetric => 'thắng';

  @override
  String get dashboardWdlWin => 'Thắng';

  @override
  String get dashboardWdlDraw => 'Hoà';

  @override
  String get dashboardWdlLoss => 'Thua';

  @override
  String get dashboardWdlWinShort => 'T';

  @override
  String get dashboardWdlDrawShort => 'H';

  @override
  String get dashboardWdlLossShort => 'B';

  @override
  String dashboardOpponentRecordLine(int count, int total, Object metric) {
    return '$count / $total trận $metric';
  }

  @override
  String dashboardWinRateValue(int value) {
    return '$value% thắng';
  }

  @override
  String dashboardNeedMoreH2H(int count) {
    return 'Cần ≥ $count trận\nđối đầu cùng người';
  }

  @override
  String dashboardMinMatchesChip(int count) {
    return '(≥ $count trận)';
  }

  @override
  String get dashboardThresholdTooltip => 'Tuỳ chỉnh ngưỡng';

  @override
  String get dashboardViewAllOpponents => 'Xem tất cả đối thủ';

  @override
  String get dashboardMinMatchesTitle => 'Ngưỡng số trận tối thiểu';

  @override
  String dashboardMinMatchesDescription(int count) {
    return 'Đối thủ phải có ít nhất $count trận đối đầu mới được tính vào \"Khắc tinh\" / \"Mồi ngon\". Đặt cao hơn để loại bớt nhiễu khi mẫu nhỏ.';
  }

  @override
  String get dashboardMatchesUnit => 'trận';

  @override
  String get feedbackTitle => 'Góp ý';

  @override
  String get feedbackSignInRequired => 'Bạn cần đăng nhập để gửi phản hồi.';

  @override
  String get feedbackCreateTitle => 'Tạo phản hồi';

  @override
  String get feedbackTitleHint => 'Tiêu đề';

  @override
  String get feedbackContentHint => 'Nội dung';

  @override
  String get feedbackRequired => 'Vui lòng điền đầy đủ thông tin.';

  @override
  String get feedbackMinimumLength =>
      'Tiêu đề phải có ít nhất 5 ký tự\nNội dung phải có ít nhất 10 ký tự.';

  @override
  String get feedbackSent => 'Góp ý đã được gửi thành công!';

  @override
  String get profileUpdateSuccess => 'Cập nhật thông tin thành công';

  @override
  String get profileUpdateTitle => 'Cập nhật thông tin';

  @override
  String get profileSetupEyebrow => 'Profile setup';

  @override
  String get profileCompleteTitle => 'Hoàn thiện hồ sơ';

  @override
  String get profileCompleteSubtitle =>
      'Nhập tên hiển thị để tiếp tục sử dụng các tính năng online.';

  @override
  String get profileContinue => 'Tiếp tục';

  @override
  String get profileDisplayInfoTitle => 'Thông tin hiển thị';

  @override
  String get profileDisplayInfoSubtitle =>
      'Cập nhật tên, số điện thoại và email.';

  @override
  String get profileFullNameHint => 'Họ và tên';

  @override
  String get profilePhoneHint => 'Số điện thoại';

  @override
  String get notificationActivityEyebrow => 'Activity feed';

  @override
  String get notificationAllRead => 'Tất cả đã được đọc';

  @override
  String notificationUnreadCount(int count) {
    return '$count thông báo mới';
  }

  @override
  String get notificationMarkAllRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get notificationRead => 'Đã đọc';

  @override
  String get profileAppSection => 'Ứng dụng';

  @override
  String get profileOfflineMode => 'Chế độ offline';

  @override
  String get profileSyncOfflineData => 'Đồng bộ dữ liệu offline';

  @override
  String get profileOtherOptions => 'Tuỳ chọn khác';

  @override
  String get profileInfoSection => 'Thông tin';

  @override
  String get profileRateApp => 'Đánh giá';

  @override
  String get profileFeedback => 'Nhận xét góp ý';

  @override
  String get profileSessionSection => 'Phiên làm việc';

  @override
  String get profileSignOut => 'Đăng xuất';

  @override
  String get profileChangeAvatar => 'Thay đổi ảnh đại diện';

  @override
  String get profileDeleteAvatar => 'Xoá ảnh đại diện';

  @override
  String get profileEditTooltip => 'Cập nhật thông tin';

  @override
  String get profileOfflineModeTitle => 'Chế độ Offline';

  @override
  String get profileOfflineModeMessage =>
      'Chế độ offline là bạn tự tạo dữ liệu trên máy và dữ liệu sẽ chỉ được lưu trên máy của bạn, không được đồng bộ.\n\nBạn có chắc chắn muốn chuyển sang chế độ offline không?';

  @override
  String get profileAccept => 'Chấp nhận';

  @override
  String get profileSignOutMessage => 'Bạn có chắc chắn muốn đăng xuất không?';

  @override
  String ownershipProcessFailed(String error) {
    return 'Không thể xử lý quyền sở hữu: $error';
  }

  @override
  String get ownershipResolutionTitle => 'Xử lý quyền sở hữu';

  @override
  String get ownershipResolutionMessage =>
      'Bạn đang là chủ sở hữu của các nhóm/giải bên dưới. Hãy chuyển quyền cho thành viên khác hoặc ngừng hoạt động trước khi xoá tài khoản.';

  @override
  String get ownershipGroup => 'Nhóm';

  @override
  String get ownershipTournament => 'Giải đấu';

  @override
  String get ownershipContinueDelete => 'Tiếp tục xoá tài khoản';

  @override
  String get ownershipTransfer => 'Chuyển';

  @override
  String get ownershipDeactivate => 'Ngừng';
}
