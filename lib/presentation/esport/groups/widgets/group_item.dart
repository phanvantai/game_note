import 'package:flutter/material.dart';

import '../../../../firebase/firestore/esport/group/gn_esport_group.dart';
import '../../../../routing.dart';

class GroupItem extends StatelessWidget {
  final GNEsportGroup group;
  const GroupItem({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white60,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Image.asset('assets/images/pes_club_logo.png'),
        title: Text(group.groupName),
        subtitle: Text(
          'Thành viên: ${group.members.length}  Khu vực: ${group.location}',
          style: const TextStyle(fontSize: 11),
        ),
        onTap: () => Navigator.of(context).pushNamed(
          Routing.groupDetail,
          arguments: group,
        ),
      ),
    );
  }
}
