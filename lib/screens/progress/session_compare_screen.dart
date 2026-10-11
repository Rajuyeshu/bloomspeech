import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes/app_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/session.dart';
import '../../utils/app_time.dart';

class SessionCompareScreen extends ConsumerStatefulWidget {
  final String childId;
  const SessionCompareScreen({super.key, required this.childId});

  @override
  ConsumerState<SessionCompareScreen> createState() =>
      _SessionCompareScreenState();
}

class _SessionCompareScreenState extends ConsumerState<SessionCompareScreen> {
  Session? _sessionA;
  Session? _sessionB;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(body: Center(child: Text('Login required'.tr())));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Compare Sessions'.tr()),
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
              childId: widget.childId,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];

          if (sessions.length < 2) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.compare_arrows_rounded,
                      size: 60, color: AppColors.textHint.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Need at least 2 sessions'.tr(),
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Complete more sessions to compare'.tr(),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Selectors
                Text('Select sessions to compare'.tr(),
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildSessionSelector(
                        label: 'Session A'.tr(),
                        selectedSession: _sessionA,
                        sessions: sessions,
                        color: AppColors.primary,
                        onSelected: (s) =>
                            setState(() => _sessionA = s),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.compare_arrows_rounded,
                        color: AppColors.textHint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSessionSelector(
                        label: 'Session B'.tr(),
                        selectedSession: _sessionB,
                        sessions: sessions,
                        color: AppColors.secondary,
                        onSelected: (s) =>
                            setState(() => _sessionB = s),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Comparison
                if (_sessionA != null && _sessionB != null) ...[
                  _buildComparisonCard(
                    'Dysfluency / Stuttering Frequency (%)',
                    '${_sessionA!.stats.dysfluencyPercentage.toStringAsFixed(1)}%',
                    '${_sessionB!.stats.dysfluencyPercentage.toStringAsFixed(1)}%',
                    _sessionA!.stats.dysfluencyPercentage,
                    _sessionB!.stats.dysfluencyPercentage,
                    Icons.trending_down_rounded,
                    // A reduction is the improvement being looked for.
                    higherIsBetter: false,
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 12),

                  _buildComparisonCard(
                    'Total Words Recorded',
                    '${_sessionA!.stats.totalUtterances}',
                    '${_sessionB!.stats.totalUtterances}',
                    _sessionA!.stats.totalUtterances.toDouble(),
                    _sessionB!.stats.totalUtterances.toDouble(),
                    Icons.chat_bubble_outline,
                    higherIsBetter: true,
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 12),

                  _buildComparisonCard(
                    'Fluent Words',
                    '${_sessionA!.stats.fluentCount}',
                    '${_sessionB!.stats.fluentCount}',
                    _sessionA!.stats.fluentCount.toDouble(),
                    _sessionB!.stats.fluentCount.toDouble(),
                    Icons.check_circle_outline,
                    higherIsBetter: true,
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 12),

                  _buildComparisonCard(
                    'Stuttered Words',
                    '${_sessionA!.stats.dysfluentCount}',
                    '${_sessionB!.stats.dysfluentCount}',
                    _sessionA!.stats.dysfluentCount.toDouble(),
                    _sessionB!.stats.dysfluentCount.toDouble(),
                    Icons.replay_circle_filled_outlined,
                    higherIsBetter: false,
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 12),

                  _buildComparisonCard(
                    'Reward Cycles',
                    '${_sessionA!.stats.rewardCyclesCompleted}',
                    '${_sessionB!.stats.rewardCyclesCompleted}',
                    _sessionA!.stats.rewardCyclesCompleted.toDouble(),
                    _sessionB!.stats.rewardCyclesCompleted.toDouble(),
                    Icons.emoji_events_outlined,
                    higherIsBetter: true,
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 12),

                  _buildComparisonCard(
                    'Duration',
                    _formatDuration(_sessionA!.stats.duration),
                    _formatDuration(_sessionB!.stats.duration),
                    _sessionA!.stats.duration.inSeconds.toDouble(),
                    _sessionB!.stats.duration.inSeconds.toDouble(),
                    Icons.timer_outlined,
                    higherIsBetter: false,
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Select two sessions above to compare'.tr(),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textHint),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionSelector({
    required String label,
    required Session? selectedSession,
    required List<Session> sessions,
    required Color color,
    required ValueChanged<Session> onSelected,
  }) {
    return GestureDetector(
      onTap: () => _showSessionPicker(sessions, color, onSelected),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selectedSession != null
              ? color.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedSession != null
                ? color
                : AppColors.textHint.withValues(alpha: 0.2),
            width: selectedSession != null ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.labelMedium.copyWith(color: color)),
            const SizedBox(height: 6),
            if (selectedSession != null) ...[
              Text(
                '#${selectedSession.sessionNumber}',
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                AppTime.format(selectedSession.date, 'dd MMM'),
                style: AppTextStyles.labelSmall,
              ),
            ] else
              Text(
                'Tap to select'.tr(),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
              ),
          ],
        ),
      ),
    );
  }

  void _showSessionPicker(
    List<Session> sessions,
    Color color,
    ValueChanged<Session> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select a Session'.tr(), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Text(
                          '#${session.sessionNumber}',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: color),
                        ),
                      ),
                      title: Text(
                        AppTime.format(session.date, 'dd MMM yyyy'),
                        style: AppTextStyles.titleSmall,
                      ),
                      subtitle: Text(
                        '${session.stats.fluencyPercentage.toStringAsFixed(0)}% fluency',
                      ),
                      onTap: () {
                        onSelected(session);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonCard(
    String label,
    String valueA,
    String valueB,
    double numA,
    double numB,
    IconData icon, {
    required bool higherIsBetter,
  }) {
    final aBetter = higherIsBetter ? numA > numB : numA < numB;
    final bBetter = higherIsBetter ? numB > numA : numB < numA;
    final equal = numA == numB;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Value A
          Expanded(
            child: Column(
              children: [
                Text(
                  valueA,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: aBetter
                        ? AppColors.smoothGreen
                        : equal
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
                if (aBetter)
                  const Icon(Icons.arrow_upward_rounded,
                      color: AppColors.smoothGreen, size: 16),
              ],
            ),
          ),

          // Label
          Column(
            children: [
              Icon(icon, color: AppColors.textHint, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          // Value B
          Expanded(
            child: Column(
              children: [
                Text(
                  valueB,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: bBetter
                        ? AppColors.smoothGreen
                        : equal
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
                if (bBetter)
                  const Icon(Icons.arrow_upward_rounded,
                      color: AppColors.smoothGreen, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
}
