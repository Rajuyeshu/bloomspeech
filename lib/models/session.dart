import '../config/constants/app_constants.dart';
import '../utils/app_time.dart';

/// Session configuration model — set by clinician before each session
class SessionConfig {
  final String childId;
  final String childName;
  final int sessionNumber;
  final String therapyLevel; // TherapyLevel name
  final int tokensPerFluent;
  final int tokensPerDysfluent;
  final int tokenGoal;
  final String playTheme; // PlayTheme name
  final String rewardType; // RewardType name ('inAppAnimation', 'inAppMiniGame', 'physicalReward')
  final String miniGame; // MiniGameType name
  final int sessionTimerMinutes; // 0 = off
  final String? physicalReward; // Key from BilingualPhrases.physicalRewards
  final String language; // 'en' or 'kn'

  SessionConfig({
    required this.childId,
    required this.childName,
    this.sessionNumber = 1,
    this.therapyLevel = 'word',
    this.tokensPerFluent = AppConstants.defaultTokensPerFluent,
    this.tokensPerDysfluent = AppConstants.defaultTokensPerDysfluent,
    this.tokenGoal = AppConstants.defaultTokenGoal,
    this.playTheme = 'diyaFestival',
    this.rewardType = 'inAppMiniGame',
    this.miniGame = 'bubbleBurst',
    this.sessionTimerMinutes = 0,
    this.physicalReward,
    this.language = 'en',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'childName': childName,
      'sessionNumber': sessionNumber,
      'therapyLevel': therapyLevel,
      'tokensPerFluent': tokensPerFluent,
      'tokensPerDysfluent': tokensPerDysfluent,
      'tokenGoal': tokenGoal,
      'playTheme': playTheme,
      'rewardType': rewardType,
      'miniGame': miniGame,
      'sessionTimerMinutes': sessionTimerMinutes,
      'physicalReward': physicalReward,
      'language': language,
    };
  }

  factory SessionConfig.fromFirestore(Map<String, dynamic> data) {
    return SessionConfig(
      childId: data['childId'] ?? '',
      childName: data['childName'] ?? '',
      sessionNumber: data['sessionNumber'] ?? 1,
      therapyLevel: data['therapyLevel'] ?? 'word',
      tokensPerFluent: data['tokensPerFluent'] ?? AppConstants.defaultTokensPerFluent,
      tokensPerDysfluent: data['tokensPerDysfluent'] ?? AppConstants.defaultTokensPerDysfluent,
      tokenGoal: data['tokenGoal'] ?? AppConstants.defaultTokenGoal,
      playTheme: data['playTheme'] ?? 'diyaFestival',
      rewardType: data['rewardType'] ?? 'inAppMiniGame',
      miniGame: data['miniGame'] ?? 'bubbleBurst',
      sessionTimerMinutes: data['sessionTimerMinutes'] ?? 0,
      physicalReward: data['physicalReward'],
      language: data['language'] ?? 'en',
    );
  }

  SessionConfig copyWith({
    String? childId,
    String? childName,
    int? sessionNumber,
    String? therapyLevel,
    int? tokensPerFluent,
    int? tokensPerDysfluent,
    int? tokenGoal,
    String? playTheme,
    String? rewardType,
    String? miniGame,
    int? sessionTimerMinutes,
    String? physicalReward,
    String? language,
  }) {
    return SessionConfig(
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      therapyLevel: therapyLevel ?? this.therapyLevel,
      tokensPerFluent: tokensPerFluent ?? this.tokensPerFluent,
      tokensPerDysfluent: tokensPerDysfluent ?? this.tokensPerDysfluent,
      tokenGoal: tokenGoal ?? this.tokenGoal,
      playTheme: playTheme ?? this.playTheme,
      rewardType: rewardType ?? this.rewardType,
      miniGame: miniGame ?? this.miniGame,
      sessionTimerMinutes: sessionTimerMinutes ?? this.sessionTimerMinutes,
      physicalReward: physicalReward ?? this.physicalReward,
      language: language ?? this.language,
    );
  }
}

