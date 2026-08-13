import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes/app_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/session.dart';
import '../../widgets/back_to_home_scope.dart';
import '../../widgets/load_error_view.dart';

class SessionHistoryScreen extends ConsumerWidget {
  final String childId;
  const SessionHistoryScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Login required')));

    return BackToHomeScope(
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session History'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRouter.home);
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: FutureBuilder<List<Session>>(
        future: ref.read(firestoreServiceProvider).fetchSessions(
          clinicianId: user.uid,
          childId: childId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // A failed query must not look like "no sessions yet".
          if (snapshot.hasError) {
            return LoadErrorView(error: snapshot.error!);
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 60,
                      color: AppColors.textHint.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No sessions yet', style: AppTextStyles.headlineSmall),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    // Session number
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '#${session.sessionNumber}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(session.date),
                            style: AppTextStyles.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildChip(session.therapyLevel, AppColors.primary),
                              const SizedBox(width: 6),
                              _buildChip(
                                '${session.stats.totalUtterances} utt.',
                                AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              _buildChip(
                                '🏆 ${session.stats.rewardCyclesCompleted}',
                                AppColors.accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${_formatDuration(session.stats.duration)} • Theme: ${session.playTheme}',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    // Fluency badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: session.stats.fluencyPercentage >= 80
                            ? AppColors.successLight
                            : session.stats.fluencyPercentage >= 50
                                ? AppColors.warningLight
                                : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${session.stats.fluencyPercentage.toStringAsFixed(0)}%',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: session.stats.fluencyPercentage >= 80
                              ? AppColors.success
                              : session.stats.fluencyPercentage >= 50
                                  ? AppColors.warning
                                  : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontSize: 9,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
}
