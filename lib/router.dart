import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

import 'features/auth/auth_provider.dart';

// -----------------------------------------------------------------------------
// 1. APP STARTUP NOTIFIER
// -----------------------------------------------------------------------------
final appStartupProvider = NotifierProvider<AppStartupNotifier, bool>(
  AppStartupNotifier.new,
);

class AppStartupNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setInitialized() => state = true;
}

// -----------------------------------------------------------------------------
// 2. NAVIGATOR KEYS
// -----------------------------------------------------------------------------
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// -----------------------------------------------------------------------------
// 3. ROUTER PROVIDER
// -----------------------------------------------------------------------------
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode, // ✅ Only logs in debug builds

    redirect: (context, state) {
      final isAppInitialized = ref.read(appStartupProvider);
      final location = state.uri.toString();

      // --- A. STARTUP GATE ---
      if (!isAppInitialized) {
        return location == '/splash' ? null : '/splash';
      }

      // --- B. AUTH STATE ---
      final authState = ref.read(authProvider);

      // Still loading → don't redirect
      if (authState.isLoading) return null;

      // Auth error → send to login so user isn't stuck
      if (authState.hasError) return '/login';

      final auth = authState.value;
      final isLoggedIn = auth?.isAuthenticated ?? false;
      final isFinishedOnboarding = auth?.profile?.onboardingCompleted ?? false;
      final isFinishedSetup = auth?.profile?.isSetupComplete ?? false;

      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isSignup = location == '/signup';
      final isForgot = location == '/forgot-password';
      final isOnboarding = location == '/onboarding';
      final isSetup = location == '/setup';
      final isPublicRoute = isLogin || isSignup || isForgot || isSplash;

      // 1. Not logged in → block private pages
      if (!isLoggedIn) {
        return isPublicRoute ? null : '/login';
      }

      // 2. Logged in but hasn't finished onboarding
      if (!isFinishedOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      // 3. Onboarded but hasn't finished setup
      if (!isFinishedSetup) {
        return isSetup ? null : '/setup';
      }

      // 4. Fully authenticated → kick out of public/setup pages
      if (isPublicRoute || isOnboarding || isSetup) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onInitialized: () {
            ref.read(appStartupProvider.notifier).setInitialized();
          },
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // --- APP SHELL ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
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
        ],
      ),

      // --- INDEPENDENT ROUTES ---
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/log',
        name: 'log',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WaterLogPage(),
      ),
      GoRoute(
        path: '/presets',
        builder: (context, state) => const PresetsScreen(),
      ),
      GoRoute(
        path: '/custom-log',
        builder: (context, state) => const CustomLogScreen(),
      ),
    ],
  );
});

// -----------------------------------------------------------------------------
// 4. ROUTER NOTIFIER — Fixed: sync, multi-listener support
// -----------------------------------------------------------------------------
final routerNotifierProvider = NotifierProvider<RouterNotifier, void>(
  // ✅ No longer Async
  RouterNotifier.new,
);

class RouterNotifier extends Notifier<void> implements Listenable {
  final List<VoidCallback> _listeners = []; // ✅ Supports multiple listeners

  @override
  void build() {
    // ✅ No longer async — listeners are registered immediately
    ref.listen(authProvider, (_, __) => _notifyAll());
    ref.listen(appStartupProvider, (_, __) => _notifyAll());
  }

  void _notifyAll() {
    for (final l in _listeners) l();
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}
