/// Child profile model
class ChildProfile {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String gender; // 'male', 'female', 'other'
  final DateTime enrollmentDate;
  final String currentLevel; // TherapyLevel name
  final String? photoUrl;
  final String clinicianId;
  final int totalSessions;
  final DateTime? lastSessionDate;

  /// Stuttering frequency measured before treatment began, as a percentage.
  ///
  /// Null when it has not been recorded. Kept on the child rather than the
  /// session because it is a single pre-treatment measure that every later
  /// session is read against.
  final double? baselineDysfluencyPct;

  ChildProfile({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.enrollmentDate,
    this.currentLevel = 'word',
    this.photoUrl,
    required this.clinicianId,
    this.totalSessions = 0,
    this.lastSessionDate,
    this.baselineDysfluencyPct,
  });

  /// Calculate age in years from DOB
  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Calculate age in months
  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (now.day < dateOfBirth.day) {
      months--;
    }
    return months;
  }

  /// Display age string (e.g., "4 years 6 months")
  String get ageDisplay {
    final years = ageInYears;
    final months = ageInMonths % 12;
    if (months == 0) return '$years years';
    return '$years years $months months';
  }

  /// Parse a value that may arrive as a DateTime, an ISO string, or nothing.
  /// Returns null for anything unusable so callers choose their own default.
  /// A percentage, or null. Anything unusable or out of range is discarded
  /// rather than charted as a nonsense baseline.
  static double? _pct(dynamic v) {
    if (v == null) return null;
    final d = v is num ? v.toDouble() : double.tryParse('$v');
    if (d == null || !d.isFinite || d < 0 || d > 100) return null;
    return d;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  /// Create from Map (Supabase / JSON)
  factory ChildProfile.fromMap(Map<String, dynamic> data) {
    return ChildProfile(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      // Supabase columns are snake_case and `toMap` writes them that way, but
      // both of these only ever read the camelCase key. Every child loaded
      // from the database therefore fell through to DateTime.now() and showed
      // an age of "0 years" — with no error to point at.
      dateOfBirth: _date(data['date_of_birth'] ?? data['dateOfBirth']) ??
          DateTime.now(),
      gender: data['gender'] ?? 'other',
      enrollmentDate: _date(data['enrollment_date'] ?? data['enrollmentDate']) ??
          DateTime.now(),
      currentLevel: data['currentLevel'] ?? data['current_level'] ?? 'word',
      photoUrl: data['photoUrl'] ?? data['photo_url'],
      clinicianId: data['clinicianId'] ?? data['clinician_id'] ?? '',
      totalSessions: data['totalSessions'] ?? data['total_sessions'] ?? 0,
      lastSessionDate:
          _date(data['last_session_date'] ?? data['lastSessionDate']),
      baselineDysfluencyPct: _pct(
          data['baseline_dysfluency_pct'] ?? data['baselineDysfluencyPct']),
    );
  }

  /// Convert to Map for Supabase / JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'gender': gender,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'current_level': currentLevel,
      'photo_url': photoUrl,
      'clinician_id': clinicianId,
      'total_sessions': totalSessions,
      'last_session_date': lastSessionDate?.toIso8601String(),
      'baseline_dysfluency_pct': baselineDysfluencyPct,
    };
  }

  /// Create a copy with updated fields
  ChildProfile copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? enrollmentDate,
    String? currentLevel,
    String? photoUrl,
    String? clinicianId,
    int? totalSessions,
    DateTime? lastSessionDate,
    double? baselineDysfluencyPct,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      currentLevel: currentLevel ?? this.currentLevel,
      photoUrl: photoUrl ?? this.photoUrl,
      clinicianId: clinicianId ?? this.clinicianId,
      totalSessions: totalSessions ?? this.totalSessions,
      baselineDysfluencyPct:
          baselineDysfluencyPct ?? this.baselineDysfluencyPct,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
    );
  }
}
