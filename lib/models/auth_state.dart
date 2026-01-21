/// Represents an authenticated user identity.
/// This is NOT UI state and NOT a profile.
/// It only exists after successful authentication.
class AuthUser {
  final String id;
  final String email;

  const AuthUser({required this.id, required this.email});

  /// Create AuthUser from raw data (e.g. Firebase user map)
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(id: json['id'] as String, email: json['email'] as String);
  }

  /// Convert AuthUser to raw map (for storage if needed)
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email};
  }

  AuthUser copyWith({String? id, String? email}) {
    return AuthUser(id: id ?? this.id, email: email ?? this.email);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

/// State class for Auth
class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({AuthUser? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
