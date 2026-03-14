import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/profile/update/bloc/update_profile_bloc.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

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
                padding: const EdgeInsets.all(24),
                children: [
                  TextField(
                    textInputAction: TextInputAction.next,
                    controller: _displayNameController,
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Họ và tên',
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneNumberController,
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Số điện thoại',
                      prefixIcon: Icons.phone_outlined,
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: state.viewStatus == ViewStatus.loading
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              context
                                  .read<UpdateProfileBloc>()
                                  .add(SubmittUpdateProfile(
                                    userDisplayName:
                                        _displayNameController.text,
                                    userPhoneNumber:
                                        _phoneNumberController.text,
                                    userEmail: _emailController.text,
                                  ));
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cập nhật',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
