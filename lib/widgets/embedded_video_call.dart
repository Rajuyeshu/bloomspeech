import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  const EmbeddedVideoCallWidget({
    super.key,
    required this.sessionCode,
    required this.userName,
    this.isClinician = false,
  });

  @override
  State<EmbeddedVideoCallWidget> createState() =>
      _EmbeddedVideoCallWidgetState();
}

class _EmbeddedVideoCallWidgetState extends State<EmbeddedVideoCallWidget> {
  bool _isCallActive = false;
  bool _isAudioMuted = false;

  String get _roomName =>
      'BloomSpeech_${widget.sessionCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

  String get _displayName =>
      '${widget.userName} (${widget.isClinician ? 'Clinician' : 'Kid'})';

  String get _jitsiUrl {
    final encoded = Uri.encodeComponent(_displayName);
    return 'https://meet.jit.si/$_roomName#userInfo.displayName="$encoded"&config.startWithAudioMuted=${_isAudioMuted}&config.prejoinPageEnabled=false';
  }

  Future<void> _startCall() async {
    if (kIsWeb) {
      // On web, activate the iframe
      setState(() => _isCallActive = true);
      // Register the iframe in the platform layer
      platform_video.registerJitsiIframe(_roomName, _jitsiUrl);
    } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // On mobile, use native Jitsi SDK
      await VideoCallService.joinCall(
        roomName: _roomName,
        displayName: _displayName,
      );
      setState(() => _isCallActive = true);
    } else {
      // Desktop fallback — open in browser
      final uri = Uri.parse('https://meet.jit.si/$_roomName');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      setState(() => _isCallActive = true);
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
            Text(
              'Session: ${widget.sessionCode}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startCall,
              icon: const Icon(Icons.call_rounded, size: 20),
              label: const Text('Join Video Call'),
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
    if (kIsWeb) {
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

    // Mobile — call is running natively, show status card
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_rounded,
              color: Colors.greenAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            '🟢 Video Call Active',
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
        ],
      ),
    );
  }
}
