import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'analytics_model.dart';
import 'analytics_provider.dart';
import 'components/analytics_bar_chart.dart';
import 'components/period_selector.dart';
import 'components/summary_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);

    // Header text helper
    String getDateRangeText() {
      if (state.period == TimePeriod.custom &&
          state.customStart != null &&
          state.customEnd != null) {
        return '${DateFormat('MMM d').format(state.customStart!)} - ${DateFormat('MMM d').format(state.customEnd!)}';
      }
      return DateFormat('MMMM d, y').format(DateTime.now());
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analysis'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(analyticsProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SCOPE SELECTOR
              ScopeSelector(
                selectedPeriod: state.period,
                onChanged: (period) {
                  if (period == TimePeriod.custom) {
                    _pickDateRange(context, ref);
                  } else {
                    ref.read(analyticsProvider.notifier).setPeriod(period);
                  }
                },
              ),
              const SizedBox(height: 24),

              // 2. STREAK BADGE (Shows up if a milestone is reached)
              if (state.summary.currentStreak > 0)
                _StreakBadge(
                  milestone: state.summary.streakMilestone!,
                  phrase: state.summary.wittyPhrase!,
                  streakCount: state.summary.currentStreak,
                ),

              // 3. MAIN CHART
              Container(
                height: 340,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Hydration Trend",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          getDateRangeText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: state.isLoading && state.chartData.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : state.chartData.isEmpty
                          ? const Center(child: Text("No data available"))
                          : HydrationBarChart(dataPoints: state.chartData),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. STATS GRID
              const Text(
                "Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (state.isLoading && state.summary.totalVolume == 0)
                const Center(child: CircularProgressIndicator())
              else
                SummaryGrid(summary: state.summary),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      ref
          .read(analyticsProvider.notifier)
          .setCustomRange(result.start, result.end);
    }
  }
}

/// A dynamic badge that changes color and icon based on the user's streak milestone.
class _StreakBadge extends StatelessWidget {
  final String milestone;
  final String phrase;
  final int streakCount;

  const _StreakBadge({
    required this.milestone,
    required this.phrase,
    required this.streakCount,
  });

  // Helper to determine gradient colors and icon based on the milestone string
  (Color, Color, IconData) _getBadgeStyle() {
    switch (milestone) {
      case "7 Days":
        return (Colors.lightBlue[300]!, Colors.blue[600]!, Icons.water_drop);
      case "10 Days":
        return (Colors.teal[300]!, Colors.teal[600]!, Icons.waves);
      case "2 Weeks":
        return (Colors.indigo[300]!, Colors.indigo[600]!, Icons.pool);
      case "1 Month":
        return (Colors.purple[300]!, Colors.purple[600]!, Icons.anchor);
      case "6 Months":
        return (Colors.cyan[300]!, Colors.cyan[800]!, Icons.ac_unit); // Glacier
      case "1 Year":
        return (
          Colors.amber[400]!,
          Colors.orange[700]!,
          Icons.emoji_events,
        ); // King/Queen
      default:
        return (Colors.blue[400]!, Colors.blue[700]!, Icons.star);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (colorStart, colorEnd, badgeIcon) = _getBadgeStyle();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorStart, colorEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorEnd.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dynamic Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(badgeIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),

          // Milestone Text & Witty Phrase
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      milestone.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    // Show exact streak count in a tiny chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$streakCount 🔥",
                        style: TextStyle(
                          color: colorEnd,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  phrase,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
