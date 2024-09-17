import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

import '../../../../../domain/repositories/esport/esport_league_repository.dart';
import '../../../../../firebase/firestore/esport/league/match/gn_esport_match.dart';

part 'tournament_detail_event.dart';
part 'tournament_detail_state.dart';

class TournamentDetailBloc
    extends Bloc<TournamentDetailEvent, TournamentDetailState> {
  final GNEsportLeague league;
  final EsportLeagueRepository _esportLeagueRepository;

  TournamentDetailBloc(this.league, this._esportLeagueRepository)
      : super(TournamentDetailState(league: league)) {
    on<GetParticipantStats>(_onGetParticipants);
    on<AddParticipant>(_onAddParticipant);

    on<GenerateRound>(_onGenerateRound);
  }

  void _onGetParticipants(
      GetParticipantStats event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final participants =
          await _esportLeagueRepository.getLeagueStats(event.tournamentId);
      emit(state.copyWith(
          viewStatus: ViewStatus.success, participants: participants));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onAddParticipant(
      AddParticipant event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.addParticipant(
          leagueId: league.id, userId: event.userId);
      add(GetParticipantStats(league.id));
      showToast('Thêm người chơi thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onGenerateRound(
      GenerateRound event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.generateRound(
          leagueId: league.id,
          teamIds: state.participants.map((e) => e.userId).toList());
      // add(GetMatches(league.id));
      showToast('Tạo vòng đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }
}
