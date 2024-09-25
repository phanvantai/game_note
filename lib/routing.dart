import 'package:flutter/material.dart';
import 'package:game_note/offline/presentation/offline_view.dart';
import 'package:game_note/presentation/app/app_view.dart';
import 'package:game_note/presentation/auth/verify/verify_page.dart';
import 'package:game_note/presentation/team/create_team/create_team_page.dart';

import 'presentation/esport/groups/group_detail/group_detail_page.dart';
import 'presentation/esport/tournament/tournament_detail/tournament_detail_page.dart';
import 'presentation/profile/update/update_profile_page.dart';

class Routing {
  static const String app = '/';
  static const String offline = '/offline';
  static const String offlineLeague = '/offline/league';
  static const String league = '/league';
  static const String verify = '/verify';

  // community
  static const String createTeam = '/create-team';

  // esport
  static const String groupDetail = '/group-detail';
  static const String tournamentDetail = '/tournament-detail';

  // profile
  static const String updateProfile = '/update-profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    return fadeThrough(settings, (context) {
      switch (settings.name) {
        case Routing.app:
          return const AppView();
        case Routing.offline:
          return const OfflineView();
        case Routing.verify:
          return const VerifyPage();
        case Routing.createTeam:
          return const CreateTeamPage();
        // esport
        case Routing.groupDetail:
          return const GroupDetailPage();
        case Routing.tournamentDetail:
          return const TournamentDetailPage();

        // profile
        case Routing.updateProfile:
          return const UpdateProfilePage();
        default:
          return const AppView();
      }
    });
  }

  static Route<T> fadeThrough<T>(RouteSettings settings, WidgetBuilder page,
      {int duration = 200}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: Duration(milliseconds: duration),
      pageBuilder: (context, animation, secondaryAnimation) => page(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);

        // return FadeTransition(
        //   opacity: animation,
        //   child: child,
        // );
      },
    );
  }
}
