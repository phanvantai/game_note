import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/presentation/profile/update/bloc/update_profile_bloc.dart';

import '../../../core/common/view_status.dart';

class UpdateProfileView extends StatefulWidget {
  const UpdateProfileView({Key? key}) : super(key: key);

  @override
  State<UpdateProfileView> createState() => _UpdateProfileViewState();
}

class _UpdateProfileViewState extends State<UpdateProfileView> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final state = context.read<UpdateProfileBloc>().state;
    _displayNameController.text = state.user?.displayName ?? '';
    _phoneNumberController.text = state.user?.phoneNumber ?? '';
    _emailController.text = state.user?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateProfileBloc, UpdateProfileState>(
      listener: (context, state) {
        if (state.error.isNotEmpty) {
          showToast(state.error);
        }
        if (state.viewStatus == ViewStatus.success) {
          showToast('Cập nhật thông tin thành công');
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Cập nhật thông tin'),
        ),
        body: Column(
          children: [
            if (state.viewStatus == ViewStatus.loading)
              const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  TextField(
                    textInputAction: TextInputAction.next,
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Số điện thoại'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // submit update profile
                      context
                          .read<UpdateProfileBloc>()
                          .add(SubmittUpdateProfile(
                            userDisplayName: _displayNameController.text,
                            userPhoneNumber: _phoneNumberController.text,
                            userEmail: _emailController.text,
                          ));
                    },
                    child: const Text('Cập nhật'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
