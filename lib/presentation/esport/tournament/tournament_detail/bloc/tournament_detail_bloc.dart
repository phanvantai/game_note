import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import '../../../../../domain/repositories/esport/esport_league_repository.dart';
import '../../../../../firebase/firestore/esport/league/match/gn_esport_match.dart';
import '../../../../../firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart'
    show ConcurrentMatchUpdateException;

part 'tournament_detail_event.dart';
part 'tournament_detail_state.dart';

class TournamentDetailBloc
    extends Bloc<TournamentDetailEvent, TournamentDetailState> {
  static const bool _enableStatsAudit = bool.fromEnvironment(
    'DEBUG_AUDIT_TOURNAMENT_STATS',
  );

  final EsportLeagueRepository _esportLeagueRepository;

  TournamentDetailBloc(this._esportLeagueRepository)
    : super(const TournamentDetailState()) {
    on<GetParticipantStats>(_onGetParticipants);
    on<GetMatches>(_onGetMatches);
    on<GetParticipantsAndMatches>(_onGetParticipantsAndMatches);

    on<AddParticipant>(_onAddParticipant);
    on<AddMultipleParticipants>(_onAddMultipleParticipants);

    on<GenerateRound>(_onGenerateRound);
    on<GenerateGroupRound>(_onGenerateGroupRound);
    on<UpdateEsportMatch>(_onUpdateMatch);
    on<ApplyMatchStatDelta>(_onApplyMatchStatDelta);

    on<ChangeLeagueStatus>(_onChangeLeagueStatus);
    on<SubmitLeagueStatus>(_onSubmitLeagueStatus);

    on<InactiveLeague>(_onInactiveLeague);

    on<DeleteEsportMatch>(_onDeleteMatch);
    on<CreateCustomMatch>(_onCreateCustomMatch);

    on<UpdateLeague>(_onUpdateLeague);
    on<UpdateLeagueCostConfig>(_onUpdateLeagueCostConfig);
    on<UpdateMatches>(_onUpdateMatches);

    on<GetLeague>(_onGetLeague);
    on<RecomputeStats>(_onRecomputeStats);
    on<GenerateCup>(_onGenerateCup);
    on<GenerateFull>(_onGenerateFull);
    on<SelectGroup>((event, emit) {
      emit(state.copyWith(
        selectedGroupId: event.groupId,
        clearSelectedGroupId: event.groupId == null,
      ));
    });
    on<LoadLeagueError>((event, emit) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: event.message,
        ),
      );
    });
  }

  StreamSubscription<List<GNEsportMatch>>? _matchesSubscription;
  StreamSubscription<List<GNEsportLeagueStat>>? _participantsSubscription;
  StreamSubscription<GNEsportLeague>? _leagueSubscription;

  Future<void> _onGetLeague(
    GetLeague event,
    Emitter<TournamentDetailState> emit,
  ) async {
    // Stats stream: any change to a league stat means a match was just
    // recorded. Re-fetch the full participants+matches snapshot (with users)
    // so the table updates with fresh user data. Matches stream alone is
    // not enough — it doesn't refresh stats.
    _participantsSubscription?.cancel();
    _participantsSubscription = _esportLeagueRepository
        .listenForLeagueStats(event.leagueId)
        .skip(1) // skip initial snapshot — initial load is fired explicitly below
        .listen((_) {
          add(GetParticipantsAndMatches(event.leagueId));
        });

    // Matches stream covers fixture-only changes (custom match created,
    // match deleted) where stats don't change. Apply directly to state
    // using cached users — no extra fetch. Don't skip(1) here: re-applying
    // the initial snapshot is cheap (no network call), and we want to
    // catch the case where the stream fires before the initial fetch
    // completes.
    _matchesSubscription?.cancel();
    _matchesSubscription = _esportLeagueRepository
        .listenForMatchesUpdated(event.leagueId)
        .listen((matches) {
          add(UpdateMatches(matches));
        });

    _leagueSubscription?.cancel();
    _leagueSubscription = _esportLeagueRepository
        .listenForLeagueUpdated(event.leagueId)
        .listen(
          (league) {
            add(UpdateLeague(league));
          },
          onError: (e) {
            //add(LoadLeagueError(e.toString()));
          },
        );

    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      // Load league + participants + matches in parallel so the screen
      // shows full data on first paint instead of loading in two phases.
      final results = await Future.wait([
        _esportLeagueRepository.getLeague(event.leagueId),
        _esportLeagueRepository.getParticipantsAndMatches(event.leagueId),
      ]);
      final league = results[0] as GNEsportLeague?;
      var data = results[1] as LeagueDetailData;

      if (league == null) {
        emit(
          state.copyWith(
            viewStatus: ViewStatus.failure,
            errorMessage: 'Không tìm thấy giải đấu',
          ),
        );
        return;
      }

      final users = <GNUser>[
        for (final p in data.participants)
          if (p.user != null) p.user!,
      ];

      _auditStats(league, data.participants, data.matches);

      emit(
        state.copyWith(
          viewStatus: ViewStatus.success,
          league: league,
          participants: _sortParticipants(data.participants),
          users: users,
          matches: data.matches,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  List<GNEsportLeagueStat> _sortParticipants(
    List<GNEsportLeagueStat> participants,
  ) {
    final sorted = List<GNEsportLeagueStat>.of(participants)
      ..sort((a, b) {
        if (a.points != b.points) return b.points.compareTo(a.points);
        if (a.goalDifference != b.goalDifference) {
          return b.goalDifference.compareTo(a.goalDifference);
        }
        if (a.goals != b.goals) return b.goals.compareTo(a.goals);
        return b.matchesPlayed.compareTo(a.matchesPlayed);
      });
    return sorted;
  }

  /// Debug-only audit: recompute stats from the finished-matches list and
  /// diff against the stat docs in DB. Logs every mismatch + every finished
  /// match for cross-reference. Helps catch ghost/orphan matches that
  /// updateMatch's old non-transactional flow could leave behind.
  void _auditStats(
    GNEsportLeague? league,
    List<GNEsportLeagueStat> participants,
    List<GNEsportMatch> matches,
  ) {
    if (!kDebugMode || !_enableStatsAudit) {
      return;
    }
    final tag = '[AUDIT][${league?.name.isNotEmpty == true ? league!.name : league?.id ?? "?"}]';
    final finished = matches.where((m) => m.isFinished).toList();
    debugPrint(
      '$tag matches=${matches.length} finished=${finished.length} '
      'participants=${participants.length}',
    );

    final computed = <String, _AuditTotals>{
      for (final p in participants) p.userId: _AuditTotals(),
    };
    final orphanMatches = <GNEsportMatch>[];

    for (final m in finished) {
      final h = m.homeScore;
      final a = m.awayScore;
      if (h == null || a == null) continue;
      final ch = computed[m.homeTeamId];
      final ca = computed[m.awayTeamId];
      if (ch == null || ca == null) {
        orphanMatches.add(m);
        // Still record into the side that exists, if any, to surface the
        // mismatch on that player too.
      }
      if (ch != null) ch.add(scoredFor: h, scoredAgainst: a);
      if (ca != null) ca.add(scoredFor: a, scoredAgainst: h);
    }

    if (orphanMatches.isNotEmpty) {
      debugPrint('$tag ⚠ ORPHAN matches (player not in stats):');
      for (final m in orphanMatches) {
        debugPrint(
          '$tag   matchId=${m.id} home=${m.homeTeamId} away=${m.awayTeamId} '
          'score=${m.homeScore}-${m.awayScore}',
        );
      }
    }

    var anyMismatch = false;
    for (final p in participants) {
      final c = computed[p.userId]!;
      final ok = p.matchesPlayed == c.mp &&
          p.goals == c.gf &&
          p.goalsConceded == c.ga &&
          p.wins == c.w &&
          p.draws == c.d &&
          p.losses == c.l;
      final name = p.user?.displayName ?? p.userId;
      if (!ok) {
        anyMismatch = true;
        debugPrint(
          '$tag ❌ $name '
          'DB(MP:${p.matchesPlayed} W:${p.wins} D:${p.draws} L:${p.losses} '
          'GF:${p.goals} GA:${p.goalsConceded}) '
          'vs Computed(MP:${c.mp} W:${c.w} D:${c.d} L:${c.l} '
          'GF:${c.gf} GA:${c.ga})',
        );
      }
    }

    if (!anyMismatch && orphanMatches.isEmpty) {
      debugPrint('$tag ✅ stats consistent');
    }

    debugPrint('$tag --- finished match list ---');
    for (final m in finished) {
      final hName = m.homeTeam?.displayName ?? m.homeTeamId;
      final aName = m.awayTeam?.displayName ?? m.awayTeamId;
      debugPrint(
        '$tag   ${m.id}: $hName ${m.homeScore}-${m.awayScore} $aName '
        '(updatedAt=${m.updatedAt?.toDate().toIso8601String() ?? "—"})',
      );
    }
    debugPrint('$tag ---------------------------');
  }

  Future<void> _onRecomputeStats(
    RecomputeStats event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.recomputeLeagueStats(leagueId);
      // Reload from server so the UI reflects the freshly written totals.
      // The participants stream will also catch the writes, but pulling
      // explicitly avoids relying on stream timing.
      add(GetParticipantsAndMatches(leagueId));
      showToast('Đã đồng bộ lại điểm số');
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateLeague(
    UpdateLeague event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final newLeague = event.league.copyWith(group: state.league?.group);
    emit(state.copyWith(league: newLeague));
    if (event.league.isActive) {
      add(GetParticipantsAndMatches(event.league.id));
    }
  }

  Future<void> _onUpdateLeagueCostConfig(
    UpdateLeagueCostConfig event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final league = state.league;
    if (league == null) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final updated = league.copyWith(
        rankPayoutEnabled: event.rankPayoutEnabled,
        rankPayouts: event.rankPayouts,
        defaultMatchCost: event.defaultMatchCost,
        defaultPerGoalEnabled: event.defaultPerGoalEnabled,
        defaultCostPerGoal: event.defaultCostPerGoal,
      );
      await _esportLeagueRepository.updateLeague(updated);
      emit(state.copyWith(viewStatus: ViewStatus.success, league: updated));
      showToast('Đã cập nhật chi phí giải đấu');
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateMatches(
    UpdateMatches event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final usersById = {for (final u in state.users) u.id: u};
    emit(
      state.copyWith(
        matches: event.matches
            .map(
              (e) => e.copyWith(
                homeTeam: usersById[e.homeTeamId],
                awayTeam: usersById[e.awayTeamId],
              ),
            )
            .toList(),
      ),
    );
  }

  void _onCreateCustomMatch(
    CreateCustomMatch event,
    Emitter<TournamentDetailState> emit,
  ) async {
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
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onDeleteMatch(
    DeleteEsportMatch event,
    Emitter<TournamentDetailState> emit,
  ) async {
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
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onInactiveLeague(
    InactiveLeague event,
    Emitter<TournamentDetailState> emit,
  ) async {
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
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onChangeLeagueStatus(
    ChangeLeagueStatus event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final newLeague = state.league?.copyWith(status: event.status.value);
    emit(state.copyWith(league: newLeague));
  }

  void _onSubmitLeagueStatus(
    SubmitLeagueStatus event,
    Emitter<TournamentDetailState> emit,
  ) async {
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
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onGetParticipants(
    GetParticipantStats event,
    Emitter<TournamentDetailState> emit,
  ) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final participants = await _esportLeagueRepository.getLeagueStats(
        event.tournamentId,
      );
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
      emit(
        state.copyWith(
          viewStatus: ViewStatus.success,
          participants: participants,
          users: users,
        ),
      );
      add(GetMatches(event.tournamentId));
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onGetMatches(
    GetMatches event,
    Emitter<TournamentDetailState> emit,
  ) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final matches = await _esportLeagueRepository.getMatches(
        event.tournamentId,
      );
      final users = state.users;
      emit(
        state.copyWith(
          viewStatus: ViewStatus.success,
          matches: matches
              .map(
                (e) => e.copyWith(
                  homeTeam: users.firstWhere(
                    (element) => element.id == e.homeTeamId,
                  ),
                  awayTeam: users.firstWhere(
                    (element) => element.id == e.awayTeamId,
                  ),
                ),
              )
              .toList(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetParticipantsAndMatches(
    GetParticipantsAndMatches event,
    Emitter<TournamentDetailState> emit,
  ) async {
    // Only show the loading bar on the initial load. Reactive refreshes
    // (stream-triggered or pull-to-refresh) keep the existing data on
    // screen so the user doesn't see a spinner flash on every match update.
    final isInitial = state.participants.isEmpty;
    if (isInitial) {
      emit(state.copyWith(viewStatus: ViewStatus.loading));
    }
    try {
      var data = await _esportLeagueRepository.getParticipantsAndMatches(
        event.leagueId,
      );

      final users = <GNUser>[
        for (final p in data.participants)
          if (p.user != null) p.user!,
      ];

      _auditStats(state.league, data.participants, data.matches);

      emit(
        state.copyWith(
          viewStatus: ViewStatus.success,
          participants: _sortParticipants(data.participants),
          users: users,
          matches: data.matches,
          refreshTick: state.refreshTick + 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
          refreshTick: state.refreshTick + 1,
        ),
      );
    }
  }

  void _onAddParticipant(
    AddParticipant event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.addParticipant(
        leagueId: leagueId,
        userId: event.userId,
      );
      add(GetParticipantStats(leagueId));
      showToast('Thêm người chơi thành công');
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onAddMultipleParticipants(
    AddMultipleParticipants event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    if (event.userIds.isEmpty) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.addMultipleParticipants(
        leagueId: leagueId,
        userIds: event.userIds,
      );
      add(GetParticipantStats(leagueId));
      showToast('Thêm ${event.userIds.length} người chơi thành công');
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGenerateGroupRound(
    GenerateGroupRound event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null || state.viewStatus == ViewStatus.loading) return;
    final teamIds = state.participants
        .where((p) => p.groupId == event.groupId)
        .map((p) => p.userId)
        .toList();
    if (teamIds.length < 2) {
      showToast('Bảng cần ít nhất 2 người chơi để tạo vòng đấu');
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.generateGroupRound(
        leagueId: leagueId,
        groupId: event.groupId,
        teamIds: teamIds,
      );
      add(GetParticipantsAndMatches(leagueId));
      showToast('Tạo vòng đấu thành công');
    } catch (e) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onGenerateRound(
    GenerateRound event,
    Emitter<TournamentDetailState> emit,
  ) async {
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
        teamIds: state.participants.map((e) => e.userId).toList(),
      );
      add(GetMatches(leagueId));
      showToast('Tạo vòng đấu thành công');
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onUpdateMatch(
    UpdateEsportMatch event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      // Match write only — stats are reconciled on the ApplyMatchStatDelta
      // handler below so this path stays fast (no stat queries, no extra
      // transaction reads). UX returns as soon as the match doc is saved.
      final result = await _esportLeagueRepository.updateMatch(event.match);
      add(ApplyMatchStatDelta(
        previous: result.previous,
        updated: result.updated,
      ));
      showToast('Cập nhật trận đấu thành công');
    } on ConcurrentMatchUpdateException {
      // Another admin updated this match while the dialog was open. The
      // listener stream has already pulled the new values into state, so
      // the user just needs to be told their submission was rejected.
      showToast(
        'Trận này vừa được người khác cập nhật. Vui lòng kiểm tra lại.',
      );
      emit(state.copyWith(viewStatus: ViewStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onApplyMatchStatDelta(
    ApplyMatchStatDelta event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null) return;
    try {
      await _esportLeagueRepository.applyMatchStatDelta(
        previous: event.previous,
        updated: event.updated,
      );
      // Refresh leaderboard once stats settle. Failure path skips this —
      // listenForLeagueStats will still surface any reconciled writes.
      add(GetParticipantStats(leagueId));
    } catch (e) {
      // Don't surface to UI: the match save already succeeded, and stat
      // drift is recoverable via the manual "đồng bộ điểm số" action.
      debugPrint('ApplyMatchStatDelta failed: $e');
    }
  }

  Future<void> _onGenerateCup(
    GenerateCup event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null || state.viewStatus == ViewStatus.loading) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.generateCupBracket(
        leagueId: leagueId,
        seededTeamIds: event.seededTeamIds,
      );
      add(GetMatches(leagueId));
      showToast('Tạo bracket thành công');
    } catch (e) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onGenerateFull(
    GenerateFull event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null || state.viewStatus == ViewStatus.loading) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.generateFullTournament(
        leagueId: leagueId,
        groups: event.groups,
        advanceCount: event.advanceCount,
      );
      add(GetParticipantsAndMatches(leagueId));
      showToast('Tạo giải Full thành công');
    } catch (e) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        errorMessage: e.toString(),
      ));
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

/// Mutable accumulator used by the debug audit to recompute per-player
/// totals from the finished-match list.
class _AuditTotals {
  int mp = 0;
  int gf = 0;
  int ga = 0;
  int w = 0;
  int d = 0;
  int l = 0;

  void add({required int scoredFor, required int scoredAgainst}) {
    mp++;
    gf += scoredFor;
    ga += scoredAgainst;
    if (scoredFor > scoredAgainst) {
      w++;
    } else if (scoredFor == scoredAgainst) {
      d++;
    } else {
      l++;
    }
  }
}
