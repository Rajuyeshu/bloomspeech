import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_theme.dart';
import '../../config/routes/app_router.dart';
import '../../config/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/child_profile.dart';
import '../../models/session.dart';
import '../../widgets/back_to_home_scope.dart';
import '../../widgets/load_error_view.dart';

class ProgressDashboard extends ConsumerWidget {
  final String childId;
  const ProgressDashboard({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(body: Center(child: Text('Login required'.tr())));
    }

    return BackToHomeScope(
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Progress Dashboard'.tr()),
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
        actions: [
          IconButton(
            onPressed: () => context.pushNamed(
              AppRouter.sessionCompare,
              pathParameters: {'childId': childId},
            ),
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'Compare Sessions'.tr(),
          ),
        ],
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
          //
          // On the CHILD's device the commonest cause is not a fault but a
          // missing link: until the clinician has completed a session, the
          // child's login is attached to no child record, and the query either
          // returns nothing or is refused. Showing a raw database error there
          // is both alarming and unactionable for a parent.
          if (snapshot.hasError) {
            if (user.role == 'kid') {
              return _buildNotLinkedYet(context);
            }
            return LoadErrorView(error: snapshot.error!);
          }

          final sessions = (snapshot.data ?? []).reversed.toList();

          if (sessions.isEmpty) {
            if (user.role == 'kid') return _buildNotLinkedYet(context);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_rounded,
                      size: 60, color: AppColors.textHint.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No session data yet'.tr(),
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Complete a session to see progress'.tr(),
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
                // ─── Stuttering frequency across sessions ───
                // The primary outcome is a REDUCTION in this figure, so the
                // chart is framed as stuttering frequency rather than as
                // fluency development.
                _buildSectionTitle('Stuttering Frequency Across Sessions',
                    Icons.show_chart_rounded),
                const SizedBox(height: 14),
                // The baseline comes from the child record; a database that
                // predates the column simply yields null and no line.
                FutureBuilder<ChildProfile?>(
                  // The baseline is decoration on this chart, not its subject.
                  // On the child's own device the child row may be unreadable,
                  // and that must cost the reference line — never the chart.
                  future: ref
                      .read(firestoreServiceProvider)
                      .getChild(clinicianId: user.uid, childId: childId)
                      .catchError((_) => null),
                  builder: (context, snap) => _buildFluencyChart(
                    sessions,
                    snap.data?.baselineDysfluencyPct,
                  ),
                ).animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 28),

                // ─── Token Economy Trend ───
                _buildSectionTitle(
                    'Token Economy Trend', Icons.toll_rounded),
                const SizedBox(height: 14),
                _buildTokenTrendChart(sessions)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 28),

                // ─── Treatment Level Timeline ───
                _buildSectionTitle(
                    'Treatment Level Progression', Icons.timeline_rounded),
                const SizedBox(height: 14),
                _buildLevelTimeline(sessions)
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 28),

