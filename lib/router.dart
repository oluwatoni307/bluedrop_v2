import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- SCREENS ---
// Ensure these paths match your project structure
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

// -----------------------------------------------------------------------------
// 1. APP STARTUP NOTIFIER
// -----------------------------------------------------------------------------
// This replaces the old StateProvider. It tracks if the splash screen logic is done.
final appStartupProvider = NotifierProvider<AppStartupNotifier, bool>(
  AppStartupNotifier.new,
);

class AppStartupNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Default state: App is NOT initialized
  }

  void setInitialized() {
    state = true;
  }
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
  // This validates that the router will rebuild if auth/startup state changes
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/splash',
    debugLogDiagnostics: true, // Useful for debugging redirects

    redirect: (context, state) {
      // --- A. STARTUP GATE ---
      // If app hasn't finished initializing, FORCE stay on Splash
      final isAppInitialized = ref.read(appStartupProvider);

      if (!isAppInitialized) {
        // If we are already on splash, do nothing (return null).
        // If we are elsewhere, go to splash.
        return state.uri.toString() == '/splash' ? null : '/splash';
      }

      // --- B. AUTHENTICATION LOGIC ---
      final authState = ref.read(authProvider);
      final auth = authState.value;

      final isLoading = authState.isLoading || authState.hasError;
      if (isLoading) return null; // Don't redirect while loading

      final isLoggedIn = auth?.isAuthenticated ?? false;
      final isFinishedOnboarding = auth?.profile?.onboardingCompleted ?? false;
      final isFinishedSetup = auth?.profile?.isSetupComplete ?? false;

      // Where are we trying to go?
      final location = state.uri.toString();

      // Define public routes
      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isSignup = location == '/signup';
      final isForgot = location == '/forgot-password';
      final isOnboarding = location == '/onboarding';
      final isSetup = location == '/setup';

      // Bundle all "Public" routes
      final isPublicRoute = isLogin || isSignup || isForgot || isSplash;

      // 1. If NOT logged in, block access to private pages
      if (!isLoggedIn) {
        return isPublicRoute ? null : '/login';
      }

      // // 2. If logged in but hasn't finished Onboarding
      // if (isLoggedIn && !isFinishedOnboarding) {
      //   return isOnboarding ? null : '/onboarding';
      // }

      // 3. If logged in, Onboarded, but hasn't finished Profile Setup
      if (isLoggedIn && isFinishedOnboarding && !isFinishedSetup) {
        return isSetup ? null : '/setup';
      }

      // 4. If fully authenticated, kick them OUT of public pages (like login/splash)
      if (isLoggedIn && (isPublicRoute || isOnboarding || isSetup)) {
        return '/'; // Send to Home
      }

      return null; // No redirection needed
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onInitialized: () {
            // Modern call to the Notifier to unlock the app
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

      // --- APP SHELL (Bottom Navigation) ---
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
        ],
      ),
      // --- INDEPENDENT ROUTES ---
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/log',
        name: 'log', // ✅ ADD THIS LINE
        parentNavigatorKey: _rootNavigatorKey, // ✅ ADD THIS (Covers bottom nav)
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
// 4. ROUTER NOTIFIER
// -----------------------------------------------------------------------------
// This bridges Riverpod state to GoRouter's refreshListenable
final routerNotifierProvider = AsyncNotifierProvider<RouterNotifier, void>(
  RouterNotifier.new,
);

class RouterNotifier extends AsyncNotifier<void> implements Listenable {
  VoidCallback? _listener;

  @override
  Future<void> build() async {
    // Watch Auth Provider: Any change here triggers a redirect check
    ref.listen(authProvider, (_, __) => _listener?.call());

    // Watch Startup Provider: Any change here triggers a redirect check
    ref.listen(appStartupProvider, (_, __) => _listener?.call());
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
