import 'package:flutter/material.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import '../../../../../../widgets/gn_circle_avatar.dart';

class EsportMatchTeam extends StatelessWidget {
  final GNUser user;
  const EsportMatchTeam({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          GNCircleAvatar(
            photoUrl: user.photoUrl,
            size: 30,
          ),
          const SizedBox(width: 8),
          Text(
            user.displayName ?? user.email ?? user.phoneNumber ?? user.id,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }
}
