class UserProfile {
  final String name;
  final String email;
  final double? weight;
  final String? activityLevel; // 'low', 'moderate', 'high'
  final List<String> healthConditions;
  final int? dailyGoal; // in ml
  final bool setupCompleted;
  final String createdAt;
  final String? updatedAt;

  const UserProfile({
    required this.name,
    required this.email,
    this.weight,
    this.activityLevel,
    this.healthConditions = const [],
    this.dailyGoal,
    this.setupCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert from JSON/Map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] as String?,
      healthConditions: List<String>.from(json['healthConditions'] ?? []),
      dailyGoal: json['dailyGoal'] as int?,
      setupCompleted: json['setupCompleted'] as bool? ?? false,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String?,
    );
  }

  /// Convert to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (weight != null) 'weight': weight,
      if (activityLevel != null) 'activityLevel': activityLevel,
      'healthConditions': healthConditions,
      if (dailyGoal != null) 'dailyGoal': dailyGoal,
      'setupCompleted': setupCompleted,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    double? weight,
    String? activityLevel,
    List<String>? healthConditions,
    int? dailyGoal,
    bool? setupCompleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      healthConditions: healthConditions ?? this.healthConditions,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSetupComplete =>
      setupCompleted && weight != null && activityLevel != null;

  double get activityMultiplier {
    switch (activityLevel) {
      case 'low':
        return 1.0;
      case 'moderate':
        return 1.2;
      case 'high':
        return 1.5;
      default:
        return 1.0;
    }
  }

  String get activityDisplayName {
    switch (activityLevel) {
      case 'low':
        return 'Low (Sedentary)';
      case 'moderate':
        return 'Moderate (Active)';
      case 'high':
        return 'High (Very Active)';
      default:
        return 'Not set';
    }
  }

  String get healthConditionsDisplay {
    if (healthConditions.isEmpty) return 'None';
    return healthConditions
        .map(
          (c) => c.isNotEmpty ? '${c[0].toUpperCase()}${c.substring(1)}' : '',
        )
        .join(', ');
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, email: $email, weight: $weight, '
        'activityLevel: $activityLevel, dailyGoal: $dailyGoal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.name == name &&
        other.email == email &&
        other.weight == weight &&
        other.activityLevel == activityLevel &&
        other.dailyGoal == dailyGoal &&
        other.setupCompleted == setupCompleted;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        email.hashCode ^
        weight.hashCode ^
        activityLevel.hashCode ^
        dailyGoal.hashCode ^
        setupCompleted.hashCode;
  }
}
