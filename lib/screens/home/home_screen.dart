import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
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
    if (user?.role == 'kid') {
      return _buildKidHomeScreen(context, ref, user!);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to exit BloomSpeech?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          // Home is the only route on the stack, so `Navigator.pop` is a no-op
          // here — ask the platform to close the app instead.
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
                      onPressed: () => context.pushNamed(AppRouter.settings),
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
                            context.pushNamed(AppRouter.children);
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
                        onTap: () => context.pushNamed(AppRouter.children),
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
                        onTap: () => context.pushNamed(AppRouter.children),
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
                      onPressed: () => context.pushNamed(AppRouter.children),
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

    return FutureBuilder<List<ChildProfile>>(
      future: ref.read(firestoreServiceProvider).fetchChildren(clinicianId),
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
      onTap: () => context.pushNamed(
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
              onPressed: () => context.pushNamed(
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
            onPressed: () => context.pushNamed(AppRouter.addChild),
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

  Widget _buildKidHomeScreen(BuildContext context, WidgetRef ref, AppUser user) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to exit BloomSpeech?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2), Colors.white],
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
                            '${user.displayName} 🧒',
                            style: AppTextStyles.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pushNamed(AppRouter.settings),
                      icon: const Icon(Icons.settings_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 24),

                // ─── Welcome Header ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🌸', style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Let\'s practice smooth speech!',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Practice makes perfect. Have fun with your therapist today! 🪁',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // ─── Join Live Session Card ───
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'Live Session',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Join a video call and start speech practice with your therapist.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pushNamed(AppRouter.kidJoin),
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: Text(
                            'Join Your Session',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.accentDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.accentDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // ─── Child Info & Cards ───
                FutureBuilder<ChildProfile?>(
                  // Resolve the clinician's child record this kid is linked
                  // to — that is where their sessions are actually recorded.
                  // Keyed on the refresh counter so finishing a session
                  // re-queries rather than showing the old count.
                  key: ValueKey(ref.watch(dataRefreshProvider)),
                  future:
                      ref.read(firestoreServiceProvider).getChildForKid(user.uid),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final totalSessions = profile?.totalSessions ?? 0;
                    final currentLevel = profile?.currentLevel ?? 'Word Level';
                    // Progress/history must query the linked child id, not the
                    // kid's auth uid, or they come back empty.
                    final progressChildId = profile?.id ?? user.uid;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Speech Stats Quick Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildKidStatCard(
                                title: 'Completed',
                                value: '$totalSessions sessions',
                                icon: Icons.done_all_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildKidStatCard(
                                title: 'Active Level',
                                value: currentLevel,
                                icon: Icons.stairs_rounded,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 450.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // Action Cards (Progress & History)
                        _buildKidActionCard(
                          context,
                          title: 'My Progress Reports',
                          subtitle: 'View your speech progress charts and milestones',
                          icon: Icons.insights_rounded,
                          color: AppColors.primary,
                          onTap: () => context.pushNamed(
                            AppRouter.progressDashboard,
                            pathParameters: {'childId': progressChildId},
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 14),

                        _buildKidActionCard(
                          context,
                          title: 'Speech Practice History',
                          subtitle: 'View stars and feedback from your past sessions',
                          icon: Icons.history_rounded,
                          color: AppColors.secondary,
                          onTap: () => context.pushNamed(
                            AppRouter.sessionHistory,
                            pathParameters: {'childId': progressChildId},
                          ),
                        ).animate().fadeIn(delay: 750.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildKidStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKidActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textHint.withValues(alpha: 0.7), size: 16),
          ],
        ),
      ),
    );
  }
}
