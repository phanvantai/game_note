import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';

import '../../../domain/repositories/team_repository.dart';
import '../../../firebase/firestore/team/gn_team.dart';

part 'teams_event.dart';
part 'teams_state.dart';

class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  final TeamRepository _teamRepository;
  TeamsBloc(this._teamRepository) : super(const TeamsState()) {
    on<GetMyTeams>(_onGetMyTeams);
    on<GetOtherTeams>(_onGetOtherTeams);
  }

  void _onGetMyTeams(GetMyTeams event, Emitter<TeamsState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    await _teamRepository.getMyTeams().then((myTeams) {
      emit(state.copyWith(viewStatus: ViewStatus.success, myTeams: myTeams));
    }).catchError((error) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: error.toString()));
    });
  }

  void _onGetOtherTeams(GetOtherTeams event, Emitter<TeamsState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    await _teamRepository.getOtherTeams().then((otherTeams) {
      emit(state.copyWith(
          viewStatus: ViewStatus.success, otherTeams: otherTeams));
    }).catchError((error) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: error.toString()));
    });
  }
}
