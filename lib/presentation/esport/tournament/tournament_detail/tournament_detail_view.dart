import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import '../../../../core/helpers/admob_helper.dart';
import 'add_player_popup.dart';
import 'bloc/tournament_detail_bloc.dart';
import 'bracket/bracket_view.dart';
import 'cost/cost_split_view.dart';
import 'groups/group_standings_view.dart';
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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Firestore listeners can be paused while the app is backgrounded
    // (Doze mode on Android, suspended on iOS) and don't always re-fire
    // immediately on resume. Force a refresh so the user sees changes
    // made by other members while the app was off-screen.
    if (state == AppLifecycleState.resumed && mounted) {
      final bloc = context.read<TournamentDetailBloc>();
      final leagueId = bloc.state.league?.id;
      if (leagueId != null) {
        bloc.add(GetParticipantsAndMatches(leagueId));
      }
    }
  }

  final GlobalKey _shareCardKey = GlobalKey();
  final GlobalKey _shareCardLightKey = GlobalKey();

  /// Width used for the off-screen share card. Wide enough to fit all columns.
  static const double _shareCardWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) {
        final mode = state.league?.mode ?? TournamentMode.league;

        final List<Tab> tabs;
        final List<Widget> tabViews;
        switch (mode) {
          case TournamentMode.cup:
            tabs = const [Tab(text: 'Bracket'), Tab(text: 'Kết quả'), Tab(text: 'Chi phí')];
            tabViews = const [BracketView(), EsportMatchesView(isFixtures: false), CostSplitView()];
          case TournamentMode.full:
            tabs = const [Tab(text: 'Bảng'), Tab(text: 'Bracket'), Tab(text: 'Kết quả'), Tab(text: 'Chi phí')];
            tabViews = const [GroupStandingsView(), BracketView(), EsportMatchesView(isFixtures: false), CostSplitView()];
          case TournamentMode.league:
            tabs = const [Tab(text: 'BXH'), Tab(text: 'Lịch'), Tab(text: 'Kết quả'), Tab(text: 'Chi phí')];
            tabViews = const [EsportTableView(), EsportMatchesView(isFixtures: true), EsportMatchesView(isFixtures: false), CostSplitView()];
        }

        return DefaultTabController(
        key: ValueKey(mode),
        length: tabs.length,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.secondary.withValues(alpha: 0.16),
                  theme.scaffoldBackgroundColor,
                  colorScheme.primary.withValues(alpha: 0.06),
                ],
                stops: const [0, 0.46, 1],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _TournamentDetailHero(
                    state: state,
                    leagueName: _leagueName(state),
                    onBack: () => Navigator.of(context).maybePop(),
                    onAddParticipant: state.currentUserIsMember &&
                            state.league?.status !=
                                GNEsportLeagueStatus.finished.value
                        ? () => _addParticipant(context, state)
                        : null,
                    onMenuSelected: (value) {
                      switch (value) {
                        case 'share':
                          _shareStandings(state);
                          break;
                        case 'change_status':
                          _changeStatus(context, state);
                          break;
                        case 'recompute_stats':
                          _recomputeStats(context);
                          break;
                        case 'delete':
                          _deleteLeague(context);
                          break;
                      }
                    },
                  ),
                  _TournamentDetailTabBar(tabs: tabs),
                  Expanded(
                    child: Stack(
                      children: [
                        TabBarView(children: tabViews),
                        if (state.viewStatus.isLoading)
                          const Positioned(
                            top: 0,
                            right: 0,
                            left: 0,
                            child: LinearProgressIndicator(minHeight: 3),
                          ),

                        // Off-screen share cards (dark + light) — outside visible area
                        // so Flutter fully paints them (required for toImage()).
                        Positioned(
                          left: -_shareCardWidth - 10,
                          top: 0,
                          child: RepaintBoundary(
                            key: _shareCardKey,
                            child: LeagueShareCard(
                              leagueName: _leagueName(state),
                              participants: state.participants,
                              cardWidth: _shareCardWidth,
                              isDark: true,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -_shareCardWidth - 10,
                          top: 0,
                          child: RepaintBoundary(
                            key: _shareCardLightKey,
                            child: LeagueShareCard(
                              leagueName: _leagueName(state),
                              participants: state.participants,
                              cardWidth: _shareCardWidth,
                              isDark: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: (!kIsWeb && _bannerAd != null)
              ? SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
              : null,
        ),
        );
      },
    );
  }

  String _leagueName(TournamentDetailState state) {
    if (state.league?.name.isEmpty == true) {
      return "${state.league?.group?.groupName ?? " "} ${DateFormat('dd/MM/yyyy').format(state.league?.startDate ?? DateTime.now())}";
    }
    return state.league?.name ?? '';
  }

  Future<void> _shareStandings(TournamentDetailState state) async {
    Future<Uint8List?> capture(GlobalKey key) async {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }

    final results = await Future.wait([
      capture(_shareCardKey),
      capture(_shareCardLightKey),
    ]);
    final darkBytes = results[0];
    final lightBytes = results[1];
    if (darkBytes == null || lightBytes == null) return;

    if (!mounted) return;
    await showSharePreviewBottomSheet(
      context: context,
      darkImageBytes: darkBytes,
      lightImageBytes: lightBytes,
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

  void _recomputeStats(BuildContext context) async {
    final bloc = BlocProvider.of<TournamentDetailBloc>(context);
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Đồng bộ điểm số',
      message:
          'Tính lại toàn bộ điểm số từ kết quả các trận đã đấu? '
          'Dùng khi điểm bị lệch do dữ liệu cũ.',
      confirmText: 'Đồng bộ',
    );
    if (confirmed == true) {
      bloc.add(RecomputeStats());
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() async {
    if (kIsWeb || isAdsLoaded || !getIt<GNRemoteConfig>().adsEnabled) return;
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

class _TournamentDetailHero extends StatelessWidget {
  final TournamentDetailState state;
  final String leagueName;
  final VoidCallback onBack;
  final VoidCallback? onAddParticipant;
  final ValueChanged<String> onMenuSelected;

  const _TournamentDetailHero({
    required this.state,
    required this.leagueName,
    required this.onBack,
    required this.onAddParticipant,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final league = state.league;
    final status = GNEsportLeagueStatusExtension.fromString(league?.status);
    final groupName = league?.group?.groupName ?? 'Chưa rõ nhóm';
    final hasMenuActions =
        (!kIsWeb && state.participants.isNotEmpty) ||
        state.currentUserIsLeagueAdmin;
    final dateLabel = league == null
        ? 'Đang tải'
        : league.endDate == null
        ? DateFormat('dd/MM/yyyy').format(league.startDate)
        : '${DateFormat('dd/MM').format(league.startDate)} - ${DateFormat('dd/MM/yyyy').format(league.endDate!)}';
    final metadata = '$groupName • $dateLabel';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeroIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Quay lại',
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  'assets/svg/trophy-solid.svg',
                  colorFilter: ColorFilter.mode(
                    colorScheme.onSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            leagueName.isEmpty
                                ? 'Đang tải giải đấu'
                                : leagueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(status: status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      metadata,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAddParticipant != null) ...[
                const SizedBox(width: 8),
                _HeroIconButton(
                  icon: Icons.person_add_outlined,
                  tooltip: 'Thêm người chơi',
                  onPressed: onAddParticipant!,
                ),
              ],
              if (hasMenuActions) ...[
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  tooltip: 'Tuỳ chọn giải đấu',
                  onSelected: onMenuSelected,
                  icon: Icon(Icons.more_horiz, color: colorScheme.onSurface),
                  itemBuilder: (context) => [
                    if (!kIsWeb && state.participants.isNotEmpty)
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
                        value: 'recompute_stats',
                        child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Đồng bộ điểm số'),
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
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.onSurface, size: 20),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final GNEsportLeagueStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: status.color.withValues(alpha: 0.22)),
      ),
      child: Text(
        status.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TournamentDetailTabBar extends StatelessWidget {
  final List<Tab> tabs;

  const _TournamentDetailTabBar({required this.tabs});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.42)),
      ),
      child: TabBar(
        padding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: colorScheme.onSecondary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        tabs: tabs,
      ),
    );
  }
}
