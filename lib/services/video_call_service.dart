import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to handle remote teletherapy video calls.
/// Uses native Jitsi Meet SDK on mobile (Android/iOS) and web-fallback (url_launcher) on macOS/Web.
class VideoCallService {
  VideoCallService._();

  static final JitsiMeet _jitsiMeet = JitsiMeet();

  /// Launch a video call for a given room name.
  /// Optionally takes a display name for the user.
  static Future<void> joinCall({
    required String roomName,
    required String displayName,
    String? subject,
    bool isAudioMuted = false,
    bool isVideoMuted = false,
  }) async {
    // Sanitize room name (Jitsi rooms are alphanumeric, no spaces/special characters)
    final sanitizedRoom = roomName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final serverUrl = 'https://meet.jit.si/$sanitizedRoom';

    debugPrint('Joining video call room: $sanitizedRoom (Platform: ${defaultTargetPlatform.name})');

    // On macOS/Windows/Linux/Web, launch the Jitsi Meet room in the web browser
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      final uri = Uri.parse(serverUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch video call URL: $serverUrl');
      }
      return;
    }

    // On iOS & Android, use the native Jitsi Meet SDK
    try {
      final options = JitsiMeetConferenceOptions(
        room: sanitizedRoom,
        configOverrides: {
          'startWithAudioMuted': isAudioMuted,
          'startWithVideoMuted': isVideoMuted,
          'prejoinPageEnabled': false, // skip prejoin page for kids/patients
        },
        featureFlags: {
          'unsecureMeetingIndicatorEnabled': false,
          'welcomePageEnabled': false,
          'resolution': 360, // save bandwidth
        },
        userInfo: JitsiMeetUserInfo(
          displayName: displayName,
        ),
      );

      await _jitsiMeet.join(options);
    } catch (e) {
      debugPrint('Error joining Jitsi native call: $e');
      // Fallback to web link if SDK fails to load or configure
      final uri = Uri.parse(serverUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        rethrow;
      }
    }
  }

  /// Hang up / leave the current call
  static Future<void> leaveCall() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await _jitsiMeet.hangUp();
      } catch (e) {
        debugPrint('Error hanging up Jitsi call: $e');
      }
    }
  }
}
