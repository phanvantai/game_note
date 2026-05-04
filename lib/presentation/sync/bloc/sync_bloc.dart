import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pes_arena/data/sync/mapping_target.dart';
import 'package:pes_arena/data/sync/migration_plan.dart';
import 'package:pes_arena/data/sync/offline_to_online_migrator.dart';
import 'package:pes_arena/data/sync/sync_remote_gateway.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/offline/domain/entities/league_model.dart';
import 'package:pes_arena/offline/domain/repositories/league_repository.dart';

part 'sync_event.dart';
part 'sync_state.dart';

/// Resolver cho uid của user đang đăng nhập. Inject để test không cần
/// FirebaseAuth thật.
typedef CurrentUidResolver = String? Function();

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required LeagueRepository offlineLeagueRepository,
    required SyncRemoteGateway gateway,
    required OfflineToOnlineMigrator migrator,
    CurrentUidResolver? currentUid,
  })  : _offlineRepo = offlineLeagueRepository,
        _gateway = gateway,
        _migrator = migrator,
        _currentUid =
            currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
        super(const SyncState()) {
    on<SyncLoadInitialData>(_onLoad);
    on<SyncSelectOfflineLeague>(_onSelectLeague);
    on<SyncSelectGroup>(_onSelectGroup);
    on<SyncSetMapping>(_onSetMapping);
    on<SyncClearMapping>(_onClearMapping);
    on<SyncGoToStep>(_onGoToStep);
    on<SyncRun>(_onRun);
  }

  final LeagueRepository _offlineRepo;
  final SyncRemoteGateway _gateway;
  final OfflineToOnlineMigrator _migrator;
  final CurrentUidResolver _currentUid;

  Future<void> _onLoad(SyncLoadInitialData event, Emitter<SyncState> emit) async {
    emit(state.copyWith(status: SyncStatus.loading, clearError: true));
    try {
      final leaguesResult = await _offlineRepo.getLeagues(GetLeaguesParams());
      final offlineLeagues = leaguesResult.fold<List<LeagueModel>>(
        (_) => const [],
        (l) => l,
      );
      final myGroups = await _gateway.getMyGroups();
      emit(state.copyWith(
        status: SyncStatus.ready,
        offlineLeagues: offlineLeagues,
        myGroups: myGroups,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Không tải được dữ liệu: $e',
      ));
    }
  }

  Future<void> _onSelectLeague(
    SyncSelectOfflineLeague event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(status: SyncStatus.loading, clearError: true));
    try {
      final result =
          await _offlineRepo.getLeague(GetLeagueParams(event.leagueId));
      result.fold(
        (failure) => emit(state.copyWith(
          status: SyncStatus.error,
          errorMessage: 'Không tải được league offline',
        )),
        (league) => emit(state.copyWith(
          status: SyncStatus.ready,
          selectedLeague: league,
          mappings: const {},
          plan: null,
          clearPlan: true,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Không tải được league offline: $e',
      ));
    }
  }

  Future<void> _onSelectGroup(
    SyncSelectGroup event,
    Emitter<SyncState> emit,
  ) async {
    final group = state.myGroups.firstWhere(
      (g) => g.id == event.groupId,
      orElse: () => GNEsportGroup.placeholder(event.groupId),
    );
    final isDifferent = state.selectedGroup?.id != event.groupId;
    emit(state.copyWith(
      status: SyncStatus.loading,
      selectedGroup: group,
      mappings: isDifferent ? const {} : state.mappings,
      clearPlan: isDifferent,
      clearError: true,
    ));
    try {
      final members = await _gateway.getGroupMembers(event.groupId);
      emit(state.copyWith(
        status: SyncStatus.ready,
        groupMembers: members,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Không tải được thành viên group: $e',
      ));
    }
  }

  void _onSetMapping(SyncSetMapping event, Emitter<SyncState> emit) {
    final next = Map<int, MappingTarget>.from(state.mappings);
    next[event.playerId] = event.target;
    emit(state.copyWith(mappings: next, clearPlan: true, clearError: true));
  }

  void _onClearMapping(SyncClearMapping event, Emitter<SyncState> emit) {
    final next = Map<int, MappingTarget>.from(state.mappings);
    next.remove(event.playerId);
    emit(state.copyWith(mappings: next, clearPlan: true));
  }

  void _onGoToStep(SyncGoToStep event, Emitter<SyncState> emit) {
    if (event.step == SyncStep.preview) {
      // Build plan khi vào preview để hiện op count cho user.
      final league = state.selectedLeague;
      final group = state.selectedGroup;
      final uid = _currentUid();
      if (league == null || group == null || uid == null) {
        emit(state.copyWith(
          status: SyncStatus.error,
          errorMessage: 'Thiếu dữ liệu để tạo kế hoạch',
        ));
        return;
      }
      try {
        final plan = _migrator.buildPlan(
          offlineLeague: league,
          groupId: group.id,
          currentUserUid: uid,
          mappings: state.mappings,
        );
        emit(state.copyWith(
          step: SyncStep.preview,
          plan: plan,
          clearError: true,
        ));
      } on PlanTooLargeException catch (e) {
        emit(state.copyWith(
          step: SyncStep.mapPlayers,
          status: SyncStatus.error,
          errorMessage:
              'League quá lớn: ${e.totalOps} thao tác (giới hạn ${MigrationPlan.batchLimit}). '
              'Hãy chia nhỏ league trước khi sync.',
        ));
      } catch (e) {
        emit(state.copyWith(
          step: SyncStep.mapPlayers,
          status: SyncStatus.error,
          errorMessage: 'Không build được kế hoạch: $e',
        ));
      }
      return;
    }
    emit(state.copyWith(step: event.step, clearError: true));
  }

  Future<void> _onRun(SyncRun event, Emitter<SyncState> emit) async {
    final league = state.selectedLeague;
    final plan = state.plan;
    if (league == null || plan == null) {
      emit(state.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Thiếu kế hoạch sync',
      ));
      return;
    }
    emit(state.copyWith(
      step: SyncStep.executing,
      status: SyncStatus.running,
      progress: 0,
      progressLabel: 'Đang ghi ${plan.totalOps} bản ghi lên server...',
      clearError: true,
    ));
    try {
      await _migrator.commit(plan);
      if (isClosed) return;
      // Delete offline league last — only after successful online write.
      await _offlineRepo.deleteLeauge(GetLeagueParams(league.id!));
      if (isClosed) return;
      emit(state.copyWith(
        status: SyncStatus.success,
        createdLeagueId: plan.leagueId,
        progress: 1.0,
        progressLabel: 'Hoàn tất',
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: SyncStatus.error,
        errorMessage:
            'Sync thất bại: $e\nKhông có dữ liệu nào được tạo trên server.',
      ));
    }
  }
}
