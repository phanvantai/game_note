import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/feedback/gn_firestore_feedback.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';
import 'package:pes_arena/presentation/profile/feedback/feedback_item.dart';

import '../../../firebase/firestore/feedback/feedback_model.dart';
import '../../../firebase/firestore/gn_firestore.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('FeedbackView init');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const SmartBackButton(),
        title: Text(context.l10n.feedbackTitle),
      ),
      body: AppPageBackground(child: SafeArea(child: _body())),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_feedback',
        onPressed: _addFeedback,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addFeedback() {
    final user = getIt<GNAuth>().auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.feedbackSignInRequired),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    String title = '';
    String detail = '';

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(context.l10n.feedbackCreateTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => title = value,
                  decoration: appInputDecoration(
                    context: context,
                    hintText: context.l10n.feedbackTitleHint,
                    prefixIcon: Icons.title,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => detail = value,
                  decoration: appInputDecoration(
                    context: context,
                    hintText: context.l10n.feedbackContentHint,
                    prefixIcon: Icons.notes,
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            // coverage:ignore-start
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            // coverage:ignore-end
            FilledButton(
              onPressed: () {
                if (title.isEmpty || detail.isEmpty) {
                  showToast(context.l10n.feedbackRequired);
                  return;
                }
                if (title.length < 5 || detail.length < 10) {
                  showToast(context.l10n.feedbackMinimumLength);
                  return;
                }
                final sentMessage = context.l10n.feedbackSent;
                getIt<GNFirestore>()
                    .createFeedback(title, detail, user.uid)
                    .then((_) => showToast(sentMessage));
                Navigator.of(context).pop();
                setState(() {});
              },
              child: Text(context.l10n.commonSend),
            ),
          ],
        );
      },
    );
  }

  Widget _body() {
    return FutureBuilder<List<FeedbackModel>>(
      future: getIt<GNFirestore>().getAllFeedback(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return AppEmptyState(
            icon: Icons.error_outline,
            title: context.l10n.commonErrorTitle,
            subtitle: '${snapshot.error}',
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final feedbackList = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const _FeedbackHero(),
              const SizedBox(height: 16),
              ...feedbackList.map(
                (feedback) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FeedbackItem(feedback: feedback),
                ),
              ),
            ],
          );
        } else {
          return const _FeedbackEmptyState();
        }
      },
    );
  }
}

class _FeedbackHero extends StatelessWidget {
  const _FeedbackHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 24,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feedback board',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Góp ý cộng đồng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Theo dõi và gửi phản hồi để cải thiện PES Arena.',
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

class _FeedbackEmptyState extends StatelessWidget {
  const _FeedbackEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 96),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                size: 40,
              ),
              const SizedBox(height: 14),
              Text(
                'Chưa có góp ý nào',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nhấn nút + để thêm góp ý mới',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
