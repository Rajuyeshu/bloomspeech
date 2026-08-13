import '../config/constants/app_constants.dart';

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

  factory SessionStats.fromFirestore(Map<String, dynamic> data) {
    return SessionStats(
      totalUtterances: data['totalUtterances'] ?? 0,
      fluentCount: data['fluentCount'] ?? 0,
      dysfluentCount: data['dysfluentCount'] ?? 0,
      fluencyPercentage: (data['fluencyPercentage'] ?? 0).toDouble(),
      rewardCyclesCompleted: data['rewardCyclesCompleted'] ?? 0,
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
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
    this.kidVideoStarted = false,
    this.kidAudioMuted = false,
    this.kidVideoMuted = false,
    this.kidUserId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'sessionCode': sessionCode,
      'clinicianId': clinicianId,
      'childId': childId,
      'childName': childName,
      'status': status.name,
      'currentTokenCount': currentTokenCount,
      'tokenGoal': tokenGoal,
      'therapyLevel': therapyLevel,
      'playTheme': playTheme,
      'miniGame': miniGame,
      'language': language,
      'lastFeedbackType': lastFeedbackType,
      'lastFeedbackTime': lastFeedbackTime?.toIso8601String(),
      'rewardActive': rewardActive,
      'miniGameActive': miniGameActive,
      'videoRoomId': videoRoomId,
      'rewardCyclesCompleted': rewardCyclesCompleted,
      'tokensPerFluent': tokensPerFluent,
      'tokensPerDysfluent': tokensPerDysfluent,
    };
  }

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
      kidVideoStarted:
          data['kid_video_started'] ?? data['kidVideoStarted'] ?? false,
      kidAudioMuted: data['kid_audio_muted'] ?? data['kidAudioMuted'] ?? false,
      kidVideoMuted: data['kid_video_muted'] ?? data['kidVideoMuted'] ?? false,
      kidUserId: data['kid_user_id'] ?? data['kidUserId'],
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'session_code': sessionCode,
      'clinician_id': clinicianId,
      'child_id': childId,
      'child_name': childName,
      'current_token_count': currentTokenCount,
      'token_goal': tokenGoal,
      'therapy_level': therapyLevel,
      'play_theme': playTheme,
      'mini_game': miniGame,
      'language': language,
      'last_feedback_type': lastFeedbackType,
      'last_feedback_time': lastFeedbackTime?.toIso8601String(),
      'reward_cycles_completed': rewardCyclesCompleted,
    };
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
    );
  }
}
