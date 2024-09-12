import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';

import '../../../../domain/repositories/esport/esport_group_repository.dart';
import '../../../../firebase/firestore/esport/group/gn_esport_group.dart';

part 'group_event.dart';
part 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final EsportGroupRepository _esportGroupRepository;

  GroupBloc(this._esportGroupRepository) : super(const GroupState()) {
    on<GetEsportGroups>(_onGetEsportGroups);
    on<CreateEsportGroup>(_onCreateEsportGroup);
    on<AddMemberToGroup>(_onAddMemberToGroup);
  }

  Future<void> _onGetEsportGroups(
    GetEsportGroups event,
    Emitter<GroupState> emit,
  ) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final groups = await _esportGroupRepository.getEsportGroups();
      emit(state.copyWith(viewStatus: ViewStatus.success, groups: groups));
    } catch (e) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateEsportGroup(
    CreateEsportGroup event,
    Emitter<GroupState> emit,
  ) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final group = await _esportGroupRepository.createEsportGroup(
        groupName: event.groupName,
        esportId: event.esportId,
        description: event.description,
        location: event.location,
      );
      emit(state.copyWith(
        viewStatus: ViewStatus.success,
        groups: [...state.groups, group],
      ));
      showToast('Tạo nhóm thành công');
    } catch (e) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddMemberToGroup(
    AddMemberToGroup event,
    Emitter<GroupState> emit,
  ) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportGroupRepository.addMemberToGroup(
        groupId: event.groupId,
        memberId: event.memberId,
      );
      emit(state.copyWith(viewStatus: ViewStatus.success));
    } catch (e) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
