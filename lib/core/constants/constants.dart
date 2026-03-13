import 'package:flutter/material.dart';

const double kDefaultPadding = 16;

Widget kDefaultLoading(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FittedBox(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

const String playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.november.game_note';
const String appStoreUrl = 'https://apps.apple.com/app/game-note/id6443969710';