/// Recorded utterance
class Utterance {
  final String id;
  final DateTime timestamp;
  final UtteranceType type;
  final int tokenCountAfter;
  final String? note;

  Utterance({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.tokenCountAfter,
    this.note,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'tokenCountAfter': tokenCountAfter,
      'note': note,
    };
  }

  factory Utterance.fromFirestore(Map<String, dynamic> data) {
    return Utterance(
      id: data['id'] ?? '',
      timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
      type: UtteranceType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => UtteranceType.fluent,
      ),
      tokenCountAfter: data['tokenCountAfter'] ?? data['token_count_after'] ?? 0,
      note: data['note'],
    );
  }
}

/// Session stats summary
class SessionStats {
  final int totalUtterances;
  final int fluentCount;
  final int dysfluentCount;
  final double fluencyPercentage;
  final int rewardCyclesCompleted;
  final Duration duration;

  SessionStats({
    required this.totalUtterances,
    required this.fluentCount,
    required this.dysfluentCount,
    required this.fluencyPercentage,
    required this.rewardCyclesCompleted,
    required this.duration,
  });

  factory SessionStats.calculate({
    required List<Utterance> utterances,
    required int rewardCycles,
    required Duration duration,
  }) {
    final fluent = utterances.where((u) => u.type == UtteranceType.fluent).length;
    final dysfluent = utterances.where((u) => u.type == UtteranceType.dysfluent).length;
    final total = fluent + dysfluent;

    return SessionStats(
      totalUtterances: total,
      fluentCount: fluent,
      dysfluentCount: dysfluent,
      fluencyPercentage: total > 0 ? (fluent / total) * 100 : 0,
      rewardCyclesCompleted: rewardCycles,
      duration: duration,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalUtterances': totalUtterances,
      'fluentCount': fluentCount,
      'dysfluentCount': dysfluentCount,
      'fluencyPercentage': fluencyPercentage,
      'rewardCyclesCompleted': rewardCyclesCompleted,
      'durationSeconds': duration.inSeconds,
    };
  }

  /// Stuttering (dysfluency) frequency: the share of recorded words that were
  /// stuttered.
  ///
  /// This is the clinical outcome measure the app now reports. Fluency
  /// percentage is its complement and is retained in storage for sessions
  /// already saved, but is no longer displayed: progress in Response Cost is
  /// read as a *reduction* in stuttering frequency across sessions, and showing
  /// the complement inverts the direction a clinician expects to see.
  double get dysfluencyPercentage {
    if (totalUtterances <= 0) return 0;
    return (dysfluentCount / totalUtterances) * 100;
  }

  /// Coerce a stored value to a chart-safe double.
  ///
  /// The progress charts feed these straight into `FlSpot`, and fl_chart
  /// asserts on NaN or infinity — one bad row would take down the whole
  /// dashboard. Stored values can be strings, nulls, or non-finite doubles
  /// (a zero-length session divided by zero before the guard existed), so
  /// everything unusable collapses to 0 rather than crashing the screen.
  static double _safeDouble(dynamic v) {
    final d = v is num ? v.toDouble() : double.tryParse('$v');
    if (d == null || !d.isFinite) return 0;
    return d;
  }

  static int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is num && v.isFinite) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  factory SessionStats.fromFirestore(Map<String, dynamic> data) {
    return SessionStats(
      totalUtterances: _safeInt(data['totalUtterances']),
      fluentCount: _safeInt(data['fluentCount']),
      dysfluentCount: _safeInt(data['dysfluentCount']),
      // Clamped: a percentage outside 0-100 would draw outside the chart axes.
      fluencyPercentage: _safeDouble(data['fluencyPercentage']).clamp(0, 100),
      rewardCyclesCompleted: _safeInt(data['rewardCyclesCompleted']),
      // Negative durations are possible if the device clock moved backwards
      // mid-session; a negative bar breaks the layout.
      duration: Duration(seconds: _safeInt(data['durationSeconds']).abs()),
    );
  }
}

