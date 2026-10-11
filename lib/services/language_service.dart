import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants/app_constants.dart';
import '../utils/app_localizations.dart';

/// Holds the chosen interface language and remembers it across restarts.
///
/// This was previously a plain `StateProvider`, so the selection was lost on
/// every launch and always reverted to English.
class LanguageService extends StateNotifier<AppLanguage> {
  static const String boxName = 'app_settings';
  static const String _key = 'language_code';

  LanguageService() : super(_restore()) {
    AppLocalizations.current = state;
  }

  static AppLanguage _restore() {
    try {
      final code = Hive.box(boxName).get(_key) as String?;
      if (code != null) {
        return AppLanguage.values.firstWhere(
          (l) => l.code == code,
          orElse: () => AppLanguage.english,
        );
      }
    } catch (e) {
      debugPrint('Language restore failed, defaulting to English: $e');
    }
    return AppLanguage.english;
  }

  void setLanguage(AppLanguage language) {
    state = language;
    AppLocalizations.current = language;
    try {
      Hive.box(boxName).put(_key, language.code);
    } catch (e) {
      debugPrint('Language persist failed: $e');
    }
  }
}

/// Global language provider. Watch this in a widget and it rebuilds when the
/// language changes.
final appLanguageProvider =
    StateNotifierProvider<LanguageService, AppLanguage>(
  (ref) => LanguageService(),
);
