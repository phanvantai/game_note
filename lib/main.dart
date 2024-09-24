import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/app.dart';
import 'package:game_note/injection_container.dart' as di;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase/messaging/gn_firebase_messaging.dart';
import 'offline/data/database/database_manager.dart';
import 'presentation/app/bloc/app_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

var dataFile = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await di.init();
  await di.getIt<DatabaseManager>().open();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AppBloc>()..add(InitApp())),
      ],
      child: App(),
    ),
  );
}
