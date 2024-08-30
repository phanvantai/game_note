import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:game_note/firebase/auth/gn_auth.dart';
import 'package:game_note/injection_container.dart';

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
        title: const Text('Feedback'),
      ),
      body: const Center(
        child: Text('Feedback'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
                      // create feedback logic here
                      getIt<GNFirestore>()
                          .createFeedback(title, detail, user.uid)
                          .then(
                            // ignore: use_build_context_synchronously
                            (_) => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                'Feedback đã được gửi thành công!',
                              )),
                            ),
                          );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Gửi'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
