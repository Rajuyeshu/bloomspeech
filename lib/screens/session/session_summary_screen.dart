import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_theme.dart';
import '../../config/routes/app_router.dart';
import '../../config/constants/app_constants.dart';
import '../../services/session_report_pdf.dart';
import 'active_session_screen.dart';

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeSessionProvider);
    if (state == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No session data'.tr()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.goNamed(AppRouter.home),
                child: Text('Go Home'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final duration = DateTime.now().difference(state.startTime);
    final fluent =
        state.utterances.where((u) => u.type == UtteranceType.fluent).length;
    final dysfluent =
        state.utterances.where((u) => u.type == UtteranceType.dysfluent).length;
    final total = fluent + dysfluent;
    // Stuttering frequency is the clinical outcome; progress is a REDUCTION.
    final dysfluencyPct = total > 0 ? (dysfluent / total) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Session Summary'.tr()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.goNamed(AppRouter.home),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── Fluency Percentage Hero ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: dysfluencyPct >= 80
                    ? AppColors.smoothGradient
                    : dysfluencyPct >= 50
                        ? const LinearGradient(
                            colors: [AppColors.accent, AppColors.accentLight])
                        : AppColors.bumpyGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Column(
                children: [
                  Text(
                    '${dysfluencyPct.toStringAsFixed(1)}%',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 56,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dysfluency / Stuttering Frequency (%)'.tr(),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dysfluencyPct <= 20
                          ? '📉 Great session!'
                          : dysfluencyPct <= 50
                              ? '📊 Good progress!'
                              : '💪 Keep practicing!',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                ),

            const SizedBox(height: 24),

            // ─── Stats Grid ───
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Total', '$total', Icons.chat_bubble_outline_rounded,
                        AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'Fluent Words', '$fluent', Icons.check_circle_outline,
                        AppColors.smoothGreen)),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Stuttered Words', '$dysfluent',
                        Icons.replay_circle_filled_outlined,
                        AppColors.bumpyOrange)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'Rewards', '${state.rewardCycles}',
                        Icons.emoji_events_outlined,
                        AppColors.tokenGold)),
              ],
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Duration',
                        _formatDuration(duration),
                        Icons.timer_outlined,
                        AppColors.info)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard(
                        'Level',
                        state.config.therapyLevel,
                        Icons.stairs_rounded,
                        AppColors.primary)),
              ],
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 28),

            // ─── Share / Export Buttons ───
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final summary = _buildShareText(
                        state.config.childName,
                        dysfluencyPct,
                        total,
                        fluent,
                        dysfluent,
                        state.rewardCycles,
                        duration,
                        state.config.therapyLevel,
                      );
                      Share.share(summary);
                    },
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: Text('Share via WhatsApp'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportPdf(
                      context,
                      SessionReportData(
                        childName: state.config.childName,
                        therapyLevel: state.config.therapyLevel,
                        date: DateTime.now(),
                        duration: duration,
                        totalUtterances: total,
                        fluentCount: fluent,
                        dysfluentCount: dysfluent,
                        rewardCycles: state.rewardCycles,
                        tokenGoal: state.config.tokenGoal,
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: Text('Export PDF'.tr()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 20),

            // ─── Done Button ───
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.goNamed(AppRouter.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Done'.tr(), style: AppTextStyles.buttonText),
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
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
            style: AppTextStyles.statValue.copyWith(fontSize: 22),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds.remainder(60);
    return '${mins}m ${secs}s';
  }

  /// Generate the report and hand it to the system share sheet.
  ///
  /// The button used to show "PDF export coming soon" and produce nothing —
  /// it looked like a broken export rather than an unbuilt feature. Sharing is
  /// used rather than a silent write to disk because a file saved into the
  /// app's private storage is somewhere the clinician cannot reach.
  Future<void> _exportPdf(
      BuildContext context, SessionReportData data) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Preparing the report…'.tr()),
      ),
    );

    try {
      final bytes = await SessionReportPdf.build(data);

      // Write it out so the share sheet offers a real file with a real name;
      // sharing raw bytes gives the clinician an unnamed attachment.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${data.fileName}');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: data.fileName)],
        subject: 'BloomSpeech session report — ${data.childName}',
      );
    } catch (e) {
      debugPrint('PDF export failed: $e');
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Could not create the PDF report.'.tr()),
        ),
      );
    }
  }

  String _buildShareText(
    String childName,
    double dysfluencyPct,
    int total,
    int fluent,
    int dysfluent,
    int rewards,
    Duration duration,
    String level,
  ) {
    return '''
📊 *BloomSpeech Session Summary*
━━━━━━━━━━━━━━━━━━
👤 Child: $childName
📉 Dysfluency / Stuttering Frequency: ${dysfluencyPct.toStringAsFixed(1)}%

📝 Total Words Recorded: $total
✅ Fluent Words: $fluent
🔄 Stuttered Words: $dysfluent
🏆 Rewards Earned: $rewards

⏱ Duration: ${_formatDuration(duration)}
📚 Level: $level
━━━━━━━━━━━━━━━━━━
_Powered by BloomSpeech_
''';
  }
}
