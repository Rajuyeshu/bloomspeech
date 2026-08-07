import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/kid_join_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/child/child_list_screen.dart';
import '../../screens/child/add_child_screen.dart';
import '../../screens/child/child_profile_screen.dart';
import '../../screens/session/session_setup_screen.dart';
import '../../screens/session/theme_selection_screen.dart';
import '../../screens/session/active_session_screen.dart';
import '../../screens/session/kid_session_screen.dart';
import '../../screens/session/session_summary_screen.dart';
import '../../screens/session/session_history_screen.dart';
import '../../screens/reward/reward_screen.dart';
import '../../screens/reward/mini_games/bubble_burst_game.dart';
import '../../screens/reward/mini_games/plant_water_game.dart';
import '../../screens/reward/mini_games/rangoli_paint_game.dart';
import '../../screens/progress/progress_dashboard.dart';
import '../../screens/progress/session_compare_screen.dart';
import '../../screens/settings/settings_screen.dart';

/// App router configuration
class AppRouter {
  // Route names
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String kidJoin = 'kidJoin';
  static const String home = 'home';
  static const String children = 'children';
  static const String addChild = 'addChild';
  static const String editChild = 'editChild';
  static const String childProfile = 'childProfile';
  static const String sessionSetup = 'sessionSetup';
  static const String themeSelection = 'themeSelection';
  static const String activeSession = 'activeSession';
  static const String kidSession = 'kidSession';
  static const String sessionSummary = 'sessionSummary';
  static const String sessionHistory = 'sessionHistory';
  static const String reward = 'reward';
  static const String bubbleBurst = 'bubbleBurst';
  static const String plantWater = 'plantWater';
  static const String rangoliPaint = 'rangoliPaint';
  static const String progressDashboard = 'progressDashboard';
  static const String sessionCompare = 'sessionCompare';
  static const String settings = 'settings';

  // Route paths
  static const String splashPath = '/';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String kidJoinPath = '/kid-join';
  static const String homePath = '/home';
  static const String childrenPath = '/children';
  static const String addChildPath = '/children/add';
  static const String editChildPath = '/children/edit/:childId';
  static const String childProfilePath = '/children/:childId';
  static const String sessionSetupPath = '/session/setup/:childId';
  static const String themeSelectionPath = '/session/themes';
  static const String activeSessionPath = '/session/active';
  static const String kidSessionPath = '/session/kid/:sessionCode';
  static const String sessionSummaryPath = '/session/summary';
  static const String sessionHistoryPath = '/session/history/:childId';
  static const String rewardPath = '/reward';
  static const String bubbleBurstPath = '/reward/bubble-burst';
  static const String plantWaterPath = '/reward/plant-water';
  static const String rangoliPaintPath = '/reward/rangoli-paint';
  static const String progressDashboardPath = '/progress/:childId';
  static const String sessionComparePath = '/progress/compare/:childId';
  static const String settingsPath = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRouter.splashPath,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authState.value ?? ref.read(authServiceProvider).currentUser;
      final isLoggedIn = user != null;
      final isLoading = authState.isLoading && user == null;
      final isAuthRoute = state.matchedLocation == AppRouter.loginPath ||
          state.matchedLocation == AppRouter.registerPath;
      final isSplash = state.matchedLocation == AppRouter.splashPath;
      final isKidJoin = state.matchedLocation == AppRouter.kidJoinPath;
      final isKidSession = state.matchedLocation.startsWith('/session/kid/');
      final isRewardRoute = state.matchedLocation.startsWith('/reward');

      // Allow kid join, active session, and reward screens regardless of auth
      if (isKidJoin || isKidSession || isRewardRoute) return null;

      // Still loading auth state — stay on splash
      if (isLoading && isSplash) return null;

      // Not logged in and not on auth route — redirect to login
      if (!isLoggedIn && !isAuthRoute && !isSplash) {
        return AppRouter.loginPath;
      }

      // Logged in and on auth route — redirect to home
      if (isLoggedIn && (isAuthRoute || isSplash)) {
        return AppRouter.homePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRouter.splashPath,
        name: AppRouter.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRouter.loginPath,
        name: AppRouter.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRouter.registerPath,
        name: AppRouter.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRouter.kidJoinPath,
        name: AppRouter.kidJoin,
        builder: (context, state) => const KidJoinScreen(),
      ),
      GoRoute(
        path: AppRouter.homePath,
        name: AppRouter.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.childrenPath,
        name: AppRouter.children,
        builder: (context, state) => const ChildListScreen(),
      ),
      GoRoute(
        path: AppRouter.addChildPath,
        name: AppRouter.addChild,
        builder: (context, state) => const AddChildScreen(),
      ),
      GoRoute(
        path: AppRouter.editChildPath,
        name: AppRouter.editChild,
        builder: (context, state) => AddChildScreen(
          childId: state.pathParameters['childId'],
        ),
      ),
      GoRoute(
        path: AppRouter.childProfilePath,
        name: AppRouter.childProfile,
        builder: (context, state) => ChildProfileScreen(
          childId: state.pathParameters['childId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.sessionSetupPath,
        name: AppRouter.sessionSetup,
        builder: (context, state) => SessionSetupScreen(
          childId: state.pathParameters['childId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.themeSelectionPath,
        name: AppRouter.themeSelection,
        builder: (context, state) => const ThemeSelectionScreen(),
      ),
      GoRoute(
        path: AppRouter.activeSessionPath,
        name: AppRouter.activeSession,
        builder: (context, state) => const ActiveSessionScreen(),
      ),
      GoRoute(
        path: AppRouter.kidSessionPath,
        name: AppRouter.kidSession,
        builder: (context, state) => KidSessionScreen(
          sessionCode: state.pathParameters['sessionCode']!,
        ),
      ),
      GoRoute(
        path: AppRouter.sessionSummaryPath,
        name: AppRouter.sessionSummary,
        builder: (context, state) => const SessionSummaryScreen(),
      ),
      GoRoute(
        path: AppRouter.sessionHistoryPath,
        name: AppRouter.sessionHistory,
        builder: (context, state) => SessionHistoryScreen(
          childId: state.pathParameters['childId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.rewardPath,
        name: AppRouter.reward,
        builder: (context, state) => const RewardScreen(),
      ),
      GoRoute(
        path: AppRouter.bubbleBurstPath,
        name: AppRouter.bubbleBurst,
        builder: (context, state) => const BubbleBurstGame(),
      ),
      GoRoute(
        path: AppRouter.plantWaterPath,
        name: AppRouter.plantWater,
        builder: (context, state) => const PlantWaterGame(),
      ),
      GoRoute(
        path: AppRouter.rangoliPaintPath,
        name: AppRouter.rangoliPaint,
        builder: (context, state) => const RangoliPaintGame(),
      ),
      GoRoute(
        path: AppRouter.progressDashboardPath,
        name: AppRouter.progressDashboard,
        builder: (context, state) => ProgressDashboard(
          childId: state.pathParameters['childId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.sessionComparePath,
        name: AppRouter.sessionCompare,
        builder: (context, state) => SessionCompareScreen(
          childId: state.pathParameters['childId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.settingsPath,
        name: AppRouter.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
