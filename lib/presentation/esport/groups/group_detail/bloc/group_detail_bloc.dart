import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import '../../../../../domain/repositories/esport/esport_group_repository.dart';
import '../../../../../domain/repositories/esport/esport_league_repository.dart';

part 'group_detail_event.dart';
part 'group_detail_state.dart';

class GroupDetailBloc extends Bloc<GroupDetailEvent, GroupDetailState> {
  final EsportGroupRepository _groupRepository;
  final EsportLeagueRepository _leagueRepository;

  GroupDetailBloc(
    this._groupRepository,
    this._leagueRepository,
    GNEsportGroup group, {
    String? currentUserId,
  }) : super(GroupDetailState(
          group: group,
          currentUserId: currentUserId ?? FirebaseAuth.instance.currentUser?.uid,
        )) {
    on<GetMembers>(_onGetMembers);
    on<AddMember>(_onAddMember);
    on<RemoveMember>(_onRemoveMember);
    on<GetGroupDetail>(_onGetGroupDetail);
    on<LoadGroupLeagues>(_onLoadGroupLeagues);
    on<ReplaceLeagueParticipant>(_onReplaceLeagueParticipant);
    on<SetLeagueMergeCompleted>(_onSetLeagueMergeCompleted);
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

  Future<void> _onLoadGroupLeagues(
      LoadGroupLeagues event, Emitter<GroupDetailState> emit) async {
    emit(state.copyWith(leaguesStatus: ViewStatus.loading));
    try {
      final leagues =
          await _leagueRepository.getLeaguesByGroupId(event.groupId);
      emit(state.copyWith(
          leaguesStatus: ViewStatus.success, leagues: leagues));
    } catch (e) {
      emit(state.copyWith(
          leaguesStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onReplaceLeagueParticipant(
      ReplaceLeagueParticipant event, Emitter<GroupDetailState> emit) async {
    emit(state.copyWith(replaceParticipantStatus: ViewStatus.loading));
    try {
      await _leagueRepository.replaceParticipant(
        leagueId: event.leagueId,
        oldUserId: event.oldUserId,
        newUserId: event.newUserId,
      );
      emit(state.copyWith(replaceParticipantStatus: ViewStatus.success));
      add(LoadGroupLeagues(state.group.id));
    } catch (e) {
      emit(state.copyWith(
        replaceParticipantStatus: ViewStatus.failure,
        replaceErrorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSetLeagueMergeCompleted(
      SetLeagueMergeCompleted event, Emitter<GroupDetailState> emit) async {
    try {
      await _leagueRepository.setMergeCompleted(
        event.leagueId,
        completed: event.completed,
      );
      // Update local state optimistically — no need to reload all leagues
      final updated = state.leagues.map((l) {
        return l.id == event.leagueId
            ? l.copyWith(mergeCompleted: event.completed)
            : l;
      }).toList();
      emit(state.copyWith(leagues: updated));
    } catch (e) {
      showToast('Không thể cập nhật trạng thái');
    }
  }
}
