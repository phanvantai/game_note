import 'package:flutter/material.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';

import '../../widgets/gn_circle_avatar.dart';

class UserItem extends StatelessWidget {
  final GNUser user;
  final Function()? onTap;
  final Function()? onLongPress;
  final Widget? trailing;
  const UserItem({
    Key? key,
    required this.user,
    this.onTap,
    this.onLongPress,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title:
          Text(user.displayName ?? user.email ?? user.phoneNumber ?? user.id),
      leading: GNCircleAvatar(
        photoUrl: user.photoUrl,
        size: 40,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: trailing,
    );
  }
}
