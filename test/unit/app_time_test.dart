import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/utils/app_time.dart';

/// Sessions are stored as UTC instants and read on an IST wall clock. Getting
/// this wrong is silent — a session simply displays a time 5h30m off, which
/// looks like a stale record rather than a bug.
void main() {
  group('toIst', () {
    test('shifts a UTC instant onto the India clock', () {
      final utc = DateTime.utc(2025, 8, 20, 10, 0);
      final ist = AppTime.toIst(utc);
      expect(ist.hour, 15);
      expect(ist.minute, 30);
      expect(ist.day, 20);
    });

    test('rolls over midnight correctly', () {
      // 19:00 UTC is 00:30 the next day in India.
      final ist = AppTime.toIst(DateTime.utc(2025, 8, 20, 19, 0));
      expect(ist.day, 21);
      expect(ist.hour, 0);
      expect(ist.minute, 30);
    });

    test('a local-flagged instant is normalised before shifting', () {
      final utc = DateTime.utc(2025, 8, 20, 10, 0);
      // Same instant, expressed in the machine's local zone.
      final asLocal = utc.toLocal();
      expect(AppTime.toIst(asLocal), AppTime.toIst(utc),
          reason: 'the result must not depend on the device time zone');
    });

    test('the offset is exactly 5h30m in both directions', () {
      final utc = DateTime.utc(2025, 1, 1, 0, 0);
      expect(AppTime.toIst(utc).difference(utc), AppTime.istOffset);
      expect(AppTime.istOffset, const Duration(hours: 5, minutes: 30));
    });
  });

  group('format', () {
    test('renders IST clock time, not UTC', () {
      final s = AppTime.format(DateTime.utc(2025, 8, 20, 10, 0), 'HH:mm');
      expect(s, '15:30');
    });

    test('renders the IST date across a midnight boundary', () {
      final s = AppTime.format(DateTime.utc(2025, 8, 20, 19, 0), 'd MMM yyyy');
      expect(s, '21 Aug 2025');
    });

    test('a malformed pattern falls back instead of taking down the screen', () {
      // An unterminated quote is one of the few patterns DateFormat actually
      // rejects; unknown letters are passed through as literals instead.
      final s = AppTime.format(DateTime.utc(2025, 8, 20, 10, 0), "'unclosed");
      expect(s, contains('2025'),
          reason: 'should fall back to an ISO-style IST string');
      expect(s, contains('15:30'), reason: 'the fallback is still on IST');
    });

    test('never throws, whatever pattern it is handed', () {
      for (final pattern in ['', 'not a pattern', "'unclosed", 'yyyy-MM-dd']) {
        expect(() => AppTime.format(DateTime.utc(2025, 8, 20), pattern),
            returnsNormally,
            reason: 'pattern "$pattern" must not reach the widget tree');
      }
    });
  });

  group('toStorage', () {
    test('always writes UTC with an explicit zone', () {
      final s = AppTime.toStorage(DateTime.utc(2025, 8, 20, 10, 0));
      expect(s, '2025-08-20T10:00:00.000Z');
      expect(s.endsWith('Z'), isTrue);
    });

    test('a display value is never written back double-shifted', () {
      final instant = DateTime.utc(2025, 8, 20, 10, 0);
      // Storing the original instant must round-trip exactly.
      final restored = DateTime.parse(AppTime.toStorage(instant));
      expect(restored, instant);
    });
  });

  group('todayIst', () {
    test('has no time component', () {
      final t = AppTime.todayIst();
      expect(t.hour, 0);
      expect(t.minute, 0);
      expect(t.second, 0);
    });

    test('matches the IST calendar date of now', () {
      final t = AppTime.todayIst();
      final nowIst = AppTime.toIst(DateTime.now());
      expect(t.year, nowIst.year);
      expect(t.month, nowIst.month);
      expect(t.day, nowIst.day);
    });
  });
}
