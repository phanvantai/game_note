import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';
import 'package:pes_arena/presentation/profile/update/bloc/update_profile_bloc.dart';

import '../../../core/common/view_status.dart';

class UpdateProfileView extends StatefulWidget {
  const UpdateProfileView({super.key});

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
          context.smartBack();
        }
      },
      builder: (context, state) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: const SmartBackButton(),
          title: const Text('Cập nhật thông tin'),
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
                if (state.viewStatus == ViewStatus.loading)
                  const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _FormHero(
                        icon: Icons.manage_accounts_outlined,
                        eyebrow: 'Profile setup',
                        title: 'Thông tin hiển thị',
                        subtitle: 'Cập nhật tên, số điện thoại và email.',
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: state.viewStatus == ViewStatus.loading
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  context.read<UpdateProfileBloc>().add(
                                    SubmittUpdateProfile(
                                      userDisplayName:
                                          _displayNameController.text,
                                      userPhoneNumber:
                                          _phoneNumberController.text,
                                      userEmail: _emailController.text,
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cập nhật',
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
    );
  }
}

class _FormHero extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;

  const _FormHero({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

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
            child: Icon(icon, color: colorScheme.onSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

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
