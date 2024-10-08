import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:game_note/presentation/users/bloc/user_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/helpers/admob_helper.dart';
import '../../../users/user_item.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({Key? key}) : super(key: key);

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupDetailBloc, GroupDetailState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          centerTitle: true,
          title: ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Image.asset('assets/images/pes_club_logo.png'),
            ),
            title: Text(
              state.group.groupName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // trailing: state.isOwner
            //     ? IconButton(
            //         icon: const Icon(Icons.edit),
            //         onPressed: () {},
            //       )
            //     : null,
          ),
        ),
        body: ListView(
          children: [
            if (state.viewStatus == ViewStatus.loading)
              const LinearProgressIndicator(),
            ExpansionTile(
              leading: const Icon(
                Icons.description,
                color: Colors.black,
              ),
              expandedAlignment: Alignment.centerLeft,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              showTrailingIcon: false,
              initiallyExpanded: true,
              maintainState: true,
              title: const Text(
                'Mô tả',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              children: [
                Text(
                  state.group.description,
                  textAlign: TextAlign.justify,
                )
              ],
            ),
            ExpansionTile(
              leading: const Icon(
                Icons.location_on,
                color: Colors.black,
              ),
              showTrailingIcon: false,
              initiallyExpanded: true,
              expandedAlignment: Alignment.centerLeft,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text(
                'Khu vực hoạt động',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              children: [
                Text(state.group.location),
              ],
            ),
            ExpansionTile(
              leading: const Icon(
                Icons.people,
                color: Colors.black,
              ),
              showTrailingIcon: false,
              initiallyExpanded: true,
              title: const Text(
                'Thành viên',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              children: state.members
                  .map(
                    (user) => UserItem(
                      user: user,
                      trailing: state.isOwner
                          ? !user.isCurrentUser
                              ? IconButton(
                                  onPressed: () {
                                    _removeMember(
                                        false, context, state, user.id);
                                  },
                                  icon: const Icon(Icons.person_remove_sharp),
                                )
                              : IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.red,
                                  ),
                                )
                          : user.id == state.group.ownerId
                              ? const Icon(Icons.admin_panel_settings,
                                  color: Colors.red)
                              : null,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        floatingActionButton: _floatingButton(context, state),
        bottomNavigationBar: _bannerAd != null
            ? SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
      ),
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage);
        }
      },
    );
  }

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

  Widget? _floatingButton(BuildContext context, GroupDetailState state) {
    if (state.isOwner) {
      return TextButton.icon(
        onPressed: () {
          // show dialog to search user add add to group
          _addMember(context, state);
        },
        label: const Text('Thêm thành viên'),
        icon: const Icon(Icons.add),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.red[100]),
        ),
      );
    }
    if (state.currentUserIsMember) {
      return TextButton.icon(
        onPressed: () {
          if (state.currentUserId != null) {
            _removeMember(true, context, state, state.currentUserId!);
          }
        },
        label: const Text('Rời nhóm'),
        icon: const Icon(Icons.exit_to_app),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.red[100]),
        ),
      );
    }
    return null;
  }

  _addMember(BuildContext context, GroupDetailState state) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final userBloc = getIt<UserBloc>();
        return BlocBuilder<UserBloc, UserState>(
          bloc: userBloc..add(const SearchUser('')),
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
                    userBloc.add(SearchUser(value));
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
                      // ignore current user and member of group
                      if (user.isCurrentUser ||
                          state.group.members.contains(user.id)) {
                        return const SizedBox.shrink();
                      }
                      return UserItem(
                        user: user,
                        onTap: () {
                          // add user to group
                          BlocProvider.of<GroupDetailBloc>(context).add(
                            AddMember(state.group.id, user.id),
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

  _removeMember(bool currentUser, BuildContext context, GroupDetailState state,
      String userId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(currentUser
            ? 'Bạn có chắc chắn muốn rời nhóm?'
            : 'Bạn có chắc chắn muốn xóa thành viên này không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              BlocProvider.of<GroupDetailBloc>(context).add(
                RemoveMember(state.group.id, userId),
              );
              Navigator.of(context).pop();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red[100]),
            ),
            child: Text(currentUser ? 'Rời nhóm' : 'Xoá thành viên'),
          ),
        ],
      ),
    );
  }
}
