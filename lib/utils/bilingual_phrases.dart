/// Bilingual phrases for BloomSpeech (English + Kannada)
class BilingualPhrases {
  BilingualPhrases._();

  // ─── Feedback Phrases ───
  static const Map<String, Map<String, String>> feedback = {
    'fluent_1': {
      'en': 'Wow, that was smooth speech!',
      'kn': 'ಶಾಭಾಶ್, ತುಂಬಾ ಚೆನ್ನಾಗಿ ಮಾತಾಡ್ದೆ!',
    },
    'fluent_2': {
      'en': 'Great job! So smooth!',
      'kn': 'ತುಂಬಾ ಚೆನ್ನಾಗಿದೆ! ಹೀಗೇ ಮಾತಾಡು!',
    },
    'fluent_3': {
      'en': 'Beautiful! That was perfect!',
      'kn': 'ಸೂಪರ್! ತುಂಬಾ ಚೆನ್ನಾಗಿ ಹೇಳಿದೆ!',
    },
    'fluent_4': {
      'en': 'Wonderful smooth talking!',
      'kn': 'ಅದ್ಭುತ! ಎಷ್ಟು ಚೆನ್ನಾಗಿ ಮಾತಾಡ್ತೀಯ!',
    },
    'fluent_5': {
      'en': 'You are a star! So smooth!',
      'kn': 'ನೀನು ಸ್ಟಾರ್! ತುಂಬಾ ಸ್ಮೂತ್!',
    },
    'dysfluent_1': {
      'en': 'Oh, that was a bumpy one! Try again!',
      'kn': 'ಅದು ತೊಡಲಿತು, ಇನ್ನೊಂದು ಸಾರಿ ಹೇಳು!',
    },
    'dysfluent_2': {
      'en': "That's okay! Let's try once more!",
      'kn': 'ಪರವಾಗಿಲ್ಲ! ಇನ್ನೊಂದು ಸಾರಿ ಪ್ರಯತ್ನಿಸು!',
    },
    'dysfluent_3': {
      'en': 'Almost there! Try again slowly!',
      'kn': 'ಸ್ವಲ್ಪ ನಿಧಾನವಾಗಿ ಹೇಳು!',
    },
  };

  // ─── Reward Phrases ───
  static const Map<String, Map<String, String>> reward = {
    'goal_reached': {
      'en': 'Amazing! You reached your goal!',
      'kn': 'ಅದ್ಭುತ! ನೀನು ಗುರಿ ತಲುಪಿದೆ!',
    },
    'celebration': {
      'en': 'Time to celebrate! You are wonderful!',
      'kn': 'ಸಂಭ್ರಮಿಸೋ ಸಮಯ! ನೀನು ಅದ್ಭುತ!',
    },
    'sticker_time': {
      'en': 'Time for your sticker!',
      'kn': 'ನಿನ್ನ ಸ್ಟಿಕ್ಕರ್ ಸಮಯ!',
    },
    'great_work': {
      'en': 'Great work today!',
      'kn': 'ಇವತ್ತು ತುಂಬಾ ಚೆನ್ನಾಗಿ ಮಾಡಿದೆ!',
    },
  };

  // ─── Session Phrases ───
  static const Map<String, Map<String, String>> session = {
    'session_start': {
      'en': 'Let\'s start! Are you ready?',
      'kn': 'ಶುರು ಮಾಡೋಣ! ರೆಡಿ ಇದ್ಯಾ?',
    },
    'session_end': {
      'en': 'Great session! Well done!',
      'kn': 'ಒಳ್ಳೆ ಸೆಶನ್! ತುಂಬಾ ಚೆನ್ನಾಗಿ ಮಾಡಿದೆ!',
    },
    'level_up': {
      'en': 'You are moving to the next level!',
      'kn': 'ನೀನು ಮುಂದಿನ ಹಂತಕ್ಕೆ ಹೋಗ್ತಿದ್ಯಾ!',
    },
  };

  // ─── Clinician Prompts by Level ───
  static const Map<String, Map<String, String>> levelPrompts = {
    'word': {
      'en': 'What is this?',
      'kn': 'ಇದು ಏನು?',
    },
    'sentence': {
      'en': 'Tell me one thing about this picture',
      'kn': 'ಈ ಚಿತ್ರದ ಬಗ್ಗೆ ಒಂದು ವಿಷಯ ಹೇಳು',
    },
    'continuous': {
      'en': 'Tell me what is happening here, then what happened next',
      'kn': 'ಇಲ್ಲಿ ಏನಾಗ್ತಿದೆ ಹೇಳು, ಮುಂದೆ ಏನಾಯ್ತು',
    },
    'narrative': {
      'en': 'Tell me the whole story',
      'kn': 'ಪೂರ್ತಿ ಕಥೆ ಹೇಳು',
    },
    'conversational': {
      'en': 'Now you are the shopkeeper. What do you say?',
      'kn': 'ಈಗ ನೀನು ಅಂಗಡಿಯವನು. ಏನು ಹೇಳ್ತೀಯ?',
    },
  };

  // ─── Physical Reward Options ───
  static const Map<String, Map<String, String>> physicalRewards = {
    'sticker': {
      'en': 'Time for your sticker!',
      'kn': 'ನಿನ್ನ ಸ್ಟಿಕ್ಕರ್ ಸಮಯ!',
    },
    'star': {
      'en': 'You earned a gold star!',
      'kn': 'ನೀನು ಚಿನ್ನದ ನಕ್ಷತ್ರ ಗಳಿಸಿದೆ!',
    },
    'stamp': {
      'en': 'Time for your special stamp!',
      'kn': 'ನಿನ್ನ ವಿಶೇಷ ಸ್ಟಾಂಪ್ ಸಮಯ!',
    },
    'treat': {
      'en': 'You can have your special treat!',
      'kn': 'ನಿನ್ನ ವಿಶೇಷ ಟ್ರೀಟ್ ತಗೊಳ್ಳಬಹುದು!',
    },
    'toy_time': {
      'en': 'Time to play with your favourite toy!',
      'kn': 'ನಿನ್ನ ಇಷ್ಟದ ಆಟಿಕೆ ಆಡುವ ಸಮಯ!',
    },
  };

  /// Get a phrase by key and language code
  static String getPhrase(Map<String, Map<String, String>> phraseMap, String key, String languageCode) {
    return phraseMap[key]?[languageCode] ?? phraseMap[key]?['en'] ?? '';
  }
}
