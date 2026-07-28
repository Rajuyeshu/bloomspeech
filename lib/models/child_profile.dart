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

  /// Create from Map (Supabase / JSON)
  factory ChildProfile.fromMap(Map<String, dynamic> data) {
    return ChildProfile(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      dateOfBirth: data['dateOfBirth'] is DateTime
          ? data['dateOfBirth']
          : DateTime.tryParse(data['dateOfBirth']?.toString() ?? '') ?? DateTime.now(),
      gender: data['gender'] ?? 'other',
      enrollmentDate: data['enrollmentDate'] is DateTime
          ? data['enrollmentDate']
          : DateTime.tryParse(data['enrollmentDate']?.toString() ?? '') ?? DateTime.now(),
      currentLevel: data['currentLevel'] ?? data['current_level'] ?? 'word',
      photoUrl: data['photoUrl'] ?? data['photo_url'],
      clinicianId: data['clinicianId'] ?? data['clinician_id'] ?? '',
      totalSessions: data['totalSessions'] ?? data['total_sessions'] ?? 0,
      lastSessionDate: data['lastSessionDate'] != null
          ? (data['lastSessionDate'] is DateTime
              ? data['lastSessionDate']
              : DateTime.tryParse(data['lastSessionDate'].toString()))
          : (data['last_session_date'] != null
              ? DateTime.tryParse(data['last_session_date'].toString())
              : null),
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
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
    );
  }
}
