import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import '../../../../core/helpers/admob_helper.dart';
import 'add_player_popup.dart';
import 'bloc/tournament_detail_bloc.dart';
import 'matches/matches_view.dart';
import 'table/table_view.dart';
import 'widgets/league_share_card.dart';
import 'widgets/share_preview_bottom_sheet.dart';

class TournamentDetailView extends StatefulWidget {
  const TournamentDetailView({super.key});

  @override
  State<TournamentDetailView> createState() => _TournamentDetailViewState();
}

class _TournamentDetailViewState extends State<TournamentDetailView>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

  /// Key used to capture the off-screen share card (no horizontal scroll).
  final GlobalKey _shareCardKey = GlobalKey();

  /// Width used for the off-screen share card. Wide enough to fit all columns.
  static const double _shareCardWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) => DefaultTabController(
        length: 3,
        child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/svg/trophy-solid.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  colorScheme.secondary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.league?.name.isEmpty == true
                      ? ("${state.league?.group?.groupName ?? " "} ${DateFormat('dd/MM/yyyy').format(state.league?.startDate ?? DateTime.now())}")
                      : state.league?.name ?? '',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'BXH'),
              Tab(text: 'Lịch thi đấu'),
              Tab(text: 'Kết quả'),
            ],
          ),
          actions: [
            if (state.currentUserIsMember)
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                tooltip: 'Thêm người chơi',
                onPressed: () => _addParticipant(context, state),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    _shareStandings(state);
                    break;
                  case 'change_status':
                    _changeStatus(context, state);
                    break;
                  case 'edit_cost':
                    _editCostConfig(context, state);
                    break;
                  case 'delete':
                    _deleteLeague(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (state.participants.isNotEmpty)
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Chia sẻ BXH'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (state.currentUserIsLeagueAdmin)
                  const PopupMenuItem(
                    value: 'change_status',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Trạng thái'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (state.currentUserIsLeagueAdmin)
                  const PopupMenuItem(
                    value: 'edit_cost',
                    child: ListTile(
                      leading: Icon(Icons.payments_outlined),
                      title: Text('Sửa chi phí'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (state.currentUserIsLeagueAdmin)
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      title: Text(
                        'Xóa giải đấu',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            const TabBarView(
              children: [
                EsportTableView(),
                EsportMatchesView(isFixtures: true),
                EsportMatchesView(isFixtures: false),
              ],
            ),
            if (state.viewStatus.isLoading)
              const Positioned(
                top: 0,
                right: 0,
                left: 0,
                child: LinearProgressIndicator(),
              ),

            // Off-screen share card — positioned far outside the visible area
            // so Flutter fully paints it (required for toImage()).
            // Offstage would skip painting and cause a debugNeedsPaint error.
            Positioned(
              left: -_shareCardWidth - 10,
              top: 0,
              child: RepaintBoundary(
                key: _shareCardKey,
                child: LeagueShareCard(
                  leagueName: _leagueName(state),
                  participants: state.participants,
                  cardWidth: _shareCardWidth,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _bannerAd != null
            ? SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
        ),
      ),
    );
  }

  String _leagueName(TournamentDetailState state) {
    if (state.league?.name.isEmpty == true) {
      return "${state.league?.group?.groupName ?? " "} ${DateFormat('dd/MM/yyyy').format(state.league?.startDate ?? DateTime.now())}";
    }
    return state.league?.name ?? '';
  }

  Future<void> _shareStandings(TournamentDetailState state) async {
    // Capture from the hidden full-width share card (no scroll clipping).
    final boundary =
        _shareCardKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;

    // Use a pixel ratio of ~2.5 for a high-quality image without being too heavy.
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();

    if (!mounted) return;
    await showSharePreviewBottomSheet(
      context: context,
      imageBytes: pngBytes,
      leagueName: _leagueName(state),
    );
  }

  void _changeStatus(BuildContext context, TournamentDetailState state) {
    final bloc = BlocProvider.of<TournamentDetailBloc>(context);
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Trạng thái giải đấu'),
          content: BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
            bloc: bloc,
            builder: (ctx, state) =>
                DropdownButtonFormField<GNEsportLeagueStatus>(
                  initialValue: GNEsportLeagueStatusExtension.fromString(
                    state.league?.status,
                  ),
                  onChanged: (value) {
                    if (value != null) bloc.add(ChangeLeagueStatus(value));
                  },
                  items: GNEsportLeagueStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.name),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                bloc.add(SubmitLeagueStatus());
                Navigator.of(context).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  List<int> _parseRankPayouts(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e) ?? 0)
        .where((v) => v > 0)
        .toList();
  }

  void _editCostConfig(BuildContext context, TournamentDetailState state) {
    final league = state.league;
    if (league == null) return;
    final bloc = BlocProvider.of<TournamentDetailBloc>(context);
    final colorScheme = Theme.of(context).colorScheme;

    bool rankPayoutEnabled = league.rankPayoutEnabled;
    final rankPayoutsController = TextEditingController(
      text: league.rankPayouts.isEmpty
          ? '50000, 100000, 150000'
          : league.rankPayouts.join(', '),
    );
    final defaultMatchCostController = TextEditingController(
      text: league.defaultMatchCost.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Sửa chi phí'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Tính tiền theo thứ hạng'),
                  subtitle: const Text(
                    'Hạng dưới góp tiền cho hạng nhất theo cấu hình',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: rankPayoutEnabled,
                  onChanged: (v) =>
                      setLocalState(() => rankPayoutEnabled = v),
                ),
                if (rankPayoutEnabled) ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: rankPayoutsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'VD: 50000, 100000, 150000',
                      prefixIcon:
                          const Icon(Icons.format_list_numbered, size: 20),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lần lượt: hạng 2, hạng 3, hạng 4… đóng cho hạng 1.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: defaultMatchCostController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Tiền mặc định mỗi trận (VND)',
                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Số này sẽ được điền sẵn khi bật cost cho từng trận lúc nhập kết quả.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                FocusScope.of(ctx).unfocus();
                final parsedRankPayouts = rankPayoutEnabled
                    ? _parseRankPayouts(rankPayoutsController.text)
                    : <int>[];
                if (rankPayoutEnabled && parsedRankPayouts.isEmpty) {
                  showToast('Nhập số tiền theo thứ hạng (VD: 50000, 100000)');
                  return;
                }
                final defaultMatchCost = int.tryParse(
                      defaultMatchCostController.text.trim(),
                    ) ??
                    50000;
                bloc.add(UpdateLeagueCostConfig(
                  rankPayoutEnabled: rankPayoutEnabled,
                  rankPayouts: parsedRankPayouts,
                  defaultMatchCost: defaultMatchCost,
                ));
                Navigator.of(ctx).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteLeague(BuildContext context) async {
    final bloc = BlocProvider.of<TournamentDetailBloc>(context);
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Xóa giải đấu',
      message: 'Bạn có chắc chắn muốn xóa giải đấu này không?',
      confirmText: 'Xóa',
      isDestructive: true,
    );
    if (confirmed == true) {
      bloc.add(InactiveLeague());
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() async {
    if (isAdsLoaded) return;
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate(),
        );
    _bannerAd = BannerAd(
      adUnitId: AdmobHelper.bannerUnitIDDetailBottom,
      request: const AdRequest(),
      size: size ?? AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() => isAdsLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => debugPrint('on Ad Opened'),
        onAdClosed: (Ad ad) => debugPrint('on Ad Closed'),
        onAdImpression: (Ad ad) => debugPrint('on Ad Impression'),
      ),
    )..load();
  }

  void _addParticipant(BuildContext context, TournamentDetailState state) {
    final league = state.league;
    if (league == null) return;
    final tournamentDetailBloc = BlocProvider.of<TournamentDetailBloc>(context);

    showDialog(
      context: context,
      builder: (context) => AddPlayerPopup(
        league: league,
        existingParticipants: state.participants,
        tournamentDetailBloc: tournamentDetailBloc,
      ),
    );
  }
}
