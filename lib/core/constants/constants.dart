import 'package:flutter/material.dart';

const double kDefaultPadding = 16;

const Widget kDefaultLoading = Padding(
  padding: EdgeInsets.symmetric(vertical: 8),
  child: FittedBox(
    child: CircularProgressIndicator(
      color: Colors.white,
    ),
  ),
);

const TextStyle kDefaultBoldWhite = TextStyle(
  fontSize: 16,
  color: Colors.white,
  fontWeight: FontWeight.bold,
  letterSpacing: 1,
);

const boldTextStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 24,
);

const MaterialColor primaryBlack = MaterialColor(
  _blackPrimaryValue,
  <int, Color>{
    50: Color(0xFF000000),
    100: Color(0xFF000000),
    200: Color(0xFF000000),
    300: Color(0xFF000000),
    400: Color(0xFF000000),
    500: Color(_blackPrimaryValue),
    600: Color(0xFF000000),
    700: Color(0xFF000000),
    800: Color(0xFF000000),
    900: Color(0xFF000000),
  },
);
const int _blackPrimaryValue = 0xFF000000;

const String playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.november.game_note';
const String appStoreUrl = 'https://apps.apple.com/app/game-note/id6443969710';
