part of 'change_password_bloc.dart';

class ChangePasswordState extends Equatable {
  final ViewStatus viewStatus;
  final String oldPassword;
  final String errorOldPassword;
  final String newPassword;
  final String errorNewPassword;
  final String confirmPassword;
  final String errorConfirmPassword;
  final String errorMessage;

  const ChangePasswordState({
    this.viewStatus = ViewStatus.initial,
    this.errorMessage = '',
    this.oldPassword = '',
    this.errorOldPassword = '',
    this.newPassword = '',
    this.errorNewPassword = '',
    this.confirmPassword = '',
    this.errorConfirmPassword = '',
  });

  ChangePasswordState copyWith({
    ViewStatus? viewStatus,
    String? errorMessage,
    String? oldPassword,
    String? errorOldPassword,
    String? newPassword,
    String? errorNewPassword,
    String? confirmPassword,
    String? errorConfirmPassword,
  }) {
    return ChangePasswordState(
      viewStatus: viewStatus ?? this.viewStatus,
      errorMessage: errorMessage ?? '',
      oldPassword: oldPassword ?? this.oldPassword,
      errorOldPassword: errorOldPassword ?? this.errorOldPassword,
      newPassword: newPassword ?? this.newPassword,
      errorNewPassword: errorNewPassword ?? this.errorNewPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      errorConfirmPassword: errorConfirmPassword ?? this.errorConfirmPassword,
    );
  }

  bool get notValidForm =>
      (errorConfirmPassword.isNotEmpty ||
          errorOldPassword.isNotEmpty ||
          errorNewPassword.isNotEmpty) ||
      (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty);

  @override
  List<Object?> get props => [
        viewStatus,
        errorMessage,
        oldPassword,
        errorOldPassword,
        newPassword,
        errorNewPassword,
        confirmPassword,
        errorConfirmPassword,
      ];
}
