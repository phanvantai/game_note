import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/app.dart';
import 'package:game_note/injection_container.dart' as di;
import 'package:game_note/simple_bloc_observer.dart';

import 'core/database/database_manager.dart';
import 'features/common/presentation/bloc/app_bloc.dart';

var dataFile = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await di.getIt<DatabaseManager>().open();
  Bloc.observer = SimpleBlocObserver();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppBloc()),
      ],
      child: App(),
    ),
  );
}
