import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/injection_container.dart';

import '../../../../firebase/firestore/esport/group/gn_esport_group.dart';
import 'bloc/group_detail_bloc.dart';
import 'group_detail_view.dart';

class GroupDetailPage extends StatelessWidget {
  const GroupDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GNEsportGroup group =
        ModalRoute.of(context)!.settings.arguments as GNEsportGroup;
    return BlocProvider(
      create: (_) => GroupDetailBloc(getIt(), group)
        ..add(GetGroupDetail(group.id))
        ..add(GetMembers(group.id)),
      child: const GroupDetailView(),
    );
  }
}
