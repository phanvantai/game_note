part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class SearchUser extends UserEvent {
  final String query;

  const SearchUser(this.query);

  @override
  List<Object?> get props => [query];
}
