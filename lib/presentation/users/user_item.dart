import 'package:flutter/material.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import '../../widgets/gn_circle_avatar.dart';

class UserItem extends StatelessWidget {
  final GNUser user;
  final Function()? onTap;
  final Function()? onLongPress;
  final Widget? trailing;
  final Widget? subtitle;
  const UserItem({
    super.key,
    required this.user,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        user.displayName ?? user.email ?? user.phoneNumber ?? user.id,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: subtitle,
      leading: GNCircleAvatar(photoUrl: user.photoUrl, size: 40),
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: trailing,
    );
  }
}
