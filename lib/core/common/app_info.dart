import 'package:equatable/equatable.dart';

/// App information
class AppInfo extends Equatable {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  @override
  List<Object?> get props => [appName, packageName, version, buildNumber];

  String get versionNumber => '$version ($buildNumber)';
}
