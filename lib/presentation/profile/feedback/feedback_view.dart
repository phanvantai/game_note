import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/firebase/auth/gn_auth.dart';
import 'package:game_note/firebase/firestore/feedback/gn_firestore_feedback.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/profile/feedback/feedback_item.dart';

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
    // getFeedback();
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

  _addFeedback() {
    // create feedback
    final user = getIt<GNAuth>().auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần đăng nhập để gửi phản hồi.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        String title = '';
        String detail = '';

        return AlertDialog(
          title: const Text('Tạo phản hồi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                ),
              ),
              TextField(
                onChanged: (value) {
                  detail = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                ),
                maxLines: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
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
                // create feedback logic here
                getIt<GNFirestore>()
                    .createFeedback(title, detail, user.uid)
                    .then(
                      (_) => showToast('Góp ý đã được gửi thành công!'),
                    );
                Navigator.of(context).pop();
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
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          final feedbackList = snapshot.data!;
          if (feedbackList.isEmpty) {
            return const Center(
              child: Text(
                  'Chưa có góp ý/phản hồi nào\nBạn có thể thêm bằng cách nhấn vào nút + bên dưới.'),
            );
          }
          return ListView.separated(
            itemCount: feedbackList.length,
            itemBuilder: (context, index) {
              final feedback = feedbackList[index];

              return FeedbackItem(feedback: feedback);
            },
            separatorBuilder: (context, index) => const Divider(),
          );
        } else {
          return const Center(
            child: Text(
                'Chưa có góp ý/phản hồi nào\nBạn có thể thêm bằng cách nhấn vào nút + bên dưới.'),
          );
        }
      },
    );
  }
}
