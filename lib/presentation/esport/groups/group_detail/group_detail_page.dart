import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/injection_container.dart';

import '../../../../firebase/firestore/esport/group/gn_esport_group.dart';
import 'bloc/group_detail_bloc.dart';
import 'group_detail_view.dart';

class GroupDetailPage extends StatelessWidget {
  final GNEsportGroup group;
  const GroupDetailPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupDetailBloc(getIt(), group)
        ..add(GetGroupDetail(group.id))
        ..add(GetMembers(group.id)),
      child: const GroupDetailView(),
    );
  }
}
