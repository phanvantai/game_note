import 'package:flutter/material.dart';
import 'package:game_note/core/constants/constants.dart';

import 'routing.dart';

class App extends MaterialApp {
  App({Key? key})
      : super(
          key: key,
          onGenerateRoute: Routing.generateRoute,
          initialRoute: Routing.app,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            primarySwatch: primaryBlack,
            primaryColor: Colors.black,
            brightness: Brightness.dark,
            dividerColor: Colors.black12,
            colorScheme: ColorScheme.fromSwatch(
              backgroundColor: Colors.black,
              primarySwatch: primaryBlack,
              brightness: Brightness.dark,
            ).copyWith(secondary: Colors.white),
          ),
        );
}
