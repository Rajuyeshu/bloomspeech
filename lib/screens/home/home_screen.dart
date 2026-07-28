import 'package:flutter/material.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ─── Top Bar ───
                Row(
                  children: [
                    // Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.displayName ?? 'Clinician',
                            style: AppTextStyles.headlineMedium,
                          ),
                        ],
                      ),
                    ),

                    // Settings
                    IconButton(
                      onPressed: () => context.goNamed(AppRouter.settings),
                      icon: const Icon(Icons.settings_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 28),

                // ─── Quick Actions ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.spa_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'BloomSpeech',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Response Cost Therapy for fluent speech',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // If a child exists, go to session setup directly for that child
                            context.goNamed(
                              AppRouter.sessionSetup,
                              pathParameters: {'childId': 'aarav_01'},
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text('Start New Session'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 28),

                // ─── Dashboard Cards ───
                Row(
                  children: [
                    Expanded(
                      child: _buildDashboardCard(
                        context,
                        icon: Icons.people_rounded,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.surfaceVariant,
                        label: 'My Children',
                        subtitle: 'Manage profiles',
                        onTap: () => context.goNamed(AppRouter.children),
                        delay: 300,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildDashboardCard(
                        context,
                        icon: Icons.history_rounded,
                        iconColor: AppColors.accent,
                        iconBg: AppColors.accentLight.withValues(alpha: 0.3),
                        label: 'History',
                        subtitle: 'Past sessions',
                        onTap: () => context.goNamed(AppRouter.children),
                        delay: 400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── Recent Children ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Children',
                      style: AppTextStyles.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () => context.goNamed(AppRouter.children),
                      child: Text(
                        'View All',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 12),

                // Children list
                _buildChildrenList(context, ref, user?.uid),

                const SizedBox(height: 28),

                // ─── Quick Tips Card ───
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.info,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Tip',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap Smooth or Bumpy within 1 second of the child\'s utterance for best results.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 14),
            Text(label, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 600.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildChildrenList(BuildContext context, WidgetRef ref, String? clinicianId) {
    if (clinicianId == null) {
      final demoChildren = [
        ChildProfile(id: 'aarav_01', name: 'Aarav Kumar', dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 4)), gender: 'male', enrollmentDate: DateTime.now(), clinicianId: 'demo_clinician', totalSessions: 12, currentLevel: 'continuousSpeech'),
        ChildProfile(id: 'priya_02', name: 'Priya Sharma', dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 5)), gender: 'female', enrollmentDate: DateTime.now(), clinicianId: 'demo_clinician', totalSessions: 8, currentLevel: 'sentence'),
        ChildProfile(id: 'karthik_03', name: 'Karthik V', dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 6)), gender: 'male', enrollmentDate: DateTime.now(), clinicianId: 'demo_clinician', totalSessions: 22, currentLevel: 'narrative'),
      ];

      return Column(
        children: demoChildren.asMap().entries.map((entry) {
          return _buildChildCard(context, entry.value, entry.key);
        }).toList(),
      );
    }

    return StreamBuilder(
      stream: ref.read(firestoreServiceProvider).getChildren(clinicianId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final children = snapshot.data ?? [];

        if (children.isEmpty) {
          final demoChildren = [
            ChildProfile(id: 'aarav_01', name: 'Aarav Kumar', dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 4)), gender: 'male', enrollmentDate: DateTime.now(), clinicianId: 'demo_clinician', totalSessions: 12, currentLevel: 'continuousSpeech'),
            ChildProfile(id: 'priya_02', name: 'Priya Sharma', dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 5)), gender: 'female', enrollmentDate: DateTime.now(), clinicianId: 'demo_clinician', totalSessions: 8, currentLevel: 'sentence'),
          ];
          return Column(
            children: demoChildren.asMap().entries.map((entry) {
              return _buildChildCard(context, entry.value, entry.key);
            }).toList(),
          );
        }

        final recentChildren = children.take(3).toList();

        return Column(
          children: recentChildren.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            return _buildChildCard(context, child, index);
          }).toList(),
        );
      },
    );
  }

  Widget _buildChildCard(
      BuildContext context, ChildProfile child, int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
    ];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => context.goNamed(
        AppRouter.childProfile,
        pathParameters: {'childId': child.id},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  child.name.isNotEmpty
                      ? child.name[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.name, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    '${child.ageDisplay} • ${child.totalSessions} sessions',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),

            // Play Button / Arrow
            IconButton(
              onPressed: () => context.goNamed(
                AppRouter.sessionSetup,
                pathParameters: {'childId': child.id},
              ),
              icon: const Icon(Icons.play_circle_filled_rounded),
              color: AppColors.primary,
              iconSize: 32,
              tooltip: 'Start Session',
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 500 + (index * 100)),
          duration: 500.ms,
        )
        .slideX(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.child_care_rounded,
            size: 56,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No children yet',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a child to start your first therapy session',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.goNamed(AppRouter.addChild),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Child'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 600.ms);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }
}
