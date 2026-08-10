import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/l10n/app_text.dart';

import '../../../../../domain/repositories/esport/esport_group_repository.dart';
import '../../../../../domain/repositories/esport/esport_league_repository.dart';
import '../../../../../firebase/firestore/esport/league/match/gn_esport_match.dart';
import '../../../../../firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart'
    show ConcurrentMatchUpdateException;
import '../../../../../firebase/firestore/esport/league/match/round_robin_scheduler.dart'
    show RoundTooLargeException;

part 'tournament_detail_event.dart';
part 'tournament_detail_state.dart';

class TournamentDetailBloc
    extends Bloc<TournamentDetailEvent, TournamentDetailState> {
  static const bool _enableStatsAudit = bool.fromEnvironment(
    'DEBUG_AUDIT_TOURNAMENT_STATS',
  );

  final EsportLeagueRepository _leagueRepository;
  final EsportGroupRepository _groupRepository;

  StreamSubscription<GNEsportLeague?>? _leagueSubscription;
  StreamSubscription<List<GNEsportLeagueStat>>? _statsSubscription;
  StreamSubscription<List<GNEsportMatch>>? _matchesSubscription;

  String? _activeLeagueId;
  int _lifecycleEpoch = 0;
  int _leagueSnapshotSequence = 0;
  int _leagueGeneration = 0;
  int _statsGeneration = 0;
  int _matchesGeneration = 0;
  bool _isClosing = false;

  final Map<TournamentDetailSlice, int> _retryAttempts = {
    TournamentDetailSlice.league: 0,
    TournamentDetailSlice.stats: 0,
    TournamentDetailSlice.matches: 0,
  };
  final Map<TournamentDetailSlice, Timer?> _retryTimers = {
    TournamentDetailSlice.league: null,
    TournamentDetailSlice.stats: null,
    TournamentDetailSlice.matches: null,
  };

  final Map<String, GNEsportGroup> _groupsById = {};
  final Set<String> _resolvedGroupIds = {};
  final Map<String, Future<GNEsportGroup?>> _loadingGroups = {};
  final Map<String, int> _loadingUserEpochById = {};

  TournamentDetailBloc(
    EsportLeagueRepository leagueRepository,
    EsportGroupRepository groupRepository,
  ) : _leagueRepository = leagueRepository,
      _groupRepository = groupRepository,
      super(const TournamentDetailState()) {
    on<OpenLeagueDetail>(_onOpenLeagueDetail);
    on<EnsureDetailSubscriptions>(_onEnsureDetailSubscriptions);
    on<RetryDetailSlice>(_onRetryDetailSlice);
    on<LeagueSnapshotReceived>(_onLeagueSnapshotReceived);
    on<StatsSnapshotReceived>(_onStatsSnapshotReceived);
    on<MatchesSnapshotReceived>(_onMatchesSnapshotReceived);
    on<DetailStreamFailed>(_onDetailStreamFailed);
    on<_DetailStreamCompleted>(_onDetailStreamCompleted);

    on<AddParticipant>(_onAddParticipant);
    on<AddMultipleParticipants>(_onAddMultipleParticipants);
    on<GenerateRound>(_onGenerateRound);
    on<GenerateGroupRound>(_onGenerateGroupRound);
    on<UpdateEsportMatch>(_onUpdateMatch);
    on<ChangeLeagueStatus>(_onChangeLeagueStatus);
    on<SubmitLeagueStatus>(_onSubmitLeagueStatus);
    on<InactiveLeague>(_onInactiveLeague);
    on<DeleteEsportMatch>(_onDeleteMatch);
    on<CreateCustomMatch>(_onCreateCustomMatch);
    on<LeagueDeleted>(_onLeagueDeleted);
    on<UpdateLeagueCostConfig>(_onUpdateLeagueCostConfig);
    on<RecomputeStats>(_onRecomputeStats);
    on<GenerateCup>(_onGenerateCup);
    on<GenerateFull>(_onGenerateFull);
    on<SelectGroup>((event, emit) {
      emit(
        state.copyWith(
          selectedGroupId: event.groupId,
          clearSelectedGroupId: event.groupId == null,
        ),
      );
    });
  }

  Future<void> _onOpenLeagueDetail(
    OpenLeagueDetail event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (_isClosing || isClosed || emit.isDone) return;
    if (_activeLeagueId == event.leagueId) {
      _ensureSubscriptions(event.leagueId, emit);
      return;
    }

    final lifecycleEpoch = ++_lifecycleEpoch;
    await _cancelLifecycle(clearActiveLeague: true);
    if (!_canContinueLifecycle(lifecycleEpoch, emit)) return;
    _activeLeagueId = event.leagueId;
    _resetRetryState();
    _groupsById.clear();
    _resolvedGroupIds.clear();
    _loadingGroups.clear();
    _loadingUserEpochById.clear();

    emit(
      const TournamentDetailState().copyWith(
        viewStatus: ViewStatus.initial,
        refreshTick: state.refreshTick,
      ),
    );
    _bindLeagueStream(event.leagueId);
    _bindStatsStream(event.leagueId);
    _bindMatchesStream(event.leagueId);
  }

  void _onEnsureDetailSubscriptions(
    EnsureDetailSubscriptions event,
    Emitter<TournamentDetailState> emit,
  ) {
    if (_isClosing || isClosed || emit.isDone) return;
    if (_activeLeagueId != event.leagueId) {
      _addIfOpen(OpenLeagueDetail(event.leagueId));
      return;
    }
    _ensureSubscriptions(event.leagueId, emit);
  }

  void _ensureSubscriptions(
    String leagueId,
    Emitter<TournamentDetailState> emit,
  ) {
    if (_isClosing || isClosed || emit.isDone) return;
    final allActive =
        _leagueSubscription != null &&
        _statsSubscription != null &&
        _matchesSubscription != null;
    if (!allActive) {
      if (_leagueSubscription == null) _bindLeagueStream(leagueId);
      if (_statsSubscription == null) _bindStatsStream(leagueId);
      if (_matchesSubscription == null) _bindMatchesStream(leagueId);
    }
    emit(state.copyWith(refreshTick: state.refreshTick + 1));
  }

  void _bindLeagueStream(String leagueId) {
    if (_isClosing ||
        isClosed ||
        _leagueSubscription != null ||
        _activeLeagueId != leagueId) {
      return;
    }
    final generation = ++_leagueGeneration;
    try {
      _leagueSubscription = _leagueRepository
          .listenForLeagueUpdated(leagueId)
          .listen(
            (league) {
              if (_isClosing || isClosed) return;
              final sequence = ++_leagueSnapshotSequence;
              add(
                _SourcedLeagueSnapshotReceived(
                  leagueId,
                  generation,
                  sequence,
                  league,
                ),
              );
            },
            onError: (Object error) => _addIfOpen(
              _SourcedDetailStreamFailed(
                leagueId,
                generation,
                TournamentDetailSlice.league,
                error,
              ),
            ),
            onDone: () => _addIfOpen(
              _DetailStreamCompleted(
                leagueId,
                generation,
                TournamentDetailSlice.league,
              ),
            ),
            cancelOnError: true,
          );
    } catch (error) {
      _addIfOpen(
        _SourcedDetailStreamFailed(
          leagueId,
          generation,
          TournamentDetailSlice.league,
          error,
        ),
      );
    }
  }

  void _bindStatsStream(String leagueId) {
    if (_isClosing ||
        isClosed ||
        _statsSubscription != null ||
        _activeLeagueId != leagueId) {
      return;
    }
    final generation = ++_statsGeneration;
    try {
      _statsSubscription = _leagueRepository
          .listenForLeagueStats(leagueId)
          .listen(
            (stats) => _addIfOpen(
              _SourcedStatsSnapshotReceived(leagueId, generation, stats),
            ),
            onError: (Object error) => _addIfOpen(
              _SourcedDetailStreamFailed(
                leagueId,
                generation,
                TournamentDetailSlice.stats,
                error,
              ),
            ),
            onDone: () => _addIfOpen(
              _DetailStreamCompleted(
                leagueId,
                generation,
                TournamentDetailSlice.stats,
              ),
            ),
            cancelOnError: true,
          );
    } catch (error) {
      _addIfOpen(
        _SourcedDetailStreamFailed(
          leagueId,
          generation,
          TournamentDetailSlice.stats,
          error,
        ),
      );
    }
  }

  void _bindMatchesStream(String leagueId) {
    if (_isClosing ||
        isClosed ||
        _matchesSubscription != null ||
        _activeLeagueId != leagueId) {
      return;
    }
    final generation = ++_matchesGeneration;
    try {
      _matchesSubscription = _leagueRepository
          .listenForMatchesUpdated(leagueId)
          .listen(
            (matches) => _addIfOpen(
              _SourcedMatchesSnapshotReceived(leagueId, generation, matches),
            ),
            onError: (Object error) => _addIfOpen(
              _SourcedDetailStreamFailed(
                leagueId,
                generation,
                TournamentDetailSlice.matches,
                error,
              ),
            ),
            onDone: () => _addIfOpen(
              _DetailStreamCompleted(
                leagueId,
                generation,
                TournamentDetailSlice.matches,
              ),
            ),
            cancelOnError: true,
          );
    } catch (error) {
      _addIfOpen(
        _SourcedDetailStreamFailed(
          leagueId,
          generation,
          TournamentDetailSlice.matches,
          error,
        ),
      );
    }
  }

  Future<void> _onLeagueSnapshotReceived(
    LeagueSnapshotReceived event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (!_isCurrentEvent(event, TournamentDetailSlice.league)) return;
    final sourceLeagueId = _sourceLeagueId(event) ?? _activeLeagueId;
    if (sourceLeagueId == null) return;
    final lifecycleEpoch = _lifecycleEpoch;
    final snapshotSequence = event is _SourcedLeagueSnapshotReceived
        ? event.sequence
        : ++_leagueSnapshotSequence;

    final league = event.league;
    if (league == null) {
      _terminateDeletedLeague(emit);
      return;
    }
    if (!_isCurrentLeagueSnapshot(
      sourceLeagueId,
      lifecycleEpoch,
      snapshotSequence,
    )) {
      return;
    }

    if (league.id != sourceLeagueId) return;

    final group = await _resolveGroup(
      league,
      sourceLeagueId,
      lifecycleEpoch,
      snapshotSequence,
    );
    if (emit.isDone ||
        !_isCurrentLeagueSnapshot(
          sourceLeagueId,
          lifecycleEpoch,
          snapshotSequence,
        )) {
      return;
    }
    final nextLeague = league.copyWith(group: group);
    _markSliceSuccessful(TournamentDetailSlice.league);
    final streamErrors = Map<TournamentDetailSlice, String>.of(
      state.streamErrors,
    )..remove(TournamentDetailSlice.league);
    emit(
      state.copyWith(
        league: nextLeague,
        leagueDeleted: false,
        leagueSliceStatus: DetailSliceStatus.ready,
        streamErrors: streamErrors,
      ),
    );
    await _loadMissingUsers(emit, sourceLeagueId, lifecycleEpoch);
  }

  Future<GNEsportGroup?> _resolveGroup(
    GNEsportLeague league,
    String sourceLeagueId,
    int lifecycleEpoch,
    int snapshotSequence,
  ) async {
    final embedded = league.group;
    if (embedded != null) {
      if (_isCurrentLeagueSnapshot(
        sourceLeagueId,
        lifecycleEpoch,
        snapshotSequence,
      )) {
        _groupsById[league.groupId] = embedded;
        _resolvedGroupIds.add(league.groupId);
      }
      return embedded;
    }

    final current = state.league;
    if (current?.groupId == league.groupId && current?.group != null) {
      return current!.group;
    }
    if (_resolvedGroupIds.contains(league.groupId)) {
      return _groupsById[league.groupId];
    }

    final future = _loadingGroups.putIfAbsent(
      league.groupId,
      () => _groupRepository.getGroup(league.groupId),
    );
    try {
      final group = await future;
      if (_isCurrentLeagueSnapshot(
        sourceLeagueId,
        lifecycleEpoch,
        snapshotSequence,
      )) {
        _resolvedGroupIds.add(league.groupId);
        if (group != null) _groupsById[league.groupId] = group;
      }
      return group;
    } catch (error) {
      if (_isCurrentLeagueSnapshot(
        sourceLeagueId,
        lifecycleEpoch,
        snapshotSequence,
      )) {
        _resolvedGroupIds.add(league.groupId);
      }
      debugPrint('Unable to enrich league detail group: $error');
      return null;
    } finally {
      if (identical(_loadingGroups[league.groupId], future)) {
        _loadingGroups.remove(league.groupId);
      }
    }
  }

  Future<void> _onStatsSnapshotReceived(
    StatsSnapshotReceived event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (!_isCurrentEvent(event, TournamentDetailSlice.stats)) return;
    final sourceLeagueId = _sourceLeagueId(event) ?? _activeLeagueId;
    if (sourceLeagueId == null) return;
    final lifecycleEpoch = _lifecycleEpoch;

    final participants = _sortParticipants(
      _deduplicateStats(event.stats)
          .map((stat) => stat.copyWith(user: state.usersById[stat.userId]))
          .toList(growable: false),
    );
    _markSliceSuccessful(TournamentDetailSlice.stats);
    final streamErrors = Map<TournamentDetailSlice, String>.of(
      state.streamErrors,
    )..remove(TournamentDetailSlice.stats);
    emit(
      state.copyWith(
        participants: participants,
        statsSliceStatus: DetailSliceStatus.ready,
        streamErrors: streamErrors,
      ),
    );
    _auditStats(state.league, participants, state.matches);
    await _loadMissingUsers(emit, sourceLeagueId, lifecycleEpoch);
  }

  Future<void> _onMatchesSnapshotReceived(
    MatchesSnapshotReceived event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (!_isCurrentEvent(event, TournamentDetailSlice.matches)) return;
    final sourceLeagueId = _sourceLeagueId(event) ?? _activeLeagueId;
    if (sourceLeagueId == null) return;
    final lifecycleEpoch = _lifecycleEpoch;

    final matches = _deduplicateMatches(event.matches)
        .map(
          (match) => match.copyWith(
            homeTeam: state.usersById[match.homeTeamId],
            awayTeam: state.usersById[match.awayTeamId],
          ),
        )
        .toList(growable: false);
    _markSliceSuccessful(TournamentDetailSlice.matches);
    final streamErrors = Map<TournamentDetailSlice, String>.of(
      state.streamErrors,
    )..remove(TournamentDetailSlice.matches);
    emit(
      state.copyWith(
        matches: matches,
        matchesSliceStatus: DetailSliceStatus.ready,
        streamErrors: streamErrors,
      ),
    );
    _auditStats(state.league, state.participants, matches);
    await _loadMissingUsers(emit, sourceLeagueId, lifecycleEpoch);
  }

  List<GNEsportLeagueStat> _deduplicateStats(List<GNEsportLeagueStat> stats) {
    final byId = <String, GNEsportLeagueStat>{
      for (final stat in stats) stat.id: stat,
    };
    return byId.values.toList(growable: false);
  }

  List<GNEsportMatch> _deduplicateMatches(List<GNEsportMatch> matches) {
    final byId = <String, GNEsportMatch>{
      for (final match in matches) match.id: match,
    };
    final result = byId.values.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    return result;
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
        if (a.matchesPlayed != b.matchesPlayed) {
          return b.matchesPlayed.compareTo(a.matchesPlayed);
        }
        return a.id.compareTo(b.id);
      });
    return sorted;
  }

  Future<void> _loadMissingUsers(
    Emitter<TournamentDetailState> emit,
    String leagueId,
    int lifecycleEpoch,
  ) async {
    if (!_canContinueLifecycle(lifecycleEpoch, emit) ||
        _activeLeagueId != leagueId) {
      return;
    }
    final requiredIds = <String>{
      ...?state.league?.participants,
      ...state.participants.map((stat) => stat.userId),
      for (final match in state.matches) ...[
        if (match.homeTeamId.isNotEmpty) match.homeTeamId,
        if (match.awayTeamId.isNotEmpty) match.awayTeamId,
      ],
    };
    final missing =
        requiredIds
            .difference(state.usersById.keys.toSet())
            .difference(_loadingUserEpochById.keys.toSet())
            .toList(growable: false)
          ..sort();
    if (missing.isEmpty) return;

    for (final userId in missing) {
      _loadingUserEpochById[userId] = lifecycleEpoch;
    }
    try {
      final users = await _leagueRepository.getUsersByIds(missing);
      if (!_canContinueLifecycle(lifecycleEpoch, emit) ||
          _activeLeagueId != leagueId) {
        return;
      }
      final usersById = Map<String, GNUser>.of(state.usersById)..addAll(users);
      emit(
        state.copyWith(
          usersById: usersById,
          participants: state.participants
              .map((stat) => stat.copyWith(user: usersById[stat.userId]))
              .toList(growable: false),
          matches: state.matches
              .map(
                (match) => match.copyWith(
                  homeTeam: usersById[match.homeTeamId],
                  awayTeam: usersById[match.awayTeamId],
                ),
              )
              .toList(growable: false),
        ),
      );
    } catch (error) {
      debugPrint('Unable to enrich league detail users: $error');
    } finally {
      for (final userId in missing) {
        if (_loadingUserEpochById[userId] == lifecycleEpoch) {
          _loadingUserEpochById.remove(userId);
        }
      }
    }
  }

  Future<void> _onDetailStreamFailed(
    DetailStreamFailed event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (!_isCurrentEvent(event, event.slice)) return;
    final lifecycleEpoch = _lifecycleEpoch;
    await _cancelSliceSubscription(event.slice);
    if (!_canContinueLifecycle(lifecycleEpoch, emit) ||
        !_isCurrentEvent(event, event.slice)) {
      return;
    }
    final streamErrors = Map<TournamentDetailSlice, String>.of(
      state.streamErrors,
    )..[event.slice] = event.error.toString();
    emit(
      state.copyWith(
        leagueSliceStatus: event.slice == TournamentDetailSlice.league
            ? DetailSliceStatus.failed
            : null,
        statsSliceStatus: event.slice == TournamentDetailSlice.stats
            ? DetailSliceStatus.failed
            : null,
        matchesSliceStatus: event.slice == TournamentDetailSlice.matches
            ? DetailSliceStatus.failed
            : null,
        streamErrors: streamErrors,
      ),
    );
    _scheduleRetry(event.slice);
  }

  Future<void> _onDetailStreamCompleted(
    _DetailStreamCompleted event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (!_isCurrentEvent(event, event.slice)) return;
    await _cancelSliceSubscription(event.slice);
  }

  void _scheduleRetry(TournamentDetailSlice slice) {
    final leagueId = _activeLeagueId;
    if (_isClosing || isClosed || leagueId == null) return;
    final attempt = _retryAttempts[slice] ?? 0;
    if (attempt >= 3) return;
    _retryAttempts[slice] = attempt + 1;
    _retryTimers[slice]?.cancel();
    _retryTimers[slice] = Timer(Duration(seconds: 1 << attempt), () {
      if (!isClosed && _activeLeagueId == leagueId) {
        add(RetryDetailSlice(slice));
      }
    });
  }

  void _onRetryDetailSlice(
    RetryDetailSlice event,
    Emitter<TournamentDetailState> emit,
  ) {
    if (_isClosing || isClosed || emit.isDone) return;
    _retryTimers[event.slice] = null;
    final leagueId = _activeLeagueId;
    if (leagueId == null) return;
    switch (event.slice) {
      case TournamentDetailSlice.league:
        if (_leagueSubscription == null) _bindLeagueStream(leagueId);
      case TournamentDetailSlice.stats:
        if (_statsSubscription == null) _bindStatsStream(leagueId);
      case TournamentDetailSlice.matches:
        if (_matchesSubscription == null) _bindMatchesStream(leagueId);
    }
  }

  void _markSliceSuccessful(TournamentDetailSlice slice) {
    _retryTimers[slice]?.cancel();
    _retryTimers[slice] = null;
    _retryAttempts[slice] = 0;
  }

  bool _isCurrentEvent(
    TournamentDetailEvent event,
    TournamentDetailSlice slice,
  ) {
    final sourceLeagueId = _sourceLeagueId(event);
    if (sourceLeagueId != null && sourceLeagueId != _activeLeagueId) {
      return false;
    }
    final sourceGeneration = _sourceGeneration(event);
    if (sourceGeneration == null) return _activeLeagueId != null;
    return sourceGeneration == _generationFor(slice);
  }

  bool _canContinueLifecycle(
    int lifecycleEpoch,
    Emitter<TournamentDetailState> emit,
  ) {
    return !_isClosing &&
        !isClosed &&
        !emit.isDone &&
        lifecycleEpoch == _lifecycleEpoch;
  }

  bool _isCurrentLeagueSnapshot(
    String leagueId,
    int lifecycleEpoch,
    int snapshotSequence,
  ) {
    return !_isClosing &&
        !isClosed &&
        _activeLeagueId == leagueId &&
        _lifecycleEpoch == lifecycleEpoch &&
        _leagueSnapshotSequence == snapshotSequence;
  }

  void _addIfOpen(TournamentDetailEvent event) {
    if (_isClosing || isClosed) return;
    add(event);
  }

  String? _sourceLeagueId(TournamentDetailEvent event) {
    return switch (event) {
      _SourcedLeagueSnapshotReceived e => e.sourceLeagueId,
      _SourcedStatsSnapshotReceived e => e.sourceLeagueId,
      _SourcedMatchesSnapshotReceived e => e.sourceLeagueId,
      _SourcedDetailStreamFailed e => e.sourceLeagueId,
      _DetailStreamCompleted e => e.sourceLeagueId,
      _ => null,
    };
  }

  int? _sourceGeneration(TournamentDetailEvent event) {
    return switch (event) {
      _SourcedLeagueSnapshotReceived e => e.generation,
      _SourcedStatsSnapshotReceived e => e.generation,
      _SourcedMatchesSnapshotReceived e => e.generation,
      _SourcedDetailStreamFailed e => e.generation,
      _DetailStreamCompleted e => e.generation,
      _ => null,
    };
  }

  int _generationFor(TournamentDetailSlice slice) {
    return switch (slice) {
      TournamentDetailSlice.league => _leagueGeneration,
      TournamentDetailSlice.stats => _statsGeneration,
      TournamentDetailSlice.matches => _matchesGeneration,
    };
  }

  Future<void> _cancelSliceSubscription(TournamentDetailSlice slice) async {
    switch (slice) {
      case TournamentDetailSlice.league:
        final subscription = _leagueSubscription;
        _leagueSubscription = null;
        await subscription?.cancel();
      case TournamentDetailSlice.stats:
        final subscription = _statsSubscription;
        _statsSubscription = null;
        await subscription?.cancel();
      case TournamentDetailSlice.matches:
        final subscription = _matchesSubscription;
        _matchesSubscription = null;
        await subscription?.cancel();
    }
  }

  Future<void> _cancelLifecycle({required bool clearActiveLeague}) async {
    for (final timer in _retryTimers.values) {
      timer?.cancel();
    }
    for (final slice in TournamentDetailSlice.values) {
      _retryTimers[slice] = null;
    }
    final league = _leagueSubscription;
    final stats = _statsSubscription;
    final matches = _matchesSubscription;
    _leagueSubscription = null;
    _statsSubscription = null;
    _matchesSubscription = null;
    if (clearActiveLeague) _activeLeagueId = null;
    await Future.wait<void>([
      if (league != null) league.cancel(),
      if (stats != null) stats.cancel(),
      if (matches != null) matches.cancel(),
    ]);
  }

  Future<void> _cleanupDeletedLeagueLifecycle() async {
    try {
      await _cancelLifecycle(clearActiveLeague: true);
    } catch (error) {
      debugPrint('Unable to clean up deleted league subscriptions: $error');
    }
  }

  void _terminateDeletedLeague(Emitter<TournamentDetailState> emit) {
    if (_isClosing || isClosed || emit.isDone) return;
    _lifecycleEpoch++;
    _leagueSnapshotSequence++;
    emit(
      state.copyWith(
        clearLeague: true,
        leagueDeleted: true,
        leagueSliceStatus: DetailSliceStatus.failed,
        errorMessage: appText.commonErrorTitle,
      ),
    );
    _groupsById.clear();
    _resolvedGroupIds.clear();
    _loadingGroups.clear();
    _loadingUserEpochById.clear();
    // A synchronous Firestore/controller callback can keep a subscription's
    // cancel Future pending until the current delivery unwinds. Publish the
    // terminal state first so navigation is never coupled to cancellation.
    // The cleanup call still clears all owned references/timers immediately,
    // while this guarded Future handles any delayed cancellation error.
    unawaited(_cleanupDeletedLeagueLifecycle());
  }

  void _resetRetryState() {
    for (final slice in TournamentDetailSlice.values) {
      _retryAttempts[slice] = 0;
      _retryTimers[slice]?.cancel();
      _retryTimers[slice] = null;
    }
  }

  Future<void> _onUpdateMatch(
    UpdateEsportMatch event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (state.league == null ||
        state.pendingMatchIds.contains(event.match.id)) {
      return;
    }

    final pending = Set<String>.of(state.pendingMatchIds)..add(event.match.id);
    final errors = Map<String, String>.of(state.matchErrorsById)
      ..remove(event.match.id);
    emit(state.copyWith(pendingMatchIds: pending, matchErrorsById: errors));
    try {
      await _leagueRepository.updateMatchAtomically(event.match);
      final nextPending = Set<String>.of(state.pendingMatchIds)
        ..remove(event.match.id);
      emit(state.copyWith(pendingMatchIds: nextPending));
      showToast(appText.tournamentMatchUpdated);
    } on ConcurrentMatchUpdateException {
      final nextPending = Set<String>.of(state.pendingMatchIds)
        ..remove(event.match.id);
      final nextErrors = Map<String, String>.of(state.matchErrorsById)
        ..[event.match.id] = appText.tournamentMatchConcurrentUpdate;
      emit(
        state.copyWith(
          pendingMatchIds: nextPending,
          matchErrorsById: nextErrors,
        ),
      );
      showToast(appText.tournamentMatchConcurrentUpdate);
    } catch (_) {
      final nextPending = Set<String>.of(state.pendingMatchIds)
        ..remove(event.match.id);
      final nextErrors = Map<String, String>.of(state.matchErrorsById)
        ..[event.match.id] = appText.commonErrorTitle;
      emit(
        state.copyWith(
          pendingMatchIds: nextPending,
          matchErrorsById: nextErrors,
        ),
      );
    }
  }

  Future<void> _onRecomputeStats(
    RecomputeStats event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _leagueRepository.recomputeLeagueStats(leagueId);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentStatsSynced);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
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
      await _leagueRepository.updateLeague(updated);
      emit(state.copyWith(viewStatus: ViewStatus.success, league: updated));
      showToast(appText.tournamentCostUpdated);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onLeagueDeleted(
    LeagueDeleted event,
    Emitter<TournamentDetailState> emit,
  ) {
    _terminateDeletedLeague(emit);
  }

  Future<void> _onCreateCustomMatch(
    CreateCustomMatch event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (state.viewStatus == ViewStatus.loading) return;
    final leagueId = state.league?.id;
    if (leagueId == null) return;
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
      await _leagueRepository.createCustomMatch(match);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentCustomMatchCreated);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteMatch(
    DeleteEsportMatch event,
    Emitter<TournamentDetailState> emit,
  ) async {
    if (state.league == null) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _leagueRepository.deleteMatch(event.match);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentMatchDeleted);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onInactiveLeague(
    InactiveLeague event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final league = state.league;
    if (league == null) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _leagueRepository.inactiveLeague(league);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentDeleted);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onChangeLeagueStatus(
    ChangeLeagueStatus event,
    Emitter<TournamentDetailState> emit,
  ) {
    emit(
      state.copyWith(
        league: state.league?.copyWith(status: event.status.value),
      ),
    );
  }

  Future<void> _onSubmitLeagueStatus(
    SubmitLeagueStatus event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final league = state.league;
    if (league == null) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _leagueRepository.updateLeague(league);
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentStatusUpdated);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAddParticipant(
    AddParticipant event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _leagueRepository.addParticipant(
        leagueId: leagueId,
        userId: event.userId,
      );
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentPlayerAdded);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAddMultipleParticipants(
    AddMultipleParticipants event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null || event.userIds.isEmpty) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _leagueRepository.addMultipleParticipants(
        leagueId: leagueId,
        userIds: event.userIds,
      );
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentPlayersAdded(event.userIds.length));
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
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
        .where((participant) => participant.groupId == event.groupId)
        .map((participant) => participant.userId)
        .toList(growable: false);
    if (teamIds.length < 2) {
      showToast(appText.tournamentGroupRoundMinimum);
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _leagueRepository.generateGroupRound(
        leagueId: leagueId,
        groupId: event.groupId,
        teamIds: teamIds,
      );
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentRoundCreated);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onGenerateRound(
    GenerateRound event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final leagueId = state.league?.id;
    if (leagueId == null ||
        state.participants.length < 2 ||
        state.viewStatus == ViewStatus.loading) {
      return;
    }
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _leagueRepository.generateRound(
        leagueId: leagueId,
        teamIds: state.participants
            .map((participant) => participant.userId)
            .toList(growable: false),
      );
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentRoundCreated);
    } on RoundTooLargeException catch (error) {
      emit(state.copyWith(viewStatus: ViewStatus.initial));
      showToast(appText.tournamentRoundTooLarge(error.maxParticipants));
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
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
      await _leagueRepository.generateCupBracket(
        leagueId: leagueId,
        seededTeamIds: event.seededTeamIds,
      );
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentBracketCreated);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
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
      await _leagueRepository.generateFullTournament(
        leagueId: leagueId,
        groups: event.groups,
        advanceCount: event.advanceCount,
      );
      emit(state.copyWith(viewStatus: ViewStatus.success));
      showToast(appText.tournamentFullCreated);
    } catch (error) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Debug-only audit: recompute stats from the finished matches and compare
  /// them with the streamed standings documents.
  void _auditStats(
    GNEsportLeague? league,
    List<GNEsportLeagueStat> participants,
    List<GNEsportMatch> matches,
  ) {
    if (!kDebugMode || !_enableStatsAudit) return;
    final tag =
        '[AUDIT][${league?.name.isNotEmpty == true ? league!.name : league?.id ?? "?"}]';
    final finished = matches.where((match) => match.isFinished).toList();
    debugPrint(
      '$tag matches=${matches.length} finished=${finished.length} '
      'participants=${participants.length}',
    );

    final computed = <String, _AuditTotals>{
      for (final participant in participants)
        participant.userId: _AuditTotals(),
    };
    final orphanMatches = <GNEsportMatch>[];
    for (final match in finished) {
      final homeScore = match.homeScore;
      final awayScore = match.awayScore;
      if (homeScore == null || awayScore == null) continue;
      final home = computed[match.homeTeamId];
      final away = computed[match.awayTeamId];
      if (home == null || away == null) orphanMatches.add(match);
      home?.add(scoredFor: homeScore, scoredAgainst: awayScore);
      away?.add(scoredFor: awayScore, scoredAgainst: homeScore);
    }

    var mismatch = orphanMatches.isNotEmpty;
    for (final participant in participants) {
      final total = computed[participant.userId]!;
      final matches =
          participant.matchesPlayed == total.matchesPlayed &&
          participant.goals == total.goalsFor &&
          participant.goalsConceded == total.goalsAgainst &&
          participant.wins == total.wins &&
          participant.draws == total.draws &&
          participant.losses == total.losses;
      mismatch = mismatch || !matches;
    }
    debugPrint('$tag ${mismatch ? "stats mismatch" : "stats consistent"}');
  }

  @override
  Future<void> close() async {
    if (isClosed) return;
    _isClosing = true;
    _lifecycleEpoch++;
    _leagueSnapshotSequence++;
    await _cancelLifecycle(clearActiveLeague: true);
    _groupsById.clear();
    _resolvedGroupIds.clear();
    _loadingGroups.clear();
    _loadingUserEpochById.clear();
    await super.close();
  }
}

