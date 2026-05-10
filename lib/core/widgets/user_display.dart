import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

String displayNameOrFallback(GNUser? user, {String fallback = 'Người chơi'}) {
  if (user == null) return fallback;
  return user.effectiveDisplayName;
}
