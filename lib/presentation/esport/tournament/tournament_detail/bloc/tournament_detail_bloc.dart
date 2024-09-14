import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';

part 'tournament_detail_event.dart';
part 'tournament_detail_state.dart';

class TournamentDetailBloc
    extends Bloc<TournamentDetailEvent, TournamentDetailState> {
  final GNEsportLeague league;

  TournamentDetailBloc(this.league)
      : super(TournamentDetailState(league: league)) {
    on<GetParticipantStats>(_onGetParticipants);
  }

  void _onGetParticipants(
      GetParticipantStats event, Emitter<TournamentDetailState> emit) {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    // final participants = await _esportRepository.getParticipants(event.tournamentId);
    // emit(state.copyWith(viewStatus: ViewStatus.loaded, participants: participants));
  }
}
