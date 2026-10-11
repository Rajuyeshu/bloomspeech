import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/utils/app_localizations.dart';
import 'package:bloomspeech/utils/bilingual_phrases.dart';

/// Translation lookup must never lose a string. When a key has no Kannada
/// entry the English text has to survive — a blank label is worse than an
/// untranslated one.
void main() {
  tearDown(() => AppLocalizations.current = AppLanguage.english);

  group('lookup', () {
    test('returns the Kannada string when one exists', () {
      final kn = AppLocalizations.get('tagline', AppLanguage.kannada);
      final en = AppLocalizations.get('tagline', AppLanguage.english);
      expect(en, 'Nurturing fluent speech');
      expect(kn, isNot(en));
      expect(kn, isNotEmpty);
    });

    test('an unknown key falls back to the key itself, never to blank', () {
      const key = 'a key that does not exist anywhere';
      expect(AppLocalizations.get(key, AppLanguage.english), key);
      expect(AppLocalizations.get(key, AppLanguage.kannada), key);
    });

    test('English text is returned untranslated when no Kannada exists', () {
      // The agreed behaviour: leave it in English rather than blank it out.
      const english = 'Speech Practice History';
      final out = AppLocalizations.get(english, AppLanguage.kannada);
      expect(out, isNotEmpty);
    });
  });

  group('the .tr() extension', () {
    test('follows the active language', () {
      AppLocalizations.current = AppLanguage.english;
      final en = 'tagline'.tr();
      AppLocalizations.current = AppLanguage.kannada;
      final kn = 'tagline'.tr();

      expect(en, 'Nurturing fluent speech');
      expect(kn, isNot(en));
    });

    test('an explicit language overrides the active one', () {
      AppLocalizations.current = AppLanguage.kannada;
      expect('tagline'.tr(AppLanguage.english), 'Nurturing fluent speech');
    });
  });

  group('feedback phrases', () {
    test('every phrase exists in both languages and is non-empty', () {
      for (final entry in BilingualPhrases.feedback.entries) {
        expect(entry.value['en'], isNotNull,
            reason: '${entry.key} has no English text');
        expect(entry.value['kn'], isNotNull,
            reason: '${entry.key} has no Kannada text');
        expect(entry.value['en']!.trim(), isNotEmpty, reason: entry.key);
        expect(entry.value['kn']!.trim(), isNotEmpty, reason: entry.key);
      }
    });

    test('there is at least one fluent and one dysfluent phrase', () {
      final keys = BilingualPhrases.feedback.keys;
      expect(keys.where((k) => k.startsWith('fluent_')), isNotEmpty);
      expect(keys.where((k) => k.startsWith('dysfluent_')), isNotEmpty);
    });

    test('the smooth-speech phrase is the agreed wording', () {
      expect(BilingualPhrases.feedback['fluent_1']!['en'],
          'Wow, that was smooth speech!');
    });
  });

  test('every AppLanguage has a code and a display name', () {
    for (final lang in AppLanguage.values) {
      expect(lang.code.trim(), isNotEmpty);
      expect(lang.displayName.trim(), isNotEmpty);
    }
    expect(AppLanguage.values.map((l) => l.code).toSet().length,
        AppLanguage.values.length,
        reason: 'language codes must be unique — they are the storage key');
  });
}
