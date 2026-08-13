/// App-wide constants and default configurations
class AppConstants {
  AppConstants._();

  // ─── App Info ───
  static const String appName = 'BloomSpeech';
  static const String appTagline = 'Nurturing Fluent Speech';
  static const String appVersion = '1.0.0';

  // ─── Token Defaults ───
  static const int defaultTokensPerFluent = 1;
  static const int defaultTokensPerDysfluent = 1;
  static const int defaultTokenGoal = 10;
  static const int minTokensPerFluent = 1;
  static const int maxTokensPerFluent = 5;
  static const int minTokensPerDysfluent = 1;
  static const int maxTokensPerDysfluent = 3;
  static const int minTokenGoal = 5;
  static const int maxTokenGoal = 30;

  // ─── Session Timer Options (minutes) ───
  static const List<int> sessionTimerOptions = [0, 20, 30, 45];

  // ─── Mini-Game Duration (seconds) ───
  static const int miniGameDuration = 60;
  static const int maxMiniGameDuration = 120;

  // ─── Reward Animation Duration (seconds) ───
  static const int rewardAnimationDuration = 6;

  // ─── Feedback Delay (milliseconds) ───
  static const int maxFeedbackDelay = 1000;

  // ─── Session Code Length ───
  static const int sessionCodeLength = 6;

  // ─── Video Call (Jitsi) ───
  // MUST be identical on every platform. Web and mobile once pointed at
  // different servers, which put the clinician and the kid in two separate
  // conferences (no remote video, no remote audio).
  //
  // Host choice is constrained by two independent server policies:
  //
  //   meet.jit.si     — embeds in an iframe, but its config.js sets
  //                     `anonymousdomain` + `tokenAuthUrl`, so the first
  //                     participant must sign in and everyone else is held at
  //                     "waiting for a moderator". Unusable for anonymous kids.
  //   meet.ffmuc.net  — no authdomain and no lobby, so anyone can open a room,
  //                     but it sends `X-Frame-Options: SAMEORIGIN`, so it
  //                     cannot be embedded in an iframe.
  //
  // Being able to join at all beats being inline, so ffmuc wins and the web
  // build opens the call in a second tab (see `jitsiSupportsIframe`).
  static const String jitsiDomain = 'meet.ffmuc.net';
  static const String jitsiServerUrl = 'https://$jitsiDomain';
  static const String jitsiRoomPrefix = 'BloomSpeech_';

  /// Whether [jitsiDomain] permits being framed by this app on web.
  /// Keep in sync with the host above — a wrong value here shows the clinician
  /// a blank grey box instead of the call.
  static const bool jitsiSupportsIframe = false;

  // ─── Min Token Positions Per Theme ───
  static const int minTokenPositions = 20;

  // ─── Child Age Range ───
  static const int minChildAge = 3;
  static const int maxChildAge = 6;

  // ─── Trend Badge Threshold (last N sessions) ───
  static const int trendSessionCount = 3;
  static const double trendImprovingThreshold = 5.0; // % improvement
  static const double trendNeedsAttentionThreshold = -5.0; // % decline

  // ─── Progress Chart ───
  static const double clinicalGoalMin = 80.0;
  static const double clinicalGoalMax = 100.0;

  // ─── Firestore Collections ───
  static const String usersCollection = 'users';
  static const String childrenCollection = 'children';
  static const String sessionsCollection = 'sessions';
  static const String utterancesCollection = 'utterances';
  static const String activeSessionsCollection = 'activeSessions';

  // ─── Hive Box Names ───
  static const String settingsBox = 'settings';
  static const String offlineSessionsBox = 'offlineSessions';
  static const String childProfilesBox = 'childProfiles';
}

/// Therapy levels
enum TherapyLevel {
  word('Word Level', 'Single target words', 1),
  sentence('Sentence Level', 'Single fluent sentences (3–8 words)', 2),
  continuousSpeech('Continuous Speech', '2–4 connected sentences', 3),
  narrative('Narrative Speech', 'Short story retell (5–8 sentences)', 4),
  conversational('Conversational Speech', 'Back-and-forth dialogue (2–3 turns)', 5);

