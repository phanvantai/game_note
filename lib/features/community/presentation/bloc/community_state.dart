part of 'community_bloc.dart';

enum CommunityStatus { none, loggedIn }

class CommunityState extends Equatable {
  final CommunityStatus status;
  final UserModel? userModel;

  const CommunityState({
    this.status = CommunityStatus.none,
    this.userModel,
  });

  CommunityState copyWith({
    CommunityStatus? status,
    UserModel? userModel,
  }) {
    return CommunityState(
      status: status ?? this.status,
      userModel: userModel ?? this.userModel,
    );
  }

  @override
  List<Object?> get props => [status, userModel];
}