/// Complete session model
class Session {
  final String id;
  final String childId;
  final String clinicianId;
  final int sessionNumber;
  final DateTime date;
  final String therapyLevel;
  final String playTheme;
  final String miniGame;
  final SessionConfig config;
  final SessionStats stats;
  final SessionStatus status;
  final List<Utterance> utterances;

  Session({
    required this.id,
    required this.childId,
    required this.clinicianId,
    required this.sessionNumber,
    required this.date,
    required this.therapyLevel,
    required this.playTheme,
    required this.miniGame,
    required this.config,
    required this.stats,
    this.status = SessionStatus.completed,
    this.utterances = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'clinicianId': clinicianId,
      'sessionNumber': sessionNumber,
      'date': date.toIso8601String(),
      'therapyLevel': therapyLevel,
      'playTheme': playTheme,
      'miniGame': miniGame,
      'config': config.toFirestore(),
      'stats': stats.toFirestore(),
      'status': status.name,
    };
  }

  factory Session.fromFirestore(Map<String, dynamic> data) {
    return Session(
      id: data['id'] ?? '',
      childId: data['childId'] ?? data['child_id'] ?? '',
      clinicianId: data['clinicianId'] ?? data['clinician_id'] ?? '',
      sessionNumber: data['sessionNumber'] ?? data['session_number'] ?? 0,
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      therapyLevel: data['therapyLevel'] ?? data['therapy_level'] ?? 'word',
      playTheme: data['playTheme'] ?? data['play_theme'] ?? 'diyaFestival',
      miniGame: data['miniGame'] ?? data['mini_game'] ?? 'bubbleBurst',
      config: SessionConfig.fromFirestore(
          data['config'] is Map<String, dynamic> ? data['config'] : {}),
      stats: SessionStats.fromFirestore(
          data['stats'] is Map<String, dynamic> ? data['stats'] : {}),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SessionStatus.completed,
      ),
    );
  }
}

/// Active session model (for real-time sync between devices)
class ActiveSession {
  final String sessionCode;
  final String clinicianId;
  final String childId;
  final String childName;
  final SessionStatus status;
  final int currentTokenCount;
  final int tokenGoal;
  final String therapyLevel;
  final String playTheme;
  final String miniGame;
  final String language;
  final String? lastFeedbackType; // 'fluent' or 'dysfluent'
  final DateTime? lastFeedbackTime;
  final bool rewardActive;
  final bool miniGameActive;
  final String? videoRoomId;
  final int rewardCyclesCompleted;
  final int tokensPerFluent;
  final int tokensPerDysfluent;

  // ─── Clinician-controlled call state ───
  // The kid's device never decides these for itself; it polls them and obeys.
  /// Clinician has started the kid's video call. Until this is true the kid
  /// waits rather than auto-joining.
  final bool kidVideoStarted;

  /// Clinician has muted the kid's microphone.
  final bool kidAudioMuted;

  /// Clinician has turned off the kid's camera.
  final bool kidVideoMuted;

  /// What the child gets when the token goal is reached — a mini-game, a
  /// celebration animation, or a physical reward handed over by the clinician.
  /// Without this on the shared row the child's device had no way to know, so
  /// it always offered the mini-game.
  final String rewardType;

  /// Which physical reward the clinician will hand over, when [rewardType] is
  /// `physicalReward`.
  final String? physicalReward;

  /// Whether the row actually carried the clinician-control columns.
  ///
  /// A missing column and a deliberate `false` are indistinguishable once
  /// parsed — both arrive as `false`. That mattered: the child's device treats
  /// a flag going false as "the clinician stopped the call" and hangs up, so a
  /// database without those columns, or one partial read, could drop a child
  /// out of a live session. Callers can now tell the two apart.
  final bool kidCallColumnsPresent;

