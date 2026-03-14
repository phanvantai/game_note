import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/feedback/gn_firestore_feedback.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/profile/feedback/feedback_item.dart';

import '../../../firebase/firestore/feedback/feedback_model.dart';
import '../../../firebase/firestore/gn_firestore.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('Góp ý'),
      ),
      body: _body(),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      'Tiêu đề phải có ít nhất 5 ký tự\nNội dung phải có ít nhất 10 ký tự.');
                  return;
                }
                getIt<GNFirestore>()
                    .createFeedback(title, detail, user.uid)
                    .then(
                      (_) => showToast('Góp ý đã được gửi thành công!'),
                    );
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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: feedbackList.length,
            itemBuilder: (context, index) =>
                FeedbackItem(feedback: feedbackList[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          );
        } else {
          return const AppEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Chưa có góp ý nào',
            subtitle: 'Nhấn nút + để thêm góp ý mới',
          );
        }
      },
    );
  }
}
