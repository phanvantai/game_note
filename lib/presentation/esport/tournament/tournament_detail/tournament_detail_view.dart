import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/users/bloc/user_bloc.dart';
import 'package:game_note/presentation/users/user_item.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import '../../../../core/helpers/admob_helper.dart';
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
  List<Widget> contentWidgets = [];

  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/svg/trophy-solid.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.league?.name.isEmpty == true
                      ? ("${state.league?.group?.groupName ?? " "} ${DateFormat('dd/MM/yyyy').format(state.league?.startDate ?? DateTime.now())}")
                      : state.league?.name ?? '',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            // if current user in group of league
            if (state.currentUserIsMember)
              // add participant button
              IconButton(
                icon: const Icon((Icons.person_add)),
                onPressed: () {
                  _addParticipant(context, state);
                },
              ),
            if (state.currentUserIsLeagueAdmin)
              IconButton(
                icon: const Icon(Icons.edit),
                //title: const Text('Cập nhật trạng thái'),
                onPressed: () {
                  final bloc = BlocProvider.of<TournamentDetailBloc>(context);
                  // show dialog to change league status
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Thay đổi trạng thái giải đấu'),
                        content: BlocBuilder<TournamentDetailBloc,
                            TournamentDetailState>(
                          bloc: bloc,
                          builder: (ctx, state) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Chọn trạng thái mới cho giải đấu:'),
                              const SizedBox(height: 8),
                              DropdownButton<GNEsportLeagueStatus>(
                                value: GNEsportLeagueStatusExtension.fromString(
                                    state.league?.status),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  bloc.add(ChangeLeagueStatus(value));
                                },
                                items:
                                    GNEsportLeagueStatus.values.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status.name),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              // submit league status
                              bloc.add(SubmitLeagueStatus());
                              Navigator.of(context).pop();
                            },
                            child: const Text('Lưu'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            if (state.currentUserIsLeagueAdmin)
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () {
                  final bloc = BlocProvider.of<TournamentDetailBloc>(context);
                  // show dialog to confirm delete
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xác nhận xóa giải đấu'),
                      content: const Text(
                          'Bạn có chắc chắn muốn xóa giải đấu này không?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            // delete league (inactive)
                            bloc.add(InactiveLeague());
                            Navigator.of(context).pop();
                          },
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                spacing: 16.0,
                children: [
                  const EsportTableView(),
                  const EsportMatchesView(),
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

  /// Loads a banner ad.
  void _loadAd() async {
    if (isAdsLoaded) {
      return;
    }
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());
    _bannerAd = BannerAd(
      adUnitId: AdmobHelper.bannerUnitIDDetailBottom,
      request: const AdRequest(),
      size: size ?? AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            isAdsLoaded = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          // Dispose the ad here to free resources.
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {
          debugPrint('on Ad Opened');
        },
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {
          debugPrint('on Ad Closed');
        },
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {
          debugPrint('on Ad Impression');
        },
      ),
    )..load();
  }

  _addParticipant(BuildContext context, TournamentDetailState state) {
    final league = state.league;
    if (league == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final userBloc = getIt<UserBloc>();
        return BlocBuilder<UserBloc, UserState>(
          bloc: userBloc..add(SearchUserByEsportGroup(league.groupId, '')),
          builder: (userContext, userState) => AlertDialog(
            title: const Text('Thêm thành viên'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm',
                  ),
                  onChanged: (value) {
                    userBloc
                        .add(SearchUserByEsportGroup(league.groupId, value));
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: userState.users.length,
                    itemBuilder: (ctx, index) {
                      final user = userState.users[index];
                      // ignore existing participants stats
                      if (state.participants
                          .map((e) => e.userId)
                          .contains(user.id)) {
                        return const SizedBox.shrink();
                      }
                      return UserItem(
                        user: user,
                        onTap: () {
                          // add participant to league
                          BlocProvider.of<TournamentDetailBloc>(context).add(
                            AddParticipant(league.id, user.id),
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Hủy'),
              ),
            ],
          ),
        );
      },
    );
  }
}
