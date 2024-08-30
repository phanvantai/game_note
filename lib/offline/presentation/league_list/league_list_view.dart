import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../league_detail/league_detail_page.dart';
import 'add_tournament_button.dart';
import 'bloc/league_list_bloc.dart';
import 'league_list_body.dart';

class LeagueListView extends StatelessWidget {
  const LeagueListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text('Giải đấu'),
        backgroundColor: Colors.white70,
      ),
      body: SafeArea(
        child: BlocConsumer<LeagueListBloc, LeagueListState>(
          listener: (context, state) {
            if (state.newLeague != null) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      LeagueDetailPage(model: state.newLeague!)));
              context.read<LeagueListBloc>().add(LeagueListStarted());
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case LeagueListStatus.error:
                return const Center(child: Text('error'));
              case LeagueListStatus.loading:
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              case LeagueListStatus.loaded:
                if (state.leagues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => context
                              .read<LeagueListBloc>()
                              .add(LeagueListStarted()),
                          icon: const Icon(Icons.refresh),
                        ),
                        const Text(
                          'Chưa có giải đấu nào được tạo.\nBấm nút + bên dưới để tạo một giải đấu',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else {
                  return const LeagueListBody();
                }
            }
          },
        ),
      ),
      floatingActionButton: const AddTournamentButton(),
    );
  }
}
