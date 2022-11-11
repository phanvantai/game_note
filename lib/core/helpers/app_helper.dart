import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/app/bloc/app_bloc.dart';

import 'shared_preferences_helper.dart';

AppStatus get appStatus {
  var abc = getIt<SharedPreferencesHelper>().isCommunityMode;
  switch (abc) {
    case true:
      return AppStatus.community;
    case false:
      return AppStatus.offline;
    default:
      return AppStatus.none;
  }
}

setAppStatus(AppStatus status) {
  getIt<SharedPreferencesHelper>().setCommunityMode(status.isCommunity);
}
