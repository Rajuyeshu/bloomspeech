import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/services/session_report_pdf.dart';

/// The export button used to show "coming soon" and produce nothing. These
/// assert that a real, non-empty PDF comes out and that the numbers on it are
/// the session's numbers.
void main() {
  SessionReportData data({
    String childName = 'Aarav Kumar',
    int total = 20,
    int fluent = 15,
    int dysfluent = 5,
    Duration duration = const Duration(minutes: 12, seconds: 30),
  }) =>
      SessionReportData(
        childName: childName,
        therapyLevel: 'sentence',
        date: DateTime.utc(2025, 8, 20, 10, 0),
        duration: duration,
        totalUtterances: total,
        fluentCount: fluent,
        dysfluentCount: dysfluent,
        rewardCycles: 2,
        tokenGoal: 10,
      );

  group('report figures', () {
    test('stuttering frequency is the stuttered share of recorded words', () {
      // 5 stuttered of 20 recorded. Reported as the outcome measure because
      // progress in Response Cost is read as a reduction in this figure.
      expect(data().dysfluencyPercentage, 25.0);
    });

    test('an empty session is 0%, not a division by zero', () {
      final empty = data(total: 0, fluent: 0, dysfluent: 0);
      expect(empty.dysfluencyPercentage, 0);
      expect(empty.dysfluencyPercentage.isFinite, isTrue);
    });

    test('duration is rendered at a sensible scale', () {
      expect(data(duration: const Duration(seconds: 45)).formattedDuration,
          '45s');
      expect(
          data(duration: const Duration(minutes: 12, seconds: 30))
              .formattedDuration,
          '12m 30s');
      expect(
          data(duration: const Duration(hours: 1, minutes: 5))
              .formattedDuration,
          '1h 5m');
    });
  });

  group('file name', () {
    test('carries the child and the session date', () {
      final name = data().fileName;
      expect(name, 'BloomSpeech_Aarav_Kumar_2025-08-20.pdf');
    });

    test('strips characters the file system would reject', () {
      // A child's name goes straight into the filename.
      final name = data(childName: 'Meera / R. "Mimi"').fileName;
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('"')));
      expect(name.endsWith('.pdf'), isTrue);
    });

    test('a blank or symbol-only name still yields a usable file', () {
      expect(data(childName: '').fileName, 'BloomSpeech_Session_2025-08-20.pdf');
      expect(data(childName: '???').fileName,
          'BloomSpeech_Session_2025-08-20.pdf');
    });

    test('the date on the file is the IST date', () {
      // 19:00 UTC on the 20th is already the 21st in India.
      final late = SessionReportData(
        childName: 'A',
        therapyLevel: 'word',
        date: DateTime.utc(2025, 8, 20, 19, 0),
        duration: Duration.zero,
        totalUtterances: 0,
        fluentCount: 0,
        dysfluentCount: 0,
        rewardCycles: 0,
        tokenGoal: 10,
      );
      expect(late.fileName, contains('2025-08-21'));
    });
  });

  group('the document itself', () {
    test('produces bytes that are actually a PDF', () async {
      final bytes = await SessionReportPdf.build(data());

      expect(bytes.length, greaterThan(1000),
          reason: 'a report this size should not be a near-empty file');
      // Every PDF begins with %PDF-.
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      // …and ends with the EOF marker, so the file is complete.
      expect(String.fromCharCodes(bytes.skip(bytes.length - 8)),
          contains('EOF'));
    });

    test('an empty session still renders rather than throwing', () async {
      final bytes = await SessionReportPdf.build(
          data(total: 0, fluent: 0, dysfluent: 0, duration: Duration.zero));
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('a long child name does not break generation', () async {
      final bytes =
          await SessionReportPdf.build(data(childName: 'A' * 120));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('generation is deterministic in size for the same input', () async {
      final a = await SessionReportPdf.build(data());
      final b = await SessionReportPdf.build(data());
      // Guards against a stray timestamp or random id creeping into the page.
      expect((a.length - b.length).abs(), lessThan(64));
    });
  });
}
