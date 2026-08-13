import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_router.dart';
import 'services/auth_service.dart';

/// Root MaterialApp widget with routing, theming, and lifecycle management.
///
/// Monitors app lifecycle to force re-login after prolonged inactivity
/// (30+ minutes in background or killed from recents).
class BloomSpeechApp extends ConsumerStatefulWidget {
  const BloomSpeechApp({super.key});

  @override
  ConsumerState<BloomSpeechApp> createState() => _BloomSpeechAppState();
}

class _BloomSpeechAppState extends ConsumerState<BloomSpeechApp>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  /// If app is in background for longer than this, force re-login
  static const _sessionTimeoutDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Record when the app went to background
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground — check how long it was away
      if (_pausedAt != null) {
        final elapsed = DateTime.now().difference(_pausedAt!);
        if (elapsed > _sessionTimeoutDuration) {
          // Session expired — sign out and redirect to login
          debugPrint('Session timeout after ${elapsed.inMinutes} minutes. Forcing re-login.');
          _forceReLogin();
        }
        _pausedAt = null;
      }
    }
  }

  Future<void> _forceReLogin() async {
    try {
      await Supabase.instance.client.auth.signOut();
      ref.read(authServiceProvider).signOut();
    } catch (e) {
      debugPrint('Error during forced sign-out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BloomSpeech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
