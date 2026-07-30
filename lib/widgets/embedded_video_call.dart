import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_text_styles.dart';
import '../services/video_call_service.dart';

/// Embedded Floating Video Call overlay widget for remote teletherapy.
///
/// Keeps the interactive therapy screen (token board, mini-game, prompts)
/// front and center while floating a live video call window at the corner.
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
  State<EmbeddedVideoCallWidget> createState() => _EmbeddedVideoCallWidgetState();
}

class _EmbeddedVideoCallWidgetState extends State<EmbeddedVideoCallWidget> {
  bool _isMinimized = false;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  Offset _position = const Offset(16, 80);

  Future<void> _openFullVideoCall() async {
    final cleanCode = widget.sessionCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final roomName = 'BloomSpeech_$cleanCode';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Use native Jitsi Meet conference directly on mobile/emulator
      await VideoCallService.joinCall(
        roomName: roomName,
        displayName: widget.userName + (widget.isClinician ? ' (Clinician)' : ' (Kid)'),
      );
    } else {
      // Use web URL on desktop/browser platforms
      final uri = Uri.parse('https://meet.jit.si/$roomName');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx.clamp(8, screenSize.width - 240),
      top: _position.dy.clamp(60, screenSize.height - 200),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isMinimized ? 180 : 260,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: widget.isClinician
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.accent.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isClinician
                      ? AppColors.primary
                      : AppColors.accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isClinician ? Icons.medical_services : Icons.child_care,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isMinimized
                            ? '🎥 Call Active'
                            : '🎥 Video Call (${widget.sessionCode})',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isMinimized ? Icons.expand_more : Icons.expand_less,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _isMinimized = !_isMinimized),
                    ),
                  ],
                ),
              ),

              if (!_isMinimized) ...[
                // Video Stream Placeholder / Status Window
                Container(
                  height: 120,
                  width: double.infinity,
                  color: const Color(0xFF1E1E2C),
                  child: Stack(
                    children: [
                      // Simulated video feed / call info
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D2D44),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isVideoMuted
                                    ? Icons.videocam_off_rounded
                                    : Icons.videocam_rounded,
                                color: _isVideoMuted ? Colors.redAccent : Colors.greenAccent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isVideoMuted
                                  ? 'Camera Muted'
                                  : 'Live Stream Connected 🟢',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${widget.userName} (${widget.isClinician ? 'Doctor' : 'Patient'})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Room Code Badge
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.sessionCode,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Mic
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _isAudioMuted ? Icons.mic_off : Icons.mic,
                          color: _isAudioMuted ? Colors.red : AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isAudioMuted = !_isAudioMuted),
                      ),
                      // Mute Video
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _isVideoMuted ? Icons.videocam_off : Icons.videocam,
                          color: _isVideoMuted ? Colors.red : AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isVideoMuted = !_isVideoMuted),
                      ),
                      // Launch External / Pop-out Call
                      ElevatedButton.icon(
                        onPressed: _openFullVideoCall,
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('Pop-out', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
