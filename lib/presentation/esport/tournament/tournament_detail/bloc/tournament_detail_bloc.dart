import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';

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
    on<GetLeagueUpdated>(_onGetLeague);

    on<GetParticipantStats>(_onGetParticipants);
    on<GetMatches>(_onGetMatches);

    on<AddParticipant>(_onAddParticipant);

    on<GenerateRound>(_onGenerateRound);
    on<UpdateEsportMatch>(_onUpdateMatch);

    on<ChangeLeagueStatus>(_onChangeLeagueStatus);
    on<SubmitLeagueStatus>(_onSubmitLeagueStatus);

    on<InactiveLeague>(_onInactiveLeague);
  }

  void _onInactiveLeague(
      InactiveLeague event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.inactiveLeague(state.league);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast('Đã xoá giải đấu');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onChangeLeagueStatus(
      ChangeLeagueStatus event, Emitter<TournamentDetailState> emit) async {
    final newLeague = state.league.copyWith(status: event.status.value);
    emit(state.copyWith(league: newLeague));
  }

  void _onSubmitLeagueStatus(
      SubmitLeagueStatus event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.updateLeague(state.league);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast('Cập nhật trạng thái giải đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onGetLeague(
      GetLeagueUpdated event, Emitter<TournamentDetailState> emit) async {
    try {
      final league = await _esportLeagueRepository.getLeague(this.league.id);
      emit(state.copyWith(league: league));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _onGetParticipants(
      GetParticipantStats event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final participants =
          await _esportLeagueRepository.getLeagueStats(event.tournamentId);
      List<GNUser> users = [];
      for (var participant in participants) {
        final user = participant.user;
        if (user != null) users.add(user);
      }
      // sort participants by point, then goal difference, then goals scored, then match played
      participants.sort((a, b) {
        if (a.points != b.points) return b.points.compareTo(a.points);
        if (a.goalDifference != b.goalDifference) {
          return b.goalDifference.compareTo(a.goalDifference);
        }
        if (a.goals != b.goals) return b.goals.compareTo(a.goals);
        return b.matchesPlayed.compareTo(a.matchesPlayed);
      });
      emit(state.copyWith(
        viewStatus: ViewStatus.success,
        participants: participants,
        users: users,
      ));
      add(GetMatches(event.tournamentId));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onGetMatches(
      GetMatches event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final matches =
          await _esportLeagueRepository.getMatches(event.tournamentId);
      final users = state.users;
      emit(
        state.copyWith(
          viewStatus: ViewStatus.success,
          matches: matches
              .map((e) => e.copyWith(
                    homeTeam: users
                        .firstWhere((element) => element.id == e.homeTeamId),
                    awayTeam: users
                        .firstWhere((element) => element.id == e.awayTeamId),
                  ))
              .toList(),
        ),
      );
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
      add(GetLeagueUpdated());
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
      add(GetMatches(league.id));
      showToast('Tạo vòng đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onUpdateMatch(
      UpdateEsportMatch event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.updateMatch(event.match);
      add(GetParticipantStats(league.id));
      showToast('Cập nhật trận đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }
}