  /// Whether the row carried the `kid_user_id` column at all.
  ///
  /// A database without that column and a session no child ever joined both
  /// yield a null id, and they call for completely different action: one needs
  /// a migration run, the other is simply a clinician testing alone. Telling
  /// them apart is the difference between an actionable message and a mystery.
  final bool kidUserIdColumnPresent;

  /// Auth id of the kid who joined with this code.
  ///
  /// The kid records it here so the clinician — who owns the child row and is
  /// therefore always permitted to write it — can attach it to `children` when
  /// the session is saved. The kid's own device may be refused that write by
  /// row-level security, which is why it cannot be the one to do it.
  final String? kidUserId;

  ActiveSession({
    required this.sessionCode,
    required this.clinicianId,
    required this.childId,
    required this.childName,
    this.status = SessionStatus.active,
    this.currentTokenCount = 0,
    required this.tokenGoal,
    required this.therapyLevel,
    required this.playTheme,
    required this.miniGame,
    this.language = 'en',
    this.lastFeedbackType,
    this.lastFeedbackTime,
    this.rewardActive = false,
    this.miniGameActive = false,
    this.videoRoomId,
    this.rewardCyclesCompleted = 0,
    this.tokensPerFluent = 1,
    this.tokensPerDysfluent = 1,
    this.rewardType = 'inAppMiniGame',
    this.physicalReward,
    this.kidVideoStarted = false,
    this.kidAudioMuted = false,
    this.kidVideoMuted = false,
    this.kidUserId,
    this.kidCallColumnsPresent = true,
    this.kidUserIdColumnPresent = true,
  });

  // NOTE: there is deliberately no camelCase `toFirestore()` here. One used to
  // exist, unused, writing keys like `sessionCode` — every one of which would
  // have been rejected by the snake_case `active_sessions` table. Use [toMap].

