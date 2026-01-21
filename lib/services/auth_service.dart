// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';

/// AuthService - Handles authentication and user ID management
///
/// Features:
/// - Firebase Authentication integration
/// - Auth state tracking
/// - Automatic userId propagation to DatabaseService
/// - Simple sign in/out methods
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================
  // GETTERS
  // ============================================

  /// Get current user ID (null if not logged in)
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Get user email
  String? get userEmail => _auth.currentUser?.email;

  /// Get user display name
  String? get displayName => _auth.currentUser?.displayName;

  // ============================================
  // AUTH STATE STREAM
  // ============================================

  /// Stream of user ID changes (null when logged out)
  ///
  /// Use this to rebuild UI based on auth state
  ///
  /// Example:
  /// authService.authStateChanges.listen((userId) {
  ///   if (userId != null) {
  ///     // User logged in
  ///   } else {
  ///     // User logged out
  ///   }
  /// });
  Stream<String?> get authStateChanges {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  /// Stream of User objects (null when logged out)
  Stream<User?> get userChanges => _auth.userChanges();

  // ============================================
  // AUTHENTICATION METHODS
  // ============================================

  /// Sign in with email and password
  ///
  /// Returns userId on success
  /// Throws FirebaseAuthException on failure
  ///
  /// Example:
  /// try {
  ///   final userId = await authService.signIn(email, password);
  ///   print('Logged in: $userId');
  /// } on FirebaseAuthException catch (e) {
  ///   print('Login failed: ${e.message}');
  /// }
  Future<String> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;
      print('✅ Signed in: $userId');
      return userId;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in failed: ${e.message}');
      rethrow;
    }
  }

  /// Register new user with email and password
  ///
  /// Returns userId on success
  /// Throws FirebaseAuthException on failure
  ///
  /// Example:
  /// try {
  ///   final userId = await authService.register(email, password);
  ///   print('Account created: $userId');
  /// } on FirebaseAuthException catch (e) {
  ///   print('Registration failed: ${e.message}');
  /// }
  Future<String> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;
      print('✅ Account created: $userId');
      return userId;
    } on FirebaseAuthException catch (e) {
      print('❌ Registration failed: ${e.message}');
      rethrow;
    }
  }

  /// Sign out current user
  ///
  /// Example:
  /// await authService.signOut();
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ Signed out');
    } catch (e) {
      print('❌ Sign out failed: $e');
      rethrow;
    }
  }

  /// Send password reset email
  ///
  /// Example:
  /// await authService.sendPasswordResetEmail(email);
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset failed: ${e.message}');
      rethrow;
    }
  }

  /// Update user display name
  ///
  /// Example:
  /// await authService.updateDisplayName('John Doe');
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();
      print('✅ Display name updated: $displayName');
    } catch (e) {
      print('❌ Update display name failed: $e');
      rethrow;
    }
  }

  /// Update user email
  ///
  /// Requires recent authentication
  ///
  /// Example:
  /// await authService.updateEmail('newemail@example.com');
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
      print('✅ Verification email sent to: $newEmail');
    } on FirebaseAuthException catch (e) {
      print('❌ Update email failed: ${e.message}');
      rethrow;
    }
  }

  /// Update user password
  ///
  /// Requires recent authentication
  ///
  /// Example:
  /// await authService.updatePassword('newPassword123');
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      print('✅ Password updated');
    } on FirebaseAuthException catch (e) {
      print('❌ Update password failed: ${e.message}');
      rethrow;
    }
  }

  /// Re-authenticate user (required before sensitive operations)
  ///
  /// Example:
  /// await authService.reauthenticate(email, password);
  /// await authService.updatePassword(newPassword);
  Future<void> reauthenticate(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      print('✅ Re-authenticated');
    } on FirebaseAuthException catch (e) {
      print('❌ Re-authentication failed: ${e.message}');
      rethrow;
    }
  }

  /// Delete current user account
  ///
  /// Requires recent authentication
  ///
  /// Example:
  /// await authService.reauthenticate(email, password);
  /// await authService.deleteAccount();
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      print('✅ Account deleted');
    } on FirebaseAuthException catch (e) {
      print('❌ Delete account failed: ${e.message}');
      rethrow;
    }
  }

  /// Send email verification
  ///
  /// Example:
  /// await authService.sendEmailVerification();
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      print('✅ Verification email sent');
    } catch (e) {
      print('❌ Send verification email failed: $e');
      rethrow;
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Reload current user (refresh auth state)
  ///
  /// Example:
  /// await authService.reloadUser();
  /// if (authService.isEmailVerified) { ... }
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      print('✅ User reloaded');
    } catch (e) {
      print('❌ Reload user failed: $e');
      rethrow;
    }
  }

  // ============================================
  // UTILITIES
  // ============================================

  /// Get formatted Firebase error message
  ///
  /// Example:
  /// try {
  ///   await authService.signIn(email, password);
  /// } on FirebaseAuthException catch (e) {
  ///   showError(authService.getErrorMessage(e));
  /// }
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Check if error requires re-authentication
  bool requiresReauth(FirebaseAuthException e) {
    return e.code == 'requires-recent-login';
  }
}
