import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';
import 'package:pes_arena/presentation/profile/change_password/bloc/change_password_bloc.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: const SmartBackButton(),
          title: const Text('Đổi mật khẩu'),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.secondary.withValues(alpha: 0.16),
                Theme.of(context).scaffoldBackgroundColor,
                colorScheme.primary.withValues(alpha: 0.06),
              ],
              stops: const [0, 0.46, 1],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (state.viewStatus.isLoading)
                  const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _SecurityHero(),
                      const SizedBox(height: 16),
                      _SecurityFormCard(
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
                                () => setState(
                                  () => _isObscureOld = !_isObscureOld,
                                ),
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
                                () => setState(
                                  () => _isObscureNew = !_isObscureNew,
                                ),
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
                                  () => _isObscureConfirm = !_isObscureConfirm,
                                ),
                              ),
                              errorText: state.errorConfirmPassword.isEmpty
                                  ? null
                                  : state.errorConfirmPassword,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: !state.notValidForm
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  context.read<ChangePasswordBloc>().add(
                                    const ChangePasswordSubmitted(),
                                  );
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
        ),
      ),
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage, gravity: ToastGravity.TOP);
        }
        if (state.viewStatus == ViewStatus.success) {
          showToast('Đổi mật khẩu thành công', gravity: ToastGravity.TOP);
          context.smartBack();
        }
      },
    );
  }
}

class _SecurityHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.shield_outlined, color: colorScheme.onSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đổi mật khẩu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cập nhật mật khẩu để bảo vệ tài khoản.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityFormCard extends StatelessWidget {
  final List<Widget> children;

  const _SecurityFormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.48)),
      ),
      child: Column(children: children),
    );
  }
}
