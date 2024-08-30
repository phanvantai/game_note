import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/offline/data/database/database_manager.dart';
import 'package:game_note/offline/data/database/league_manager.dart';
import 'package:game_note/injection_container.dart';

import '../../../../core/common/view_status.dart';
import '../models/personal_statistic.dart';

part 'statistic_event.dart';
part 'statistic_state.dart';

class StatisticBloc extends Bloc<StatisticEvent, StatisticState> {
  StatisticBloc() : super(const StatisticState()) {
    on<GeneratePersonalStatisticEvent>(_onGeneratePersonalStatistic);
  }

  _onGeneratePersonalStatistic(GeneratePersonalStatisticEvent event,
      Emitter<StatisticState> emit) async {
    final dm = getIt<DatabaseManager>();
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      // get player model
      final playModels = await dm.players();
      // get leagues
      final leagues = await dm.getLeagues();
      List<PersonalStatistic> personalStatistics =
          playModels.map((e) => PersonalStatistic(playerModel: e)).toList();
      for (var league in leagues) {
        if (league.id != null) {
          final realLeague = await dm.getLeague(league.id!);
          if (realLeague != null) {
            personalStatistics = personalStatistics
                .map((element) => element.getStatisticWithLeague(realLeague))
                .toList();
          }
        }
      }
      emit(state.copyWith(
        viewStatus: ViewStatus.success,
        listStatistic: personalStatistics,
      ));
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure));
    }
  }
}
