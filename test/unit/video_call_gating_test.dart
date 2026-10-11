import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/models/session.dart';

/// The child's device joins the video call only when the clinician says so,
/// via `kid_video_started`. A missing column and a deliberate `false` both
/// parse as `false`, and the two mean opposite things: one is "this database
/// cannot express the instruction", the other is "hang up now".
void main() {
  Map<String, dynamic> row({Map<String, dynamic> extra = const {}}) => {
        'session_code': 'AB12CD',
        'clinician_id': 'clin-1',
        'child_id': 'child-1',
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
        ...extra,
      };

  /// Mirrors `_videoAllowed` on the child's session screen.
  bool videoAllowed(ActiveSession s) =>
      s.kidCallColumnsPresent ? s.kidVideoStarted : true;

  group('telling a missing column apart from a deliberate false', () {
    test('a row without the column is reported as absent', () {
      final s = ActiveSession.fromMap(row());
      expect(s.kidCallColumnsPresent, isFalse);
      expect(s.kidVideoStarted, isFalse);
    });

    test('a row carrying false is reported as present', () {
      final s = ActiveSession.fromMap(row(extra: {'kid_video_started': false}));
      expect(s.kidCallColumnsPresent, isTrue);
      expect(s.kidVideoStarted, isFalse);
    });

    test('a row carrying true is reported as present', () {
      final s = ActiveSession.fromMap(row(extra: {'kid_video_started': true}));
      expect(s.kidCallColumnsPresent, isTrue);
      expect(s.kidVideoStarted, isTrue);
    });

    test('the camelCase spelling counts too', () {
      final s = ActiveSession.fromMap(row(extra: {'kidVideoStarted': true}));
      expect(s.kidCallColumnsPresent, isTrue);
      expect(s.kidVideoStarted, isTrue);
    });
  });

  group('when the clinician can give the instruction', () {
    test('the child waits until the call is started', () {
      final waiting =
          ActiveSession.fromMap(row(extra: {'kid_video_started': false}));
      expect(videoAllowed(waiting), isFalse);
    });

    test('the child joins once it is started', () {
      final started =
          ActiveSession.fromMap(row(extra: {'kid_video_started': true}));
      expect(videoAllowed(started), isTrue);
    });
  });

  group('when the database cannot carry the instruction', () {
    test('the child joins rather than never joining at all', () {
      // Gating on a flag that can never become true left the clinician in the
      // room alone — video appeared to work on one device only.
      final s = ActiveSession.fromMap(row());
      expect(s.kidCallColumnsPresent, isFalse);
      expect(videoAllowed(s), isTrue);
    });
  });

  group('hanging up', () {
    /// Mirrors the hang-up condition in `_applyClinicianCallControls`.
    bool shouldHangUp(ActiveSession s, {required bool wasInCall}) =>
        wasInCall && !videoAllowed(s) && s.kidCallColumnsPresent;

    test('hangs up when the clinician stops the call', () {
      final stopped =
          ActiveSession.fromMap(row(extra: {'kid_video_started': false}));
      expect(shouldHangUp(stopped, wasInCall: true), isTrue);
    });

    test('does not hang up on a row that never carried the column', () {
      // This is polled every two seconds; one such read would have ended a
      // live call for no reason.
      final s = ActiveSession.fromMap(row());
      expect(shouldHangUp(s, wasInCall: true), isFalse);
    });

    test('does not hang up when the call is still running', () {
      final running =
          ActiveSession.fromMap(row(extra: {'kid_video_started': true}));
      expect(shouldHangUp(running, wasInCall: true), isFalse);
    });

    test('does not hang up a call that was never joined', () {
      final stopped =
          ActiveSession.fromMap(row(extra: {'kid_video_started': false}));
      expect(shouldHangUp(stopped, wasInCall: false), isFalse);
    });

    test('a whole poll cycle of unchanged reads never hangs up', () {
      final started =
          ActiveSession.fromMap(row(extra: {'kid_video_started': true}));
      var inCall = false;
      for (var poll = 0; poll < 30; poll++) {
        expect(shouldHangUp(started, wasInCall: inCall), isFalse,
            reason: 'poll $poll ended a healthy call');
        inCall = videoAllowed(started);
      }
      expect(inCall, isTrue);
    });
  });

  test('the mute flags still round-trip', () {
    final s = ActiveSession.fromMap(row(extra: {
      'kid_video_started': true,
      'kid_audio_muted': true,
      'kid_video_muted': false,
    }));
    expect(s.kidAudioMuted, isTrue);
    expect(s.kidVideoMuted, isFalse);
  });
}
