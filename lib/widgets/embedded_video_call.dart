import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants/app_constants.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_text_styles.dart';
import '../services/video_call_service.dart';
// Conditional web import for HtmlElementView
import 'embedded_video_call_stub.dart'
    if (dart.library.html) 'embedded_video_call_web.dart' as platform_video;

/// Embedded Video Call overlay widget for remote teletherapy.
///
/// On web, renders a live Jitsi iframe within the app layout.
/// On mobile, uses native Jitsi Meet SDK.
/// Always keeps the token board visible alongside the video call.
class EmbeddedVideoCallWidget extends StatefulWidget {
  final String sessionCode;
  final String userName;
  final bool isClinician;

  /// Initial mute state, set by the clinician for the kid's device.
  final bool startAudioMuted;
  final bool startVideoMuted;

  /// Join as soon as this turns true. The clinician drives this from the
  /// "Start video call" control so both ends enter the room together —
  /// otherwise the kid joins an empty room and sees no clinician video.
  final bool autoJoin;

  const EmbeddedVideoCallWidget({
    super.key,
    required this.sessionCode,
    required this.userName,
    this.isClinician = false,
    this.startAudioMuted = false,
    this.startVideoMuted = false,
    this.autoJoin = false,
  });

  @override
  State<EmbeddedVideoCallWidget> createState() =>
      _EmbeddedVideoCallWidgetState();
}

class _EmbeddedVideoCallWidgetState extends State<EmbeddedVideoCallWidget> {
  bool _isCallActive = false;
  bool _isConnecting = false;
  String? _callError;
  bool _permissionBlocked = false;

  bool get _isAudioMuted => widget.startAudioMuted;

  @override
  void initState() {
    super.initState();
    // The kid's widget is only built once the clinician has started the call,
    // so it joins straight away. The clinician joins when `autoJoin` is set.
    if (!widget.isClinician || widget.autoJoin) {
      _scheduleAutoJoin();
    }
  }

  @override
  void didUpdateWidget(covariant EmbeddedVideoCallWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clinician pressed "Start video call" — join them into the room too.
    if (widget.autoJoin && !oldWidget.autoJoin && !_isCallActive) {
      _scheduleAutoJoin();
    }
  }

  // NOTE: deliberately no hang-up in dispose().
  //
  // This State is torn down on any sibling change in the parent Column (a
  // reward counter appearing, the session code arriving), and the clinician's
  // screen rebuilds every second for the timer. Hanging up here dropped a
  // participant out of the conference mid-session for reasons that had nothing
  // to do with the call — which is why each side ended up seeing only their own
  // video. Leaving the call is now driven explicitly from the session screens,
  // which actually know when it should end.

  void _scheduleAutoJoin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isCallActive && !_isConnecting) {
          _startCall();
        }
      });
    });
  }

  String get _roomName =>
      '${AppConstants.jitsiRoomPrefix}${widget.sessionCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

  String get _displayName =>
      '${widget.userName} (${widget.isClinician ? 'Clinician' : 'Kid'})';

  /// Both sides MUST resolve to the same host, otherwise the clinician and the
  /// kid end up in two unrelated conferences on two different servers.
  String get _jitsiUrl {
    final encoded = Uri.encodeComponent(_displayName);
    return '${AppConstants.jitsiServerUrl}/$_roomName'
        '#userInfo.displayName="$encoded"'
        '&config.startWithAudioMuted=$_isAudioMuted'
        '&config.prejoinPageEnabled=false'
        '&config.prejoinConfig.enabled=false'
        // Match the mobile side: bridge-routed, never peer-to-peer, so a
        // half-open P2P connection cannot leave one participant unable to
        // see the other.
        '&config.p2p.enabled=false'
        '&config.channelLastN=-1';
  }

  /// Mirrors the real conference lifecycle back into the widget so the card
  /// never claims the call is live after the kid has left it.
  JitsiMeetEventListener get _callListener => JitsiMeetEventListener(
        conferenceJoined: (_) {
          if (mounted) {
            setState(() {
              _isCallActive = true;
              _isConnecting = false;
              _callError = null;
            });
          }
        },
        conferenceTerminated: (_, error) {
          if (mounted) {
            setState(() {
              _isCallActive = false;
              _isConnecting = false;
              _callError = error?.toString();
            });
          }
        },
      );

  /// True only when the configured host actually allows being framed.
  bool get _useInlineIframe => kIsWeb && AppConstants.jitsiSupportsIframe;

  Future<void> _startCall() async {
    setState(() {
      _isConnecting = true;
      _callError = null;
    });

    if (_useInlineIframe) {
      // On web, activate the iframe
      setState(() {
        _isCallActive = true;
        _isConnecting = false;
      });
      // Register the iframe in the platform layer
      platform_video.registerJitsiIframe(_roomName, _jitsiUrl);
    } else if (kIsWeb) {
      // Host refuses to be framed — open the call in a second browser tab so
      // the token board stays visible in this one.
      await launchUrl(
        Uri.parse(_jitsiUrl),
        webOnlyWindowName: '_blank',
      );
      if (mounted) {
        setState(() {
          _isCallActive = true;
          _isConnecting = false;
        });
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      // On mobile, use native Jitsi SDK. `_isCallActive` is driven by the
      // listener callbacks, not assumed here.
      try {
        await VideoCallService.joinCall(
          roomName: _roomName,
          displayName: _displayName,
          isAudioMuted: widget.startAudioMuted,
          isVideoMuted: widget.startVideoMuted,
          listener: _callListener,
        );
      } catch (e) {
        final denied =
            e.toString().contains(VideoCallService.permissionDeniedError);
        final permanent = denied && await VideoCallService.isPermanentlyDenied();
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _permissionBlocked = permanent;
            _callError = denied
                ? 'Camera and microphone access is needed for the video call.'
                : e.toString();
          });
        }
      }
    } else {
      // Desktop fallback — open in browser
      final uri = Uri.parse('${AppConstants.jitsiServerUrl}/$_roomName');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        setState(() {
          _isCallActive = true;
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Before call is started — show a "Join Call" card
    if (!_isCallActive) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isClinician
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.accent.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isClinician
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_rounded,
                color: widget.isClinician ? AppColors.primary : AppColors.accent,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Video Call',
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _callError ?? 'Session: ${widget.sessionCode}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              // Retrying is pointless once the user chose "Don't ask again";
              // send them to system settings instead.
              onPressed: _isConnecting
                  ? null
                  : (_permissionBlocked
                      ? VideoCallService.openSettings
                      : _startCall),
              icon: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _permissionBlocked
                          ? Icons.settings_rounded
                          : Icons.call_rounded,
                      size: 20),
              label: Text(_isConnecting
                  ? 'Connecting…'
                  : (_permissionBlocked ? 'Open Settings' : 'Join Video Call')),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.isClinician ? AppColors.primary : AppColors.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Call is active — show live Jitsi iframe on web, or status on mobile
    if (_useInlineIframe) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.greenAccent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: platform_video.buildJitsiView(_roomName),
        ),
      );
    }

    // Mobile (or a web host that refuses framing) — show a status card.
    // The parent gives this a fixed height as small as 130px, so scale the
    // contents down rather than overflowing.
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_rounded,
              color: Colors.greenAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            kIsWeb ? '🟢 Call open in another tab' : '🟢 Video Call Active',
            style: AppTextStyles.titleSmall.copyWith(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _displayName,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          // The tab can be closed or lost behind the app window, and the
          // native call screen can be dismissed — always leave a way back in.
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _startCall,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(kIsWeb ? 'Reopen call' : 'Return to call'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.greenAccent,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
