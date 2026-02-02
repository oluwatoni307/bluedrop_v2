import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- SCREENS ---
import 'app_shell.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/splash.dart';
import 'features/cabinet/ContainerCabinetPage.dart';
import 'features/home/home_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/hub/presentation/pages/Hub_page.dart';
import 'features/settings/pages/edit_screen.dart';
import 'features/settings/setting.dart';
import 'features/water_logging/screens/custom_log_screen.dart';
import 'features/water_logging/screens/presets_screen.dart';
import 'features/water_logging/screens/water_log_page.dart';

// --- PROVIDERS ---
import 'features/auth/auth_provider.dart';

// ✅ FIX 1: Define Keys OUTSIDE the provider so they persist
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // ✅ FIX 2: Watch the Notifier, not the Auth State directly
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    // This allows the router to react to changes without rebuilding itself
    refreshListenable: notifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      // ✅ Use READ here, because the refreshListenable triggers the check
      final authState = ref.read(authProvider);
      final auth = authState.value;

      final location = state.uri.toString();
      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isSignup = location == '/signup';
      final isForgot = location == '/forgot-password';
      final isOnboarding = location == '/onboarding';
      final isSetup = location == '/setup';

      final isPublicRoute = isLogin || isSignup || isForgot || isOnboarding;
      final isAuthenticated = auth?.isAuthenticated ?? false;

      final hasFinishedOnboarding = auth?.profile?.onboardingCompleted ?? false;
      final hasFinishedSetup = auth?.profile?.isSetupComplete ?? false;

      // 1. Loading Phase
      if (authState.isLoading || auth == null) return null;

      // 2. Not Logged In
      if (!isAuthenticated) {
        if (isPublicRoute) return null;
        return '/login';
      }

      // 3. Logged In: Gate 1 (Onboarding)
      if (!hasFinishedOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      // 4. Logged In: Gate 2 (Setup)
      if (!hasFinishedSetup) {
        return isSetup ? null : '/setup';
      }

      // 5. Fully Authenticated
      if (isSplash || isPublicRoute || isSetup) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // --- APP SHELL ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/cabinet',
            name: 'cabinet',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ContainerCabinetPage()),
          ),
          GoRoute(
            path: '/goals',
            name: 'goals',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GoalsHubPage()),
          ),
          GoRoute(
            path: '/setting',
            name: 'setting',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileSetupScreen()),
          ),
        ],
      ),

      // --- SUB ROUTES ---
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/setting/notifications',
        name: 'notifications',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text("Notifications Settings (Coming Soon)")),
        ),
      ),
      GoRoute(
        path: '/log',
        name: 'log',
        builder: (context, state) => const WaterLogPage(),
      ),
      GoRoute(
        path: '/presets',
        name: 'presets',
        builder: (context, state) => const PresetsScreen(),
      ),
      GoRoute(
        path: '/custom-log',
        name: 'custom-log',
        builder: (context, state) => const CustomLogScreen(),
      ),
    ],
  );
});

// ✅ HELPER: Bridges Auth changes to Router refresh
final routerNotifierProvider = AsyncNotifierProvider<RouterNotifier, void>(() {
  return RouterNotifier();
});

class RouterNotifier extends AsyncNotifier<void> implements Listenable {
  VoidCallback? _listener;

  @override
  Future<void> build() async {
    // Listen to Auth and notify the router when it changes
    ref.listen(authProvider, (_, __) {
      _listener?.call();
    });
  }

  @override
  void addListener(VoidCallback listener) {
    _listener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _listener = null;
  }
}