                // ─── Quick Stats ───
                _buildSectionTitle('Overall Stats', Icons.analytics_rounded),
                const SizedBox(height: 14),
                _buildOverallStats(sessions)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headlineSmall),
      ],
    );
  }

  /// What the child's device shows when it has no sessions to display.
  ///
  /// Deliberately not phrased as an error: from the family's side nothing has
  /// gone wrong, and the situation resolves itself once a session is completed.
  /// The diagnostics link is there for the clinician, not the parent.
  Widget _buildNotLinkedYet(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No progress to show yet'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 10),
            Text(
              'Your charts appear here once your therapist finishes a session '
                      'with you. Come back after your next session.'
                  .tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => context.pushNamed(AppRouter.dataDiagnostics),
              icon: const Icon(Icons.troubleshoot_rounded, size: 18),
              label: Text('Details for your therapist'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stuttering frequency line chart ───
  ///
  /// [baselinePct] is the child's pre-treatment stuttering frequency, drawn as
  /// a reference line so the reduction since baseline is readable at a glance.
  /// Null when it has not been recorded, in which case no line is drawn.
  Widget _buildFluencyChart(List<Session> sessions, double? baselinePct) {
    final spots = sessions.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.stats.dysfluencyPercentage,
      );
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.textHint.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameSize: 20,
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Session number',
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sessions.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '#${sessions[index].sessionNumber}',
                      style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameSize: 22,
              axisNameWidget: Text('Dysfluency / Stuttering Frequency (%)',
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 20,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          // Clinical goal band. On this axis lower is better, so the band
          // sits at the BOTTOM — shading the old 80-100% zone here would have
          // marked the worst outcomes as the target.
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: 0,
                y2: 100 - AppConstants.clinicalGoalMin,
                color: AppColors.smoothGreen.withValues(alpha: 0.08),
              ),
            ],
          ),
          extraLinesData: baselinePct == null
              ? null
              : ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: baselinePct,
                    color: AppColors.bumpyOrange.withValues(alpha: 0.8),
                    strokeWidth: 2,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 9, color: AppColors.bumpyOrange),
                      labelResolver: (_) =>
                          'Baseline ${baselinePct.toStringAsFixed(1)}%',
                    ),
                  ),
                ]),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final sessionIndex = spot.x.toInt();
                  if (sessionIndex >= sessions.length) return null;
                  final session = sessions[sessionIndex];
                  return LineTooltipItem(
                    '${session.stats.dysfluencyPercentage.toStringAsFixed(1)}%\n'
                    '${session.stats.totalUtterances} words',
                    AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Token Trend Bar Chart ───
  Widget _buildTokenTrendChart(List<Session> sessions) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: sessions.fold<double>(0, (max, s) {
                final total = s.stats.totalUtterances.toDouble();
                return total > max ? total : max;
              }) *
              1.2,
          barGroups: sessions.asMap().entries.map((entry) {
            final s = entry.value;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: s.stats.fluentCount.toDouble(),
                  color: AppColors.smoothGreen,
                  width: 10,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: s.stats.dysfluentCount.toDouble(),
                  color: AppColors.bumpyOrange,
                  width: 10,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameSize: 20,
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Session number',
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sessions.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '#${sessions[index].sessionNumber}',
                      style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.textHint.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Level Timeline ───
  Widget _buildLevelTimeline(List<Session> sessions) {
    // The four current levels. Hardcoding the list meant the retired sentence
    // level kept appearing here after it was withdrawn.
    final levels = TherapyLevel.selectable;

    // Determine which levels have been used
    final usedLevels = <String>{};
    for (final s in sessions) {
      usedLevels.add(s.therapyLevel);
    }
    final currentLevel =
        sessions.isNotEmpty ? sessions.last.therapyLevel : 'word';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Timeline nodes
          Row(
            children: levels.asMap().entries.map((entry) {
              final index = entry.key;
              final level = entry.value;
              final isUsed = usedLevels.contains(level.name);
              final isCurrent = level.name == currentLevel;
              final levelColor = _getLevelColor(level);

              return Expanded(
                child: Column(
                  children: [
                    // Node
                    Row(
                      children: [
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isUsed
                                  ? levelColor
                                  : AppColors.textHint.withValues(alpha: 0.15),
                            ),
                          ),
                        Container(
                          width: isCurrent ? 36 : 28,
                          height: isCurrent ? 36 : 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUsed
                                ? levelColor
                                : AppColors.textHint.withValues(alpha: 0.15),
                            border: isCurrent
                                ? Border.all(
                                    color: levelColor.withValues(alpha: 0.3),
                                    width: 4)
                                : null,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: levelColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${level.levelNumber}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isUsed ? Colors.white : AppColors.textHint,
                                fontWeight: FontWeight.w700,
                                fontSize: isCurrent ? 12 : 10,
                              ),
                            ),
                          ),
                        ),
                        if (index < levels.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: usedLevels.contains(levels[index + 1].name)
                                  ? _getLevelColor(levels[index + 1])
                                  : AppColors.textHint.withValues(alpha: 0.15),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level.shortName,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isUsed ? levelColor : AppColors.textHint,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.smoothGreen, 'Completed'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.primary, 'Current'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.textHint.withValues(alpha: 0.3), 'Upcoming'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
      ],
    );
  }

  Color _getLevelColor(TherapyLevel level) {
    switch (level) {
      case TherapyLevel.word:
        return AppColors.levelWord;
      case TherapyLevel.sentence:
        return AppColors.levelSentence;
      case TherapyLevel.continuousSpeech:
        return AppColors.levelContinuous;
      case TherapyLevel.narrative:
        return AppColors.levelNarrative;
      case TherapyLevel.conversational:
        return AppColors.levelConversational;
    }
  }

  // ─── Overall Stats ───
  Widget _buildOverallStats(List<Session> sessions) {
    final totalUtterances =
        sessions.fold<int>(0, (sum, s) => sum + s.stats.totalUtterances);
    final totalFluent =
        sessions.fold<int>(0, (sum, s) => sum + s.stats.fluentCount);
    final totalDysfluent =
        sessions.fold<int>(0, (sum, s) => sum + s.stats.dysfluentCount);
    final totalRewards =
        sessions.fold<int>(0, (sum, s) => sum + s.stats.rewardCyclesCompleted);
    final avgFluency = sessions.isNotEmpty
        ? sessions.fold<double>(0, (sum, s) => sum + s.stats.dysfluencyPercentage) /
            sessions.length
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                  'Total Sessions', '${sessions.length}',
                  Icons.calendar_today_outlined, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                  'Avg Stuttering %', '${avgFluency.toStringAsFixed(1)}%',
                  Icons.trending_up_rounded, AppColors.smoothGreen)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                  'Total Words Recorded', '$totalUtterances',
                  Icons.chat_bubble_outline, AppColors.info)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                  'Total Rewards', '$totalRewards',
                  Icons.emoji_events_outlined, AppColors.tokenGold)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                  'Fluent', '$totalFluent',
                  Icons.check_circle_outline, AppColors.smoothGreen)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                  'Dysfluent', '$totalDysfluent',
                  Icons.replay_circle_filled_outlined, AppColors.bumpyOrange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(label, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
