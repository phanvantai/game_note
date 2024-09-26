import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'common/app_info.dart';

T randomObject<T>(List<T> list) {
  final random = Random();
  return list[random.nextInt(list.length)];
}

List<T> rotateList<T>(List<T> list) {
  if (list.length < 2) {
    return list;
  }
  list.insert(1, list.last);
  list.removeLast();
  return list;
}

List<Map<T, T>> createMaps<T>(List<T> list) {
  List<Map<T, T>> maps = [];
  for (int i = 0; i < list.length / 2; i++) {
    maps.add({list[i]: list[list.length - 1 - i]});
  }
  return maps;
}

/// Get the app information
Future<AppInfo> appInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return AppInfo(
    appName: packageInfo.appName,
    packageName: packageInfo.packageName,
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );
}

// Show a snackbar with a message
void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 2),
    backgroundColor: Colors.black54,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// Show toast message
void showToast(
  String message, {
  ToastGravity gravity = ToastGravity.BOTTOM,
}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: gravity,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black54,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