class _SourcedLeagueSnapshotReceived extends LeagueSnapshotReceived {
  final String sourceLeagueId;
  final int generation;
  final int sequence;

  const _SourcedLeagueSnapshotReceived(
    this.sourceLeagueId,
    this.generation,
    this.sequence,
    super.league,
  );

  @override
  List<Object?> get props => [sourceLeagueId, generation, sequence, league];
}

class _SourcedStatsSnapshotReceived extends StatsSnapshotReceived {
  final String sourceLeagueId;
  final int generation;

  const _SourcedStatsSnapshotReceived(
    this.sourceLeagueId,
    this.generation,
    super.stats,
  );

  @override
  List<Object?> get props => [sourceLeagueId, generation, stats];
}

class _SourcedMatchesSnapshotReceived extends MatchesSnapshotReceived {
  final String sourceLeagueId;
  final int generation;

  const _SourcedMatchesSnapshotReceived(
    this.sourceLeagueId,
    this.generation,
    super.matches,
  );

  @override
  List<Object?> get props => [sourceLeagueId, generation, matches];
}

class _SourcedDetailStreamFailed extends DetailStreamFailed {
  final String sourceLeagueId;
  final int generation;

  const _SourcedDetailStreamFailed(
    this.sourceLeagueId,
    this.generation,
    super.slice,
    super.error,
  );

  @override
  List<Object?> get props => [sourceLeagueId, generation, slice, error];
}

class _DetailStreamCompleted extends TournamentDetailEvent {
  final String sourceLeagueId;
  final int generation;
  final TournamentDetailSlice slice;

  const _DetailStreamCompleted(
    this.sourceLeagueId,
    this.generation,
    this.slice,
  );

  @override
  List<Object?> get props => [sourceLeagueId, generation, slice];
}

class _AuditTotals {
  int matchesPlayed = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;

  void add({required int scoredFor, required int scoredAgainst}) {
    matchesPlayed++;
    goalsFor += scoredFor;
    goalsAgainst += scoredAgainst;
    if (scoredFor > scoredAgainst) {
      wins++;
    } else if (scoredFor == scoredAgainst) {
      draws++;
    } else {
      losses++;
    }
  }
}
