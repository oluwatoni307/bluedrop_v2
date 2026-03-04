import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../router.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'auth_model.dart';

part 'auth_provider.g.dart';

/// ========== AUTH STATE ==========
class AuthState {
  final bool isLoading;
  final String? error;
  final UserProfile? profile;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserProfile? profile,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  AuthState clearError() => copyWith(error: null);
}

/// ========== PROVIDER ==========
@riverpod
class Auth extends _$Auth {
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  @override
  Future<AuthState> build() async {
    // ✅ FIX: Wait for the app (and database) to be fully initialized
    // before we attempt to read from it. This prevents a race condition
    // where authProvider tries to load the profile before Hive is ready.
    final isAppReady = ref.watch(appStartupProvider);
    if (!isAppReady) {
      return AuthState(isAuthenticated: false);
    }

    if (_authService.isLoggedIn) {
      final profile = await _loadProfile();
      return AuthState(isAuthenticated: true, profile: profile);
    }

    return AuthState(isAuthenticated: false);
  }

  // ===========================================================================
  // 🔐 AUTHENTICATION METHODS
  // ===========================================================================

  Future<bool> login(String email, String password) async {
    state = AsyncValue.data(state.value!.clearError());
    final validationError = _validateLoginInputs(email, password);

    if (validationError != null) {
      state = AsyncValue.data(state.value!.copyWith(error: validationError));
      return false;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _authService.signIn(email.trim(), password);
      await _databaseService.syncAllFromCloud();
      final profile = await _loadProfile();
      state = AsyncValue.data(
        state.value!.copyWith(
          isAuthenticated: true,
          profile: profile,
          isLoading: false,
        ),
      );
      return true;
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: _mapAuthError(e)),
      );
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = AsyncValue.data(state.value!.clearError());

