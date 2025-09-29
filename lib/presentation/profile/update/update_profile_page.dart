import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/profile/update/bloc/update_profile_bloc.dart';
import 'package:pes_arena/presentation/profile/update/update_profile_view.dart';

import '../../../firebase/firestore/user/gn_user.dart';

class UpdateProfilePage extends StatelessWidget {
  const UpdateProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // get user from arguments
    final user = ModalRoute.of(context)!.settings.arguments as GNUser?;

    return BlocProvider(
      create: (_) => UpdateProfileBloc(getIt(), user),
      child: const UpdateProfileView(),
    );
  }
}
