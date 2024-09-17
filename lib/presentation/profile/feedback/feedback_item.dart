import 'package:flutter/material.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';

import '../../../firebase/firestore/feedback/feedback_model.dart';
import '../../../firebase/firestore/feedback/feedback_status.dart';
import '../../../firebase/firestore/gn_firestore.dart';
import '../../../firebase/firestore/user/gn_user.dart';
import '../../../injection_container.dart';

class FeedbackItem extends StatelessWidget {
  final FeedbackModel feedback;
  const FeedbackItem({Key? key, required this.feedback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = FeedbackStatusX.fromInt(feedback.status);
    return InkWell(
      onLongPress: () {},
      child: ListTile(
        leading: FutureBuilder<GNUser?>(
          future: getIt<GNFirestore>().getUserById(feedback.userId),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (userSnapshot.hasError) {
              return const Icon(Icons.error);
            } else if (userSnapshot.hasData) {
              final user = userSnapshot.data;
              if (user?.photoUrl == null) {
                return const Icon(Icons.error);
              }
              return CircleAvatar(
                backgroundImage: NetworkImage(user!.photoUrl!),
              );
            } else {
              return const Icon(Icons.error);
            }
          },
        ),
        title: Text(feedback.title),
        subtitle: Text(feedback.detail),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status.name),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.color, // Replace with your desired color
              ),
            )
          ],
        ),
      ),
    );
  }
}
