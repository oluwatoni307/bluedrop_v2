// lib/models/profile_goal_settings.dart

class ProfileGoalSettings {
  final double weightKg;
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final String location;
  final double temperatureC;
  final int humidity;
  final int exerciseMinutes;
  final String intent; // 'maintenance', 'weight_loss', 'skin_health', 'athletic', 'kidney_health'
  final bool pregnant;
  final bool breastfeeding;
  final bool feverOrIllness;
  final bool medicalRestriction;

  ProfileGoalSettings({
    required this.weightKg,
    this.activityLevel = 'moderate',
    this.location = 'Lagos',
    required this.temperatureC,
    required this.humidity,
    this.exerciseMinutes = 0,
    this.intent = 'maintenance',
    this.pregnant = false,
    this.breastfeeding = false,
    this.feverOrIllness = false,
    this.medicalRestriction = false,
  });

  /// Create settings with smart defaults based on location and season
  factory ProfileGoalSettings.withDefaults({
    required double weightKg,
    String activityLevel = 'moderate',
    String location = 'Lagos',
  }) {
    final month = DateTime.now().month;
    final isDrySeason = month >= 11 || month <= 3;

    final cityDefaults = {
      'Lagos': {'temp': 30.0, 'humidityDry': 50, 'humidityRainy': 80},
      'Abuja': {'temp': 28.0, 'humidityDry': 45, 'humidityRainy': 75},
      'Port Harcourt': {'temp': 31.0, 'humidityDry': 55, 'humidityRainy': 85},
      'Kano': {'temp': 29.0, 'humidityDry': 35, 'humidityRainy': 65},
      'Ibadan': {'temp': 29.5, 'humidityDry': 48, 'humidityRainy': 78},
    };

    final city = cityDefaults[location] ?? cityDefaults['Lagos']!;

    return ProfileGoalSettings(
      weightKg: weightKg,
      activityLevel: activityLevel,
      location: location,
      temperatureC: city['temp']! as double,
      humidity: (isDrySeason ? city['humidityDry']! : city['humidityRainy']!) as int,
    );
  }

  ProfileGoalSettings copyWith({
    double? weightKg,
    String? activityLevel,
    String? location,
    double? temperatureC,
    int? humidity,
    int? exerciseMinutes,
    String? intent,
    bool? pregnant,
    bool? breastfeeding,
    bool? feverOrIllness,
    bool? medicalRestriction,
  }) {
    return ProfileGoalSettings(
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      location: location ?? this.location,
      temperatureC: temperatureC ?? this.temperatureC,
      humidity: humidity ?? this.humidity,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      intent: intent ?? this.intent,
      pregnant: pregnant ?? this.pregnant,
      breastfeeding: breastfeeding ?? this.breastfeeding,
      feverOrIllness: feverOrIllness ?? this.feverOrIllness,
      medicalRestriction: medicalRestriction ?? this.medicalRestriction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'activityLevel': activityLevel,
      'location': location,
      'temperatureC': temperatureC,
      'humidity': humidity,
      'exerciseMinutes': exerciseMinutes,
      'intent': intent,
      'pregnant': pregnant,
      'breastfeeding': breastfeeding,
      'feverOrIllness': feverOrIllness,
      'medicalRestriction': medicalRestriction,
    };
  }

  factory ProfileGoalSettings.fromJson(Map<String, dynamic> json) {
    return ProfileGoalSettings(
      weightKg: (json['weightKg'] as num).toDouble(),
      activityLevel: json['activityLevel'] as String? ?? 'moderate',
      location: json['location'] as String? ?? 'Lagos',
      temperatureC: (json['temperatureC'] as num).toDouble(),
      humidity: json['humidity'] as int,
      exerciseMinutes: json['exerciseMinutes'] as int? ?? 0,
      intent: json['intent'] as String? ?? 'maintenance',
      pregnant: json['pregnant'] as bool? ?? false,
      breastfeeding: json['breastfeeding'] as bool? ?? false,
      feverOrIllness: json['feverOrIllness'] as bool? ?? false,
      medicalRestriction: json['medicalRestriction'] as bool? ?? false,
    );
  }
}