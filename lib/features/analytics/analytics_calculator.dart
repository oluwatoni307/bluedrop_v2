import 'package:intl/intl.dart';

import '../water_logging/water_log.dart';
import 'analytics_model.dart';

class AnalyticsCalculator {
  // 1. DATE NORMALIZER (The Bug Killer)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 2. CHART GENERATOR (Zero-Fill Logic)
  static List<ChartDataPoint> generateDailyPoints({
    required List<WaterLog> logs,
    required DateTime startDate,
    required DateTime endDate,
    required int dailyGoal,
  }) {
    final points = <ChartDataPoint>[];
    final normalizedStart = normalizeDate(startDate);
    final normalizedEnd = normalizeDate(endDate);

    // O(1) Lookup Map
    final Map<String, int> dailyTotals = {};
    for (var log in logs) {
      final key = DateFormat('yyyy-MM-dd').format(log.timestamp);
      dailyTotals.update(
        key,
        (val) => val + log.amount,
        ifAbsent: () => log.amount,
      );
    }

    // Iterate through EVERY day
    for (
      var d = normalizedStart;
      d.isBefore(normalizedEnd) || d.isAtSameMomentAs(normalizedEnd);
      d = d.add(const Duration(days: 1))
    ) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      final total = dailyTotals[key]?.toDouble() ?? 0.0;

      // Smart Labeling
      String label;
      final rangeDays = normalizedEnd.difference(normalizedStart).inDays;
      if (rangeDays <= 7) {
        label = DateFormat('E').format(d); // Mon, Tue
      } else {
        label = DateFormat('d').format(d); // 1, 2, 3
      }

      points.add(
        ChartDataPoint(
          x: d,
          y: total,
          label: label,
          goal: dailyGoal.toDouble(),
          isMet: total >= dailyGoal,
        ),
      );
    }
    return points;
  }

  // 3. MONTHLY AGGREGATOR (With "Current Month" Fix)
  static List<ChartDataPoint> generateMonthlyPoints({
    required List<WaterLog> logs,
    required int year,
    required int dailyGoal,
  }) {
    final points = <ChartDataPoint>[];
    final Map<int, List<WaterLog>> monthBuckets = {};
    final now = DateTime.now();

    // Group by month
    for (var log in logs) {
      if (log.timestamp.year == year) {
        monthBuckets.putIfAbsent(log.timestamp.month, () => []).add(log);
      }
    }

    // Generate 12 months
    for (int month = 1; month <= 12; month++) {
      final monthLogs = monthBuckets[month] ?? [];
      double average = 0;

      if (monthLogs.isNotEmpty) {
        final totalVol = monthLogs.fold(0, (sum, l) => sum + l.amount);

        // 🔥 FIX: If it's the current month, divide by days elapsed, not total days
        int divisor;
        if (year == now.year && month == now.month) {
          divisor = now.day; // e.g., 5th of Jan = divide by 5
        } else {
          // Days in month logic (0th day of next month = last day of current)
          divisor = DateTime(year, month + 1, 0).day;
        }

        // Prevent division by zero (e.g., 1st of month just started)
        average = divisor > 0 ? totalVol / divisor : totalVol.toDouble();
      }

      final date = DateTime(year, month, 1);
      points.add(
        ChartDataPoint(
          x: date,
          y: average,
          label: DateFormat('MMM').format(date),
          goal: dailyGoal.toDouble(),
          isMet: average >= dailyGoal,
        ),
      );
    }
    return points;
  }
}
