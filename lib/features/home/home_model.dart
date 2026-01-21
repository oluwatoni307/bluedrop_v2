class TodayProgress {
  final int totalAmount; // ml logged today
  final int goalAmount; // daily goal
  final double percentage; // achievement %
  final int logsCount; // number of logs today
  final DateTime date; // today's date

  const TodayProgress({
    required this.totalAmount,
    required this.goalAmount,
    required this.percentage,
    required this.logsCount,
    required this.date,
  });

  TodayProgress copyWith({
    int? totalAmount,
    int? goalAmount,
    double? percentage,
    int? logsCount,
    DateTime? date,
  }) {
    return TodayProgress(
      totalAmount: totalAmount ?? this.totalAmount,
      goalAmount: goalAmount ?? this.goalAmount,
      percentage: percentage ?? this.percentage,
      logsCount: logsCount ?? this.logsCount,
      date: date ?? this.date,
    );
  }
}

class LastLog {
  final int amount; // ml
  final DateTime timestamp; // when logged
  final String drinkType; // water/tea/etc

  const LastLog({
    required this.amount,
    required this.timestamp,
    required this.drinkType,
  });

  LastLog copyWith({int? amount, DateTime? timestamp, String? drinkType}) {
    return LastLog(
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      drinkType: drinkType ?? this.drinkType,
    );
  }
}
