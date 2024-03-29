import 'package:flutter/material.dart';
import 'package:game_note/features/common/presentation/app_view.dart';

class Routing {
  static const String app = '/';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    return fadeThrough(settings, (context) {
      switch (settings.name) {
        case Routing.app:
          return const AppView();
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
        // const begin = Offset(1.0, 0.0);
        // const end = Offset.zero;
        // final tween = Tween(begin: begin, end: end);
        // final offsetAnimation = animation.drive(tween);

        //return SlideTransition(position: offsetAnimation, child: child);

        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