  /// Create from Map (Supabase / JSON)
  factory ActiveSession.fromMap(Map<String, dynamic> data) {
    return ActiveSession(
      sessionCode: data['session_code'] ?? data['sessionCode'] ?? '',
      clinicianId: data['clinician_id'] ?? data['clinicianId'] ?? '',
      childId: data['child_id'] ?? data['childId'] ?? '',
      childName: data['child_name'] ?? data['childName'] ?? '',
      status: SessionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SessionStatus.active,
      ),
      currentTokenCount: data['current_token_count'] ?? data['currentTokenCount'] ?? 0,
      tokenGoal: data['token_goal'] ?? data['tokenGoal'] ?? 10,
      therapyLevel: data['therapy_level'] ?? data['therapyLevel'] ?? 'word',
      playTheme: data['play_theme'] ?? data['playTheme'] ?? 'diyaFestival',
      miniGame: data['mini_game'] ?? data['miniGame'] ?? 'bubbleBurst',
      language: data['language'] ?? 'en',
      lastFeedbackType: data['last_feedback_type'] ?? data['lastFeedbackType'],
      lastFeedbackTime: data['last_feedback_time'] != null
          ? (data['last_feedback_time'] is DateTime
              ? data['last_feedback_time']
              : DateTime.tryParse(data['last_feedback_time'].toString()))
          : (data['lastFeedbackTime'] != null
              ? (data['lastFeedbackTime'] is DateTime
                  ? data['lastFeedbackTime']
                  : DateTime.tryParse(data['lastFeedbackTime'].toString()))
              : null),
      rewardActive: data['reward_active'] ?? data['rewardActive'] ?? false,
      miniGameActive: data['mini_game_active'] ?? data['miniGameActive'] ?? false,
      videoRoomId: data['video_room_id'] ?? data['videoRoomId'],
      rewardCyclesCompleted: data['reward_cycles_completed'] ?? data['rewardCyclesCompleted'] ?? 0,
      tokensPerFluent: data['tokens_per_fluent'] ?? data['tokensPerFluent'] ?? 1,
      tokensPerDysfluent: data['tokens_per_dysfluent'] ?? data['tokensPerDysfluent'] ?? 1,
      kidCallColumnsPresent: data.containsKey('kid_video_started') ||
          data.containsKey('kidVideoStarted'),
      kidUserIdColumnPresent:
          data.containsKey('kid_user_id') || data.containsKey('kidUserId'),
      kidVideoStarted:
          data['kid_video_started'] ?? data['kidVideoStarted'] ?? false,
      kidAudioMuted: data['kid_audio_muted'] ?? data['kidAudioMuted'] ?? false,
      kidVideoMuted: data['kid_video_muted'] ?? data['kidVideoMuted'] ?? false,
      kidUserId: data['kid_user_id'] ?? data['kidUserId'],
      rewardType:
          data['reward_type'] ?? data['rewardType'] ?? 'inAppMiniGame',
      physicalReward: data['physical_reward'] ?? data['physicalReward'],
    );
  }

  /// Build the shared row from the clinician's session setup.
  ///
  /// The three places that start a session each used to construct this by
  /// hand, repeating the same field list — and one of them omitted the reward
  /// configuration and the language, so a clinician who chose a physical
  /// reward and then picked a play theme had that choice silently replaced by
  /// the default mini-game before the child's device ever saw it. Mapping the
  /// config in exactly one place removes the opportunity.
  factory ActiveSession.fromConfig(
    SessionConfig config, {
    required String sessionCode,
    required String clinicianId,
  }) {
    return ActiveSession(
      sessionCode: sessionCode,
      clinicianId: clinicianId,
      childId: config.childId,
      childName: config.childName,
      tokenGoal: config.tokenGoal,
      therapyLevel: config.therapyLevel,
      playTheme: config.playTheme,
      miniGame: config.miniGame,
      language: config.language,
      rewardType: config.rewardType,
      physicalReward: config.physicalReward,
      tokensPerFluent: config.tokensPerFluent,
      tokensPerDysfluent: config.tokensPerDysfluent,
    );
  }

  /// Columns added by later migrations. Split out so a write can be retried
  /// without them on a database where those migrations have not been run yet.
  static const List<String> optionalColumns = [
    'reward_type',
    'physical_reward',
    'kid_user_id',
    'kid_video_started',
    'kid_audio_muted',
    'kid_video_muted',
  ];

  /// The complete row for Supabase.
  ///
  /// This used to omit the reward configuration and every clinician-control
  /// flag, which meant a session saved through it silently lost the
  /// clinician's choices — the child's device fell back to offering the
  /// mini-game no matter what had been selected. It was also dead code while
  /// `createActiveSession` hand-built its own copy of the same mapping, so the
  /// two were free to drift apart unnoticed. It is now the single definition.
  Map<String, dynamic> toMap() {
    return {
      'session_code': sessionCode,
      'clinician_id': clinicianId,
      'child_id': childId,
      'child_name': childName,
      'status': status.name,
      'current_token_count': currentTokenCount,
      'token_goal': tokenGoal,
      'therapy_level': therapyLevel,
      'play_theme': playTheme,
      'mini_game': miniGame,
      'language': language,
      'last_feedback_type': lastFeedbackType,
      'last_feedback_time':
          lastFeedbackTime == null ? null : AppTime.toStorage(lastFeedbackTime!),
      'reward_active': rewardActive,
      'mini_game_active': miniGameActive,
      'reward_cycles_completed': rewardCyclesCompleted,
      'tokens_per_fluent': tokensPerFluent,
      'tokens_per_dysfluent': tokensPerDysfluent,
      'reward_type': rewardType,
      'physical_reward': physicalReward,
      'kid_user_id': kidUserId,
      'kid_video_started': kidVideoStarted,
      'kid_audio_muted': kidAudioMuted,
      'kid_video_muted': kidVideoMuted,
    };
  }

  /// Columns the CHILD's device owns, or that are set later by a control
  /// action. The clinician never has a value for these when the session is
  /// created.
  static const List<String> kidOwnedColumns = [
    'kid_user_id',
    'kid_video_started',
    'kid_audio_muted',
    'kid_video_muted',
  ];

  /// The row as it should be CREATED.
  ///
  /// Deliberately omits [kidOwnedColumns]. Session creation is an upsert, and
  /// including them wrote `kid_user_id: null` over the id the child had
  /// already announced — so the clinician then found nothing to link, the
  /// child's progress screens stayed empty, and the diagnostics filled with
  /// "no kid_user_id on the session row". The database defaults cover these
  /// at creation; every later value is written by whoever owns it.
  Map<String, dynamic> toCreateMap() {
    final map = toMap();
    for (final column in kidOwnedColumns) {
      map.remove(column);
    }
    return map;
  }

  /// The same row minus columns a pre-migration database does not have.
  Map<String, dynamic> toMapWithoutOptionalColumns() {
    final map = toMap();
    for (final column in optionalColumns) {
      map.remove(column);
    }
    return map;
  }

  ActiveSession copyWith({
    String? sessionCode,
    String? clinicianId,
    String? childId,
    String? childName,
    SessionStatus? status,
    int? currentTokenCount,
    int? tokenGoal,
    String? therapyLevel,
    String? playTheme,
    String? miniGame,
    String? language,
    String? lastFeedbackType,
    DateTime? lastFeedbackTime,
    bool? rewardActive,
    bool? miniGameActive,
    String? videoRoomId,
    int? rewardCyclesCompleted,
    int? tokensPerFluent,
    int? tokensPerDysfluent,
    String? rewardType,
    String? physicalReward,
    bool? kidVideoStarted,
    bool? kidAudioMuted,
    bool? kidVideoMuted,
    String? kidUserId,
  }) {
    return ActiveSession(
      sessionCode: sessionCode ?? this.sessionCode,
      clinicianId: clinicianId ?? this.clinicianId,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      status: status ?? this.status,
      currentTokenCount: currentTokenCount ?? this.currentTokenCount,
      tokenGoal: tokenGoal ?? this.tokenGoal,
      therapyLevel: therapyLevel ?? this.therapyLevel,
      playTheme: playTheme ?? this.playTheme,
      miniGame: miniGame ?? this.miniGame,
      language: language ?? this.language,
      lastFeedbackType: lastFeedbackType ?? this.lastFeedbackType,
      lastFeedbackTime: lastFeedbackTime ?? this.lastFeedbackTime,
      rewardActive: rewardActive ?? this.rewardActive,
      miniGameActive: miniGameActive ?? this.miniGameActive,
      videoRoomId: videoRoomId ?? this.videoRoomId,
      rewardCyclesCompleted: rewardCyclesCompleted ?? this.rewardCyclesCompleted,
      tokensPerFluent: tokensPerFluent ?? this.tokensPerFluent,
      tokensPerDysfluent: tokensPerDysfluent ?? this.tokensPerDysfluent,
      // These were missing entirely, so any copyWith — updating a token count,
      // say — reset the reward configuration and every clinician-control flag
      // back to its default without touching the fields it was asked to change.
      rewardType: rewardType ?? this.rewardType,
      physicalReward: physicalReward ?? this.physicalReward,
      kidVideoStarted: kidVideoStarted ?? this.kidVideoStarted,
      kidAudioMuted: kidAudioMuted ?? this.kidAudioMuted,
      kidVideoMuted: kidVideoMuted ?? this.kidVideoMuted,
      kidUserId: kidUserId ?? this.kidUserId,
    );
  }
}
