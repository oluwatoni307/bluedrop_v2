import '../models/water_log.dart';

class HydrationState {
  final double dailyGoal;
  final double currentIntake;
  final List<WaterLog> todayLogs;
  final bool isLoading;
  final String? errorMessage;

  HydrationState({
    required this.dailyGoal,
    required this.currentIntake,
    required this.todayLogs,
    required this.isLoading,
    this.errorMessage,
  });

  double get progress => (currentIntake / dailyGoal).clamp(0.0, 1.0);

  double get progressPercentage => (progress * 100).clamp(0.0, 100.0);

  bool get isGoalReached => currentIntake >= dailyGoal;

  double get remainingAmount {
    final remaining = dailyGoal - currentIntake;
    return remaining > 0 ? remaining : 0;
  }

  // ✅ FIXED: Proper handling of nullable errorMessage
  HydrationState copyWith({
    double? dailyGoal,
    double? currentIntake,
    List<WaterLog>? todayLogs,
    bool? isLoading,
    Object? errorMessage = _undefined, // Use sentinel value
  }) {
    return HydrationState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      currentIntake: currentIntake ?? this.currentIntake,
      todayLogs: todayLogs ?? this.todayLogs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _undefined
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

// Sentinel value to distinguish between "not passed" and "passed as null"
const _undefined = Object();
