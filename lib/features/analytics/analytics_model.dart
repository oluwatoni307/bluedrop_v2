enum TimePeriod { week, month, year, custom }

// lib/features/analytics/models/analytics_models.dart

class ChartDataPoint {
  final DateTime x;
  final double
  y; // <--- Ensure this is named 'y' and is NOT nullable (double, not double?)
  final String label;
  final double goal;
  final bool isMet;

  const ChartDataPoint({
    required this.x,
    required this.y, // <--- matched here
    required this.label,
    required this.goal,
    required this.isMet,
  });
}

// lib/features/analytics/models/analytics_model.dart

class AnalyticsSummary {
  final double totalVolume;
  final double dailyAverage;
  final double completionRate;
  final bool trendUp;
  final double trendPercent;
  // NEW FIELDS
  final int currentStreak;
  final String? streakMilestone; // e.g., "7 Days"
  final String? wittyPhrase;

  const AnalyticsSummary({
    this.totalVolume = 0,
    this.dailyAverage = 0,
    this.completionRate = 0,
    this.trendUp = true,
    this.trendPercent = 0,
    this.currentStreak = 0,
    this.streakMilestone,
    this.wittyPhrase,
  });
}

class AnalyticsState {
  final TimePeriod period;
  final List<ChartDataPoint> chartData;
  final AnalyticsSummary summary;
  final bool isLoading;
  final String? error;

  // Custom Range Helpers
  final DateTime? customStart;
  final DateTime? customEnd;

  const AnalyticsState({
    this.period = TimePeriod.week,
    this.chartData = const [],
    this.summary = const AnalyticsSummary(),
    this.isLoading = false,
    this.error,
    this.customStart,
    this.customEnd,
  });

  AnalyticsState copyWith({
    TimePeriod? period,
    List<ChartDataPoint>? chartData,
    AnalyticsSummary? summary,
    bool? isLoading,
    String? error,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return AnalyticsState(
      period: period ?? this.period,
      chartData: chartData ?? this.chartData,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }
}
