import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import '../../../../../domain/repositories/esport/esport_group_repository.dart';

part 'group_detail_event.dart';
part 'group_detail_state.dart';

class GroupDetailBloc extends Bloc<GroupDetailEvent, GroupDetailState> {
  final EsportGroupRepository _groupRepository;
  GroupDetailBloc(this._groupRepository, GNEsportGroup group)
      : super(GroupDetailState(group: group)) {
    on<GetMembers>(_onGetMembers);
    on<AddMember>(_onAddMember);
    on<RemoveMember>(_onRemoveMember);

    on<GetGroupDetail>(_onGetGroupDetail);
  }

  Future<void> _onGetGroupDetail(
      GetGroupDetail event, Emitter<GroupDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final group = await _groupRepository.getGroup(event.groupId);
      emit(state.copyWith(viewStatus: ViewStatus.success, group: group));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onGetMembers(
      GetMembers event, Emitter<GroupDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final members = await _groupRepository.getMembersOfGroup(event.groupId);
      emit(state.copyWith(viewStatus: ViewStatus.success, members: members));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddMember(
      AddMember event, Emitter<GroupDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _groupRepository.addMemberToGroup(
          groupId: event.groupId, memberId: event.userId);
      add(GetMembers(state.group.id));
      add(GetGroupDetail(state.group.id));
      showToast('Thêm thành viên thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRemoveMember(
      RemoveMember event, Emitter<GroupDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _groupRepository.removeMemberFromGroup(
          groupId: event.groupId, memberId: event.userId);
      add(GetMembers(state.group.id));
      add(GetGroupDetail(state.group.id));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }
}
