import 'package:flutter/material.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/user/gn_firestore_user.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<GNUser?>(
            future: getIt<GNFirestore>().getUserById(feedback.userId),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                );
              }
              final user = userSnapshot.data;
              if (user?.photoUrl != null) {
                return CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(user!.photoUrl!),
                );
              }
              return CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.title,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  feedback.detail,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.name,
              style: textTheme.labelSmall?.copyWith(
                color: status.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
