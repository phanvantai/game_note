import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/feedback/gn_firestore_feedback.dart';
import 'package:pes_arena/injection_container.dart';
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
        title: const Text('Góp ý'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.16),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            ],
            stops: const [0, 0.46, 1],
          ),
        ),
        child: SafeArea(child: _body()),
      ),
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
          content: const Text('Bạn cần đăng nhập để gửi phản hồi.'),
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
          title: const Text('Tạo phản hồi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => title = value,
                  decoration: appInputDecoration(
                    context: context,
                    hintText: 'Tiêu đề',
                    prefixIcon: Icons.title,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => detail = value,
                  decoration: appInputDecoration(
                    context: context,
                    hintText: 'Nội dung',
                    prefixIcon: Icons.notes,
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (title.isEmpty || detail.isEmpty) {
                  showToast('Vui lòng điền đầy đủ thông tin.');
                  return;
                }
                if (title.length < 5 || detail.length < 10) {
                  showToast(
                    'Tiêu đề phải có ít nhất 5 ký tự\nNội dung phải có ít nhất 10 ký tự.',
                  );
                  return;
                }
                getIt<GNFirestore>()
                    .createFeedback(title, detail, user.uid)
                    .then((_) => showToast('Góp ý đã được gửi thành công!'));
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Gửi'),
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
            title: 'Đã xảy ra lỗi',
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
            child: Icon(
              Icons.chat_bubble_outline,
              color: colorScheme.onSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feedback board',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
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
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: colorScheme.secondary,
                  size: 30,
                ),
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
