import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/domain/repositories/user_repository.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/routing.dart';

class CompleteProfilePage extends StatefulWidget {
  final String? nextLocation;
  final UserRepository? userRepository;

  const CompleteProfilePage({
    super.key,
    this.nextLocation,
    this.userRepository,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final TextEditingController _displayNameController = TextEditingController();
  bool _loading = false;
  String _error = '';

  UserRepository get _repository =>
      widget.userRepository ?? getIt<UserRepository>();

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = 'Tên hiển thị không được để trống');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await _repository.updateProfile(displayName: displayName);
      if (getIt.isRegistered<AppBloc>()) {
        getIt<AppBloc>().add(RefreshCurrentUser());
      }
      if (!mounted) return;
      context.go(Routing.safeNextLocation(widget.nextLocation));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 56,
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.profileCompleteTitle,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.profileCompleteSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _displayNameController,
                enabled: !_loading,
                textInputAction: TextInputAction.done,
                decoration: appInputDecoration(
                  context: context,
                  hintText: context.l10n.profileFullNameHint,
                  prefixIcon: Icons.person_outline,
                ).copyWith(errorText: _error.isEmpty ? null : _error),
                onSubmitted: (_) => _loading ? null : _submit(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSecondary,
                          ),
                        )
                      : Text(
                          context.l10n.profileContinue,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
