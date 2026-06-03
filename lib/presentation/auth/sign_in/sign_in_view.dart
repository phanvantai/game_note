import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/l10n/l10n.dart';

import 'bloc/sign_in_bloc.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) async {
        if (state.status == SignInStatus.error) {
          showToast(state.error);
        }
        if (state.status == SignInStatus.success) {
          showToast(_successMessage(context, state.mode));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<SignInBloc, SignInState>(
            buildWhen: (previous, current) => previous.mode != current.mode,
            builder: (context, state) {
              final modeDescription = _modeDescription(context, state.mode);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _modeTitle(context, state.mode),
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (modeDescription != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      modeDescription,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          BlocBuilder<SignInBloc, SignInState>(
            buildWhen: (previous, current) =>
                previous.email != current.email ||
                previous.emailError != current.emailError,
            builder: (context, state) {
              return TextField(
                decoration: InputDecoration(
                  hintText: context.l10n.authEmailHint,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.secondary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  errorText: state.emailError.isEmpty ? null : state.emailError,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  context.read<SignInBloc>().add(EmailChanged(value));
                },
              );
            },
          ),
          BlocBuilder<SignInBloc, SignInState>(
            buildWhen: (previous, current) =>
                previous.mode != current.mode ||
                previous.password != current.password ||
                previous.passwordError != current.passwordError,
            builder: (context, state) {
              if (state.mode == AuthFormMode.resetPassword) {
                return const SizedBox(height: 20);
              }

              return Column(
                children: [
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: context.l10n.authPasswordHint,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        tooltip: showPassword
                            ? 'Hide password'
                            : 'Show password',
                        visualDensity: VisualDensity.standard,
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.secondary,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.error,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.error,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      errorText: state.passwordError.isEmpty
                          ? null
                          : state.passwordError,
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: !showPassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      context.read<SignInBloc>().add(PasswordChanged(value));
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
          BlocBuilder<SignInBloc, SignInState>(
            builder: (context, state) => SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: state.status == SignInStatus.loading
                    ? null
                    : () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        context.read<SignInBloc>().add(AuthFormSubmitted());
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: colorScheme.secondary.withValues(
                    alpha: 0.6,
                  ),
                ),
                child: state.status == SignInStatus.loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onSecondary,
                          ),
                        ),
                      )
                    : Text(
                        _submitText(context, state.mode),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          BlocBuilder<SignInBloc, SignInState>(
            buildWhen: (previous, current) => previous.mode != current.mode,
            builder: (context, state) {
              return _modeSwitcher(context, state.mode);
            },
          ),
        ],
      ),
    );
  }

  Widget _modeSwitcher(BuildContext context, AuthFormMode mode) {
    switch (mode) {
      case AuthFormMode.signIn:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextButton(
              onPressed: () {
                context.read<SignInBloc>().add(
                  AuthFormModeChanged(AuthFormMode.resetPassword),
                );
              },
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 10,
                ),
              ),
              child: Text(_forgotPasswordText(context)),
            ),
            const SizedBox(height: 2),
            _secondaryActionLine(
              context,
              label: _switchToRegisterPrompt(context),
              actionText: context.l10n.authRegister,
              onPressed: () {
                context.read<SignInBloc>().add(
                  AuthFormModeChanged(AuthFormMode.register),
                );
              },
            ),
          ],
        );
      case AuthFormMode.register:
        return _secondaryActionLine(
          context,
          label: _switchToSignInPrompt(context),
          actionText: context.l10n.authSignIn,
          onPressed: () {
            context.read<SignInBloc>().add(
              AuthFormModeChanged(AuthFormMode.signIn),
            );
          },
        );
      case AuthFormMode.resetPassword:
        return _secondaryActionLine(
          context,
          label: _backToSignInPrompt(context),
          actionText: context.l10n.authSignIn,
          onPressed: () {
            context.read<SignInBloc>().add(
              AuthFormModeChanged(AuthFormMode.signIn),
            );
          },
        );
    }
  }

  Widget _secondaryActionLine(
    BuildContext context, {
    required String label,
    required String actionText,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          child: Text(
            actionText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  bool _isVietnamese(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'vi';
  }

  String _forgotPasswordText(BuildContext context) {
    return _isVietnamese(context) ? 'Quên mật khẩu?' : 'Forgot password?';
  }

  String _switchToRegisterPrompt(BuildContext context) {
    return _isVietnamese(context) ? 'Chưa có tài khoản?' : 'No account yet?';
  }

  String _switchToSignInPrompt(BuildContext context) {
    return _isVietnamese(context)
        ? 'Đã có tài khoản?'
        : 'Already have an account?';
  }

  String _backToSignInPrompt(BuildContext context) {
    return _isVietnamese(context) ? 'Quay lại đăng nhập' : 'Back to sign in';
  }

  String _modeTitle(BuildContext context, AuthFormMode mode) {
    return switch (mode) {
      AuthFormMode.signIn => context.l10n.authSignIn,
      AuthFormMode.register => context.l10n.authRegister,
      AuthFormMode.resetPassword => context.l10n.authForgotPassword,
    };
  }

  String? _modeDescription(BuildContext context, AuthFormMode mode) {
    return switch (mode) {
      AuthFormMode.signIn => null,
      AuthFormMode.register =>
        _isVietnamese(context)
            ? 'Tạo tài khoản mới để tiếp tục.'
            : 'Create a new account.',
      AuthFormMode.resetPassword =>
        _isVietnamese(context)
            ? 'Nhập email để nhận link đặt lại mật khẩu.'
            : 'Enter your email and get a reset link.',
    };
  }

  String _submitText(BuildContext context, AuthFormMode mode) {
    return switch (mode) {
      AuthFormMode.signIn => context.l10n.authSignIn,
      AuthFormMode.register => context.l10n.authRegister,
      AuthFormMode.resetPassword => context.l10n.authResetPasswordSubmit,
    };
  }

  String _successMessage(BuildContext context, AuthFormMode mode) {
    return switch (mode) {
      AuthFormMode.signIn => context.l10n.authSignInSuccess,
      AuthFormMode.register => context.l10n.authSignInSuccess,
      AuthFormMode.resetPassword => context.l10n.authResetPasswordSent,
    };
  }
}
