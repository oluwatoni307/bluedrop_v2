import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- SCREENS ---
import 'app_shell.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'features/auth/screens/profile_setup_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/splash.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Get current auth state
      final auth = authState.value;

      // Define path variables
      final location = state.uri.toString();
      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isSignup = location == '/signup';
      final isForgot = location == '/forgot-password';
      final isOnboarding = location == '/onboarding';
      final isSetup = location == '/setup';

      // Group "Public" routes (Routes that don't require login)
      final isPublicRoute = isLogin || isSignup || isForgot || isOnboarding;

      final isAuthenticated = auth?.isAuthenticated ?? false;
      final isSetupComplete = auth?.profile?.isSetupComplete ?? false;

      // 1. If Auth is still initializing (loading), stay on Splash
      if (authState.isLoading || auth == null) return null;

      // 2. --- NOT LOGGED IN ---
      if (!isAuthenticated) {
        // If on a public page (Login/Signup/etc), let them stay
        if (isPublicRoute) return null;

        // If on Splash or any internal page, go to Login
        return '/login';
      }

      // 3. --- LOGGED IN BUT NO SETUP ---
      if (!isSetupComplete) {
        return isSetup ? null : '/setup';
      }

      // 4. --- FULLY LOGGED IN & SETUP ---
      // If user is on Splash, Login, or Setup, move them to Home
      if (isSplash || isPublicRoute || isSetup) {
        return '/';
      }

      // Allow all other navigation (Analytics, Settings, etc.)
      return null;
    },
    routes: [
      // --- PUBLIC AUTH ROUTES ---
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

      // --- PROFILE SETUP (Transition state) ---
      GoRoute(
        path: '/setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // --- APP SHELL (Main Navigation) ---
      ShellRoute(
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
            path: '/goals',
            name: 'goals',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GoalsHubPage()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: '/setting',
            name: 'setting',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),

      // --- SETTINGS SUB-ROUTES (Outside Shell) ---
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

      // --- LOGGING SCREENS (Overlay/Fullscreen, outside shell) ---
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
