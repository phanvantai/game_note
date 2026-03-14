import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

import '../league_detail/league_detail_page.dart';
import 'bloc/league_list_bloc.dart';

class LeagueListBody extends StatelessWidget {
  const LeagueListBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<LeagueListBloc, LeagueListState>(
      builder: (context, state) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: state.leagues.length,
        itemBuilder: (context, index) => AppCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onDoubleTap: () async {
              final confirmed = await showAppConfirmDialog(
                context: context,
                title: 'Xoá giải đấu',
                message:
                    'Bạn có chắc muốn xoá giải đấu ${state.leagues[index].name}?',
                confirmText: 'Xoá',
                isDestructive: true,
              );
              if (confirmed == true && context.mounted) {
                context
                    .read<LeagueListBloc>()
                    .add(DeleteLeagueEvent(state.leagues[index]));
              }
            },
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      LeagueDetailPage(model: state.leagues[index])));
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  state.leagues[index].name,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 12);
        },
      ),
    );
  }
}
