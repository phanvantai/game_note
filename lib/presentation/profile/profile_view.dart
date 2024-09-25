import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/common/app_info.dart';
import '../../core/constants/constants.dart';
import '../../core/ultils.dart';
import '../../routing.dart';
import 'bloc/profile_bloc.dart';
import 'feedback/feedback_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();

    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<ProfileBloc, ProfileState>(
      builder: (context, state) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  showCupertinoDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (dialogContext) {
                        return CupertinoAlertDialog(
                          actions: [
                            CupertinoDialogAction(
                              child: TextButton.icon(
                                label: const Text('Thay đổi ảnh đại diện'),
                                onPressed: () {
                                  // change avatar
                                  context
                                      .read<ProfileBloc>()
                                      .add(ChangeAvatarProfileEvent());
                                  Navigator.of(dialogContext).pop();
                                },
                                icon: const Icon(Icons.image),
                              ),
                            ),
                            CupertinoDialogAction(
                              child: TextButton.icon(
                                style: const ButtonStyle(
                                  // iconColor: WidgetStatePropertyAll(Colors.red),
                                  // textStyle: WidgetStatePropertyAll(
                                  //     TextStyle(color: Colors.red)),
                                  foregroundColor:
                                      WidgetStatePropertyAll(Colors.red),
                                ),
                                label: const Text('Xoá ảnh đại diện'),
                                onPressed: () {
                                  // delete avatar
                                  context
                                      .read<ProfileBloc>()
                                      .add(DeleteAvatarProfileEvent());
                                  Navigator.of(dialogContext).pop();
                                },
                                icon: const Icon(Icons.delete),
                              ),
                            ),
                          ],
                        );
                      });
                },
                child: CachedNetworkImage(
                  imageUrl: state.user?.photoUrl ?? '',
                  width: 100,
                  height: 100,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    backgroundImage: imageProvider,
                    radius: 50,
                  ),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.displayUser,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.reviews),
                      title: const Text('Đánh giá'),
                      onTap: () {
                        Uri url;
                        if (Platform.isAndroid) {
                          url = Uri.parse(playStoreUrl);
                        } else {
                          url = Uri.parse(appStoreUrl);
                        }
                        launchUrl(url);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.feedback),
                      title: const Text('Nhận xét góp ý'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (builder) => const FeedbackView()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.videogame_asset_off),
                      title: const Text('Chế độ offline'),
                      onTap: () {
                        // show dialog to confirm
                        showDialog(
                          context: context,
                          builder: (cxt) => AlertDialog(
                            title: const Text('Xác nhận'),
                            content: const Text(
                                'Chế độ offline là bạn tự tạo dữ liệu trên máy và dữ liệu sẽ chỉ được lưu trên máy của bạn, không được đồng bộ.\n\nBạn có chắc chắn muốn chuyển sang chế độ offline không?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Huỷ'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context)
                                      .pushReplacementNamed(Routing.offline);
                                },
                                child: const Text('Chấp nhận'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Phiên bản'),
                      trailing: FutureBuilder<AppInfo>(
                        future: appInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(snapshot.data!.versionNumber);
                          } else {
                            return const Text('1.0.0');
                          }
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      iconColor: Colors.red,
                      title: const Text(
                        'Xoá tài khoản',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        _deleteAccount(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      iconColor: Colors.red,
                      title: const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        _signOut(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      listener: (context, state) {
        if (state.error.isNotEmpty) {
          showSnackBar(context, state.error);
        }
      },
    );
  }

  void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () {
                context.read<ProfileBloc>().add(SignOutProfileEvent());
                Navigator.of(context).pop();
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text(
              'Bạn có chắc chắn muốn xoá tài khoản không?\n\nTất cả dữ liệu cá nhân của bạn sẽ bị xoá và không thể khôi phục. Một số dữ liệu liên quan đến nhóm và các người chơi khác sẽ vẫn được giữ lại.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () {
                context.read<ProfileBloc>().add(DeleteProfileEvent());
                Navigator.of(context).pop();
              },
              child: const Text(
                'Xoá tài khoản',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
