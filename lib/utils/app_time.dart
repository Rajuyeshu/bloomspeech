import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Time handling for BloomSpeech.
///
/// Timestamps are stored in UTC and displayed in India Standard Time.
/// Session rows come back from Supabase as UTC instants, and formatting a UTC
/// `DateTime` directly renders UTC clock time — which is why saved sessions
/// showed times 5h30m behind the clinic's wall clock.
///
/// IST is fixed rather than taken from the device locale so the whole care
/// team reads the same clock regardless of where a device is configured.
class AppTime {
  AppTime._();

  /// India Standard Time. No daylight saving, so a fixed offset is exact.
  static const Duration istOffset = Duration(hours: 5, minutes: 30);
  static const String istLabel = 'IST';

  /// Shift any instant onto the IST wall clock for display.
  static DateTime toIst(DateTime instant) =>
      instant.toUtc().add(istOffset);

  /// Format an instant on the IST clock.
  ///
  /// Never throws: a malformed pattern or an unavailable locale would
  /// otherwise take down whatever screen is rendering the date.
  static String format(DateTime instant, String pattern) {
    String fallback() => toIst(instant)
        .toIso8601String()
        .split('.')
        .first
        .replaceFirst('T', ' ');

    try {
      final out = DateFormat(pattern).format(toIst(instant));
      // DateFormat does not always throw on a pattern it cannot use — an
      // unterminated quote yields an empty string — so the catch below is not
      // enough on its own. A blank date field reads as missing data.
      if (out.trim().isEmpty) {
        debugPrint('Date pattern "$pattern" produced nothing; using fallback');
        return fallback();
      }
      return out;
    } catch (e) {
      debugPrint('Date format failed for "$pattern": $e');
      return fallback();
    }
  }

  /// Today's date on the IST calendar. Use for "is this today?" style checks;
  /// never store the result, since it carries IST values in a UTC-flagged
  /// object and writing it back would shift the instant a second time.
  static DateTime todayIst() {
    final n = toIst(DateTime.now());
    return DateTime.utc(n.year, n.month, n.day);
  }

  /// Canonical form for writing an instant to the backend. Always UTC and
  /// always with an explicit offset, so nothing has to guess a zone on read.
  static String toStorage(DateTime instant) =>
      instant.toUtc().toIso8601String();
}
