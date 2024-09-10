import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/profile/bloc/profile_bloc.dart';
import 'package:game_note/presentation/profile/profile_view.dart';

import '../../injection_container.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadProfileEvent()),
      child: const ProfileView(),
    );
  }
}
