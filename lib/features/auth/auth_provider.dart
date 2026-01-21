import 'package:riverpod_annotation/riverpod_annotation.dart';
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
    // Show loading state implicitly by returning the appropriate AuthState
    state = AsyncValue.data(AuthState(isLoading: true));

    if (_authService.isLoggedIn) {
      print('🔄 User already logged in, syncing from cloud...');

      try {
        await _databaseService.syncAllFromCloud();
        print('✅ Initial sync complete');
      } catch (e) {
        print('⚠️ Initial sync failed: $e');
        // Continue anyway - might be offline
      }

      final profile = await _loadProfile();
      return AuthState(isAuthenticated: true, profile: profile);
    }

    return AuthState(isAuthenticated: false);
  }

  // ========== AUTHENTICATION METHODS ==========
  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = AsyncValue.data(state.value!.clearError());
    final validationError = _validateLoginInputs(email, password);

    if (validationError != null) {
      state = AsyncValue.data(state.value!.copyWith(error: validationError));
      return false;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      // 1. Sign in with Firebase
      await _authService.signIn(email.trim(), password);

      // 2. 🔥 SYNC FROM CLOUD - This is the critical fix!
      print('🔄 Syncing user data from cloud after login...');
      await _databaseService.syncAllFromCloud();
      print('✅ Sync complete - profile should be in Hive now');

      // 3. Now load profile from Hive (it's been synced from Firestore)
      final profile = await _loadProfile();

      // 4. Debug log to verify
      print('📊 Profile loaded: setupCompleted = ${profile.setupCompleted}');

      state = AsyncValue.data(
        state.value!.copyWith(
          isAuthenticated: true,
          profile: profile,
          isLoading: false,
        ),
      );
      return true;
    } catch (e) {
      print('❌ Login failed: $e');
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: _mapAuthError(e)),
      );
      return false;
    }
  }

  /// Sign up with name, email, and password
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
        'healthConditions': <String>[],
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

  /// Logout user
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

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    state = AsyncValue.data(state.value!.clearError());

    if (email.trim().isEmpty) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Email is required'),
      );
      return false;
    }

    if (!email.trim().contains('@')) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Enter a valid email address'),
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

  // ========== PROFILE METHODS ==========

  /// Load user profile from database (public method)
  Future<void> loadProfile() async {
    try {
      final profile = await _loadProfile();
      state = AsyncValue.data(state.value!.copyWith(profile: profile));
    } catch (e) {
      // Profile loading failed, keep current state
      print('❌ Failed to load profile: $e');
    }
  }

  /// Complete profile setup (weight, activity, health)
  Future<bool> completeProfileSetup({
    required double weight,
    required String activityLevel,
    required List<String> healthConditions,
  }) async {
    state = AsyncValue.data(state.value!.clearError());

    // Validate inputs
    if (weight < 20 || weight > 300) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Weight must be between 20 and 300 kg'),
      );
      return false;
    }

    if (!['low', 'moderate', 'high'].contains(activityLevel)) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Invalid activity level'),
      );
      return false;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      // Calculate initial daily goal
      final dailyGoal = calculateDailyGoal(
        weight: weight,
        activityLevel: activityLevel,
        healthConditions: healthConditions,
      );

      // Update profile with setup data
      await _databaseService.updateProfile({
        'weight': weight,
        'activityLevel': activityLevel,
        'healthConditions': healthConditions,
        'dailyGoal': dailyGoal,
        'setupCompleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Reload profile
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

  /// Update profile field(s)
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      // Send Map to DatabaseService
      await _databaseService.updateProfile({
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Reload profile (converts to Model)
      final profile = await _loadProfile();
      state = AsyncValue.data(
        state.value!.copyWith(profile: profile, isLoading: false),
      );

      return true;
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          error: 'Failed to update profile',
        ),
      );
      return false;
    }
  }

  /// Recalculate daily goal based on current profile
  Future<bool> recalculateDailyGoal() async {
    final profile = state.value?.profile;

    if (profile == null) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Profile not loaded'),
      );
      return false;
    }

    if (profile.weight == null || profile.activityLevel == null) {
      state = AsyncValue.data(
        state.value!.copyWith(error: 'Profile data incomplete'),
      );
      return false;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final newGoal = calculateDailyGoal(
        weight: profile.weight!,
        activityLevel: profile.activityLevel!,
        healthConditions: profile.healthConditions,
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
        state.value!.copyWith(
          isLoading: false,
          error: 'Failed to recalculate goal',
        ),
      );
      return false;
    }
  }

  /// Calculate daily hydration goal
  int calculateDailyGoal({
    required double weight,
    required String activityLevel,
    required List<String> healthConditions,
  }) {
    // Activity multipliers (hidden from user)
    final multipliers = {'low': 1.0, 'moderate': 1.2, 'high': 1.5};

    // Base calculation: weight × 35 × activity multiplier
    double goal = weight * 35 * (multipliers[activityLevel] ?? 1.0);

    // Health adjustments
    if (healthConditions.contains('diabetic')) {
      goal *= 1.15; // +15%
    }
    if (healthConditions.contains('pregnant')) {
      goal += 300; // +300ml flat
    }
    if (healthConditions.contains('kidney')) {
      goal *= 1.10; // +10%
    }

    // Apply floor and ceiling
    if (goal < 1500) goal = 1500;
    if (goal > 5000) goal = 5000;

    return goal.round();
  }

  /// Check if critical profile values changed (triggers recalc prompt)
  bool shouldPromptRecalculation(UserProfile oldProfile) {
    final newProfile = state.value?.profile;
    if (newProfile == null) return false;

    // Check if critical fields changed
    return oldProfile.weight != newProfile.weight ||
        oldProfile.activityLevel != newProfile.activityLevel ||
        oldProfile.healthConditions != newProfile.healthConditions;
  }

  /// Clear error message
  void clearError() {
    state = AsyncValue.data(state.value!.clearError());
  }

  // ========== PRIVATE HELPERS ==========

  /// Load profile from database (private helper)
  Future<UserProfile> _loadProfile() async {
    try {
      final profileMap = await _databaseService.getProfile();
      return UserProfile.fromJson(profileMap!);
    } catch (e) {
      // Fallback for new user
      return UserProfile(
        name: '',
        email: _authService.userEmail ?? '',
        createdAt: DateTime.now().toIso8601String(),
      );
    }
  }

  // ========== VALIDATORS ==========

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
    String confirmPassword,
  ) {
    if (name.trim().isEmpty) return 'Name is required';
    if (name.trim().length < 2) return 'Name must be at least 2 characters';
    if (name.trim().length > 50) return 'Name is too long';
    if (email.trim().isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Enter a valid email address';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }

  String _mapAuthError(dynamic error) {
    final e = error.toString().toLowerCase();
    if (e.contains('user-not-found')) return 'No account found with this email';
    if (e.contains('wrong-password')) return 'Incorrect password';
    if (e.contains('invalid-email')) return 'Invalid email address';
    if (e.contains('user-disabled')) return 'This account has been disabled';
    if (e.contains('email-already-in-use')) {
      return 'This email is already registered';
    }
    if (e.contains('weak-password')) return 'Password is too weak';
    if (e.contains('network')) return 'No internet connection';
    if (e.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }
    if (e.contains('operation-not-allowed')) {
      return 'Email/password accounts are not enabled';
    }
    return 'Authentication failed. Please try again.';
  }
}
