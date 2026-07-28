import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_options.dart';
import 'app.dart';

/// Entry point for BloomSpeech
/// 
/// Initializes Supabase backend and sets up the app with Riverpod state management.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase backend
  try {
    await Supabase.initialize(
      url: SupabaseOptions.url,
      anonKey: SupabaseOptions.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  runApp(
    const ProviderScope(
      child: BloomSpeechApp(),
    ),
  );
}
