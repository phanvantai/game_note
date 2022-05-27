import 'package:game_note/core/database/database_manager.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerSingleton(DatabaseManager());
}
