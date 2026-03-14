import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/profile/change_password/bloc/change_password_bloc.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({Key? key}) : super(key: key);

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  Widget _buildVisibilityToggle(bool isObscure, VoidCallback onToggle) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Đổi mật khẩu'),
        ),
        body: Column(
          children: [
            if (state.viewStatus.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextField(
                    obscureText: _isObscureOld,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => context
                        .read<ChangePasswordBloc>()
                        .add(OldPasswordChanged(value)),
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Mật khẩu hiện tại',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _buildVisibilityToggle(
                        _isObscureOld,
                        () => setState(() => _isObscureOld = !_isObscureOld),
                      ),
                      errorText: state.errorOldPassword.isEmpty
                          ? null
                          : state.errorOldPassword,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    obscureText: _isObscureNew,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => context
                        .read<ChangePasswordBloc>()
                        .add(NewPasswordChanged(value)),
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Mật khẩu mới',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _buildVisibilityToggle(
                        _isObscureNew,
                        () => setState(() => _isObscureNew = !_isObscureNew),
                      ),
                      errorText: state.errorNewPassword.isEmpty
                          ? null
                          : state.errorNewPassword,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    obscureText: _isObscureConfirm,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) => context
                        .read<ChangePasswordBloc>()
                        .add(ConfirmPasswordChanged(value)),
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Xác nhận mật khẩu mới',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _buildVisibilityToggle(
                        _isObscureConfirm,
                        () => setState(
                            () => _isObscureConfirm = !_isObscureConfirm),
                      ),
                      errorText: state.errorConfirmPassword.isEmpty
                          ? null
                          : state.errorConfirmPassword,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: !state.notValidForm
                          ? () {
                              FocusScope.of(context).unfocus();
                              context
                                  .read<ChangePasswordBloc>()
                                  .add(const ChangePasswordSubmitted());
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage, gravity: ToastGravity.TOP);
        }
        if (state.viewStatus == ViewStatus.success) {
          showToast('Đổi mật khẩu thành công', gravity: ToastGravity.TOP);
          Navigator.of(context).pop();
        }
      },
    );
  }
}
