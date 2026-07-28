import '../config/constants/app_constants.dart';

/// Localization keys and their translations in English & Kannada
class AppLocalizations {
  AppLocalizations._();

  static const Map<String, Map<AppLanguage, String>> _localizedValues = {
    // ─── Landing/Login Role Page ───
    'tagline': {
      AppLanguage.english: 'Response Cost Therapy for fluent speech',
      AppLanguage.kannada: 'ಸರಾಗ ಭಾಷಣಕ್ಕಾಗಿ ರೆಸ್ಪಾನ್ಸ್ ಕಾಸ್ಟ್ ಥೆರಪಿ',
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
  static String get(String key, AppLanguage lang) {
    final entry = _localizedValues[key];
    if (entry == null) return key;
    return entry[lang] ?? entry[AppLanguage.english] ?? key;
  }
}

/// Dynamic String translation extension
extension LocalizedString on String {
  String tr(AppLanguage lang) {
    return AppLocalizations.get(this, lang);
  }
}
