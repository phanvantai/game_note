import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/presentation/profile/change_password/bloc/change_password_bloc.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({Key? key}) : super(key: key);

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Đổi mật khẩu'),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(32),
              children: [
                TextField(
                  obscureText: _isObscureOld,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) => context
                      .read<ChangePasswordBloc>()
                      .add(OldPasswordChanged(value)),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscureOld = !_isObscureOld;
                        });
                      },
                      icon: Icon(_isObscureOld
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                    // border: const OutlineInputBorder(),
                    labelText: 'Mật khẩu hiện tại',
                    errorText: state.errorOldPassword.isEmpty
                        ? null
                        : state.errorOldPassword,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: _isObscureNew,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) => context
                      .read<ChangePasswordBloc>()
                      .add(NewPasswordChanged(value)),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscureNew = !_isObscureNew;
                        });
                      },
                      icon: Icon(_isObscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                    // border: const OutlineInputBorder(),
                    labelText: 'Mật khẩu mới',
                    errorText: state.errorNewPassword.isEmpty
                        ? null
                        : state.errorNewPassword,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: _isObscureConfirm,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) => context
                      .read<ChangePasswordBloc>()
                      .add(ConfirmPasswordChanged(value)),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscureConfirm = !_isObscureConfirm;
                        });
                      },
                      icon: Icon(_isObscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                    // border: const OutlineInputBorder(),
                    labelText: 'Xác nhận mật khẩu mới',
                    errorText: state.errorConfirmPassword.isEmpty
                        ? null
                        : state.errorConfirmPassword,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: !state.notValidForm
                      ? () {
                          FocusScope.of(context).unfocus();
                          context
                              .read<ChangePasswordBloc>()
                              .add(const ChangePasswordSubmitted());
                        }
                      : null,
                  child: const Text('Đổi mật khẩu'),
                ),
              ],
            ),
            if (state.viewStatus.isLoading) const LinearProgressIndicator(),
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
