import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:game_note/app.dart';
import 'package:game_note/injection_container.dart' as di;
import 'package:game_note/simple_bloc_observer.dart';

import 'core/database/database_manager.dart';

var dataFile = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await di.getIt<DatabaseManager>().open();
  Bloc.observer = SimpleBlocObserver();

  runApp(App());
}
