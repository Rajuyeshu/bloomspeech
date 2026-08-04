import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../models/child_profile.dart';
import '../models/session.dart';
import '../config/constants/app_constants.dart';

/// Database service — handles CRUD operations and Realtime Stream sync via Supabase
class FirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════
  //  CLINICIAN PROFILE
  // ═══════════════════════════════════════════════

  /// Create or update clinician profile
  Future<void> setClinicianProfile({
    required String userId,
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase profile set warning: $e');
    }
  }

  /// Get clinician profile
  Future<Map<String, dynamic>?> getClinicianProfile(String userId) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return res;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  //  CHILD PROFILES
  // ═══════════════════════════════════════════════

  /// Add a new child profile
  Future<String> addChild({
    required String clinicianId,
    required ChildProfile child,
  }) async {
    final map = child.toMap();
    map['clinician_id'] = clinicianId;
    map.remove('id'); // Always remove client-side ID so PostgreSQL auto-generates primary key

    try {
      final res = await _supabase
          .from('children')
          .insert(map)
          .select('id')
          .single();
      return res['id'] as String;
    } catch (e) {
      debugPrint('Supabase addChild error: $e');
      return child.id.isNotEmpty ? child.id : DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Create a child profile for a registered patient (kid) linked directly to their user ID
  Future<void> createPatientChildProfile({
    required String childId,
    required String name,
    required String parentName,
    required String email,
  }) async {
    try {
      await _supabase.from('children').insert({
        'id': childId,
        'name': name,
        'clinician_id': 'patient_self', // Patient is self-managed
        'current_level': 'word',
        'enrollment_date': DateTime.now().toIso8601String(),
        'gender': 'other',
        'total_sessions': 0,
      });
    } catch (e) {
      debugPrint('Supabase createPatientChildProfile error: $e');
    }
  }

  /// Update child profile
  Future<void> updateChild({
    required String clinicianId,
    required String childId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (data.containsKey('name')) updateData['name'] = data['name'];
      if (data.containsKey('gender')) updateData['gender'] = data['gender'];
      if (data.containsKey('currentLevel')) updateData['current_level'] = data['currentLevel'];
      if (data.containsKey('totalSessions')) updateData['total_sessions'] = data['totalSessions'];
      if (data.containsKey('dateOfBirth')) {
        updateData['date_of_birth'] = data['dateOfBirth'] is DateTime
            ? (data['dateOfBirth'] as DateTime).toIso8601String().split('T').first
            : data['dateOfBirth'].toString();
      }

      await _supabase.from('children').update(updateData).eq('id', childId);
    } catch (e) {
      debugPrint('Supabase updateChild warning: $e');
    }
  }

  /// Delete child profile
  Future<void> deleteChild({
    required String clinicianId,
    required String childId,
  }) async {
    try {
      await _supabase.from('children').delete().eq('id', childId);
    } catch (e) {
      debugPrint('Supabase deleteChild warning: $e');
    }
  }

  /// Get all children for a clinician (Realtime stream)
  Stream<List<ChildProfile>> getChildren(String clinicianId) {
    try {
      return _supabase
          .from('children')
          .stream(primaryKey: ['id'])
          .eq('clinician_id', clinicianId)
          .order('name')
          .map((rows) => rows.map((r) => ChildProfile.fromMap(r)).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get a single child profile
  Future<ChildProfile?> getChild({
    required String clinicianId,
    required String childId,
  }) async {
    try {
      final res = await _supabase
          .from('children')
          .select()
          .eq('id', childId)
          .maybeSingle();
      if (res == null) return null;
      return ChildProfile.fromMap(res);
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  //  SESSIONS
  // ═══════════════════════════════════════════════

  /// Save a completed session
  Future<String> saveSession({
    required String clinicianId,
    required String childId,
    required Session session,
  }) async {
    try {
      final res = await _supabase.from('sessions').insert({
        'child_id': childId,
        'clinician_id': clinicianId,
        'session_number': session.sessionNumber,
        'date': session.date.toIso8601String(),
        'therapy_level': session.therapyLevel,
        'play_theme': session.playTheme,
        'mini_game': session.miniGame,
        'stats': session.stats.toFirestore(),
      }).select('id').single();

      // Update child's session count
      await updateChild(
        clinicianId: clinicianId,
        childId: childId,
        data: {
          'totalSessions': session.sessionNumber,
          'currentLevel': session.therapyLevel,
        },
      );

      return res['id'] as String;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Get all sessions for a child
  Stream<List<Session>> getSessions({
    required String clinicianId,
    required String childId,
  }) {
    try {
      return _supabase
          .from('sessions')
          .stream(primaryKey: ['id'])
          .eq('child_id', childId)
          .order('date', ascending: false)
          .map((rows) => rows.map((r) {
                return Session(
                  id: r['id'] ?? '',
                  childId: r['child_id'] ?? childId,
                  clinicianId: r['clinician_id'] ?? clinicianId,
                  sessionNumber: r['session_number'] ?? 1,
                  date: DateTime.tryParse(r['date'] ?? '') ?? DateTime.now(),
                  therapyLevel: r['therapy_level'] ?? 'word',
                  playTheme: r['play_theme'] ?? 'diyaFestival',
                  miniGame: r['mini_game'] ?? 'bubbleBurst',
                  config: SessionConfig(
                    childId: childId,
                    childName: '',
                    sessionNumber: r['session_number'] ?? 1,
                    therapyLevel: r['therapy_level'] ?? 'word',
                  ),
                  stats: SessionStats.fromFirestore(
                      r['stats'] is Map<String, dynamic> ? r['stats'] : {}),
                );
              }).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get last N sessions for trend analysis
  Future<List<Session>> getRecentSessions({
    required String clinicianId,
    required String childId,
    int limit = 3,
  }) async {
    try {
      final res = await _supabase
          .from('sessions')
          .select()
          .eq('child_id', childId)
          .order('date', ascending: false)
          .limit(limit);

      return (res as List).map((r) {
        return Session(
          id: r['id'] ?? '',
          childId: r['child_id'] ?? childId,
          clinicianId: r['clinician_id'] ?? clinicianId,
          sessionNumber: r['session_number'] ?? 1,
          date: DateTime.tryParse(r['date'] ?? '') ?? DateTime.now(),
          therapyLevel: r['therapy_level'] ?? 'word',
          playTheme: r['play_theme'] ?? 'diyaFestival',
          miniGame: r['mini_game'] ?? 'bubbleBurst',
          config: SessionConfig(
            childId: childId,
            childName: '',
            sessionNumber: r['session_number'] ?? 1,
            therapyLevel: r['therapy_level'] ?? 'word',
          ),
          stats: SessionStats.fromFirestore(
              r['stats'] is Map<String, dynamic> ? r['stats'] : {}),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get session count for a child
  Future<int> getSessionCount({
    required String clinicianId,
    required String childId,
  }) async {
    try {
      final res = await _supabase
          .from('sessions')
          .select('id')
          .eq('child_id', childId);
      return (res as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════
  //  UTTERANCES
  // ═══════════════════════════════════════════════

  /// Save utterances for a session
  Future<void> saveUtterances({
    required String clinicianId,
    required String childId,
    required String sessionId,
    required List<Utterance> utterances,
  }) async {
    try {
      final rows = utterances.map((u) => {
            'session_id': sessionId,
            'timestamp': u.timestamp.toIso8601String(),
            'type': u.type.name,
            'token_count_after': u.tokenCountAfter,
          }).toList();

      await _supabase.from('utterances').insert(rows);
    } catch (e) {
      debugPrint('Supabase saveUtterances warning: $e');
    }
  }

  /// Get utterances for a session
  Future<List<Utterance>> getUtterances({
    required String clinicianId,
    required String childId,
    required String sessionId,
  }) async {
    try {
      final res = await _supabase
          .from('utterances')
          .select()
          .eq('session_id', sessionId)
          .order('timestamp');

      return (res as List).map((r) {
        return Utterance(
          id: r['id'] ?? '',
          timestamp: DateTime.tryParse(r['timestamp'] ?? '') ?? DateTime.now(),
          type: UtteranceType.values.firstWhere(
            (e) => e.name == r['type'],
            orElse: () => UtteranceType.fluent,
          ),
          tokenCountAfter: r['token_count_after'] ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  //  ACTIVE SESSIONS (Supabase Realtime Dual-Device Sync)
  // ═══════════════════════════════════════════════

  /// Create an active session for dual-device sync
  Future<void> createActiveSession(ActiveSession session) async {
    try {
      await _supabase.from('active_sessions').upsert({
        'session_code': session.sessionCode,
        'clinician_id': session.clinicianId,
        'child_id': session.childId,
        'child_name': session.childName,
        'current_token_count': session.currentTokenCount,
        'token_goal': session.tokenGoal,
        'therapy_level': session.therapyLevel,
        'play_theme': session.playTheme,
        'mini_game': session.miniGame,
        'language': session.language,
        'reward_cycles_completed': session.rewardCyclesCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase createActiveSession warning: $e');
    }
  }

  /// Update active session (partial update)
  Future<void> updateActiveSession({
    required String sessionCode,
    required Map<String, dynamic> data,
  }) async {
    try {
      final updateMap = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (data.containsKey('currentTokenCount')) {
        updateMap['current_token_count'] = data['currentTokenCount'];
      }
      if (data.containsKey('lastFeedbackType')) {
        updateMap['last_feedback_type'] = data['lastFeedbackType'];
      }
      if (data.containsKey('lastFeedbackTime')) {
        final val = data['lastFeedbackTime'];
        updateMap['last_feedback_time'] = val is DateTime
            ? val.toIso8601String()
            : val.toString();
      }
      if (data.containsKey('rewardCyclesCompleted')) {
        updateMap['reward_cycles_completed'] = data['rewardCyclesCompleted'];
      }

      await _supabase
          .from('active_sessions')
          .update(updateMap)
          .eq('session_code', sessionCode);
    } catch (e) {
      debugPrint('Supabase updateActiveSession warning: $e');
    }
  }

  /// Listen to active session changes (Realtime stream for kid's device)
  Stream<ActiveSession?> listenToActiveSession(String sessionCode) {
    try {
      return _supabase
          .from('active_sessions')
          .stream(primaryKey: ['session_code'])
          .eq('session_code', sessionCode)
          .map((data) {
        if (data.isEmpty) return null;
        return ActiveSession.fromMap(data.first);
      });
    } catch (e) {
      return Stream.value(null);
    }
  }

  /// Fetch active session by code (one-shot query — reliable cross-device)
  Future<ActiveSession?> fetchActiveSession(String sessionCode) async {
    try {
      final res = await _supabase
          .from('active_sessions')
          .select()
          .eq('session_code', sessionCode)
          .maybeSingle();
      if (res == null) return null;
      return ActiveSession.fromMap(res);
    } catch (e) {
      debugPrint('Supabase fetchActiveSession error: $e');
      return null;
    }
  }

  /// Delete active session (cleanup after session ends)
  Future<void> deleteActiveSession(String sessionCode) async {
    try {
      await _supabase
          .from('active_sessions')
          .delete()
          .eq('session_code', sessionCode);
    } catch (e) {
      debugPrint('Supabase deleteActiveSession warning: $e');
    }
  }

  /// Check if session code exists
  Future<bool> sessionCodeExists(String sessionCode) async {
    try {
      final res = await _supabase
          .from('active_sessions')
          .select('session_code')
          .eq('session_code', sessionCode);
      return (res as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Riverpod provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
