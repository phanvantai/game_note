import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing.dart';

/// Web-safe "back" semantics for go_router routes.
///
/// On web, opening a URL directly seeds the router stack with exactly one
/// entry, so `context.pop()` becomes a no-op and the default AppBar back
/// arrow disappears entirely (Flutter checks `ModalRoute.canPop` before
/// rendering it). [smartBack] guarantees a working back action regardless
/// of how the user arrived: pop the previous route if there is one, else
/// go home.
extension SmartBackExt on BuildContext {
  void smartBack({String fallback = Routing.app}) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}

/// Drop-in replacement for the default AppBar back arrow that always
/// renders, and falls back to the home route on deep-linked entry.
class SmartBackButton extends StatelessWidget {
  final String? fallback;

  const SmartBackButton({super.key, this.fallback});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.smartBack(fallback: fallback ?? Routing.app),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
