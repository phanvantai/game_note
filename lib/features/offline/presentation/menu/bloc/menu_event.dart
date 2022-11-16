part of 'menu_bloc.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class SwitchThemeEvent extends MenuEvent {}

class MembersEvent extends MenuEvent {}

class ShowMenuEvent extends MenuEvent {}

class ExportDatabaseEvent extends MenuEvent {}

class ImportDatabaseEvetn extends MenuEvent {}

class SwitchFeatureEvent extends MenuEvent {}
