import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/cache/group_overview_cache.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_stats_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';

import '../../../../firebase/firestore/esport/group/gn_esport_group.dart';
import '../../../../domain/repositories/esport/esport_group_repository.dart';
import 'bloc/group_detail_bloc.dart';
import 'group_detail_view.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;
  final GNEsportGroup? initialGroup;
  const GroupDetailPage({super.key, required this.groupId, this.initialGroup});

  @override
  Widget build(BuildContext context) {
    final group = initialGroup ?? GNEsportGroup.placeholder(groupId);
    return BlocProvider(
      create: (_) => GroupDetailBloc(
        getIt<EsportGroupRepository>(),
        getIt<EsportLeagueRepository>(),
        getIt<EsportGroupStatsRepository>(),
        getIt<GroupOverviewCache>(),
        getIt<GNFirestore>(),
        group,
      )
        ..add(GetGroupDetail(groupId))
        ..add(GetMembers(groupId)),
      child: const GroupDetailView(),
    );
  }
}
