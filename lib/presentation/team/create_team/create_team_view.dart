import 'package:flutter/material.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

class CreateTeamView extends StatelessWidget {
  const CreateTeamView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Tạo đội mới',
          style: textTheme.titleMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  size: 36,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ảnh đội',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: appInputDecoration(
                context: context,
                labelText: 'Tên đội',
                prefixIcon: Icons.groups_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: appInputDecoration(
                context: context,
                labelText: 'Mô tả',
                prefixIcon: Icons.description_outlined,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sắp ra mắt'),
            ),
          ],
        ),
      ),
    );
  }
}
