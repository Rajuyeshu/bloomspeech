import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_theme.dart';
import '../../config/routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/child_profile.dart';
import '../../models/session.dart';
import '../../utils/app_time.dart';

class ChildProfileScreen extends ConsumerWidget {
  final String childId;
  const ChildProfileScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(body: Center(child: Text('Please log in'.tr())));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<ChildProfile?>(
        future: ref.read(firestoreServiceProvider).getChild(
              clinicianId: user.uid,
              childId: childId,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final child = snapshot.data;
          if (child == null) {
            return Center(child: Text('Child not found'.tr()));
          }

          return CustomScrollView(
            slivers: [
              // ─── App Bar ───
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(AppRouter.home);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white,
                ),
                actions: [
                  IconButton(
                    onPressed: () => context.pushNamed(
                      AppRouter.editChild,
                      pathParameters: {'childId': childId},
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.white,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                style: AppTextStyles.displaySmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            child.name,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${child.ageDisplay} • ${child.gender}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Stats Cards ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              child.totalSessions.toString(),
                              'Total Sessions',
                              Icons.bar_chart_rounded,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              child.currentLevel,
                              'Current Level',
                              Icons.trending_up_rounded,
                              AppColors.accent,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              child.lastSessionDate != null
                                  ? AppTime.format(child.lastSessionDate!, 'dd MMM')
                                  : 'None',
                              'Last Session',
                              Icons.calendar_today_outlined,
                              AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              AppTime.format(child.enrollmentDate, 'dd MMM yyyy'),
                              'Enrolled',
                              Icons.event_note_outlined,
                              AppColors.info,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 28),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pushNamed(
                            AppRouter.sessionSetup,
                            pathParameters: {'childId': childId},
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: Text('Start New Session'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.pushNamed(
                                AppRouter.progressDashboard,
                                pathParameters: {'childId': childId},
                              ),
                              icon: const Icon(Icons.insights_rounded, size: 20),
                              label: Text('Progress'.tr()),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.pushNamed(
                                AppRouter.sessionHistory,
                                pathParameters: {'childId': childId},
                              ),
                              icon: const Icon(Icons.history_rounded, size: 20),
                              label: Text('History'.tr()),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 28),

                      // Recent Sessions
                      Text('Recent Sessions'.tr(), style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 14),

                      _buildRecentSessions(ref, user.uid),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(WidgetRef ref, String clinicianId) {
    return FutureBuilder<List<Session>>(
      future: ref.read(firestoreServiceProvider).fetchSessions(
            clinicianId: clinicianId,
            childId: childId,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded,
                    size: 40, color: AppColors.textHint.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'No sessions yet'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: sessions.take(5).map((session) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '#${session.sessionNumber}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTime.format(session.date, 'dd MMM yyyy'),
                          style: AppTextStyles.titleSmall,
                        ),
                        Text(
                          '${session.stats.fluencyPercentage.toStringAsFixed(0)}% fluency • ${session.stats.totalUtterances} utterances',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Fluency badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: session.stats.fluencyPercentage >= 80
                          ? AppColors.successLight
                          : session.stats.fluencyPercentage >= 50
                              ? AppColors.warningLight
                              : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${session.stats.fluencyPercentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: session.stats.fluencyPercentage >= 80
                            ? AppColors.success
                            : session.stats.fluencyPercentage >= 50
                                ? AppColors.warning
                                : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
