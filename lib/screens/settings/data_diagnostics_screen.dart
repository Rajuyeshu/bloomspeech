import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/crash_log.dart';
import '../../utils/app_time.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/back_to_home_scope.dart';

/// Shows exactly what each API call behind the progress screens returns.
///
/// Empty progress has several possible causes that all look identical in the
/// UI — an unlinked kid, a permission denial on `children`, a permission denial
/// on `sessions`. This attributes the failure to a specific call so it can be
/// fixed rather than guessed at.
class DataDiagnosticsScreen extends ConsumerStatefulWidget {
  const DataDiagnosticsScreen({super.key});

  @override
  ConsumerState<DataDiagnosticsScreen> createState() =>
      _DataDiagnosticsScreenState();
}

class _DataDiagnosticsScreenState extends ConsumerState<DataDiagnosticsScreen> {
  late Future<List<DiagnosticStep>> _future;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _run() {
    final user = ref.read(currentUserProvider);
    _future = ref
        .read(firestoreServiceProvider)
        .runKidDataDiagnostics(user?.uid ?? '');
  }

  /// The copied report includes the crash records too — those are the part
  /// that is otherwise impossible to retrieve from a release build.
  String _asText(List<DiagnosticStep> steps) {
    final diagnostics = steps
        .map((s) => '${s.ok ? "OK  " : "FAIL"}  ${s.name}\n'
            '  query : ${s.query}\n'
            '  result: ${s.result}')
        .join('\n\n');

    final crashes = CrashLog.recent();
    if (crashes.isEmpty) return '$diagnostics\n\nNo crashes recorded.';

    final crashText = crashes
        .map((c) => '${AppTime.format(c.time, "yyyy-MM-dd HH:mm:ss")} '
            '${AppTime.istLabel}\n${c.error}\n${c.stack}')
        .join('\n\n---\n\n');

    return '$diagnostics\n\n'
        '=== CRASHES (${crashes.length}) ===\n\n$crashText';
  }

  @override
  Widget build(BuildContext context) {
    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Data Diagnostics'),
          actions: [
            IconButton(
              tooltip: 'Re-run',
              onPressed: () => setState(_run),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: FutureBuilder<List<DiagnosticStep>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final steps = snapshot.data ?? const <DiagnosticStep>[];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Each row is one API call the progress screens make. A FAIL '
                  'row, or a row returning 0 rows, is the reason progress is '
                  'empty.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ...steps.map(_buildStep),
                _buildCrashSection(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: _asText(steps)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy report'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Recent uncaught errors, so a crash on a real device leaves something
  /// readable behind. Without this the only available report is "it crashed",
  /// which cannot be acted on.
  Widget _buildCrashSection() {
    final crashes = CrashLog.recent();
    if (crashes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No crashes recorded on this device.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent crashes (${crashes.length})',
                style: AppTextStyles.titleSmall),
            TextButton(
              onPressed: () async {
                await CrashLog.clear();
                if (mounted) setState(() {});
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        ...crashes.take(5).map((c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppTime.format(c.time, 'd MMM, HH:mm:ss'),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(c.error,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error)),
                  if (c.stack.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      c.stack.split('\n').take(4).join('\n'),
                      style: const TextStyle(fontSize: 10, height: 1.3),
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildStep(DiagnosticStep step) {
    final color = step.ok ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(step.ok ? Icons.check_circle_rounded : Icons.error_rounded,
                  size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(step.name, style: AppTextStyles.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            step.query,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            step.result,
            style: AppTextStyles.bodySmall.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
