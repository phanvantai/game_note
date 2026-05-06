import 'package:flutter/material.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import '../../../../../../widgets/gn_circle_avatar.dart';

class EsportMatchTeam extends StatelessWidget {
  final GNUser user;
  const EsportMatchTeam({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = user.displayName ?? user.email ?? user.phoneNumber ?? user.id;
    final nameText = Text(
      name,
      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      overflow: TextOverflow.ellipsis,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedWidth = constraints.maxWidth.isFinite;
          return Row(
            mainAxisSize: hasBoundedWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              GNCircleAvatar(photoUrl: user.photoUrl, size: 28),
              const SizedBox(width: 8),
              if (hasBoundedWidth)
                Expanded(child: nameText)
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: nameText,
                ),
            ],
          );
        },
      ),
    );
  }
}
