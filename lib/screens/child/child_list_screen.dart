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

class ChildListScreen extends ConsumerWidget {
  const ChildListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Children'),
        leading: IconButton(
          onPressed: () => context.goNamed(AppRouter.home),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : FutureBuilder<List<ChildProfile>>(
              future: ref
                  .read(firestoreServiceProvider)
                  .fetchChildren(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final children = snapshot.data ?? [];

                if (children.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    return _buildChildTile(context, children[index], index);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(AppRouter.addChild),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Child'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildChildTile(
      BuildContext context, ChildProfile child, int index) {
    final levelColors = {
      'word': AppColors.levelWord,
      'sentence': AppColors.levelSentence,
      'continuousSpeech': AppColors.levelContinuous,
      'narrative': AppColors.levelNarrative,
      'conversational': AppColors.levelConversational,
    };
    final levelColor = levelColors[child.currentLevel] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => context.goNamed(
        AppRouter.childProfile,
        pathParameters: {'childId': child.id},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    levelColor.withValues(alpha: 0.2),
                    levelColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  child.name.isNotEmpty
                      ? child.name[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: levelColor,
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.cake_outlined,
                        child.ageDisplay,
                      ),
                      const SizedBox(width: 10),
                      _buildInfoChip(
                        Icons.bar_chart_rounded,
                        '${child.totalSessions} sessions',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      child.currentLevel.replaceAll('continuousSpeech', 'Continuous'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: levelColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: () => context.goNamed(
                    AppRouter.sessionSetup,
                    pathParameters: {'childId': child.id},
                  ),
                  icon: const Icon(Icons.play_circle_filled_rounded),
                  color: AppColors.primary,
                  iconSize: 36,
                  tooltip: 'Start session',
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + (index * 80)),
          duration: 500.ms,
        )
        .slideX(begin: 0.05, end: 0);
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(text, style: AppTextStyles.labelSmall),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'No Children Added Yet',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Add your first child to begin therapy sessions',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.goNamed(AppRouter.addChild),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Child'),
            ),
          ],
        ),
      ),
    );
  }
}
