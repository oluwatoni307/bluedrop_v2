import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../services/database_service.dart';

import '../water_logging/water_log.dart';
import 'analytics_calculator.dart';
import 'analytics_model.dart';

part 'analytics_provider.g.dart';

@riverpod
class Analytics extends _$Analytics {
  @override
  AnalyticsState build() {
    // Auto-load on first build
    Future.microtask(() => loadData());
    return const AnalyticsState(isLoading: true);
  }

  // --- ACTIONS ---

  void setPeriod(TimePeriod p) {
    if (state.period == p) return;
    state = state.copyWith(period: p, isLoading: true);
    loadData();
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      period: TimePeriod.custom,
      customStart: start,
      customEnd: end,
      isLoading: true,
    );
    loadData();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await loadData();
  }

  // --- CORE LOGIC ---

  Future<void> loadData() async {
    try {
      final db = DatabaseService();

      // Fetch Goal (Default: 2500)
      final profile = await db.getProfile();
      final goal = (profile?['dailyGoal'] as num?)?.toInt() ?? 2500;

      // Calculate Dates
      final (start, end, prevStart, prevEnd) = _calculateRanges();

      // Parallel Fetch (Current + Previous Period for trends)
      final results = await Future.wait([
        db.queryCollection(
          'waterLogs',
          startDate: start,
          endDate: end.add(const Duration(days: 1)),
        ),
        db.queryCollection(
          'waterLogs',
          startDate: prevStart,
          endDate: prevEnd.add(const Duration(days: 1)),
        ),
      ]);

      final currentLogs = results[0].map((e) => WaterLog.fromJson(e)).toList();
      final prevLogs = results[1].map((e) => WaterLog.fromJson(e)).toList();

      // 1. Generate Chart Data
      List<ChartDataPoint> chartData;
      if (state.period == TimePeriod.year) {
        chartData = AnalyticsCalculator.generateMonthlyPoints(
          logs: currentLogs,
          year: start.year,
          dailyGoal: goal,
        );
      } else {
        chartData = AnalyticsCalculator.generateDailyPoints(
          logs: currentLogs,
          startDate: start,
          endDate: end,
          dailyGoal: goal,
        );
      }

      // 2. Generate KPIs
      final currVol = currentLogs.fold(0, (sum, e) => sum + e.amount);
      final prevVol = prevLogs.fold(0, (sum, e) => sum + e.amount);

      // Daily Average
      final days = end.difference(start).inDays + 1;
      final dailyAvg = days > 0 ? currVol / days : 0.0;

      // Completion Rate
      final successfulDays = chartData.where((p) => p.isMet).length;
      final rate = chartData.isNotEmpty
          ? successfulDays / chartData.length
          : 0.0;

      // Trend Percentage
      double trendPct = 0;
      if (prevVol > 0) {
        trendPct = ((currVol - prevVol) / prevVol).abs() * 100;
      }

      state = state.copyWith(
        isLoading: false,
        chartData: chartData,
        summary: AnalyticsSummary(
          totalVolume: currVol.toDouble(),
          dailyAverage: dailyAvg,
          completionRate: rate,
          trendUp: currVol >= prevVol,
          trendPercent: trendPct,
        ),
      );
    } catch (e) {
      print("❌ Analytics Error: $e");
      state = state.copyWith(isLoading: false, error: "Could not load data.");
    }
  }

  /// Calculates date ranges safely based on selected period
  (DateTime, DateTime, DateTime, DateTime) _calculateRanges() {
    final now = AnalyticsCalculator.normalizeDate(DateTime.now());
    DateTime start, end;

    switch (state.period) {
      case TimePeriod.week:
        end = now;
        start = end.subtract(const Duration(days: 6));
        break;
      case TimePeriod.month:
        end = now;
        start = end.subtract(const Duration(days: 29));
        break;
      case TimePeriod.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      case TimePeriod.custom:
        start = state.customStart ?? now;
        end = state.customEnd ?? now;
        break;
    }

    final duration = end.difference(start).inDays + 1;
    final prevEnd = start.subtract(const Duration(days: 1));
    final prevStart = prevEnd.subtract(Duration(days: duration - 1));

    return (start, end, prevStart, prevEnd);
  }
}
