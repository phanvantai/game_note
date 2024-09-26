import 'package:flutter/material.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/routing.dart';

import '../../../firebase/auth/gn_auth.dart';
import '../bloc/profile_bloc.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // get arguments
    final profileBloc =
        ModalRoute.of(context)!.settings.arguments as ProfileBloc;
    final auth = getIt<GNAuth>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tuỳ chọn khác')),
      body: ListView(
        children: [
          if (auth.isSignInWithEmailAndPassword)
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Đổi mật khẩu'),
              onTap: () {
                Navigator.of(context).pushNamed(Routing.changePassword);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete),
            iconColor: Colors.red,
            title: const Text(
              'Xoá tài khoản',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              _deleteAccount(context, profileBloc);
            },
          )
        ],
      ),
    );
  }

  void _deleteAccount(BuildContext context, ProfileBloc profileBloc) {
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
                profileBloc.add(DeleteProfileEvent());
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
}
