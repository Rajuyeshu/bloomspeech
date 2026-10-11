import '../config/constants/app_constants.dart';

/// Localization keys and their translations in English & Kannada
class AppLocalizations {
  AppLocalizations._();

  /// The language the UI is currently rendering in.
  ///
  /// Kept here so `'text'.tr()` works from helper methods and non-Consumer
  /// widgets without threading a language argument through every call.
  /// [LanguageService] is the only writer; the root widget watches the
  /// provider and rebuilds the tree, so this is always read during a build
  /// that the provider change triggered.
  static AppLanguage current = AppLanguage.english;

  static const Map<String, Map<AppLanguage, String>> _localizedValues = {
    // ─── Landing/Login Role Page ───
    'tagline': {
      AppLanguage.english: 'Nurturing fluent speech',
      AppLanguage.kannada: 'ಸರಾಗ ಭಾಷಣಕ್ಕಾಗಿ',
    },
    'i_am_a': {AppLanguage.english: 'I am a…', AppLanguage.kannada: 'ನಾನು'},
    'clinician_title': {
      AppLanguage.english: 'Clinician / SLP',
      AppLanguage.kannada: 'ಚಿಕಿತ್ಸಕರು / ಎಸ್.ಎಲ್.ಪಿ',
    },
    'clinician_subtitle': {
      AppLanguage.english: 'Speech-Language Pathologist or Therapist',
      AppLanguage.kannada: 'ಮಾತು ಮತ್ತು ಭಾಷಾ ತಜ್ಞರು ಅಥವಾ ಚಿಕಿತ್ಸಕರು',
    },
    'patient_title': {
      AppLanguage.english: 'Patient / Kid',
      AppLanguage.kannada: 'ರೋಗಿ / ಮಗು',
    },
    'patient_subtitle': {
      AppLanguage.english: 'Child or parent joining a therapy session',
      AppLanguage.kannada: 'ಚಿಕಿತ್ಸಾ ಸೆಷನ್‌ಗೆ ಸೇರುವ ಮಗು ಅಥವಾ ಪೋಷಕರು',
    },

    // ─── Common Auth / Forms ───
    'login': {AppLanguage.english: 'Login', AppLanguage.kannada: 'ಲಾಗಿನ್'},
    'register': {
      AppLanguage.english: 'Register',
      AppLanguage.kannada: 'ನೋಂದಣಿ',
    },
    'join_session': {
      AppLanguage.english: 'Join Session',
      AppLanguage.kannada: 'ಸೆಶನ್ ಸೇರಿ',
    },
    'email': {AppLanguage.english: 'Email', AppLanguage.kannada: 'ಇಮೇಲ್'},
    'password': {
      AppLanguage.english: 'Password',
      AppLanguage.kannada: 'ಪಾಸ್ವರ್ಡ್',
    },
    'confirm_password': {
      AppLanguage.english: 'Confirm Password',
      AppLanguage.kannada: 'ಪಾಸ್ವರ್ಡ್ ದೃಢೀಕರಿಸಿ',
    },
    'username': {
      AppLanguage.english: 'Username',
      AppLanguage.kannada: 'ಬಳಕೆದಾರ ಹೆಸರು',
    },
    'full_name': {
      AppLanguage.english: 'Full Name',
      AppLanguage.kannada: 'ಪೂರ್ಣ ಹೆಸರು',
    },
    'child_name': {
      AppLanguage.english: 'Child\'s Name',
      AppLanguage.kannada: 'ಮಗುವಿನ ಹೆಸರು',
    },
    'parent_name': {
      AppLanguage.english: 'Parent\'s Name',
      AppLanguage.kannada: 'ಪೋಷಕರ ಹೆಸರು',
    },
    'dob': {
      AppLanguage.english: 'Date of Birth',
      AppLanguage.kannada: 'ಹುಟ್ಟಿದ ದಿನಾಂಕ',
    },
    'gender': {AppLanguage.english: 'Gender', AppLanguage.kannada: 'ಲಿಂಗ'},
    'language_pref': {
      AppLanguage.english: 'Preferred Language',
      AppLanguage.kannada: 'ಆದ್ಯತೆಯ ಭಾಷೆ',
    },
    'notes': {AppLanguage.english: 'Notes', AppLanguage.kannada: 'ಟಿಪ್ಪಣಿಗಳು'},
    'welcome_back': {
      AppLanguage.english: 'Welcome Back',
      AppLanguage.kannada: 'ಮರಳಿ ಸ್ವಾಗತ',
    },
    'create_account': {
      AppLanguage.english: 'Create Account',
      AppLanguage.kannada: 'ಖಾತೆ ರಚಿಸಿ',
    },
    'clinician_login_subtitle': {
      AppLanguage.english: 'Sign in to your clinician account',
      AppLanguage.kannada: 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರ ಖಾತೆಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ',
    },
    'clinician_register_subtitle': {
      AppLanguage.english: 'Register as a new clinician',
      AppLanguage.kannada: 'ಹೊಸ ಚಿಕಿತ್ಸಕರಾಗಿ ನೋಂದಾಯಿಸಿ',
    },

    // ─── Child Selection & Setup ───
    'select_child': {
      AppLanguage.english: 'Select Child',
      AppLanguage.kannada: 'ಮಗುವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
    },
    'who_is_session_for': {
      AppLanguage.english: 'Who is today\'s session for?',
      AppLanguage.kannada: 'ಇವತ್ತಿನ ಸೆಷನ್ ಯಾರಿಗಾಗಿ?',
    },
    'add_new_child': {
      AppLanguage.english: 'Add New Child',
      AppLanguage.kannada: 'ಹೊಸ ಮಗುವನ್ನು ಸೇರಿಸಿ',
    },
    'register_new_patient': {
      AppLanguage.english: 'Register a new patient',
      AppLanguage.kannada: 'ಹೊಸ ರೋಗಿಯನ್ನು ನೋಂದಾಯಿಸಿ',
    },
    'existing_children': {
      AppLanguage.english: 'Existing Children',
      AppLanguage.kannada: 'ಪ್ರಸ್ತುತ ಮಕ್ಕಳು',
    },
    'start_session_with': {
      AppLanguage.english: 'Start Session with',
      AppLanguage.kannada: 'ಜೊತೆ ಸೆಶನ್ ಪ್ರಾರಂಭಿಸಿ',
    },
    'treatment_level': {
      AppLanguage.english: 'Treatment Level',
      AppLanguage.kannada: 'ಚಿಕಿತ್ಸಾ ಹಂತ',
    },
    'select_speech_complexity': {
      AppLanguage.english: 'Select speech complexity',
      AppLanguage.kannada: 'ಭಾಷಣದ ಸಂಕೀರ್ಣತೆಯನ್ನು ಆರಿಸಿ',
    },
    'token_board': {
      AppLanguage.english: 'Token Board',
      AppLanguage.kannada: 'ಟೋಕನ್ ಬೋರ್ಡ್',
    },
    'tokens_to_earn_reward': {
      AppLanguage.english: 'tokens to earn a reward',
      AppLanguage.kannada: 'ಬಹುಮಾನ ಗಳಿಸಲು ಬೇಕಾದ ಟೋಕನ್‌ಗಳು',
    },
    'play_theme': {
      AppLanguage.english: 'Play Theme',
      AppLanguage.kannada: 'ಆಟದ ಥೀಮ್',
    },
    'theme_subtitle': {
      AppLanguage.english: 'Visual theme for the session',
      AppLanguage.kannada: 'ಸೆಶನ್‌ಗಾಗಿ ದೃಶ್ಯ ಥೀಮ್',
    },
    'reward_type': {
      AppLanguage.english: 'Reward Type',
      AppLanguage.kannada: 'ಬಹುಮಾನದ ವಿಧ',
    },
    'reward_subtitle': {
      AppLanguage.english: 'Mini-game when tokens are earned',
      AppLanguage.kannada: 'ಟೋಕನ್‌ಗಳು ಪೂರ್ಣಗೊಂಡಾಗ ಆಡುವ ಆಟ',
    },
    'start_therapy_button': {
      AppLanguage.english: 'Start Therapy Session',
      AppLanguage.kannada: 'ಚಿಕಿತ್ಸಾ ಸೆಷನ್ ಪ್ರಾರಂಭಿಸಿ',
    },

    // ─── Active Therapy & Tokens ───
    'smooth': {AppLanguage.english: 'SMOOTH', AppLanguage.kannada: 'ಸರಾಗ'},
    'bumpy': {AppLanguage.english: 'BUMPY', AppLanguage.kannada: 'ತೊಡರು'},
    'fluent_speech': {
      AppLanguage.english: 'Fluent speech ✓',
      AppLanguage.kannada: 'ಸರಾಗ ಮಾತು ✓',
    },
    'dysfluent_speech': {
      AppLanguage.english: 'Dysfluent speech ✗',
      AppLanguage.kannada: 'ತೊಡರಿದ ಮಾತು ✗',
    },
    'record_utterance': {
      AppLanguage.english: 'Record Utterance',
      AppLanguage.kannada: 'ಮಾತನ್ನು ದಾಖಲಿಸಿ',
    },
    'end_session': {
      AppLanguage.english: 'End Session',
      AppLanguage.kannada: 'ಸೆಶನ್ ಮುಗಿಸಿ',
    },
    'smooth_feedback': {
      AppLanguage.english: '✨ Smooth!',
      AppLanguage.kannada: '✨ ಸರಾಗ!',
    },
    'bumpy_feedback': {
      AppLanguage.english: '💪 Bumpy - Try again!',
      AppLanguage.kannada: '💪 ತೊಡರು - ಮತ್ತೊಮ್ಮೆ ಪ್ರಯತ್ನಿಸಿ!',
    },
  };

