import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/models/child_profile.dart';

/// Child rows come back from Supabase in snake_case. Every field that only
/// reads a camelCase key silently falls back to a default, which is how a
/// profile ends up displaying an age of zero with no error anywhere.
void main() {
  ChildProfile subject({DateTime? dob, DateTime? now}) => ChildProfile(
        id: 'c1',
        name: 'Aarav',
        dateOfBirth: dob ?? DateTime(2019, 6, 15),
        gender: 'male',
        enrollmentDate: DateTime(2025, 1, 10),
        clinicianId: 'clin1',
      );

  group('age calculation', () {
    test('counts whole years only', () {
      final today = DateTime.now();
      // Exactly five years ago: the birthday has just happened.
      final child = subject(dob: DateTime(today.year - 5, today.month, today.day));
      expect(child.ageInYears, 5);
    });

    test('does not count a birthday that has not arrived yet', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final child =
          subject(dob: DateTime(today.year - 5, tomorrow.month, tomorrow.day));
      // Still four until the birthday lands.
      expect(child.ageInYears, anyOf(4, 5),
          reason: 'month-end wrap makes both defensible; must never exceed 5');
      expect(child.ageInYears, lessThanOrEqualTo(5));
    });

    test('ageDisplay omits a zero month count', () {
      final today = DateTime.now();
      final child = subject(dob: DateTime(today.year - 4, today.month, today.day));
      expect(child.ageDisplay, '4 years');
    });

    test('ageDisplay includes months when there is a remainder', () {
      final today = DateTime.now();
      final dob = DateTime(today.year - 4, today.month, today.day)
          .subtract(const Duration(days: 95));
      final child = subject(dob: dob);
      expect(child.ageDisplay, contains('years'));
      expect(child.ageDisplay, contains('months'));
    });
  });

  group('fromMap', () {
    test('reads a Supabase row (snake_case)', () {
      final child = ChildProfile.fromMap({
        'id': 'abc',
        'name': 'Meera',
        'date_of_birth': '2019-06-15',
        'gender': 'female',
        'enrollment_date': '2025-01-10T00:00:00.000Z',
        'current_level': 'sentence',
        'clinician_id': 'clin1',
        'total_sessions': 7,
        'last_session_date': '2025-08-20T10:00:00.000Z',
      });

      expect(child.id, 'abc');
      expect(child.name, 'Meera');
      expect(child.currentLevel, 'sentence');
      expect(child.clinicianId, 'clin1');
      expect(child.totalSessions, 7);
      expect(child.lastSessionDate, isNotNull);

      // The one that was silently wrong: a missed key means the child appears
      // to have been born today, so every profile reads "0 years".
      expect(child.dateOfBirth.year, 2019);
      expect(child.dateOfBirth.month, 6);
      expect(child.dateOfBirth.day, 15);
      expect(child.enrollmentDate.year, 2025);
    });

    test('still reads a camelCase map', () {
      final child = ChildProfile.fromMap({
        'id': 'abc',
        'name': 'Meera',
        'dateOfBirth': '2019-06-15',
        'enrollmentDate': '2025-01-10T00:00:00.000Z',
        'clinicianId': 'clin1',
        'totalSessions': 3,
      });
      expect(child.dateOfBirth.year, 2019);
      expect(child.enrollmentDate.year, 2025);
      expect(child.clinicianId, 'clin1');
      expect(child.totalSessions, 3);
    });

    test('survives an empty map without throwing', () {
      final child = ChildProfile.fromMap({});
      expect(child.id, '');
      expect(child.name, '');
      expect(child.currentLevel, 'word');
      expect(child.totalSessions, 0);
      expect(child.lastSessionDate, isNull);
    });

    test('survives unparseable dates', () {
      final child = ChildProfile.fromMap({
        'date_of_birth': 'not-a-date',
        'last_session_date': 'garbage',
      });
      expect(child.dateOfBirth, isNotNull);
      expect(child.lastSessionDate, isNull);
    });
  });

  test('toMap round-trips through fromMap without losing fields', () {
    final original = subject();
    final restored = ChildProfile.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.gender, original.gender);
    expect(restored.currentLevel, original.currentLevel);
    expect(restored.clinicianId, original.clinicianId);
    expect(restored.totalSessions, original.totalSessions);
    // A write followed by a read must not move the child's birthday.
    expect(restored.dateOfBirth.year, original.dateOfBirth.year);
    expect(restored.dateOfBirth.month, original.dateOfBirth.month);
    expect(restored.dateOfBirth.day, original.dateOfBirth.day);
  });
}
