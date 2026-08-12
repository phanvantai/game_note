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
