import 'package:flutter/material.dart';
import 'package:game_note/core/constants/constants.dart';
import 'package:game_note/presentation/home_view.dart';

class App extends MaterialApp {
  App({Key? key})
      : super(
          key: key,
          home: const HomeView(),
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            primarySwatch: primaryBlack,
            primaryColor: Colors.black,
            brightness: Brightness.dark,
            backgroundColor: Colors.black,
            dividerColor: Colors.black12,
            colorScheme: ColorScheme.fromSwatch(
                    primarySwatch: primaryBlack,
                    primaryColorDark: Colors.black,
                    brightness: Brightness.dark)
                .copyWith(secondary: Colors.white),
          ),
        );
}
