import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms.
/// These methods are no-ops on mobile/desktop.

void registerJitsiIframe(String roomName, String url) {
  // No-op on non-web platforms
}

Widget buildJitsiView(String roomName) {
  return const Center(
    child: Text(
      'Video call running natively',
      style: TextStyle(color: Colors.white70),
    ),
  );
}
