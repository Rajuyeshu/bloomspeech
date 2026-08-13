import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants/app_constants.dart';

/// Service to handle remote teletherapy video calls.
/// Uses native Jitsi Meet SDK on mobile (Android/iOS) and web-fallback (url_launcher) on macOS/Web.
class VideoCallService {
  VideoCallService._();

  static final JitsiMeet _jitsiMeet = JitsiMeet();

  /// Thrown when the user has not granted camera/microphone access.
  static const String permissionDeniedError = 'camera-mic-permission-denied';

  /// Ask for camera + microphone up front.
  ///
  /// Declaring these in the manifest is not enough on Android 6+; they must be
  /// granted at runtime. Without them Jitsi still renders its toolbar, but the
  /// camera and mic buttons silently do nothing — which looks exactly like
  /// "the call joined but video and audio won't turn on".
  static Future<bool> ensureMediaPermissions() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final statuses = await [Permission.camera, Permission.microphone].request();
    return statuses.values.every((s) => s.isGranted);
  }

  /// True when the user picked "Don't ask again" — the in-app prompt can no
  /// longer appear, so the caller has to send them to system settings.
  static Future<bool> isPermanentlyDenied() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return await Permission.camera.isPermanentlyDenied ||
        await Permission.microphone.isPermanentlyDenied;
  }

  /// Opens the OS settings page for this app.
  static Future<void> openSettings() => openAppSettings();

  /// Mute/unmute this device's own microphone.
  static Future<void> setAudioMuted(bool muted) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await _jitsiMeet.setAudioMuted(muted);
    } catch (e) {
      debugPrint('setAudioMuted failed: $e');
    }
  }

  /// Turn this device's own camera on/off.
  static Future<void> setVideoMuted(bool muted) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await _jitsiMeet.setVideoMuted(muted);
    } catch (e) {
      debugPrint('setVideoMuted failed: $e');
    }
  }

  /// Launch a video call for a given room name.
  /// Optionally takes a display name for the user.
  static Future<void> joinCall({
    required String roomName,
    required String displayName,
    String? subject,
    bool isAudioMuted = false,
    bool isVideoMuted = false,
    JitsiMeetEventListener? listener,
  }) async {
    // Sanitize room name (Jitsi rooms are alphanumeric, no spaces/special characters)
    final sanitizedRoom = roomName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final serverUrl = '${AppConstants.jitsiServerUrl}/$sanitizedRoom';

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

    // Camera/mic must be granted before Jitsi starts, or the call joins with
    // dead media controls.
    if (!await ensureMediaPermissions()) {
      throw Exception(permissionDeniedError);
    }

    // On iOS & Android, use the native Jitsi Meet SDK
    try {
      final options = JitsiMeetConferenceOptions(
        serverURL: AppConstants.jitsiServerUrl,
        room: sanitizedRoom,
        configOverrides: {
          'startWithAudioMuted': isAudioMuted,
          'startWithVideoMuted': isVideoMuted,
          // skip prejoin page for kids/patients — newer Jitsi reads
          // `prejoinConfig.enabled`, older builds read `prejoinPageEnabled`,
          // so send both.
          'prejoinPageEnabled': false,
          'prejoinConfig.enabled': false,
          // Stay in-app instead of bouncing to the installed Jitsi app / store.
          'disableDeepLinking': true,

          // ── Route media through the bridge, never peer-to-peer ──
          //
          // Jitsi switches a two-person call to a direct P2P connection by
          // default. When that ICE negotiation only half-succeeds — routine on
          // mobile carrier NAT — media flows one way: the participant already
          // in the room receives the newcomer, but the newcomer receives
          // nothing and sees only their own camera. Leaving and rejoining
          // renegotiates and flips which side is broken, which is exactly the
          // behaviour observed.
          //
          // The videobridge terminates both directions separately, so a
          // one-way failure cannot happen. Costs a little latency; worth it
          // for a call that has to work every time.
          'p2p.enabled': false,

          // Receive every remote stream rather than a speaker-ranked subset.
          'channelLastN': -1,

          // Show both people at once. Jitsi's mobile default is "stage view",
          // which promotes the dominant speaker to fullscreen and hides the
          // other — so the clinician and the kid were never visible together.
          'disableTileView': false,
          // Keep the local camera on screen alongside the remote participant.
          'disableSelfView': false,
        },
        featureFlags: {
          'unsecureMeetingIndicatorEnabled': false,
          'welcomePageEnabled': false,
          'prejoinpage.enabled': false,
          // Required for the grid layout to be reachable at all.
          'tile-view.enabled': true,
          'filmstrip.enabled': true,
          'resolution': 360, // save bandwidth
        },
        userInfo: JitsiMeetUserInfo(
          displayName: displayName,
        ),
      );

      await _jitsiMeet.join(options, listener);
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
