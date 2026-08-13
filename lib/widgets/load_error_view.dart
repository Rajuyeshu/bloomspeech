import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_text_styles.dart';

/// Shown when a data query fails.
///
/// Deliberately distinct from the "nothing here yet" empty states: a failed
/// read used to fall through to "No sessions yet", which hid real backend
/// errors (RLS denials, missing columns) behind a friendly message and made
/// missing progress data impossible to diagnose.
class LoadErrorView extends StatelessWidget {
  final Object error;

  const LoadErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text("Couldn't load this data",
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
