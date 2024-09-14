import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../firebase/firestore/esport/league/gn_esport_league.dart';

class TournamentItem extends StatelessWidget {
  final GNEsportLeague league;
  final Function() onTap;
  const TournamentItem({
    Key? key,
    required this.league,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        leading: SvgPicture.asset(
          'assets/svg/trophy-solid.svg',
          width: 32,
          height: 32,
        ),
        title: Text(league.name),
        subtitle: league.group != null ? Text(league.group!.groupName) : null,
      ),
    );
  }
}
