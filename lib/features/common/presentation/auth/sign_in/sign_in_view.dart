import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../community/presentation/widgets/custom_button.dart';
import 'bloc/sign_in_bloc.dart';

class SignInView extends StatelessWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) async {
        if (state.status == SignInStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              state.error,
              //textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.grey,
          ));
        }
        if (state.status == SignInStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              "Sign in successfully",
              //textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.grey,
          ));
        }
        if (state.status == SignInStatus.verify) {
          final response = await Navigator.of(context).pushNamed('/verify');
          if (kDebugMode) {
            print(response);
          }
          if (response == true) {
            // push to home
          } else {
            // do nothing
          }
        }
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
            const Text(
              'Đăng nhập bằng SĐT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.mobile_friendly),
                  const SizedBox(width: 8),
                  const Text(
                    '+84',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.black12,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Số điện thoại',
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        context
                            .read<SignInBloc>()
                            .add(SignInPhoneChanged(value));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            const SizedBox(height: kDefaultPadding),
            BlocBuilder<SignInBloc, SignInState>(
              builder: (context, state) => CustomButton(
                paddingHorizontal: 16,
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.read<SignInBloc>().add(SignInSubmitted());
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
