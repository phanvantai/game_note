import 'package:flutter/material.dart';

import '../../../../firebase/firestore/esport/group/gn_esport_group.dart';

class GroupItem extends StatelessWidget {
  final GNEsportGroup group;
  final Function()? onTap;
  const GroupItem({
    Key? key,
    required this.group,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/pes_club_logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          group.groupName,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${group.members.length} thành viên  •  ${group.location}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
