import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// A record of one uncaught error.
class CrashRecord {
  final DateTime time;
  final String error;
  final String stack;

  const CrashRecord({
    required this.time,
    required this.error,
    required this.stack,
  });

  Map<String, dynamic> toMap() => {
        'time': time.toUtc().toIso8601String(),
        'error': error,
        'stack': stack,
      };

  static CrashRecord? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final time = DateTime.tryParse('${raw['time']}');
    if (time == null) return null;
    return CrashRecord(
      time: time,
      error: '${raw['error']}',
      stack: '${raw['stack']}',
    );
  }
}

/// Keeps the last few uncaught errors on the device.
///
/// In a release build `debugPrint` goes nowhere a user can see, so a crash
/// leaves no evidence at all — the only report available is "the app crashed",
/// which is not enough to fix anything. These records are surfaced in
/// Settings › Data Diagnostics so the actual error and stack can be read off
/// the device that crashed.
class CrashLog {
  CrashLog._();

  static const String boxName = 'crash_log';
  static const String _key = 'records';

  /// Deliberately small: this is for the last handful of failures, not an
  /// audit trail, and it lives on a clinician's tablet.
  static const int maxRecords = 20;

  /// Truncated so one enormous stack cannot fill the box.
  static const int _maxFieldLength = 4000;

  static String _clip(String s) =>
      s.length <= _maxFieldLength ? s : '${s.substring(0, _maxFieldLength)}…';

  static void record(Object error, StackTrace? stack) {
    try {
      if (!Hive.isBoxOpen(boxName)) return;
      final box = Hive.box(boxName);
      final existing = (box.get(_key) as List?) ?? const [];

      final updated = [
        {
          'time': DateTime.now().toUtc().toIso8601String(),
          'error': _clip(error.toString()),
          'stack': _clip(stack?.toString() ?? ''),
        },
        ...existing,
      ].take(maxRecords).toList();

      box.put(_key, updated);
    } catch (e) {
      // Never let the crash reporter become the crash.
      debugPrint('CrashLog.record failed: $e');
    }
  }

  static List<CrashRecord> recent() {
    try {
      if (!Hive.isBoxOpen(boxName)) return const [];
      final raw = (Hive.box(boxName).get(_key) as List?) ?? const [];
      return raw
          .map(CrashRecord.fromMap)
          .whereType<CrashRecord>()
          .toList(growable: false);
    } catch (e) {
      debugPrint('CrashLog.recent failed: $e');
      return const [];
    }
  }

  static Future<void> clear() async {
    try {
      if (Hive.isBoxOpen(boxName)) await Hive.box(boxName).delete(_key);
    } catch (e) {
      debugPrint('CrashLog.clear failed: $e');
    }
  }
}
