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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          GNCircleAvatar(
            photoUrl: user.photoUrl,
            size: 28,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              user.displayName ?? user.email ?? user.phoneNumber ?? user.id,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
