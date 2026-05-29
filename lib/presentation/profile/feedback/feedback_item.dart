import 'package:flutter/material.dart';
import 'package:pes_arena/core/theme/app_colors.dart';
import 'package:pes_arena/firebase/firestore/user/gn_firestore_user.dart';

import '../../../firebase/firestore/feedback/feedback_model.dart';
import '../../../firebase/firestore/feedback/feedback_status.dart';
import '../../../firebase/firestore/gn_firestore.dart';
import '../../../firebase/firestore/user/gn_user.dart';
import '../../../injection_container.dart';

class FeedbackItem extends StatelessWidget {
  final FeedbackModel feedback;
  const FeedbackItem({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final status = FeedbackStatusX.fromInt(feedback.status);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = status.themeColor(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          statusColor.withValues(alpha: 0.06),
          colorScheme.surfaceContainerHighest,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
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
              final photoUrl = user?.photoUrl;
              if (photoUrl != null && photoUrl.isNotEmpty) {
                return CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(photoUrl),
                  onBackgroundImageError: (_, _) {},
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
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback.detail,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
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
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status.name,
              style: textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FeedbackStatusThemeColor on FeedbackStatus {
  Color themeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (this) {
      case FeedbackStatus.notReceived:
        return colorScheme.onSurfaceVariant;
      case FeedbackStatus.processing:
        return AppColors.warning(context);
      case FeedbackStatus.done:
        return AppColors.success(context);
      case FeedbackStatus.rejected:
        return colorScheme.error;
    }
  }
}