  const TherapyLevel(this.displayName, this.description, this.levelNumber);
  final String displayName;
  final String description;
  final int levelNumber;

  String get shortName {
    switch (this) {
      case TherapyLevel.word:
        return 'Word';
      case TherapyLevel.sentence:
        return 'Sentence';
      case TherapyLevel.continuousSpeech:
        return 'Continuous';
      case TherapyLevel.narrative:
        return 'Narrative';
      case TherapyLevel.conversational:
        return 'Conversational';
    }
  }

  String get exemplarTask {
    switch (this) {
      case TherapyLevel.word:
        return 'Naming objects/flashcards';
      case TherapyLevel.sentence:
        return "Child describes a picture: 'Amma is cooking rice'";
      case TherapyLevel.continuousSpeech:
        return 'Child describes a sequence of pictures';
      case TherapyLevel.narrative:
        return 'Child retells a familiar Panchatantra story';
      case TherapyLevel.conversational:
        return 'Role play: buying vegetables at a market';
    }
  }

  String get clinicianPrompt {
    switch (this) {
      case TherapyLevel.word:
        return 'What is this?';
      case TherapyLevel.sentence:
        return 'Tell me one thing about this picture';
      case TherapyLevel.continuousSpeech:
        return 'Tell me what is happening here, then what happened next';
      case TherapyLevel.narrative:
        return 'Tell me the whole story of the clever crow';
      case TherapyLevel.conversational:
        return 'Now you are the shopkeeper. What do you say?';
    }
  }
}

/// Reward types
enum RewardType {
  inAppAnimation('In-app animation', '🎬', 'Theme-specific celebration animation'),
  inAppMiniGame('In-app mini-game', '🎮', 'Interactive mini-game unlock'),
  physicalReward('Physical reward', '🎁', 'Physical reward prompt for child');

  const RewardType(this.displayName, this.emoji, this.description);
  final String displayName;
  final String emoji;
  final String description;
}

/// Mini-game types
enum MiniGameType {
  bubbleBurst('Bubble Bursting', '🫧', 'Pop colorful bubbles!'),
  plantWatering('Plant Watering', '🌱', 'Water the plant and watch it grow!'),
  rangoliPainter('Rangoli Painter', '🎨', 'Color a beautiful rangoli!');

  const MiniGameType(this.displayName, this.emoji, this.description);
  final String displayName;
  final String emoji;
  final String description;
}

/// Play themes
enum PlayTheme {
  diyaFestival('Diya Festival', '🪔', 'Light diyas on a thali'),
  rangoliBuilder('Rangoli Builder', '🎨', 'Fill rangoli petals with colors'),
  mangoHarvest('Mango Harvest', '🥭', 'Grow mangoes on a tree'),
  peacockGarden('Peacock Garden', '🦚', 'Add feathers to a peacock'),
  lotusPond('Lotus Pond', '🌸', 'Bloom lotus flowers on a pond'),
  kiteFestival('Kite Festival', '🪁', 'Launch kites into the sky');

  const PlayTheme(this.displayName, this.emoji, this.description);
  final String displayName;
  final String emoji;
  final String description;
}

/// Trend badge for child progress
enum TrendBadge {
  improving('Improving', '📈'),
  stable('Stable', '📊'),
  needsAttention('Needs Attention', '⚠️');

  const TrendBadge(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

/// Utterance type
enum UtteranceType {
  fluent,
  dysfluent,
}

/// Session status
enum SessionStatus {
  setup,
  active,
  paused,
  reward,
  completed,
}

/// Supported languages
enum AppLanguage {
  english('en', 'English'),
  kannada('kn', 'ಕನ್ನಡ');

  const AppLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

/// User role
enum UserRole {
  clinician,
  kid,
}
