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

  /// Save a completed session.
  ///
  /// Throws on failure. This used to swallow every error and hand back a
  /// fabricated timestamp id, so a rejected insert (RLS, schema drift) looked
  /// identical to a successful save — the app showed a summary screen while
  /// nothing was written, and progress/history stayed empty forever with no
  /// error anywhere. Callers must surface the failure to the clinician.
  Future<String> saveSession({
    required String clinicianId,
    required String childId,
    required Session session,
  }) async {
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

    // Update the child's session count from the rows that actually exist,
    // rather than trusting the in-memory session number.
    final total = await getSessionCount(
      clinicianId: clinicianId,
      childId: childId,
    );
    await updateChild(
      clinicianId: clinicianId,
      childId: childId,
      data: {
        'totalSessions': total,
        'currentLevel': session.therapyLevel,
      },
    );

    return res['id'] as String;
  }

  /// Link a kid's login to the clinician's child record.
  ///
  /// A kid's account and the clinician's child profile are two different rows;
  /// sessions are stored against the clinician's. Without this stamp the kid's
  /// home and progress screens query their own empty profile and always show
  /// zero. Called when a kid joins a session with a code.
  /// Postgres 42703 = undefined_column. Raised when the app is newer than the
  /// database, i.e. a migration has not been run yet. Treated as "fall back to
  /// the older behaviour" rather than a fatal error, so a missed migration
  /// degrades the feature instead of blanking the screen.
  static bool _isMissingColumn(PostgrestException e) =>
      e.code == '42703' || e.message.contains('does not exist');

  Future<void> linkKidToChild({
    required String childId,
    required String kidUserId,
  }) async {
    // The link is a pointer to exactly one child, so it must be moved, not
    // added to. Leaving stale pointers behind is what made a kid's progress
    // resolve to an old child (and appear frozen at that child's session
    // count): several rows carried the same linked_user_id and the read picked
    // an arbitrary one. Release the kid from every other child first.
    await _supabase
        .from('children')
        .update({'linked_user_id': null})
        .eq('linked_user_id', kidUserId)
        .neq('id', childId);

    // Verify the write landed. A row-level-security policy that only lets the
    // owning clinician update `children` makes this update affect zero rows
    // and return success, leaving the kid permanently unlinked — and their
    // progress permanently empty — with nothing logged.
    //
    // `linked_at` only exists after migration 2; degrade rather than fail
    // outright so linking still works on a database that hasn't been migrated.
    List updated;
    try {
      updated = await _supabase
          .from('children')
          .update({
            'linked_user_id': kidUserId,
            'linked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', childId)
          .select('id') as List;
    } on PostgrestException catch (e) {
      if (!_isMissingColumn(e)) rethrow;
      updated = await _supabase
          .from('children')
          .update({'linked_user_id': kidUserId})
          .eq('id', childId)
          .select('id') as List;
    }

    if (updated.isEmpty) {
      throw Exception(
        'Could not link this device to child $childId. The update matched no '
        'rows — check the row-level-security policy on `children`.',
      );
    }
  }

  /// Resolve the child profile a kid's login is attached to.
  /// Falls back to a profile whose id *is* the user id (self-managed patients).
  Future<ChildProfile?> getChildForKid(String kidUserId) async {
    // Order explicitly. An unordered `limit(1)` lets Postgres return any
    // matching row, so a leftover link from an earlier session could win
    // permanently and pin the kid to the wrong child.
    List rows;
    try {
      rows = await _supabase
          .from('children')
          .select()
          .eq('linked_user_id', kidUserId)
          .order('linked_at', ascending: false, nullsFirst: false)
          .limit(1) as List;
    } on PostgrestException catch (e) {
      if (!_isMissingColumn(e)) rethrow;
      // Pre-migration-2 database: no `linked_at` to order by. Fall back to the
      // unordered read rather than throwing, which would blank the kid's home
      // screen entirely.
      debugPrint('children.linked_at missing — run supabase_migration_2.sql');
      rows = await _supabase
          .from('children')
          .select()
          .eq('linked_user_id', kidUserId)
          .limit(1) as List;
    }
    if (rows.isNotEmpty) {
      return ChildProfile.fromMap(rows.first as Map<String, dynamic>);
    }
    return getChild(clinicianId: 'patient_self', childId: kidUserId);
  }

  /// Fetch all sessions for a child as a one-shot query.
  ///
  /// Prefer this over [getSessions] for read-only screens. The realtime
  /// `.stream()` version emits its initial snapshot and then, if the table is
  /// not in the `supabase_realtime` publication or RLS blocks the realtime
  /// channel, re-emits an empty list — which is why progress and history
  /// appeared for a couple of seconds and then wiped themselves.
  Future<List<Session>> fetchSessions({
    required String clinicianId,
    required String childId,
  }) async {
    final rows = await _supabase
        .from('sessions')
        .select()
        .eq('child_id', childId)
        .order('date', ascending: false);

    return (rows as List)
        .map((r) => _sessionFromRow(r as Map<String, dynamic>, clinicianId, childId))
        .toList();
  }

  Session _sessionFromRow(
      Map<String, dynamic> r, String clinicianId, String childId) {
    return Session(
      id: r['id']?.toString() ?? '',
      childId: r['child_id'] ?? childId,
      clinicianId: r['clinician_id'] ?? clinicianId,
      sessionNumber: r['session_number'] ?? 1,
      date: DateTime.tryParse(r['date']?.toString() ?? '') ?? DateTime.now(),
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
  }

  /// Fetch a clinician's children as a one-shot query.
  /// Same reasoning as [fetchSessions] — the realtime list could blank itself.
  Future<List<ChildProfile>> fetchChildren(String clinicianId) async {
    final rows = await _supabase
        .from('children')
        .select()
        .eq('clinician_id', clinicianId)
        .order('name');
    return (rows as List)
        .map((r) => ChildProfile.fromMap(r as Map<String, dynamic>))
        .toList();
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
        'reward_active': false,
        'mini_game_active': false,
        'status': 'active',
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
      if (data.containsKey('rewardActive')) {
        updateMap['reward_active'] = data['rewardActive'];
      }
      if (data.containsKey('miniGameActive')) {
        updateMap['mini_game_active'] = data['miniGameActive'];
      }
      if (data.containsKey('kidVideoStarted')) {
        updateMap['kid_video_started'] = data['kidVideoStarted'];
      }
      if (data.containsKey('kidAudioMuted')) {
        updateMap['kid_audio_muted'] = data['kidAudioMuted'];
      }
      if (data.containsKey('kidVideoMuted')) {
        updateMap['kid_video_muted'] = data['kidVideoMuted'];
      }
      if (data.containsKey('kidUserId')) {
        updateMap['kid_user_id'] = data['kidUserId'];
      }
      if (data.containsKey('status')) {
        updateMap['status'] = data['status'];
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

  /// Runs, in order, every API call the kid's progress screens depend on and
  /// reports exactly what each one returned.
  ///
  /// Each step is probed independently so a permission denial is attributed to
  /// the specific table that refused, rather than surfacing as a blank screen.
  Future<List<DiagnosticStep>> runKidDataDiagnostics(String kidUserId) async {
    final steps = <DiagnosticStep>[];

    Future<void> probe(
      String name,
      String query,
      Future<String> Function() run,
    ) async {
      try {
        steps.add(DiagnosticStep(
            name: name, query: query, result: await run(), ok: true));
      } catch (e) {
        steps.add(DiagnosticStep(
            name: name, query: query, result: '$e', ok: false));
      }
    }

    steps.add(DiagnosticStep(
      name: 'Signed-in user id',
      query: 'auth.uid()',
      result: kidUserId.isEmpty ? '(none — not signed in)' : kidUserId,
      ok: kidUserId.isNotEmpty,
    ));

    String? resolvedChildId;

    await probe('Linked child row',
        "children where linked_user_id = '$kidUserId'", () async {
      List rows;
      try {
        rows = await _supabase
            .from('children')
            .select('id, name, total_sessions, linked_at')
            .eq('linked_user_id', kidUserId)
            .order('linked_at', ascending: false, nullsFirst: false) as List;
      } on PostgrestException catch (e) {
        if (!_isMissingColumn(e)) rethrow;
        rows = await _supabase
            .from('children')
            .select('id, name, total_sessions')
            .eq('linked_user_id', kidUserId) as List;
        if (rows.isNotEmpty) {
          resolvedChildId = rows.first['id']?.toString();
          return '${rows.length} row(s) — but `children.linked_at` is missing, '
              'so supabase_migration_2.sql has NOT been run. Run it: without it '
              'a kid linked to more than one child resolves unpredictably. '
              'Rows: $rows';
        }
      }
      if (rows.isEmpty) {
        return '0 rows — this kid is not linked to any child. Progress will be '
            'empty. Complete a session to link, or check the RLS policy that '
            'allows the clinician to write children.linked_user_id.';
      }
      resolvedChildId = rows.first['id']?.toString();
      return '${rows.length} row(s): $rows';
    });

    await probe('Self-managed fallback', "children where id = '$kidUserId'",
        () async {
      final row = await _supabase
          .from('children')
          .select('id, name, total_sessions')
          .eq('id', kidUserId)
          .maybeSingle();
      return row == null ? 'none' : '$row';
    });

    final childId = resolvedChildId ?? kidUserId;

    await probe('Sessions visible to this login',
        "sessions where child_id = '$childId'", () async {
      final rows = await _supabase
          .from('sessions')
          .select('id, session_number, date')
          .eq('child_id', childId)
          .order('date', ascending: false) as List;
      if (rows.isEmpty) {
        return '0 rows for child $childId. If the clinician can see sessions '
            'for this child, the rows exist and this login is being refused '
            'by row-level security on `sessions`.';
      }
      return '${rows.length} session(s); newest: ${rows.first}';
    });

    return steps;
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

/// One probe of a single API call, for the diagnostics screen.
class DiagnosticStep {
  final String name;
  final String query;
  final String result;
  final bool ok;

  DiagnosticStep({
    required this.name,
    required this.query,
    required this.result,
    required this.ok,
  });
}

/// Riverpod provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

/// Bumped whenever something changes a child's session data (a session ends,
/// a kid is re-linked). Screens that read with a one-shot query watch this so
/// they re-query instead of showing a stale count forever.
final dataRefreshProvider = StateProvider<int>((ref) => 0);
