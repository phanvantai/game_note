import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/cache/group_overview_cache.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_firestore_user.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/models/group_overview.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/services/group_overview_calculator.dart';

import '../../../../../domain/repositories/esport/esport_group_repository.dart';
import '../../../../../domain/repositories/esport/esport_group_stats_repository.dart';
import '../../../../../domain/repositories/esport/esport_league_repository.dart';
import '../services/group_overview_year_filter.dart';

part 'group_detail_event.dart';
part 'group_detail_state.dart';

class GroupDetailBloc extends Bloc<GroupDetailEvent, GroupDetailState> {
  final EsportGroupRepository _groupRepository;
  final EsportLeagueRepository _leagueRepository;
  final EsportGroupStatsRepository _groupStatsRepository;
  final GroupOverviewCache _overviewCache;
  final GNFirestore _firestore;
  final Duration _recomputeTimeout;
  late final Future<GNUser> Function({required String displayName})
      _createPlaceholderUser;

  GroupDetailBloc(
    this._groupRepository,
    this._leagueRepository,
    this._groupStatsRepository,
    this._overviewCache,
    this._firestore,
    GNEsportGroup group, {
    String? currentUserId,
    Duration recomputeTimeout = const Duration(seconds: 30),
    Future<GNUser> Function({required String displayName})? createPlaceholderUser,
  })  : _recomputeTimeout = recomputeTimeout,
        super(GroupDetailState(
          group: group,
          currentUserId: currentUserId ?? FirebaseAuth.instance.currentUser?.uid,
        )) {
    _createPlaceholderUser =
        createPlaceholderUser ?? _firestore.createPlaceholderUser;
    on<GetMembers>(_onGetMembers);
    on<AddMember>(_onAddMember);
    on<RemoveMember>(_onRemoveMember);
    on<GetGroupDetail>(_onGetGroupDetail);
    on<LoadGroupLeagues>(_onLoadGroupLeagues);
    on<LoadGroupOverview>(_onLoadGroupOverview);
    on<AddPlaceholderMember>(_onAddPlaceholderMember);
    on<ReplaceLeagueParticipant>(_onReplaceLeagueParticipant);
    on<SetLeagueMergeCompleted>(_onSetLeagueMergeCompleted);
    on<FilterGroupOverviewByYear>(_onFilterGroupOverviewByYear);
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

  Future<void> _onAddPlaceholderMember(
      AddPlaceholderMember event, Emitter<GroupDetailState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final user =
          await _createPlaceholderUser(displayName: event.displayName);
      await _groupRepository.addMemberToGroup(
          groupId: event.groupId, memberId: user.id);
      add(GetMembers(state.group.id));
      add(GetGroupDetail(state.group.id));
      showToast('Đã thêm người chơi mới');
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

  /// Load the group overview from a single Firestore doc
  /// (`esports_groups/{groupId}/stats/summary`) maintained server-side
  /// by Cloud Functions. Mirrors the dashboard pattern:
  /// - First paint hydrates from local cache (instant), marks stale.
  /// - Refresh writes a recompute request and waits for the server to
  ///   rebuild the doc.
  /// - Lazy backfill: if no summary doc exists yet, request a recompute
  ///   and wait for the first emission.
  Future<void> _onLoadGroupOverview(
      LoadGroupOverview event, Emitter<GroupDetailState> emit) async {
    final groupId = event.groupId;

    if (!event.forceRefresh && state.overview == null) {
      // First paint: try cache, otherwise show loading.
      final cached = await _overviewCache.read(groupId);
      if (cached != null) {
        final cachedUsers = await _fetchUsersFor(cached);
        emit(state.copyWith(
          overviewStatus: ViewStatus.success,
          overview: GroupOverviewCalculator.compute(
            summary: cached,
            users: cachedUsers,
          ),
          overviewIsStale: true,
          overviewErrorMessage: '',
        ));
      } else {
        emit(state.copyWith(overviewStatus: ViewStatus.loading));
      }
    } else {
      // Refresh: keep prior overview visible while fetching.
      emit(state.copyWith(overviewStatus: ViewStatus.loading));
    }

    try {
      GNEsportGroupStatsSummary? summary;
      if (event.forceRefresh) {
        // Trigger a server rebuild and take whatever the function writes
        // next. We skip the first emission (the current/stale doc) so
        // refresh always reflects fresh server state.
        await _groupStatsRepository.requestRecompute(groupId);
        summary = await _groupStatsRepository
            .listenSummary(groupId)
            .skip(1)
            .where((s) => s != null)
            .cast<GNEsportGroupStatsSummary>()
            .first
            .timeout(_recomputeTimeout);
      } else {
        summary = await _groupStatsRepository.getSummary(groupId);
        if (summary == null) {
          // Lazy backfill for groups that existed before this feature
          // shipped.
          await _groupStatsRepository.requestRecompute(groupId);
          summary = await _groupStatsRepository
              .listenSummary(groupId)
              .where((s) => s != null)
              .cast<GNEsportGroupStatsSummary>()
              .first
              .timeout(_recomputeTimeout);
        }
      }

      await _overviewCache.write(groupId, summary);
      final users = await _fetchUsersFor(summary);
      final overview = GroupOverviewCalculator.compute(
        summary: summary,
        users: users,
      );
      _debugLogOverview(groupId, summary, overview);
      // Fire-and-forget: don't block the UI on a debug dump.
      // ignore: discarded_futures
      _debugDumpPlayerLeagues(groupId, summary);
      emit(state.copyWith(
        overviewStatus: ViewStatus.success,
        overview: overview,
        overviewIsStale: false,
        overviewErrorMessage: '',
      ));
    } catch (e) {
      if (state.overview != null) {
        // Don't blow away cached overview on transient errors.
        emit(state.copyWith(
          overviewStatus: ViewStatus.success,
          overviewIsStale: true,
          overviewErrorMessage: e.toString(),
        ));
      } else {
        emit(state.copyWith(
          overviewStatus: ViewStatus.failure,
          overviewErrorMessage: e.toString(),
        ));
      }
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

  Future<void> _onFilterGroupOverviewByYear(
    FilterGroupOverviewByYear event,
    Emitter<GroupDetailState> emit,
  ) async {
    final year = event.year;

    if (year == null) {
      // Reset to all-time view; keep the yearly cache.
      emit(state.copyWith(clearSelectedYear: true));
      return;
    }

    // Cache hit: year already computed, just switch the selected year.
    if (state.yearlyOverviews.containsKey(year)) {
      emit(state.copyWith(selectedOverviewYear: year));
      return;
    }

    emit(state.copyWith(
      selectedOverviewYear: year,
      filteredOverviewStatus: ViewStatus.loading,
    ));

    try {
      final leaguesInYear =
          state.leagues.where((l) => l.startDate.year == year).toList();

      final statsList = await Future.wait(
        leaguesInYear.map((l) => _leagueRepository.getLeagueStats(l.id)),
      );
      final statsByLeague = {
        for (var i = 0; i < leaguesInYear.length; i++)
          leaguesInYear[i].id: statsList[i],
      };

      final summary = GroupOverviewYearFilter.aggregate(
        leagues: state.leagues,
        year: year,
        statsByLeague: statsByLeague,
      );
      final users = await _fetchUsersFor(summary);
      final filteredOverview =
          GroupOverviewCalculator.compute(summary: summary, users: users);

      emit(state.copyWith(
        yearlyOverviews: {...state.yearlyOverviews, year: filteredOverview},
        filteredOverviewStatus: ViewStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(filteredOverviewStatus: ViewStatus.failure));
    }
  }

  /// Fetch fresh user docs (with photoUrl) for everyone in the
  /// summary's playerStats. Mirrors the dashboard pattern: server
  /// stores stable labels, client fetches photos at render time so
  /// avatar updates propagate without a server-side rebuild.
  Future<Map<String, GNUser>> _fetchUsersFor(
    GNEsportGroupStatsSummary summary,
  ) async {
    final ids = summary.playerStats.map((p) => p.userId).toList();
    if (ids.isEmpty) return const {};
    try {
      return await _firestore.getUsersById(ids);
    } catch (_) {
      // Avatars are best-effort; never fail the whole load.
      return const {};
    }
  }

  /// Debug-only dump of the loaded summary so we can grab userIds when
  /// chasing merge/cleanup issues (e.g. a ghost participant that's still
  /// holding an award after a user merge).
  void _debugLogOverview(
    String groupId,
    GNEsportGroupStatsSummary summary,
    GroupOverview overview,
  ) {
    if (!kDebugMode) return;
    debugPrint('[GroupOverview] groupId=$groupId '
        'totalLeagues=${overview.totalLeagues} '
        'finishedLeagues=${overview.finishedLeagues} '
        'players=${summary.playerStats.length}');
    void award(String tag, GroupAward? a) {
      if (a == null) {
        debugPrint('[GroupOverview]   $tag: -');
      } else {
        debugPrint('[GroupOverview]   $tag: id=${a.player.id} '
            'name="${a.player.displayName}" '
            'value=${a.value.toStringAsFixed(3)} '
            'numerator=${a.numerator} sample=${a.sampleSize}');
      }
    }
    award('vô đối     ', overview.champion);
    award('về nhì     ', overview.runnerUpKing);
    award('hoà vương  ', overview.drawKing);
    award('cao thủ    ', overview.master);
    award('hàng thủ thép', overview.ironDefense);
    debugPrint('[GroupOverview] playerStats (raw, server-maintained):');
    for (final p in summary.playerStats) {
      debugPrint('[GroupOverview]   id=${p.userId} '
          'name="${p.displayName}" '
          'matches=${p.matches} W${p.wins}/D${p.draws}/L${p.losses} '
          'goals=${p.goals}/-${p.goalsConceded} '
          'champ=${p.championships} runnerUp=${p.runnerUps} '
          'finishedJoined=${p.finishedLeaguesJoined}');
    }
  }

  /// Debug-only: for each player in the summary, fetch the leagues in
  /// this group they are still listed as a participant of. Reveals
  /// leftover leagues after a user merge / cleanup.
  Future<void> _debugDumpPlayerLeagues(
    String groupId,
    GNEsportGroupStatsSummary summary,
  ) async {
    if (!kDebugMode) return;
    try {
      final leagues = await _leagueRepository.getLeaguesByGroupId(groupId);
      debugPrint('[GroupOverview] league participation by userId '
          '(${leagues.length} leagues in group):');
      for (final p in summary.playerStats) {
        final mine = leagues
            .where((l) => l.participants.contains(p.userId))
            .toList();
        debugPrint('[GroupOverview]   ${p.userId} ("${p.displayName}") '
            '→ ${mine.length} leagues');
        for (final l in mine) {
          debugPrint('[GroupOverview]     ${l.id} | "${l.name}" | '
              'status=${l.status} | isActive=${l.isActive} | '
              'startDate=${l.startDate.toIso8601String()}');
        }
      }
    } catch (e) {
      debugPrint('[GroupOverview] debug dump failed: $e');
    }
  }
}