  /// Retrieve translation for a key in specified language

  /// English-text → Kannada.
  ///
  /// Keyed on the English string itself rather than an invented symbol, so a
  /// screen only needs `'Some text'.tr()` and an untranslated string
  /// falls back to readable English instead of showing a raw key.
  static const Map<String, String> _kannada = {
    'Video call not started': 'ವೀಡಿಯೊ ಕರೆ ಪ್ರಾರಂಭವಾಗಿಲ್ಲ',
    'Start': 'ಪ್ರಾರಂಭಿಸಿ',
    'Forgot Password?': 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿರಾ?',
    'Reset Password': 'ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸಿ',
    'Check your email': 'ನಿಮ್ಮ ಇಮೇಲ್ ಪರಿಶೀಲಿಸಿ',
    'Send Reset Link': 'ಮರುಹೊಂದಿಸುವ ಲಿಂಕ್ ಕಳುಹಿಸಿ',
    'Enter your email and we will send you a link to set a new password.': 'ನಿಮ್ಮ ಇಮೇಲ್ ನಮೂದಿಸಿ, ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ಹೊಂದಿಸಲು ನಾವು ಲಿಂಕ್ ಕಳುಹಿಸುತ್ತೇವೆ.',
    'If an account exists for that address, a reset link is on its way. Check your inbox and spam folder.': 'ಆ ವಿಳಾಸಕ್ಕೆ ಖಾತೆ ಇದ್ದರೆ, ಮರುಹೊಂದಿಸುವ ಲಿಂಕ್ ಕಳುಹಿಸಲಾಗಿದೆ. ನಿಮ್ಮ ಇನ್‌ಬಾಕ್ಸ್ ಮತ್ತು ಸ್ಪ್ಯಾಮ್ ಫೋಲ್ಡರ್ ನೋಡಿ.',
    'Enter your email': 'ನಿಮ್ಮ ಇಮೇಲ್ ನಮೂದಿಸಿ',
    'Enter a valid email': 'ಸರಿಯಾದ ಇಮೇಲ್ ನಮೂದಿಸಿ',
    'In-person session — video off': 'ಖುದ್ದು ಸೆಷನ್ — ವೀಡಿಯೊ ಆಫ್',
    'Turn on': 'ಆನ್ ಮಾಡಿ',
    'Ask your therapist for your reward!': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರಿಂದ ನಿಮ್ಮ ಬಹುಮಾನ ಕೇಳಿ!',
    'Your clinician will give you a session code. You don\'t need an account to join a session!': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರು ನಿಮಗೆ ಸೆಷನ್ ಕೋಡ್ ನೀಡುತ್ತಾರೆ. ಸೆಷನ್‌ಗೆ ಸೇರಲು ನಿಮಗೆ ಖಾತೆ ಬೇಕಾಗಿಲ್ಲ!',
    'Your therapist is running this session. It will finish when they end it — keep practising!': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರು ಈ ಸೆಷನ್ ನಡೆಸುತ್ತಿದ್ದಾರೆ. ಅವರು ಮುಗಿಸಿದಾಗ ಇದು ಮುಗಿಯುತ್ತದೆ — ಅಭ್ಯಾಸ ಮುಂದುವರಿಸು!',
    'OR': 'ಅಥವಾ',
    'Continue with Google': 'Google ಮೂಲಕ ಮುಂದುವರಿಯಿರಿ',
    'Already have an account? ': 'ಈಗಾಗಲೇ ಖಾತೆ ಇದೆಯೇ? ',
    'your.email@example.com': 'your.email@example.com',
    'Enter password': 'ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ',
    ' or ': ' ಅಥವಾ ',
    'Already registered? ': 'ಈಗಾಗಲೇ ನೋಂದಾಯಿಸಿದ್ದೀರಾ? ',
    'Your clinician will give you a session code. ': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರು ನಿಮಗೆ ಸೆಷನ್ ಕೋಡ್ ನೀಡುತ್ತಾರೆ. ',
    'Dr. / SLP Name': 'ಡಾ. / ಎಸ್.ಎಲ್.ಪಿ ಹೆಸರು',
    'At least 6 characters': 'ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳು',
    'Re-enter password': 'ಪಾಸ್‌ವರ್ಡ್ ಮತ್ತೆ ನಮೂದಿಸಿ',
    'Enter child\'s full name': 'ಮಗುವಿನ ಪೂರ್ಣ ಹೆಸರು ನಮೂದಿಸಿ',
    'Tap Smooth or Bumpy within 1 second of the child\'s utterance for best results.': 'ಉತ್ತಮ ಫಲಿತಾಂಶಕ್ಕಾಗಿ ಮಗು ಮಾತನಾಡಿದ 1 ಸೆಕೆಂಡಿನೊಳಗೆ ಸ್ಮೂತ್ ಅಥವಾ ಬಂಪಿ ಒತ್ತಿರಿ.',
    'Practice makes perfect. Have fun with your therapist today! 🪁': 'ಅಭ್ಯಾಸದಿಂದ ಪರಿಪೂರ್ಣತೆ. ಇಂದು ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರೊಂದಿಗೆ ಖುಷಿಪಡಿ! 🪁',
    'Session A': 'ಸೆಷನ್ ಎ',
    'Session B': 'ಸೆಷನ್ ಬಿ',
    'Your therapist is running this session. It will finish when they ': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರು ಈ ಸೆಷನ್ ನಡೆಸುತ್ತಿದ್ದಾರೆ. ಅವರು ',
    'Fluent award (+)': 'ಸರಾಗ ಬಹುಮಾನ (+)',
    'Dysfluent cost (-)': 'ತೊದಲಿಕೆ ದಂಡ (-)',
    'Token goal': 'ಟೋಕನ್ ಗುರಿ',
    'In-app animation': 'ಆ್ಯಪ್‌ನೊಳಗಿನ ಅನಿಮೇಶನ್',
    'In-app mini-game': 'ಆ್ಯಪ್‌ನೊಳಗಿನ ಆಟ',
    'Physical reward': 'ನೈಜ ಬಹುಮಾನ',
    'Good Morning ☀️': 'ಶುಭೋದಯ ☀️',
    'Good Afternoon 🌤️': 'ಶುಭ ಮಧ್ಯಾಹ್ನ 🌤️',
    'Good Evening 🌙': 'ಶುಭ ಸಂಜೆ 🌙',
    'Manage profiles': 'ಪ್ರೊಫೈಲ್‌ಗಳನ್ನು ನಿರ್ವಹಿಸಿ',
    'Past sessions': 'ಹಿಂದಿನ ಸೆಷನ್‌ಗಳು',
    'Clinician': 'ಚಿಕಿತ್ಸಕರು',
    'Start session': 'ಸೆಷನ್ ಪ್ರಾರಂಭಿಸಿ',
    'Start Session': 'ಸೆಷನ್ ಪ್ರಾರಂಭಿಸಿ',
    'Toggle Video Call': 'ವೀಡಿಯೊ ಕರೆ ಬದಲಿಸಿ',
    'Compare': 'ಹೋಲಿಕೆ',
    'Male': 'ಗಂಡು',
    'Female': 'ಹೆಣ್ಣು',
    'Other': 'ಇತರೆ',
    'Overall Stats': 'ಒಟ್ಟಾರೆ ಅಂಕಿಅಂಶ',
    'Fluency Progress': 'ಸರಾಗತೆ ಪ್ರಗತಿ',
    'Total Sessions': 'ಒಟ್ಟು ಸೆಷನ್‌ಗಳು',
    'Current Level': 'ಪ್ರಸ್ತುತ ಹಂತ',
    'Last Session': 'ಕೊನೆಯ ಸೆಷನ್',
    'Enrolled': 'ದಾಖಲಾತಿ',
    'Completed': 'ಪೂರ್ಣಗೊಂಡಿದೆ',
    'Active Level': 'ಸಕ್ರಿಯ ಹಂತ',
    'My Progress Reports': 'ನನ್ನ ಪ್ರಗತಿ ವರದಿಗಳು',
    'Speech Practice History': 'ಮಾತಿನ ಅಭ್ಯಾಸದ ಇತಿಹಾಸ',
    'View your speech progress charts and milestones': 'ನಿಮ್ಮ ಮಾತಿನ ಪ್ರಗತಿ ಚಾರ್ಟ್ ಮತ್ತು ಮೈಲಿಗಲ್ಲುಗಳನ್ನು ನೋಡಿ',
    'View stars and feedback from your past sessions': 'ಹಿಂದಿನ ಸೆಷನ್‌ಗಳ ನಕ್ಷತ್ರ ಮತ್ತು ಅಭಿಪ್ರಾಯ ನೋಡಿ',
    'Join Your Session! 🎮': 'ನಿಮ್ಮ ಸೆಷನ್‌ಗೆ ಸೇರಿ! 🎮',
    'Ask your doctor for the session code': 'ಸೆಷನ್ ಕೋಡ್‌ಗಾಗಿ ನಿಮ್ಮ ವೈದ್ಯರನ್ನು ಕೇಳಿ',
    'Enter Code': 'ಕೋಡ್ ನಮೂದಿಸಿ',
    'Welcome Back': 'ಮತ್ತೆ ಸ್ವಾಗತ',
    'Welcome Back!': 'ಮತ್ತೆ ಸ್ವಾಗತ!',
    'Sign in to your clinician account': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕ ಖಾತೆಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ',
    'Email Address (Username)': 'ಇಮೇಲ್ ವಿಳಾಸ (ಬಳಕೆದಾರ ಹೆಸರು)',
    'Password': 'ಪಾಸ್‌ವರ್ಡ್',
    'Register': 'ನೋಂದಣಿ',
    'Create Account': 'ಖಾತೆ ರಚಿಸಿ',
    'Register as a new clinician': 'ಹೊಸ ಚಿಕಿತ್ಸಕರಾಗಿ ನೋಂದಾಯಿಸಿ',
    'Full Name': 'ಪೂರ್ಣ ಹೆಸರು',
    'Confirm Password': 'ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ',
    'Login': 'ಲಾಗಿನ್',
    'Login with your patient account': 'ನಿಮ್ಮ ರೋಗಿ ಖಾತೆಯಿಂದ ಲಾಗಿನ್ ಮಾಡಿ',
    'Join Session': 'ಸೆಷನ್‌ಗೆ ಸೇರಿ',
    'Create Patient Account': 'ರೋಗಿ ಖಾತೆ ರಚಿಸಿ',
    'Register with your details': 'ನಿಮ್ಮ ವಿವರಗಳೊಂದಿಗೆ ನೋಂದಾಯಿಸಿ',
    'Child\'s Name': 'ಮಗುವಿನ ಹೆಸರು',
    'Parent\'s Name': 'ಪೋಷಕರ ಹೆಸರು',
    'Enter the 6-digit code from your clinician': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರಿಂದ 6-ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ',
    'Join BloomSpeech as a clinician': 'ಚಿಕಿತ್ಸಕರಾಗಿ BloomSpeech ಸೇರಿ',
    'Email': 'ಇಮೇಲ್',
    'Sign In': 'ಸೈನ್ ಇನ್',
    'Please select date of birth': 'ದಯವಿಟ್ಟು ಜನ್ಮ ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ',
    'Date of Birth': 'ಜನ್ಮ ದಿನಾಂಕ',
    'Gender': 'ಲಿಂಗ',
    'My Children': 'ನನ್ನ ಮಕ್ಕಳು',
    'Please log in': 'ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಮಾಡಿ',
    'Add Child': 'ಮಗುವನ್ನು ಸೇರಿಸಿ',
    'No Children Added Yet': 'ಇನ್ನೂ ಯಾವ ಮಕ್ಕಳನ್ನೂ ಸೇರಿಸಿಲ್ಲ',
    'Add your first child to begin therapy sessions': 'ಚಿಕಿತ್ಸೆ ಆರಂಭಿಸಲು ನಿಮ್ಮ ಮೊದಲ ಮಗುವನ್ನು ಸೇರಿಸಿ',
    'Child not found': 'ಮಗು ಕಂಡುಬಂದಿಲ್ಲ',
    'Start New Session': 'ಹೊಸ ಸೆಷನ್ ಪ್ರಾರಂಭಿಸಿ',
    'Progress': 'ಪ್ರಗತಿ',
    'History': 'ಇತಿಹಾಸ',
    'Recent Sessions': 'ಇತ್ತೀಚಿನ ಸೆಷನ್‌ಗಳು',
    'No sessions yet': 'ಇನ್ನೂ ಯಾವ ಸೆಷನ್‌ಗಳಿಲ್ಲ',
    'Exit App?': 'ಆ್ಯಪ್‌ನಿಂದ ಹೊರಬರಬೇಕೇ?',
    'Are you sure you want to exit BloomSpeech?': 'ನೀವು ಖಚಿತವಾಗಿ BloomSpeech ನಿಂದ ಹೊರಬರಲು ಬಯಸುತ್ತೀರಾ?',
    'Cancel': 'ರದ್ದುಮಾಡಿ',
    'Exit': 'ಹೊರಬನ್ನಿ',
    'Recent Children': 'ಇತ್ತೀಚಿನ ಮಕ್ಕಳು',
    'View All': 'ಎಲ್ಲವನ್ನೂ ನೋಡಿ',
    'Quick Tip': 'ಸಲಹೆ',
    'No children yet': 'ಇನ್ನೂ ಮಕ್ಕಳಿಲ್ಲ',
    'Add a child to start your first therapy session': 'ಮೊದಲ ಚಿಕಿತ್ಸಾ ಸೆಷನ್ ಆರಂಭಿಸಲು ಮಗುವನ್ನು ಸೇರಿಸಿ',
    'Let\'s practice smooth speech!': 'ಸರಾಗವಾಗಿ ಮಾತಾಡಲು ಅಭ್ಯಾಸ ಮಾಡೋಣ!',
    'Live Session': 'ನೇರ ಸೆಷನ್',
    'Join a video call and start speech practice with your therapist.': 'ವೀಡಿಯೊ ಕರೆಗೆ ಸೇರಿ ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರೊಂದಿಗೆ ಮಾತಿನ ಅಭ್ಯಾಸ ಆರಂಭಿಸಿ.',
    'Join Your Session': 'ನಿಮ್ಮ ಸೆಷನ್‌ಗೆ ಸೇರಿ',
    'Login required': 'ಲಾಗಿನ್ ಅಗತ್ಯವಿದೆ',
    'Progress Dashboard': 'ಪ್ರಗತಿ ಫಲಕ',
    'No session data yet': 'ಇನ್ನೂ ಸೆಷನ್ ಮಾಹಿತಿ ಇಲ್ಲ',
    'Complete a session to see progress': 'ಪ್ರಗತಿ ನೋಡಲು ಒಂದು ಸೆಷನ್ ಪೂರ್ಣಗೊಳಿಸಿ',
    'Compare Sessions': 'ಸೆಷನ್‌ಗಳನ್ನು ಹೋಲಿಸಿ',
    'Need at least 2 sessions': 'ಕನಿಷ್ಠ 2 ಸೆಷನ್‌ಗಳು ಬೇಕು',
    'Complete more sessions to compare': 'ಹೋಲಿಸಲು ಇನ್ನಷ್ಟು ಸೆಷನ್‌ಗಳನ್ನು ಪೂರ್ಣಗೊಳಿಸಿ',
    'Select sessions to compare': 'ಹೋಲಿಸಲು ಸೆಷನ್‌ಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    'Select two sessions above to compare': 'ಹೋಲಿಸಲು ಮೇಲಿನ ಎರಡು ಸೆಷನ್‌ಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    'Tap to select': 'ಆಯ್ಕೆಮಾಡಲು ಒತ್ತಿರಿ',
    'Select a Session': 'ಒಂದು ಸೆಷನ್ ಆಯ್ಕೆಮಾಡಿ',
    '🎉 Great Job!': '🎉 ಭೇಷ್!',
    'Done': 'ಮುಗಿಯಿತು',
    'Water Level': 'ನೀರಿನ ಮಟ್ಟ',
    'Water!': 'ನೀರು!',
    'Tap to water your plant!': 'ನಿಮ್ಮ ಗಿಡಕ್ಕೆ ನೀರು ಹಾಕಲು ಒತ್ತಿರಿ!',
    '🎨 Beautiful Rangoli!': '🎨 ಸುಂದರ ರಂಗೋಲಿ!',
    'You created a wonderful rangoli pattern!': 'ನೀನು ಅದ್ಭುತ ರಂಗೋಲಿ ಬಿಡಿಸಿದೆ!',
    '🎨 Rangoli Painter': '🎨 ರಂಗೋಲಿ ಚಿತ್ರಕಾರ',
    'Pick a color': 'ಬಣ್ಣ ಆಯ್ಕೆಮಾಡಿ',
    'Tap petals to color them!': 'ದಳಗಳಿಗೆ ಬಣ್ಣ ಹಚ್ಚಲು ಒತ್ತಿರಿ!',
    'Amazing! 🌟': 'ಅದ್ಭುತ! 🌟',
    'You reached your goal!': 'ನೀನು ಗುರಿ ತಲುಪಿದೆ!',
    'Tap anywhere for sparkles! ✨': 'ಮಿಂಚುಗಳಿಗಾಗಿ ಎಲ್ಲಾದರೂ ಒತ್ತಿರಿ! ✨',
    'Play Mini Game! 🎮': 'ಆಟ ಆಡು! 🎮',
    'Done — Continue Session': 'ಮುಗಿಯಿತು — ಸೆಷನ್ ಮುಂದುವರಿಸಿ',
    'End Session?': 'ಸೆಷನ್ ಮುಗಿಸಬೇಕೇ?',
    'Are you sure you want to end this therapy session? Session data will be saved.': 'ಈ ಚಿಕಿತ್ಸಾ ಸೆಷನ್ ಮುಗಿಸಲು ಖಚಿತವೇ? ಸೆಷನ್ ಮಾಹಿತಿ ಉಳಿಸಲಾಗುತ್ತದೆ.',
    'End Session': 'ಸೆಷನ್ ಮುಗಿಸಿ',
    'No active session': 'ಸಕ್ರಿಯ ಸೆಷನ್ ಇಲ್ಲ',
    'Session Complete!': 'ಸೆಷನ್ ಪೂರ್ಣಗೊಂಡಿದೆ!',
    'Great job! Your clinician has ended the session.': 'ಭೇಷ್! ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರು ಸೆಷನ್ ಮುಗಿಸಿದ್ದಾರೆ.',
    'My Progress': 'ನನ್ನ ಪ್ರಗತಿ',
    'Done! 🌟': 'ಮುಗಿಯಿತು! 🌟',
    'Session in progress': 'ಸೆಷನ್ ನಡೆಯುತ್ತಿದೆ',
    'OK 👍': 'ಸರಿ 👍',
    'Connecting to session...': 'ಸೆಷನ್‌ಗೆ ಸಂಪರ್ಕಿಸಲಾಗುತ್ತಿದೆ...',
    'Session not found 😕': 'ಸೆಷನ್ ಸಿಗಲಿಲ್ಲ 😕',
    'Try Again': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
    '← Go Back': '← ಹಿಂದೆ ಹೋಗಿ',
    'Keep talking! You\'re doing great!': 'ಮಾತಾಡುತ್ತಾ ಇರು! ನೀನು ಚೆನ್ನಾಗಿ ಮಾಡುತ್ತಿದ್ದೀಯ!',
    'Waiting for your therapist…': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರಿಗಾಗಿ ಕಾಯಲಾಗುತ್ತಿದೆ…',
    'They will start the video call': 'ಅವರು ವೀಡಿಯೊ ಕರೆ ಪ್ರಾರಂಭಿಸುತ್ತಾರೆ',
    'Session History': 'ಸೆಷನ್ ಇತಿಹಾಸ',
    'Session Setup': 'ಸೆಷನ್ ಸಿದ್ಧತೆ',
    'Choose Theme': 'ಥೀಮ್ ಆಯ್ಕೆಮಾಡಿ',
    'Choose a Theme': 'ಒಂದು ಥೀಮ್ ಆಯ್ಕೆಮಾಡಿ',
    'Choose a Token': 'ಒಂದು ಟೋಕನ್ ಆಯ್ಕೆಮಾಡಿ',
    'No progress to show yet': 'ಇನ್ನೂ ತೋರಿಸಲು ಪ್ರಗತಿ ಇಲ್ಲ',
    'No practice history yet': 'ಇನ್ನೂ ಅಭ್ಯಾಸದ ಇತಿಹಾಸ ಇಲ್ಲ',
    'Details for your therapist': 'ನಿಮ್ಮ ಚಿಕಿತ್ಸಕರಿಗಾಗಿ ವಿವರಗಳು',
    'No session data': 'ಸೆಷನ್ ಮಾಹಿತಿ ಇಲ್ಲ',
    'Go Home': 'ಮುಖಪುಟಕ್ಕೆ ಹೋಗಿ',
    'Session Summary': 'ಸೆಷನ್ ಸಾರಾಂಶ',
    'Fluency Rate': 'ಸರಾಗತೆ ಪ್ರಮಾಣ',
    'Dysfluency / Stuttering Frequency (%)': 'ತೊದಲುವಿಕೆ ಪ್ರಮಾಣ (%)',
    'Fluent Word': 'ಸರಾಗ ಪದ',
    'Stuttered Word': 'ತೊದಲಿದ ಪದ',
    'Fluent Words': 'ಸರಾಗ ಪದಗಳು',
    'Stuttered Words': 'ತೊದಲಿದ ಪದಗಳು',
    'Total Words Recorded': 'ದಾಖಲಾದ ಒಟ್ಟು ಪದಗಳು',
    'Stuttering Frequency Across Sessions': 'ಸೆಷನ್‌ಗಳಾದ್ಯಂತ ತೊದಲುವಿಕೆ ಪ್ರಮಾಣ',
    'Baseline stuttering frequency (%)': 'ಆರಂಭಿಕ ತೊದಲುವಿಕೆ ಪ್ರಮಾಣ (%)',
    'Share via WhatsApp': 'WhatsApp ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ',
    'PDF export coming soon!': 'PDF ರಫ್ತು ಶೀಘ್ರದಲ್ಲಿ ಬರಲಿದೆ!',
    'Export PDF': 'PDF ರಫ್ತು ಮಾಡಿ',
    'Settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    'Language': 'ಭಾಷೆ',
    'App': 'ಆ್ಯಪ್',
    'About': 'ಕುರಿತು',
    'Privacy Policy': 'ಗೌಪ್ಯತೆ ನೀತಿ',
    'Help & Support': 'ಸಹಾಯ ಮತ್ತು ಬೆಂಬಲ',
    'Check why progress may be missing': 'ಪ್ರಗತಿ ಏಕೆ ಕಾಣುತ್ತಿಲ್ಲ ಎಂದು ಪರಿಶೀಲಿಸಿ',
    'Sign Out': 'ಸೈನ್ ಔಟ್',
    'Are you sure you want to sign out?': 'ನೀವು ಖಚಿತವಾಗಿ ಸೈನ್ ಔಟ್ ಮಾಡಲು ಬಯಸುತ್ತೀರಾ?',
    'Nurturing Fluent Speech': 'ಸರಾಗ ಮಾತಿನ ಪೋಷಣೆ',
    'Video Call': 'ವೀಡಿಯೊ ಕರೆ',
    'Add New Child': 'ಹೊಸ ಮಗುವನ್ನು ಸೇರಿಸಿ',
    'Treatment Level': 'ಚಿಕಿತ್ಸಾ ಹಂತ',
    'Reward Type': 'ಬಹುಮಾನದ ಪ್ರಕಾರ',
  };

  static String get(String key, AppLanguage lang) {
    final entry = _localizedValues[key];
    if (entry != null) {
      return entry[lang] ?? entry[AppLanguage.english] ?? key;
    }
    if (lang == AppLanguage.kannada) return _kannada[key] ?? key;
    return key;
  }
}

/// Dynamic String translation extension
extension LocalizedString on String {
  /// Translate using the active language, or an explicit one if given.
  String tr([AppLanguage? lang]) {
    return AppLocalizations.get(this, lang ?? AppLocalizations.current);
  }
}
