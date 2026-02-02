// lib/features/auth/auth_model.dart
class UserProfile {
  final String name;
  final String email;
  final double? weight;
  final String? activityLevel;
  final String? climate; // <--- NEW: 'moderate', 'hot', 'cold'
  final List<String> healthConditions;
  final int? dailyGoal;
  final bool setupCompleted;
  final bool onboardingCompleted; // <--- NEW: Track if they saw tutorials
  final String createdAt;
  final String? updatedAt;

  const UserProfile({
    required this.name,
    required this.email,
    this.weight,
    this.activityLevel,
    this.climate,
    this.healthConditions = const [],
    this.dailyGoal,
    this.setupCompleted = false,
    this.onboardingCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] as String?,
      climate: json['climate'] as String?,
      healthConditions: List<String>.from(json['healthConditions'] ?? []),
      dailyGoal: json['dailyGoal'] as int?,
      setupCompleted: json['setupCompleted'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (weight != null) 'weight': weight,
      if (activityLevel != null) 'activityLevel': activityLevel,
      if (climate != null) 'climate': climate,
      'healthConditions': healthConditions,
      if (dailyGoal != null) 'dailyGoal': dailyGoal,
      'setupCompleted': setupCompleted,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    double? weight,
    String? activityLevel,
    String? climate,
    List<String>? healthConditions,
    int? dailyGoal,
    bool? setupCompleted,
    bool? onboardingCompleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      climate: climate ?? this.climate,
      healthConditions: healthConditions ?? this.healthConditions,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters for Router checks
  bool get isSetupComplete => setupCompleted && weight != null;
}
