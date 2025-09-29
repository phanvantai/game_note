import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/ultils.dart';

import '../../../core/constants/constants.dart';
import '../auth_custom_button.dart';
import 'bloc/sign_in_bloc.dart';

class SignInView extends StatefulWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) async {
        if (state.status == SignInStatus.error) {
          showToast(state.error);
        }
        if (state.status == SignInStatus.success) {
          showToast("Đăng nhập thành công");
        }
        // if (state.status == SignInStatus.verify) {
        //   final response =
        //       await Navigator.of(context).pushNamed(Routing.verify);
        //   if (kDebugMode) {
        //     print(response);
        //   }
        //   if (response == true) {
        //     // push to home
        //   } else {
        //     // do nothing
        //   }
        // }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white70,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // const Text(
            //   'Đăng nhập bằng SĐT',
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.normal,
            //   ),
            // ),const SizedBox(height: kDefaultPadding),
            // Container(
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.black12),
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: Row(
            //     children: [
            //       const SizedBox(width: 8),
            //       const Icon(Icons.mobile_friendly),
            //       const SizedBox(width: 8),
            //       const Text(
            //         '+84',
            //         style: TextStyle(color: Colors.black),
            //       ),
            //       const SizedBox(width: 8),
            //       Container(
            //         height: 24,
            //         width: 1,
            //         color: Colors.black12,
            //       ),
            //       const SizedBox(width: 8),
            //       Expanded(
            //         child: TextField(
            //           decoration: const InputDecoration(
            //             hintText: 'Số điện thoại',
            //             border: InputBorder.none,
            //           ),
            //           keyboardType: TextInputType.phone,
            //           textInputAction: TextInputAction.done,
            //           onChanged: (value) {
            //             context
            //                 .read<SignInBloc>()
            //                 .add(SignInPhoneChanged(value));
            //           },
            //         ),
            //       ),
            //       const SizedBox(width: 8),
            //     ],
            //   ),
            // ),
            const Text(
              'Đăng nhập với email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            BlocBuilder<SignInBloc, SignInState>(
              buildWhen: (previous, current) => previous.email != current.email,
              builder: (context, state) {
                return Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                        errorText:
                            state.emailError.isEmpty ? null : state.emailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        context.read<SignInBloc>().add(EmailChanged(value));
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: kDefaultPadding),
            // password
            BlocBuilder<SignInBloc, SignInState>(
              buildWhen: (previous, current) =>
                  previous.password != current.password,
              builder: (context, state) => TextFormField(
                validator: (value) =>
                    state.passwordError.isEmpty ? null : state.passwordError,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                    icon: showPassword
                        ? const Icon(Icons.remove_red_eye)
                        : const Icon(Icons.remove_red_eye_outlined),
                  ),
                  errorText:
                      state.passwordError.isEmpty ? null : state.passwordError,
                ),
                keyboardType: TextInputType.visiblePassword,
                obscureText: !showPassword,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  context.read<SignInBloc>().add(PasswordChanged(value));
                },
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            BlocBuilder<SignInBloc, SignInState>(
              builder: (context, state) => AuthCustomButton(
                paddingHorizontal: 16,
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.read<SignInBloc>().add(EmailSignInSubmitted());
                },
                child: state.status == SignInStatus.loading
                    ? kDefaultLoading
                    : const Text('TIẾP TỤC'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
