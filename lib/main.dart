import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/app.dart';
import 'package:game_note/injection_container.dart' as di;

import 'features/offline/data/database/database_manager.dart';
import 'features/common/presentation/bloc/app_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

var dataFile = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();
  await di.getIt<DatabaseManager>().open();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AppBloc>()),
      ],
      child: App(),
    ),
  );
}
