part of 'menu_bloc.dart';

enum MenuStatus { menu, members }

extension MenuStatusX on MenuStatus {
  bool get isMenu => this == MenuStatus.menu;
  bool get isMember => this == MenuStatus.members;
}

class MenuState extends Equatable {
  final MenuStatus status;

  const MenuState({this.status = MenuStatus.menu});

  MenuState copyWith({MenuStatus? status}) {
    return MenuState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
