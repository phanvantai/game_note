import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/app/offline_button.dart';
import 'package:game_note/presentation/profile/bloc/profile_bloc.dart';

import '../../core/common/app_info.dart';
import '../../core/ultils.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: const [
            OfflineButton(),
          ],
        ),
        backgroundColor: Colors.white70,
        body: SafeArea(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: state.user?.photoURL != null
                    ? NetworkImage(state.user!.photoURL!)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                state.user?.displayName ?? '',
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
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Chính sách bảo mật'),
                      onTap: () {
                        // TODO: Implement change password functionality
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.reviews),
                      title: const Text('Đánh giá'),
                      onTap: () {
                        // TODO: Implement notification settings functionality
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.feedback),
                      title: const Text('Nhận xét góp ý'),
                      onTap: () {
                        // TODO: Implement notification settings functionality
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
      listener: (context, state) {},
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
          content: const Text('Bạn có chắc chắn muốn xoá tài khoản không?'),
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
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
