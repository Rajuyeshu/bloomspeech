import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/models/session.dart';
import 'package:bloomspeech/utils/bilingual_phrases.dart';

/// Switching the interface to Kannada changed every label but left the spoken
/// feedback in English, because SessionConfig was constructed without a
/// language and silently kept its 'en' default. The language has to survive
/// the whole path — setup, the shared session row, the child's device — or the
/// child hears the wrong language with nothing to indicate why.
void main() {
  group('the session carries the therapy language', () {
    test('a Kannada session reaches the child device as Kannada', () {
      final config = SessionConfig(
        childId: 'c1',
        childName: 'Aarav',
        language: AppLanguage.kannada.code,
      );
      final row = ActiveSession.fromConfig(config,
          sessionCode: 'AB12CD', clinicianId: 'clin-1');
      final onChildDevice = ActiveSession.fromMap(row.toMap());

      expect(config.language, 'kn');
      expect(row.language, 'kn');
      expect(onChildDevice.language, 'kn',
          reason: 'the child device decides the spoken language from this');
    });

    test('English sessions are unaffected', () {
      final row = ActiveSession.fromConfig(
        SessionConfig(childId: 'c1', childName: 'A', language: 'en'),
        sessionCode: 'X',
        clinicianId: 'c',
      );
      expect(row.language, 'en');
    });

    test('both app languages produce a code the session accepts', () {
      for (final lang in AppLanguage.values) {
        final row = ActiveSession.fromConfig(
          SessionConfig(childId: 'c', childName: 'A', language: lang.code),
          sessionCode: 'X',
          clinicianId: 'c',
        );
        expect(row.language, lang.code);
      }
    });
  });

  group('feedback phrases resolve in the session language', () {
    test('a Kannada session gets Kannada text, not English', () {
      for (final key in BilingualPhrases.feedback.keys) {
        final kn = BilingualPhrases.getPhrase(
            BilingualPhrases.feedback, key, 'kn');
        final en = BilingualPhrases.getPhrase(
            BilingualPhrases.feedback, key, 'en');
        expect(kn, isNotEmpty, reason: key);
        expect(kn, isNot(en), reason: '$key returned the English phrase');
      }
    });

    test('every phrase has an English fallback for devices with no Kannada voice',
        () {
      // The fallback is spoken when the device cannot voice Kannada; if it
      // were missing the child would hear nothing at all.
      for (final key in BilingualPhrases.feedback.keys) {
        expect(BilingualPhrases.getPhrase(BilingualPhrases.feedback, key, 'en'),
            isNotEmpty,
            reason: key);
      }
    });

    test('an unknown language falls back to English rather than to nothing', () {
      final out = BilingualPhrases.getPhrase(
          BilingualPhrases.feedback, 'fluent_1', 'fr');
      expect(out, BilingualPhrases.feedback['fluent_1']!['en']);
    });
  });

  group('themes offered for new sessions', () {
    test('none of the preschool themes are the retired festival ones', () {
      for (final t in PlayTheme.selectable) {
        expect(t.legacy, isFalse, reason: '${t.name} is retired');
        expect(t.container, isNot(TokenContainer.none),
            reason: '${t.name} has no collection container');
      }
    });

    test('the retired themes still parse, so old sessions still display', () {
      // Removing them would make every historical session fall back to a
      // default and misreport what the child actually played.
      for (final name in [
        'diyaFestival',
        'rangoliBuilder',
        'mangoHarvest',
        'peacockGarden',
        'lotusPond',
        'kiteFestival'
      ]) {
        final t = PlayTheme.values.firstWhere((x) => x.name == name,
            orElse: () => PlayTheme.initial);
        expect(t.name, name, reason: '$name no longer parses');
        expect(t.legacy, isTrue);
      }
    });

    test('the default for a new session is a preschool theme', () {
      expect(PlayTheme.initial.legacy, isFalse);
      expect(PlayTheme.selectable, contains(PlayTheme.initial));
    });

    test('every offered theme has a distinct token glyph', () {
      final glyphs = PlayTheme.selectable.map((t) => t.emoji).toList();
      expect(glyphs.toSet().length, glyphs.length,
          reason: 'two themes would look identical to the child');
    });
  });
}
