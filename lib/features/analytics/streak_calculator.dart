import 'package:intl/intl.dart';
import '../water_logging/water_log.dart';
import 'analytics_model.dart';

class AnalyticsCalculator {
  /// Removes time components to prevent date comparison bugs
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Generates bars for Week, Month, or Custom views (Zero-filled)
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

    // Iterate through EVERY day in range to zero-fill missing days
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
        label = DateFormat('d').format(d); // 1, 2, 3...
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

  /// Generates 12 bars for the Year view (Monthly Averages)
  static List<ChartDataPoint> generateMonthlyPoints({
    required List<WaterLog> logs,
    required int year,
    required int dailyGoal,
  }) {
    final points = <ChartDataPoint>[];
    final Map<int, List<WaterLog>> monthBuckets = {};
    final now = DateTime.now();

    // Group logs by month
    for (var log in logs) {
      if (log.timestamp.year == year) {
        monthBuckets.putIfAbsent(log.timestamp.month, () => []).add(log);
      }
    }

    // Generate exactly 12 bars (Jan-Dec)
    for (int month = 1; month <= 12; month++) {
      final monthLogs = monthBuckets[month] ?? [];
      double average = 0;

      if (monthLogs.isNotEmpty) {
        final totalVol = monthLogs.fold(0, (sum, l) => sum + l.amount);

        // Accurate Average Logic:
        // If current month, divide by days elapsed so far.
        // If past month, divide by total days in that month.
        int divisor;
        if (year == now.year && month == now.month) {
          divisor = now.day;
        } else {
          divisor = DateTime(year, month + 1, 0).day;
        }

        average = divisor > 0 ? totalVol / divisor : totalVol.toDouble();
      }

      final date = DateTime(year, month, 1);
      points.add(
        ChartDataPoint(
          x: date,
          y: average,
          label: DateFormat('MMM').format(date), // Jan, Feb
          goal: dailyGoal.toDouble(),
          isMet: average >= dailyGoal,
        ),
      );
    }
    return points;
  }
}
