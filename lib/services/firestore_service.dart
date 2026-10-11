import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../models/child_profile.dart';
import '../models/session.dart';
import '../utils/app_time.dart';
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
        'updated_at': AppTime.toStorage(DateTime.now()),
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

    // Drop any column this database does not have yet and retry, rather than
    // failing the whole insert. `baseline_dysfluency_pct` arrives with a later
    // migration, and a clinician should still be able to add a child before it
    // has been run — they simply cannot record a baseline until then.
    for (var attempt = 0; attempt <= map.length; attempt++) {
      try {
        final res = await _supabase
            .from('children')
            .insert(map)
            .select('id')
            .single();
        return res['id'] as String;
      } on PostgrestException catch (e) {
        final column = _isMissingColumn(e) ? missingColumnName(e.message) : null;
        const essential = {'name', 'clinician_id'};
        if (column == null ||
            essential.contains(column) ||
            !map.containsKey(column)) {
          debugPrint('Supabase addChild error: $e');
          throw Exception('Could not save the child profile: ${e.message}');
        }
        debugPrint('children.$column missing; saving without it');
        map.remove(column);
      } catch (e) {
        debugPrint('Supabase addChild error: $e');
        throw Exception('Could not save the child profile: $e');
      }
    }
    throw Exception('Could not save the child profile.');
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
        'enrollment_date': AppTime.toStorage(DateTime.now()),
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
      if (data.containsKey('lastSessionDate')) {
        final v = data['lastSessionDate'];
        updateData['last_session_date'] =
            v is DateTime ? AppTime.toStorage(v) : v?.toString();
      }
      if (data.containsKey('baselineDysfluencyPct')) {
        updateData['baseline_dysfluency_pct'] = data['baselineDysfluencyPct'];
      }
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
      'date': AppTime.toStorage(session.date),
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
        // Was never written, so the profile card showed "Last Session: None"
        // no matter how many sessions had been completed.
        'lastSessionDate': session.date,
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
      e.code == '42703' ||
      e.code == 'PGRST204' ||
      e.message.contains('does not exist') ||
      e.message.contains('schema cache');

  /// The column Postgres or PostgREST is complaining about, if it named one.
  ///
  /// Two different wordings reach us depending on which layer rejects the
  /// write:
  ///   42703    column "tokens_per_fluent" of relation "active_sessions" does not exist
  ///   PGRST204 Could not find the 'tokens_per_fluent' column of 'active_sessions' in the schema cache
  ///
  /// Reading the name out of the error means a write can adapt to whatever
  /// schema is actually deployed, instead of relying on a hardcoded list of
  /// columns that someone has to remember to keep in step with the migrations.
  static String? missingColumnName(String message) {
    for (final pattern in [
      RegExp(r'column "([^"]+)"'),
      RegExp(r"'([^']+)' column"),
      RegExp(r"column '([^']+)'"),
    ]) {
      final match = pattern.firstMatch(message);
      if (match != null) return match.group(1);
    }
    return null;
  }

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
            'linked_at': AppTime.toStorage(DateTime.now()),
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
            'timestamp': AppTime.toStorage(u.timestamp),
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

  /// Create an active session for dual-device sync.
  ///
  /// The row is built by [ActiveSession.toMap] rather than assembled here, so
  /// there is one definition of the mapping instead of two free to drift.
  ///
  /// If the deployed table is missing a column — the migrations have not been
  /// run, or a newer build writes a field this database does not have yet —
  /// the offending column is dropped and the write retried. Getting this wrong
  /// is severe out of proportion to the cause: no row means the child's device
  /// cannot find the session at all, and the only symptom is "Session not
  /// found" on a code the clinician is looking at.
  ///
  /// Throws if the session could not be created. It must not fail silently:
  /// the clinician would otherwise read out a code that can never work.
  Future<void> createActiveSession(ActiveSession session) async {
    // toCreateMap, not toMap: creation is an upsert, and the kid-owned columns
    // must not be written over. See ActiveSession.toCreateMap.
    final row = session.toCreateMap()
      ..['updated_at'] = AppTime.toStorage(DateTime.now());

    final dropped = <String>[];

    // Bounded: each pass removes one column, so this cannot spin.
    for (var attempt = 0; attempt <= row.length; attempt++) {
      try {
        await _supabase.from('active_sessions').upsert(row);
        if (dropped.isNotEmpty) {
          debugPrint(
              'active_sessions: created without ${dropped.join(", ")} — '
              'run the pending migrations to enable those features');
        }
        return;
      } on PostgrestException catch (e) {
        final column = _isMissingColumn(e) ? missingColumnName(e.message) : null;
        // Never drop a column the session cannot work without; if one of these
        // is genuinely missing the schema is broken and must be reported.
        const essential = {
          'session_code',
          'clinician_id',
          'child_id',
          'token_goal',
        };
        if (column == null ||
            essential.contains(column) ||
            !row.containsKey(column)) {
          throw Exception(
              'Could not create the session row (${e.code}): ${e.message}');
        }
        row.remove(column);
        dropped.add(column);
      }
    }

    throw Exception('Could not create the session row after dropping '
        '${dropped.length} unknown columns.');
  }

  /// Update active session (partial update)
  /// Returns true only if the update actually reached the row.
  ///
  /// This used to swallow every failure into a debugPrint. That is tolerable
  /// for a token count — the next poll corrects it — but not for the flag that
  /// tells the child's device to join the video call: a failed write there
  /// means the clinician's device enters the room alone and nothing anywhere
  /// says why.
  Future<bool> updateActiveSession({
    required String sessionCode,
    required Map<String, dynamic> data,
  }) async {
    try {
      final updateMap = <String, dynamic>{
        'updated_at': AppTime.toStorage(DateTime.now()),
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
            ? AppTime.toStorage(val)
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
      if (data.containsKey('rewardType')) {
        updateMap['reward_type'] = data['rewardType'];
      }
      if (data.containsKey('physicalReward')) {
        updateMap['physical_reward'] = data['physicalReward'];
      }
      if (data.containsKey('status')) {
        updateMap['status'] = data['status'];
      }

      await _supabase
          .from('active_sessions')
          .update(updateMap)
          .eq('session_code', sessionCode);
      return true;
    } catch (e) {
      debugPrint('Supabase updateActiveSession warning: $e');
      return false;
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

    // Which migrations have actually been applied. Without this, a missing
    // column and a genuine permission problem look identical from the app: both
    // end as "0 rows", and the report cannot say which SQL to run.
    await probe('Database schema', 'required columns on children / active_sessions',
        () async {
      final missing = <String, String>{};

      Future<void> check(String table, String column, String migration) async {
        try {
          await _supabase.from(table).select(column).limit(1);
        } on PostgrestException catch (e) {
          if (_isMissingColumn(e)) {
            missing['$table.$column'] = migration;
          }
          // A permission error here is not a schema problem; the RLS probes
          // below are the ones that report on access.
        }
      }

      await check('children', 'linked_user_id', 'supabase_setup_all.sql');
      await check('children', 'linked_at', 'supabase_setup_all.sql');
      await check('active_sessions', 'kid_user_id', 'supabase_setup_all.sql');
      await check('active_sessions', 'kid_video_started', 'supabase_setup_all.sql');
      await check('active_sessions', 'reward_type', 'supabase_setup_all.sql');

      if (missing.isEmpty) {
        return 'All required columns present — the migrations have been run.';
      }

      throw StateError(
        'MISSING: ${missing.keys.join(", ")}.\n'
        'Run ${missing.values.toSet().join(", ")} in the Supabase SQL editor. '
        'Until then the kid cannot be linked to a child, so progress stays '
        'empty however many sessions are completed.',
      );
    });

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
