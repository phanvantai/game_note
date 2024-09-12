import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';

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
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRemoveMember(
      RemoveMember event, Emitter<GroupDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      // await _groupRepository.removeMember(event.groupId, event.userId);
      // final members = state.members
      //     .where((element) => element.id != event.userId)
      //     .toList();
      // emit(state.copyWith(viewStatus: ViewStatus.success, members: members));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }
}
