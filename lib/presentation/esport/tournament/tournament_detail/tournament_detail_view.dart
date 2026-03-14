import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

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
            if (state.currentUserIsMember)
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => _addParticipant(context, state),
              ),
            if (state.currentUserIsLeagueAdmin)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _changeStatus(context, state),
              ),
            if (state.currentUserIsLeagueAdmin)
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: () => _deleteLeague(context),
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                spacing: 16.0,
                children: const [
                  EsportTableView(),
                  EsportMatchesView(),
                ],
              ),
            ),
            if (state.viewStatus.isLoading)
              const Positioned(
                  top: 0, right: 0, left: 0, child: LinearProgressIndicator()),
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
