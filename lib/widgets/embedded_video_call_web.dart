// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Register a Jitsi iframe view factory for web platform
void registerJitsiIframe(String roomName, String url) {
  final viewType = 'jitsi-iframe-$roomName';

  // Register only once per room
  try {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'camera; microphone; display-capture; autoplay; clipboard-write'
        ..setAttribute('allowfullscreen', 'true');
      return iframe;
    });
  } catch (_) {
    // Already registered — this is fine
  }
}

/// Build the HtmlElementView widget for web
Widget buildJitsiView(String roomName) {
  return HtmlElementView(viewType: 'jitsi-iframe-$roomName');
}
