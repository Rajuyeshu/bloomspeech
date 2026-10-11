import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/app_time.dart';

/// The numbers that make up a session report.
///
/// Kept separate from any widget so the document can be built and asserted on
/// without a screen, a printer, or a device.
class SessionReportData {
  final String childName;
  final String therapyLevel;
  final DateTime date;
  final Duration duration;
  final int totalUtterances;
  final int fluentCount;
  final int dysfluentCount;
  final int rewardCycles;
  final int tokenGoal;

  const SessionReportData({
    required this.childName,
    required this.therapyLevel,
    required this.date,
    required this.duration,
    required this.totalUtterances,
    required this.fluentCount,
    required this.dysfluentCount,
    required this.rewardCycles,
    required this.tokenGoal,
  });

  /// Stuttering frequency: the share of recorded words that were stuttered.
  /// This is the reported outcome — progress is a reduction. Zero for an empty
  /// session rather than a division by zero.
  double get dysfluencyPercentage =>
      totalUtterances > 0 ? (dysfluentCount / totalUtterances) * 100 : 0;

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  /// The filename offered to the share sheet. Sanitised because a child's name
  /// goes into it and a slash or colon would be rejected by the file system.
  String get fileName {
    final safeName = childName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final stamp = AppTime.format(date, 'yyyy-MM-dd');
    return 'BloomSpeech_${safeName.isEmpty ? 'Session' : safeName}_$stamp.pdf';
  }
}

/// Builds the printable session report.
class SessionReportPdf {
  SessionReportPdf._();

  static const PdfColor _ink = PdfColor.fromInt(0xFF1F2430);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _accent = PdfColor.fromInt(0xFF6C5CE7);
  static const PdfColor _good = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor _rule = PdfColor.fromInt(0xFFE5E7EB);

  /// Render the report to PDF bytes.
  ///
  /// Falls back to the built-in Helvetica faces, which have no Kannada glyphs:
  /// a child whose name is written in Kannada would appear blank on the
  /// report. Dropping NotoSansKannada into `assets/fonts/` (and uncommenting
  /// the fonts block in pubspec.yaml) is all that is needed to fix that — see
  /// [_theme]. Generation never fails over a missing glyph either way.
  static Future<Uint8List> build(SessionReportData data) async {
    final doc = pw.Document(
      title: 'BloomSpeech Session Report',
      theme: await _theme(),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 44),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(data),
            pw.SizedBox(height: 24),
            _headline(data),
            pw.SizedBox(height: 24),
            _detailTable(data),
            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Use a Unicode-capable font if one has been bundled, otherwise fall back
  /// to the built-in faces.
  ///
  /// The built-ins are Latin-only, so a Kannada name renders as nothing at
  /// all. Rather than hard-depend on an asset that may not be there — which
  /// would turn every export into a failure — this degrades to Helvetica and
  /// still produces a report.
  static Future<pw.ThemeData?> _theme() async {
    try {
      final regular =
          await rootBundle.load('assets/fonts/NotoSansKannada-Regular.ttf');
      final bold =
          await rootBundle.load('assets/fonts/NotoSansKannada-Bold.ttf');
      return pw.ThemeData.withFont(
        base: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
      );
    } catch (_) {
      // Not bundled. Latin text still renders correctly.
      return null;
    }
  }

  static pw.Widget _header(SessionReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('BloomSpeech',
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold, color: _accent)),
        pw.SizedBox(height: 2),
        pw.Text('Session Report',
            style: pw.TextStyle(fontSize: 13, color: _muted)),
        pw.SizedBox(height: 14),
        pw.Divider(color: _rule, height: 1),
        pw.SizedBox(height: 14),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(data.childName,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink)),
            pw.Text(
              '${AppTime.format(data.date, 'd MMM yyyy, HH:mm')} '
              '${AppTime.istLabel}',
              style: pw.TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _headline(SessionReportData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF5F3FF),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _metric('Stuttering frequency',
              '${data.dysfluencyPercentage.toStringAsFixed(1)}%', _good),
          _metric('Words recorded', '${data.totalUtterances}', _ink),
          _metric('Rewards earned', '${data.rewardCycles}', _accent),
        ],
      ),
    );
  }

  static pw.Widget _metric(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _muted)),
      ],
    );
  }

  static pw.Widget _detailTable(SessionReportData data) {
    final rows = <List<String>>[
      ['Fluent words', '${data.fluentCount}'],
      ['Stuttered words', '${data.dysfluentCount}'],
      ['Total words recorded', '${data.totalUtterances}'],
      ['Reward cycles completed', '${data.rewardCycles}'],
      ['Token goal', '${data.tokenGoal}'],
      ['Therapy level', data.therapyLevel],
      ['Session duration', data.formattedDuration],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Details',
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _rule, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            for (final row in rows)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 7),
                    child: pw.Text(row[0],
                        style: pw.TextStyle(fontSize: 11, color: _muted)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 7),
                    child: pw.Text(row[1],
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _rule, height: 1),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated by BloomSpeech. Times shown in ${AppTime.istLabel}.',
          style: pw.TextStyle(fontSize: 9, color: _muted),
        ),
      ],
    );
  }
}
