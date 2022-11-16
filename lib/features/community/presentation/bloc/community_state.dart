part of 'community_bloc.dart';

enum CommunityStatus { none, loggedIn }

class CommunityState extends Equatable {
  final CommunityStatus status;

  const CommunityState({
    this.status = CommunityStatus.none,
  });

  CommunityState copyWith({
    CommunityStatus? status,
  }) {
    return CommunityState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [status];
}
