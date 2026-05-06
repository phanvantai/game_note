part of 'group_detail_bloc.dart';

class GroupDetailState extends Equatable {
  final ViewStatus viewStatus;
  final List<GNUser> members;
  final GNEsportGroup group;
  final String errorMessage;
  final List<GNEsportLeague> leagues;
  final ViewStatus leaguesStatus;
  final ViewStatus replaceParticipantStatus;
  final String replaceErrorMessage;
  final String? currentUserId;
  final ViewStatus overviewStatus;
  final GroupOverview? overview;
  final String overviewErrorMessage;
  final bool overviewIsStale;

  const GroupDetailState({
    this.viewStatus = ViewStatus.initial,
    this.members = const [],
    required this.group,
    this.errorMessage = '',
    this.leagues = const [],
    this.leaguesStatus = ViewStatus.initial,
    this.replaceParticipantStatus = ViewStatus.initial,
    this.replaceErrorMessage = '',
    this.currentUserId,
    this.overviewStatus = ViewStatus.initial,
    this.overview,
    this.overviewErrorMessage = '',
    this.overviewIsStale = false,
  });

  GroupDetailState copyWith({
    ViewStatus? viewStatus,
    List<GNUser>? members,
    GNEsportGroup? group,
    String? errorMessage,
    List<GNEsportLeague>? leagues,
    ViewStatus? leaguesStatus,
    ViewStatus? replaceParticipantStatus,
    String? replaceErrorMessage,
    String? currentUserId,
    ViewStatus? overviewStatus,
    GroupOverview? overview,
    String? overviewErrorMessage,
    bool? overviewIsStale,
  }) {
    return GroupDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      members: members ?? this.members,
      group: group ?? this.group,
      errorMessage: errorMessage ?? '',
      leagues: leagues ?? this.leagues,
      leaguesStatus: leaguesStatus ?? this.leaguesStatus,
      replaceParticipantStatus:
          replaceParticipantStatus ?? this.replaceParticipantStatus,
      replaceErrorMessage: replaceErrorMessage ?? '',
      currentUserId: currentUserId ?? this.currentUserId,
      overviewStatus: overviewStatus ?? this.overviewStatus,
      overview: overview ?? this.overview,
      overviewErrorMessage: overviewErrorMessage ?? this.overviewErrorMessage,
      overviewIsStale: overviewIsStale ?? this.overviewIsStale,
    );
  }

  bool get isOwner => group.ownerId == currentUserId;

  bool get currentUserIsMember =>
      members.any((m) => m.id == currentUserId);

  @override
  List<Object?> get props => [
        viewStatus,
        members,
        group,
        errorMessage,
        leagues,
        leaguesStatus,
        replaceParticipantStatus,
        replaceErrorMessage,
        currentUserId,
        overviewStatus,
        overview,
        overviewErrorMessage,
        overviewIsStale,
      ];
}