    final validationError = _validateSignupInputs(
      name,
      email,
      password,
      confirmPassword,
    );
    if (validationError != null) {
      state = AsyncValue.data(state.value!.copyWith(error: validationError));
      return false;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _authService.register(email.trim(), password);
      await _databaseService.saveProfile({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'setupCompleted': false,
        'onboardingCompleted': false,
        'healthConditions': <String>[],
        'climate': 'moderate',
      });

      final profile = await _loadProfile();
      state = AsyncValue.data(
        state.value!.copyWith(
          isAuthenticated: true,
          profile: profile,
          isLoading: false,
        ),
      );
      return true;
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: _mapAuthError(e)),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    try {
      await _authService.signOut();
      state = AsyncValue.data(AuthState());
    } catch (_) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: 'Failed to logout'),
      );
    }
  }

  Future<bool> resetPassword(String email) async {
    state = AsyncValue.data(state.value!.clearError());
    if (email.trim().isEmpty || !email.contains('@')) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Valid email required'),
      );
      return false;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    try {
      await _authService.sendPasswordResetEmail(email.trim());
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
      return true;
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          error: 'Failed to send reset email',
        ),
      );
      return false;
    }
  }

  /// Submits the reset code and the new password to the service layer.
  /// Returns [true] if the operation is successful, or [false] if an error occurs.
  Future<bool> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    // 1. Clear previous errors and set the state to loading.
    state = AsyncValue.data(state.value!.clearError());
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      // 2. Await the service layer execution.
      await _authService.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );

      // 3. Upon success, remove the loading state.
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
      return true;
    } catch (e) {
      // 4. Upon failure, register the error and remove the loading state.
      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          error: _mapAuthError(e), // Utilizes your existing error mapping logic
        ),
      );
      return false;
    }
  }

  // ===========================================================================
  // 🚀 ONBOARDING & SETUP METHODS
  // ===========================================================================

  Future<bool> completeOnboarding() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    try {
      await _databaseService.updateProfile({
        'onboardingCompleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final profile = await _loadProfile();
      state = AsyncValue.data(
        state.value!.copyWith(profile: profile, isLoading: false),
      );
      return true;
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          error: 'Failed to save progress',
        ),
      );
      return false;
    }
  }

  Future<bool> completeProfileSetup({
    required double weight,
    required String activityLevel,
    required List<String> healthConditions,
    required String climate,
  }) async {
    state = AsyncValue.data(state.value!.clearError());

    if (weight < 20 || weight > 300) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Weight must be 20-300 kg'),
      );
      return false;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final dailyGoal = calculateDailyGoal(
        weight: weight,
        activityLevel: activityLevel,
        healthConditions: healthConditions,
        climate: climate,
      );

      await _databaseService.updateProfile({
        'weight': weight,
        'activityLevel': activityLevel,
        'healthConditions': healthConditions,
        'climate': climate,
        'dailyGoal': dailyGoal,
        'setupCompleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final profile = await _loadProfile();
      state = AsyncValue.data(
        state.value!.copyWith(profile: profile, isLoading: false),
      );
      return true;
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          error: 'Failed to save profile',
        ),
      );
      return false;
    }
  }

  Future<bool> recalculateDailyGoal() async {
    final profile = state.value?.profile;
    if (profile == null ||
        profile.weight == null ||
        profile.activityLevel == null) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Profile incomplete'),
      );
      return false;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final profileMap = await _databaseService.getProfile();
      final climate = profileMap?['climate'] ?? 'moderate';

      final newGoal = calculateDailyGoal(
        weight: profile.weight!,
        activityLevel: profile.activityLevel!,
        healthConditions: profile.healthConditions,
        climate: climate,
      );

      await _databaseService.updateProfile({
        'dailyGoal': newGoal,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final updatedProfile = await _loadProfile();
      state = AsyncValue.data(
        state.value!.copyWith(profile: updatedProfile, isLoading: false),
      );
      return true;
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: 'Recalculation failed'),
      );
      return false;
    }
  }

  // ===========================================================================
  // 🧠 CALCULATION LOGIC
  // ===========================================================================

  int calculateDailyGoal({
    required double weight,
    required String activityLevel,
    required List<String> healthConditions,
    required String climate,
  }) {
    double goal = weight * 35;

    if (activityLevel == 'high') {
      goal *= 1.5;
    } else if (activityLevel == 'moderate') {
      goal *= 1.2;
    }

    switch (climate) {
      case 'hot':
        goal += 500;
        break;
      case 'cold':
        goal += 300;
        break;
      default:
        break;
    }

    if (healthConditions.contains('kidney')) {
      goal *= 0.85;
    } else if (healthConditions.contains('pregnant')) {
      goal += 350;
    }

    if (goal < 1500) goal = 1500;
    if (goal > 5000) goal = 5000;

    return (goal / 50).round() * 50;
  }

  // ===========================================================================
  // 🛠️ PRIVATE HELPERS
  // ===========================================================================

  Future<UserProfile> _loadProfile() async {
    try {
      final profileMap = await _databaseService.getProfile();
      if (profileMap == null) {
        return UserProfile(
          name: '',
          email: _authService.userEmail ?? '',
          createdAt: DateTime.now().toIso8601String(),
        );
      }
      return UserProfile.fromJson(profileMap);
    } catch (e) {
      return UserProfile(
        name: '',
        email: _authService.userEmail ?? '',
        createdAt: DateTime.now().toIso8601String(),
      );
    }
  }

  void clearError() => state = AsyncValue.data(state.value!.clearError());

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    try {
      await _databaseService.updateProfile({
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final profile = await _loadProfile();
      state = AsyncValue.data(
        state.value!.copyWith(profile: profile, isLoading: false),
      );
      return true;
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: 'Update failed'),
      );
      return false;
    }
  }

  bool shouldPromptRecalculation(UserProfile oldProfile) {
    final newProfile = state.value?.profile;
    if (newProfile == null) return false;
    return oldProfile.weight != newProfile.weight ||
        oldProfile.activityLevel != newProfile.activityLevel ||
        oldProfile.healthConditions.length !=
            newProfile.healthConditions.length;
  }

  String? _validateLoginInputs(String email, String password) {
    if (email.trim().isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Enter a valid email address';
    if (password.isEmpty) return 'Password is required';
    return null;
  }

  String? _validateSignupInputs(
    String name,
    String email,
    String password,
    String confirm,
  ) {
    if (name.trim().isEmpty) return 'Name is required';
    if (email.trim().isEmpty || !email.contains('@'))
      return 'Valid email required';
    if (password.length < 6) return 'Min 6 characters required';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  String _mapAuthError(dynamic error) {
    final e = error.toString().toLowerCase();
    if (e.contains('wrong-password')) return 'Incorrect password';
    if (e.contains('email-already-in-use')) return 'Email already registered';
    if (e.contains('network')) return 'No internet connection';
    return 'Authentication failed. Please try again.';
  }
}
