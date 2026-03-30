import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/helpers/admob_helper.dart';
import 'add_player_popup.dart';
import 'bloc/tournament_detail_bloc.dart';
import 'matches/matches_view.dart';
import 'table/table_view.dart';

class TournamentDetailView extends StatefulWidget {
  const TournamentDetailView({Key? key}) : super(key: key);

  @override
  State<TournamentDetailView> createState() => _TournamentDetailViewState();
}

class _TournamentDetailViewState extends State<TournamentDetailView>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;
  final GlobalKey _tableKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) => Scaffold(
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
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    _shareStandings(state);
                    break;
                  case 'add_participant':
                    _addParticipant(context, state);
                    break;
                  case 'change_status':
                    _changeStatus(context, state);
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
                if (state.currentUserIsMember)
                  const PopupMenuItem(
                    value: 'add_participant',
                    child: ListTile(
                      leading: Icon(Icons.person_add_outlined),
                      title: Text('Thêm người chơi'),
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
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: colorScheme.error),
                      title: Text('Xóa giải đấu',
                          style: TextStyle(color: colorScheme.error)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                spacing: 16.0,
                children: [
                  RepaintBoundary(
                    key: _tableKey,
                    child: Container(
                      color: colorScheme.surface,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _leagueName(state),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const EsportTableView(),
                        ],
                      ),
                    ),
                  ),
                  const EsportMatchesView(),
                ],
              ),
            ),
            if (state.viewStatus.isLoading)
              const Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: LinearProgressIndicator()),
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
    );
  }

  String _leagueName(TournamentDetailState state) {
    if (state.league?.name.isEmpty == true) {
      return "${state.league?.group?.groupName ?? " "} ${DateFormat('dd/MM/yyyy').format(state.league?.startDate ?? DateTime.now())}";
    }
    return state.league?.name ?? '';
  }

  Future<void> _shareStandings(TournamentDetailState state) async {
    final boundary = _tableKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/league_standings.png');
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Bảng xếp hạng - ${_leagueName(state)}',
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
            builder: (ctx, state) => DropdownButtonFormField<
                GNEsportLeagueStatus>(
              value: GNEsportLeagueStatusExtension.fromString(
                  state.league?.status),
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
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());
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
    final tournamentDetailBloc =
        BlocProvider.of<TournamentDetailBloc>(context);

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
