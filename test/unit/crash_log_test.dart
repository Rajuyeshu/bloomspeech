import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bloomspeech/services/crash_log.dart';

/// A release build prints nowhere the user can see, so without this the only
/// available crash report is "the app crashed".
void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('crash_log_test').path);
  });

  setUp(() async {
    if (!Hive.isBoxOpen(CrashLog.boxName)) {
      await Hive.openBox(CrashLog.boxName);
    }
    await CrashLog.clear();
  });

  test('records an error with its stack', () {
    CrashLog.record(StateError('boom'), StackTrace.current);
    final recent = CrashLog.recent();

    expect(recent, hasLength(1));
    expect(recent.single.error, contains('boom'));
    expect(recent.single.stack, isNotEmpty);
  });

  test('the newest crash is first', () {
    CrashLog.record('first failure', StackTrace.current);
    CrashLog.record('second failure', StackTrace.current);

    final recent = CrashLog.recent();
    expect(recent.first.error, contains('second'));
    expect(recent.last.error, contains('first'));
  });

  test('keeps only the most recent records', () {
    for (var i = 0; i < CrashLog.maxRecords + 15; i++) {
      CrashLog.record('failure $i', StackTrace.current);
    }
    final recent = CrashLog.recent();

    expect(recent, hasLength(CrashLog.maxRecords));
    // The oldest are the ones discarded.
    expect(recent.first.error, contains('failure ${CrashLog.maxRecords + 14}'));
    expect(recent.map((c) => c.error), isNot(contains('failure 0')));
  });

  test('an enormous stack is truncated rather than stored whole', () {
    CrashLog.record('overflow', StackTrace.fromString('x' * 100000));
    final stored = CrashLog.recent().single;

    expect(stored.stack.length, lessThan(5000));
    expect(stored.stack.endsWith('…'), isTrue);
  });

  test('a null stack is handled', () {
    CrashLog.record('no stack available', null);
    expect(CrashLog.recent().single.stack, '');
  });

  test('clear empties the log', () async {
    CrashLog.record('boom', StackTrace.current);
    expect(CrashLog.recent(), isNotEmpty);

    await CrashLog.clear();
    expect(CrashLog.recent(), isEmpty);
  });

  test('records survive a box being closed and reopened', () async {
    CrashLog.record('persisted failure', StackTrace.current);
    await Hive.box(CrashLog.boxName).close();
    await Hive.openBox(CrashLog.boxName);

    expect(CrashLog.recent().single.error, contains('persisted failure'));
  });

  test('reporting never throws, even with the box closed', () async {
    await Hive.box(CrashLog.boxName).close();

    // The crash reporter must never become the crash.
    expect(() => CrashLog.record('while closed', StackTrace.current),
        returnsNormally);
    expect(CrashLog.recent(), isEmpty);

    await Hive.openBox(CrashLog.boxName);
  });

  test('malformed stored records are skipped, not fatal', () async {
    await Hive.box(CrashLog.boxName).put('records', [
      {'not': 'a record'},
      'a bare string',
      {'time': 'nonsense', 'error': 'x', 'stack': 'y'},
    ]);

    expect(CrashLog.recent(), isEmpty);
  });
}
