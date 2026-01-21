// lib/utils/calculators/hydration_calculator.dart

class HydrationCalculator {
  // Activity multipliers
  static const Map<String, double> activityMultipliers = {
    'low': 1.0,
    'moderate': 1.2,
    'high': 1.5,
  };

  // Intent multipliers
  static const Map<String, double> intentMultipliers = {
    'maintenance': 1.0,
    'weight_loss': 1.15,
    'skin_glow': 1.20,
    'muscle_gain': 1.25,
    'kidney_health': 1.30,
    'detox': 1.35,
  };

  // Humidity multipliers
  static const Map<String, double> humidityMultipliers = {
    'low': 1.10,
    'normal': 1.0,
    'high': 1.05,
  };

  /// Calculate base hydration goal based on weight and activity level
  static double calculateBaseGoal(double weightKg, String activityLevel) {
    final multiplier = activityMultipliers[activityLevel] ?? 1.0;
    final base = weightKg * 35 * multiplier;

    // Apply minimum constraint
    return base < 1500 ? 1500 : (base > 10000 ? 10000 : base);
  }

  /// Apply environmental adjustments (temperature and humidity)
  static double applyEnvironmentalAdjustment(
    double baseGoal,
    double temperatureC,
    String humidityLevel,
  ) {
    // Temperature adjustment
    double tempMultiplier = 1.0;
    if (temperatureC > 30) {
      tempMultiplier = 1.2;
    } else if (temperatureC >= 25) {
      tempMultiplier = 1.1;
    }

    // Humidity adjustment
    final humidityMultiplier = humidityMultipliers[humidityLevel] ?? 1.0;

    return baseGoal * tempMultiplier * humidityMultiplier;
  }

  /// Apply exercise bonus (10ml per minute of exercise)
  static double applyExerciseBonus(double currentGoal, int exerciseMinutes) {
    return currentGoal + (exerciseMinutes * 10);
  }

  /// Apply wellness intent multiplier
  static double applyIntentMultiplier(double currentGoal, String intent) {
    final multiplier = intentMultipliers[intent] ?? 1.0;
    return currentGoal * multiplier;
  }

  /// Apply health condition additions
  static double applyHealthConditions(
    double currentGoal,
    Map<String, dynamic> conditions,
  ) {
    double adjusted = currentGoal;

    if (conditions['pregnant'] == true) {
      adjusted += 300;
    }
    if (conditions['breastfeeding'] == true) {
      adjusted += 700;
    }
    if (conditions['feverOrIllness'] == true) {
      adjusted += 500;
    }

    return adjusted;
  }

  /// Calculate final hydration goal from complete profile
  static int calculateFinalGoal(Map<String, dynamic> profile) {
    // Step 1: Base goal
    final weightKg = (profile['weightKg'] as num?)?.toDouble() ?? 70.0;
    final activityLevel = profile['activityLevel'] as String? ?? 'moderate';
    double goal = calculateBaseGoal(weightKg, activityLevel);

    // Step 2: Environmental adjustment
    final temperatureC = (profile['temperatureC'] as num?)?.toDouble() ?? 28.0;
    final humidityLevel = profile['humidityLevel'] as String? ?? 'normal';
    goal = applyEnvironmentalAdjustment(goal, temperatureC, humidityLevel);

    // Step 3: Exercise bonus
    final exerciseMinutes = (profile['exerciseMinutes'] as num?)?.toInt() ?? 0;
    goal = applyExerciseBonus(goal, exerciseMinutes);

    // Step 4: Intent multiplier
    final intent = profile['intent'] as String? ?? 'maintenance';
    goal = applyIntentMultiplier(goal, intent);

    // Step 5: Health conditions
    goal = applyHealthConditions(goal, profile);

    // Step 6: Apply constraints
    final medicalRestriction = profile['medicalRestriction'] as bool? ?? false;
    final maxGoal = medicalRestriction ? 2500.0 : 6000.0;
    goal = goal < 1500 ? 1500 : (goal > maxGoal ? maxGoal : goal);

    // Step 7: Round to nearest 50ml
    return ((goal / 50).round() * 50).toInt();
  }
}
