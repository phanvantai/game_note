import 'package:bloc/bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  TournamentBloc() : super(const TournamentState()) {
    on<AddNewTournamentEvent>(_addNewTournament);
  }

  _addNewTournament(
      AddNewTournamentEvent event, Emitter<TournamentState> emit) {
    emit(state.copyWith(status: TournamentStatus.addPlayer));
  }
}
