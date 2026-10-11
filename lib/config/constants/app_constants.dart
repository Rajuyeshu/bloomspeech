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
  /// Where Google returns the user after they authenticate.
  ///
  /// OAuth happens in an external browser, so the result has to be handed back
  /// to the app through a deep link. This scheme must be registered in three
  /// places or sign-in silently goes nowhere:
  ///   1. AndroidManifest.xml  — an intent-filter on MainActivity
  ///   2. ios/Runner/Info.plist — CFBundleURLTypes
  ///   3. Supabase dashboard    — Authentication › URL Configuration ›
  ///                              Redirect URLs
  static const String oauthRedirectScheme = 'bloomspeech';
  static const String oauthRedirectUrl = '$oauthRedirectScheme://login-callback';

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
  // Four treatment levels. Level 1 covers words, phrases and sentences
  // together — they were previously separate levels, which split a single
  // clinical stage across two settings.
  word('Level 1 — Words, Phrases & Sentences',
      'Words, phrases and sentences', 1),
  continuousSpeech('Level 2 — Continuous Speech',
      '2-4 connected sentences', 2),
  narrative('Level 3 — Narrative Speech',
      'Short story retell (5-8 sentences)', 3),
  conversational('Level 4 — Conversational Speech',
      'Back-and-forth dialogue (2-3 turns)', 4),

  // Retained so sessions saved at the old sentence level still parse and
  // display. Not offered for new sessions — see [selectable].
  sentence('Sentence Level', 'Single fluent sentences (3-8 words)', 1,
      legacy: true);

  const TherapyLevel(this.displayName, this.description, this.levelNumber,
      {this.legacy = false});
  final String displayName;
  final String description;
  final int levelNumber;

  /// Superseded by Level 1, but kept parseable for historical sessions.
  final bool legacy;

  /// The levels a clinician can choose for a new session.
  static List<TherapyLevel> get selectable =>
      values.where((l) => !l.legacy).toList(growable: false);

  String get shortName {
    switch (this) {
      case TherapyLevel.word:
        return 'Level 1';
      case TherapyLevel.continuousSpeech:
        return 'Level 2';
      case TherapyLevel.narrative:
        return 'Level 3';
      case TherapyLevel.conversational:
        return 'Level 4';
      case TherapyLevel.sentence:
        return 'Sentence';
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
  balloonPop('Balloon Popping', '🎈', 'Pop the floating balloons!'),
  rangoliPainter('Rangoli Painter', '🎨', 'Color a beautiful rangoli!'),

  // Withdrawn: a single repeated tap target with almost no response. Kept
  // parseable so sessions already saved against it still open, and mapped to
  // balloon popping when played.
  plantWatering('Plant Watering', '🌱', 'Water the plant and watch it grow!',
      legacy: true);

  const MiniGameType(this.displayName, this.emoji, this.description,
      {this.legacy = false});
  final String displayName;
  final String emoji;
  final String description;

  /// Superseded, but still parseable for historical sessions.
  final bool legacy;

  /// The games a clinician can choose for a new session.
  static List<MiniGameType> get selectable =>
      values.where((g) => !g.legacy).toList(growable: false);
}

/// The vessel a theme's tokens collect into.
///
/// Preschool children respond to a familiar object filling up far more readily
/// than to an abstract progress bar, so each token type has a container that
/// makes sense for it — flowers go in a basket, coins in a piggy bank.
enum TokenContainer {
  basket,
  box,
  piggyBank,
  notebook,
  garage,
  stickerAlbum,
  cakeStand,
  fishBowl,
  none,
}

/// Play themes.
///
/// The first group is offered at session setup. Each pairs a reward object a
/// preschool child already recognises with a container it plausibly collects
/// into, following clinical feedback that the original festival imagery
/// (diyas, peacocks) read as decorative rather than rewarding to this age
/// group.
///
/// The second group is retained ONLY so that sessions already saved against
/// those names continue to parse and display correctly. They are excluded from
/// [selectable] and cannot be chosen for a new session. Removing them outright
/// would make every historical session fall back to a default theme and
/// misreport what the child actually played.
enum PlayTheme {
  // ── Offered at setup ────────────────────────────────────────────────
  flowerBasket('Flower Basket', '🌸', 'Collect flowers in a basket',
      TokenContainer.basket),
  iceCreamBox('Ice Cream Box', '🍦', 'Fill the freezer box with ice creams',
      TokenContainer.box),
  chocolateBox('Chocolate Box', '🍫', 'Fill the box with chocolates',
      TokenContainer.box),
  cakeStand('Cake Stand', '🧁', 'Fill the stand with cakes',
      TokenContainer.cakeStand),
  coinPiggyBank('Piggy Bank', '🪙', 'Drop coins into the piggy bank',
      TokenContainer.piggyBank),
  starChart('Star Chart', '⭐', 'Stick stars onto the page',
      TokenContainer.notebook),
  carGarage('Car Garage', '🚗', 'Park the cars in the garage',
      TokenContainer.garage),
  superheroStickers('Superhero Stickers', '🦸', 'Collect superhero stickers',
      TokenContainer.stickerAlbum),
  fishBowl('Fish Bowl', '🐠', 'Fill the bowl with fish',
      TokenContainer.fishBowl),

  // ── Retained for historical sessions only ───────────────────────────
  diyaFestival('Diya Festival', '🪔', 'Light diyas on a thali',
      TokenContainer.none, legacy: true),
  rangoliBuilder('Rangoli Builder', '🎨', 'Fill rangoli petals with colors',
      TokenContainer.none, legacy: true),
  mangoHarvest('Mango Harvest', '🥭', 'Grow mangoes on a tree',
      TokenContainer.none, legacy: true),
  peacockGarden('Peacock Garden', '🦚', 'Add feathers to a peacock',
      TokenContainer.none, legacy: true),
  lotusPond('Lotus Pond', '🌸', 'Bloom lotus flowers on a pond',
      TokenContainer.none, legacy: true),
  kiteFestival('Kite Festival', '🪁', 'Launch kites into the sky',
      TokenContainer.none, legacy: true),
  // Withdrawn after clinical review as not appropriate for this context.
  // Retained so any session already saved against it still parses.
  princessStickers('Princess Stickers', '👑', 'Collect princess stickers',
      TokenContainer.stickerAlbum, legacy: true);

  const PlayTheme(this.displayName, this.emoji, this.description, this.container,
      {this.legacy = false});
  final String displayName;
  final String emoji;
  final String description;

  /// What the tokens collect into. [TokenContainer.none] means the theme draws
  /// its own bespoke scene instead.
  final TokenContainer container;

  /// Retained for historical sessions but no longer offered for new ones.
  final bool legacy;

  /// The themes a clinician can pick for a new session.
  static List<PlayTheme> get selectable =>
      values.where((t) => !t.legacy).toList(growable: false);

  /// The default for a new session.
  static PlayTheme get initial => flowerBasket;
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
