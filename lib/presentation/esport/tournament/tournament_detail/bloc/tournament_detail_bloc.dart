import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final EsportLeagueRepository _esportLeagueRepository;

  TournamentDetailBloc(this._esportLeagueRepository)
      : super(const TournamentDetailState()) {
    on<GetParticipantStats>(_onGetParticipants);
    on<GetMatches>(_onGetMatches);

    on<AddParticipant>(_onAddParticipant);

    on<GenerateRound>(_onGenerateRound);
    on<UpdateEsportMatch>(_onUpdateMatch);

    on<ChangeLeagueStatus>(_onChangeLeagueStatus);
    on<SubmitLeagueStatus>(_onSubmitLeagueStatus);

    on<InactiveLeague>(_onInactiveLeague);

    on<DeleteEsportMatch>(_onDeleteMatch);
    on<CreateCustomMatch>(_onCreateCustomMatch);

    on<UpdateStartingMedals>(_onUpdateStartingMedals);
    on<UpdateUnitMedals>(_onUpdateUnitMedals);

    on<UpdateMatchMedals>(_onUpdateMatchMedals);

    on<UpdateLeague>(_onUpdateLeague);
    on<UpdateMatches>(_onUpdateMatches);

    on<GetLeague>(_onGetLeague);
  }

  StreamSubscription<List<GNEsportMatch>>? _matchesSubscription;
  StreamSubscription<List<GNEsportLeagueStat>>? _participantsSubscription;
  StreamSubscription<GNEsportLeague>? _leagueSubscription;

  _onGetLeague(GetLeague event, Emitter<TournamentDetailState> emit) async {
    _participantsSubscription?.cancel();
    _participantsSubscription = _esportLeagueRepository
        .listenForLeagueStats(event.leagueId)
        .listen((participants) {
      if (state.league?.id != null) {
        add(GetParticipantStats(state.league!.id));
      }
    });

    _matchesSubscription?.cancel();
    _matchesSubscription = _esportLeagueRepository
        .listenForMatchesUpdated(event.leagueId)
        .listen((matches) async {
      add(UpdateMatches(matches));
    });
    _leagueSubscription?.cancel();
    _leagueSubscription = _esportLeagueRepository
        .listenForLeagueUpdated(event.leagueId)
        .listen((league) {
      add(UpdateLeague(league));
    });
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final league = await _esportLeagueRepository.getLeague(event.leagueId);
      emit(state.copyWith(viewStatus: ViewStatus.success, league: league));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onUpdateLeague(
      UpdateLeague event, Emitter<TournamentDetailState> emit) async {
    emit(state.copyWith(league: event.league));
    if (event.league.isActive) {
      add(GetParticipantStats(event.league.id));
    }
  }

  void _onUpdateMatches(
      UpdateMatches event, Emitter<TournamentDetailState> emit) async {
    final users = state.users;
    emit(state.copyWith(
      matches: event.matches
          .map((e) => e.copyWith(
                homeTeam: users.isNotEmpty
                    ? users.firstWhere((element) => element.id == e.homeTeamId)
                    : null,
                awayTeam: users.isNotEmpty
                    ? users.firstWhere((element) => element.id == e.awayTeamId)
                    : null,
              ))
          .toList(),
    ));
  }

  void _onUpdateMatchMedals(
      UpdateMatchMedals event, Emitter<TournamentDetailState> emit) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.updateMatchMedals(
          event.matchId, leagueId, event.medals);
      add(GetMatches(leagueId));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onUpdateStartingMedals(
      UpdateStartingMedals event, Emitter<TournamentDetailState> emit) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.updateLeagueStartingMedals(
          leagueId, event.medals);
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onUpdateUnitMedals(
      UpdateUnitMedals event, Emitter<TournamentDetailState> emit) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.updateLeagueUnitMedals(
          leagueId, event.unitMedals);
      emit(state.copyWith(viewStatus: ViewStatus.success));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onCreateCustomMatch(
      CreateCustomMatch event, Emitter<TournamentDetailState> emit) async {
    if (state.viewStatus == ViewStatus.loading) {
      return;
    }
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final match = GNEsportMatch(
        id: '',
        homeTeamId: event.homeTeam.id,
        awayTeamId: event.awayTeam.id,
        homeScore: 0,
        awayScore: 0,
        date: DateTime.now(),
        isFinished: false,
        leagueId: leagueId,
      );
      await _esportLeagueRepository.createCustomMatch(match);
      add(GetMatches(leagueId));
      showToast('Tạo trận đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onDeleteMatch(
      DeleteEsportMatch event, Emitter<TournamentDetailState> emit) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.deleteMatch(event.match);
      add(GetParticipantStats(leagueId));
      showToast('Xoá trận đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onInactiveLeague(
      InactiveLeague event, Emitter<TournamentDetailState> emit) async {
    final league = state.league;
    if (league == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.inactiveLeague(league);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast('Đã xoá giải đấu');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onChangeLeagueStatus(
      ChangeLeagueStatus event, Emitter<TournamentDetailState> emit) async {
    final newLeague = state.league?.copyWith(status: event.status.value);
    emit(state.copyWith(league: newLeague));
  }

  void _onSubmitLeagueStatus(
      SubmitLeagueStatus event, Emitter<TournamentDetailState> emit) async {
    final league = state.league;
    if (league == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.updateLeague(league);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast('Cập nhật trạng thái giải đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
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
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.addParticipant(
          leagueId: leagueId, userId: event.userId);
      add(GetParticipantStats(leagueId));
      showToast('Thêm người chơi thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onGenerateRound(
      GenerateRound event, Emitter<TournamentDetailState> emit) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    if (state.participants.length < 2 ||
        state.viewStatus == ViewStatus.loading) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.generateRound(
          leagueId: leagueId,
          teamIds: state.participants.map((e) => e.userId).toList());
      add(GetMatches(leagueId));
      showToast('Tạo vòng đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onUpdateMatch(
      UpdateEsportMatch event, Emitter<TournamentDetailState> emit) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.updateMatch(event.match);
      add(GetParticipantStats(leagueId));
      showToast('Cập nhật trận đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _matchesSubscription?.cancel();
    _leagueSubscription?.cancel();
    _participantsSubscription?.cancel();
    return super.close();
  }
}
