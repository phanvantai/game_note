import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        child: Banner(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
          message: GNEsportLeagueStatusExtension.fromString(league.status).name,
          location: BannerLocation.topEnd,
          color: GNEsportLeagueStatusExtension.fromString(league.status).color,
          child: ListTile(
            onTap: onTap,
            leading: SvgPicture.asset(
              'assets/svg/trophy-solid.svg',
              width: 32,
              height: 32,
            ),
            title: Text(league.name.isEmpty
                ? '${league.group?.groupName ?? ''} - ${DateFormat('dd/MM/yyyy').format(league.startDate)}'
                : league.name),
            subtitle: league.description.isEmpty
                ? Text(league.group!.groupName)
                : Text(league.description),
          ),
        ),
      ),
    );
  }
}
